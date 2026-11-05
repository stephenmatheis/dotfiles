-- `nvim -l ~/.config/hax0r/page-full.lua <out.html> [theme] [label]`: a web page of a full-color
-- theme (Dark Modern unless one is named) in each app, drawn from palettes.lua in exact colors, then
-- the choices still open for it, each drawn as it is now and with the other options. delta's panel
-- is delta's own output, run with the theme's settings and turned into HTML; VS Code, nvim, Claude
-- Code and the shell are mocks drawn by each app's rules; the other apps' panels list the files
-- `hax0r build` wrote for them. page.lua does this for the one-color themes. label names the
-- version shown, like a commit.
local config = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. '/.config')
local P = dofile(config .. '/hax0r/palettes.lua')
local out = assert(arg[1], 'usage: nvim -l page-full.lua <out.html> [theme] [label]')
local name = arg[2] or 'dark-modern'
local label = arg[3]
local C = assert(P[name], 'no theme called ' .. name)
assert(C.full_color, name .. ' is a one-color theme: page.lua draws those')

local function rgb(h)
  return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16)
end

local function luminance(h)
  local sum, weights = 0, { 0.2126, 0.7152, 0.0722 }
  for i, v in ipairs({ rgb(h) }) do
    v = v / 255
    sum = sum + weights[i] * (v <= 0.04045 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4)
  end
  return sum
end

local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
end

-- top composited over base at p (0 to 1), as palettes.lua does it
local function mix(top, base, p)
  local hex = '#'
  for i = 2, 6, 2 do
    local t, b = tonumber(top:sub(i, i + 1), 16), tonumber(base:sub(i, i + 1), 16)
    hex = hex .. ('%02x'):format(math.floor(b + (t - b) * p + 0.5))
  end
  return hex
end

local function esc(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'))
end

-- A color: a hex, ansiN for terminal slot N, a palette key, or a dotted path into one of the
-- palette's tables (syntax.keyword, brackets.1)
local function col(c, x)
  if x:sub(1, 1) == '#' then return x end
  local slot = x:match('^ansi(%d+)$')
  if slot then return c.ansi[tonumber(slot)] end
  local v = c
  for key in x:gmatch('[^.]+') do
    v = type(v) == 'table' and v[tonumber(key) or key] or nil
  end
  return assert(v, 'no color ' .. x)
end

-- parts: { text, color, attrs, background, line color }
-- attrs: b bold, i italic, u underline, s strikethrough, ~ undercurl and o outline in the line
-- color, t a line along the top in it (VS Code's active tab), f faint (Ghostty's dim, halfway to
-- the background)
local function span(c, p, back)
  local text, attrs = p[1], p[3] or ''
  local bg = p[4] and col(c, p[4])
  local color = col(c, p[2] or 'fg')
  if attrs:find('f') then color = mix(color, bg or back, 0.5) end
  local style = { 'color:' .. color }
  if bg and bg ~= back then table.insert(style, 'background:' .. bg) end
  if attrs:find('b') then table.insert(style, 'font-weight:700') end
  if attrs:find('i') then table.insert(style, 'font-style:italic') end
  local deco = {}
  if attrs:find('u') then table.insert(deco, 'underline') end
  if attrs:find('s') then table.insert(deco, 'line-through') end
  if #deco > 0 then table.insert(style, 'text-decoration:' .. table.concat(deco, ' ')) end
  if attrs:find('~') then
    table.insert(style, 'text-decoration:underline wavy ' .. col(c, p[5]))
    table.insert(style, 'text-decoration-skip-ink:none;text-underline-offset:0.25em')
  end
  if attrs:find('o') then table.insert(style, 'box-shadow:inset 0 0 0 1px ' .. col(c, p[5])) end
  if attrs:find('t') then table.insert(style, 'box-shadow:inset 0 1px 0 ' .. col(c, p[5])) end
  return ('<span style="%s">%s</span>'):format(table.concat(style, ';'), esc(text))
end

-- A row of parts on a background. o.outline draws VS Code's current-line border around it, and
-- o.class adds a class (side: the sidebar's width)
local function line(c, parts, back, o)
  o = o or {}
  back = col(c, back or 'bg')
  local html = {}
  for _, p in ipairs(parts) do
    table.insert(html, span(c, p, back))
  end
  local style = 'background:' .. back
  if o.outline then style = style .. ';box-shadow:inset 0 0 0 1px ' .. col(c, o.outline) end
  return ('<div class="ln%s" style="%s">%s</div>'):format(o.class and ' ' .. o.class or '', style, table.concat(html))
end

local function chip(hex)
  return ('<span class="chip"><i style="background:%s"></i>%s</span>'):format(hex, hex)
end

local function copy(c, changes)
  local t = vim.deepcopy(c)
  for k, v in pairs(changes or {}) do
    if k == 'ansi' then
      for slot, hex in pairs(v) do t.ansi[slot] = hex end
    else
      t[k] = v
    end
  end
  return t
end

-- The same code in VS Code and nvim, each token a kind from the syntax table. ( and ) are brackets,
-- colored by how deep they sit, as VS Code's bracket pair colors and nvim's rainbow-delimiters do
local CODE = {
  { { 'import', 'control' }, { ' ' }, { '{', '(' }, { ' readFile ', 'variable' }, { '}', ')' }, { ' ' },
    { 'from', 'control' }, { ' ' }, { "'node:fs/promises'", 'string' } },
  { { '// Load a theme by name, or null if it has no file', 'comment' } },
  { { 'const', 'storage' }, { ' ' }, { 'MAX_THEMES', 'constant' }, { ' = ', 'operator' }, { '12', 'number' } },
  {},
  { { 'export', 'control' }, { ' ' }, { 'async', 'storage' }, { ' ' }, { 'function', 'storage' }, { ' ' },
    { 'load', 'func' }, { '(', '(' }, { 'name', 'variable' }, { ': ', 'operator' }, { 'string', 'type' },
    { ')', ')' }, { ': ', 'operator' }, { 'Promise', 'type' }, { '<', 'delimiter' }, { 'Theme', 'type', 'err' },
    { '>', 'delimiter' }, { ' ' }, { '{', '(' } },
  { { '  ' }, { 'const', 'storage' }, { ' ' }, { 'text', 'variable', 'cur' }, { ' = ', 'operator' }, { 'await', 'control' },
    { ' ' }, { 'readFile', 'func' }, { '(', '(' }, { '`themes/', 'string' }, { '${', 'keyword' }, { 'name', 'variable' },
    { '}', 'keyword' }, { '.json`', 'string' }, { ', ', 'delimiter' }, { "'utf8'", 'string' }, { ')', ')' } },
  { { '  ' }, { 'if', 'control' }, { ' ' }, { '(', '(' }, { '!', 'operator' }, { 'text', 'variable', 'match' },
    { ')', ')' }, { ' ' }, { 'return', 'control' }, { ' ' }, { 'null', 'builtin' } },
  { { '  ' }, { 'return', 'control' }, { ' ' }, { 'JSON', 'type' }, { '.', 'delimiter' }, { 'parse', 'func' },
    { '(', '(' }, { 'text', 'variable', 'match' }, { ')', ')' }, { ' ' }, { 'as', 'control' }, { ' ' }, { 'Theme', 'type' } },
  { { '}', ')' } },
}
local CURSOR = 6 -- the line the cursor is on, 1-based
local MARKS = { [3] = 'mark_added', [6] = 'mark_changed', [8] = 'mark_removed' }
local SELECTED = 'MAX_THEMES'

-- CODE's line i as parts: syntax colors, bracket depth, the search matches (match and cur), the
-- selection and an error under Theme. back: the line's background
local function code_parts(c, i, depth, back)
  local parts = {}
  for _, tok in ipairs(CODE[i]) do
    local text, kind, flag = tok[1], tok[2], tok[3]
    local color, bg, attrs, sp = 'syntax.delimiter', back, '', nil
    if kind == '(' then
      depth = depth + 1
      color = ('brackets.%d'):format((depth - 1) % #c.brackets + 1)
    elseif kind == ')' then
      color = ('brackets.%d'):format((depth - 1) % #c.brackets + 1)
      depth = depth - 1
    elseif kind then
      color = 'syntax.' .. kind
    end
    if flag == 'cur' then bg = 'cur_search' end
    if flag == 'match' then bg = 'search' end
    if text == SELECTED then bg = 'selection_tint' end
    if flag == 'err' then attrs, sp = '~', 'error' end
    local styles = kind and c.styles[kind] or ''
    if styles:find('bold') then attrs = attrs .. 'b' end
    if styles:find('italic') then attrs = attrs .. 'i' end
    table.insert(parts, { text, color, attrs, bg, sp })
  end
  return parts, depth
end

-- VS Code: the explorer beside the editor, the tabs above it and the status bar under it
local function vscode_mock(c)
  local rows = {}
  local function row(side, main, main_back, o)
    table.insert(rows, '<div class="split">' .. line(c, side, 'dark', { class = 'side' }) .. line(c, main, main_back or 'bg', o) .. '</div>')
  end
  local files = {
    { { ' EXPLORER', 'fg' } },
    { { ' ∨ hax0r', 'fg', 'b' } },
    { { '   app.ts', 'changed', '', 'unfocused_row' }, { '            M ', 'changed', '', 'unfocused_row' } },
    { { '   theme.ts', 'untracked' }, { '          U', 'untracked' } },
    { { '   old.ts', 'removed', 's' }, { '            D', 'removed' } },
    { { '   util.ts               ', 'fg', '', 'hover' } },
    { { '   README.md', 'fg' } },
    { { ' > dist', 'ignored' } },
    { { ' > node_modules', 'ignored' } },
    {},
  }
  table.insert(rows, line(c, { { ' ●  ●  ●', 'dim' }, { '                    app.ts — hax0r', 'fg' } }, 'dark'))
  row({ { '' } }, { { ' app.ts ', 'bright', 't', 'bg', 'focus' }, { ' M ', 'changed', '', 'bg' },
    { ' README.md ', 'dim', '', 'dark' }, { '                                ', 'dim', '', 'dark' } }, 'dark')
  local depth = 0
  for i = 1, #CODE do
    local nr = { ('%4d '):format(i), i == CURSOR and 'line_nr_active' or 'line_nr' }
    local mark = { MARKS[i] and (MARKS[i] == 'mark_removed' and '▸' or '▎') or ' ', MARKS[i] or 'bg' }
    local parts
    parts, depth = code_parts(c, i, depth, 'bg')
    table.insert(parts, 1, { ' ' })
    table.insert(parts, 1, mark)
    table.insert(parts, 1, nr)
    row(files[i] or {}, parts, 'bg', i == CURSOR and { outline = 'cursor_line' } or nil)
  end
  row(files[10] or {}, {})
  table.insert(rows, line(c, { { ' >< ', '#ffffff', '', 'focus' }, { '  ⎇ main*   ', 'fg', '', 'dark' }, { '⊗ 1 ', 'fg', '', 'dark' },
    { ' ⚠ 0', 'fg', '', 'dark' }, { '              Ln 6, Col 9   Spaces: 2   UTF-8   TypeScript ', 'fg', '', 'dark' } }, 'dark'))
  return table.concat(rows)
end

-- nvim: the same code with gitsigns' marks, the cursor line, search, a diagnostic, the completion
-- menu and the statusline
local function nvim_mock(c)
  local rows = {}
  local depth = 0
  for i = 1, #CODE do
    local back = i == CURSOR and 'cursor_line' or 'bg'
    local parts
    parts, depth = code_parts(c, i, depth, back)
    -- indent guides in the function's body, the current scope's brighter
    if i >= 6 and i <= 8 then
      parts[1] = { '│ ', 'indent_active' }
    end
    table.insert(parts, 1, { MARKS[i] and (MARKS[i] == 'mark_removed' and '▁' or '▎') or ' ', MARKS[i] or 'bg' })
    table.insert(parts, 1, { ('%3d '):format(i), i == CURSOR and 'line_nr_active' or 'line_nr' })
    if i == 5 then
      table.insert(parts, { "  ■ Cannot find name 'Theme'.", 'error' })
    end
    table.insert(rows, line(c, parts, back))
    if i == CURSOR then
      for _, item in ipairs({ { ' readFile  ', ' Function ', true }, { ' readdir   ', ' Function ' }, { ' realpath  ', ' Function ' } }) do
        local bg, fg = item[3] and 'menu_sel' or 'float_bg', item[3] and 'menu_sel_text' or 'fg'
        table.insert(rows, line(c, { { '                         ' }, { item[1], fg, '', bg }, { item[2], item[3] and fg or 'dim', '', bg } }))
      end
    end
  end
  table.insert(rows, line(c, { { '  ~', 'nontext' } }))
  table.insert(rows, line(c, { { ' NORMAL ', 'statusline', 'b', 'dark' }, { ' app.ts [+] ', 'statusline', '', 'dark' },
    { ' +3', 'added', '', 'dark' }, { ' ~1', 'changed', '', 'dark' }, { ' -2', 'removed', '', 'dark' },
    { '                               6:9 ', 'statusline', '', 'dark' } }, 'dark'))
  table.insert(rows, line(c, { { '/text', 'fg' } }))
  return table.concat(rows)
end

-- Claude Code in Ghostty: a prompt, a reply with inline code, an edit and its diff, a ! command,
-- a permission question and the mode line. Its diff bands are Ghostty's slots 22, 28, 52 and 88
local function claude_mock(c, o)
  o = o or {}
  local rows = {}
  local function add(parts, back) table.insert(rows, line(c, parts, back)) end
  add({ { ' ❯ ', 'fg', '', 'prompt_band' }, { 'make the code text match nvim', 'fg', '', 'prompt_band' },
    { '                    ', 'fg', '', 'prompt_band' } }, 'prompt_band')
  add({})
  add({ { ' ● ', 'claude' }, { 'Setting ', 'fg' }, { 'ansi 7', 'ansi12' }, { ' to ', 'fg' }, { 'fg', 'ansi12' },
    { ' in ', 'fg' }, { 'palettes.lua', 'ansi12' }, { ', see ', 'fg' }, { 'the docs', 'link', 'u' }, { '.', 'fg' } })
  add({})
  add({ { ' ● ', 'success' }, { 'Update', 'fg', 'b' }, { '(hax0r/palettes.lua)', 'fg' } })
  add({ { '   ⎿  Updated hax0r/palettes.lua with 1 addition and 1 removal', 'dim' } })
  add({ { '      7 ', 'ansi7', 'f', 'diff_del' }, { '-', 'ansi7', '', 'diff_del' }, { "  [7] = '", 'ansi7', '', 'diff_del' },
    { '#e5e5e5', 'ansi7', '', 'diff_del_word' }, { "',", 'ansi7', '', 'diff_del' }, { ' -- white', 'ansi8', '', 'diff_del' },
    { '         ', 'ansi7', '', 'diff_del' } }, 'diff_del')
  add({ { '      7 ', 'ansi7', 'f', 'diff_add' }, { '+', 'ansi7', '', 'diff_add' }, { "  [7] = '", 'ansi7', '', 'diff_add' },
    { '#cccccc', 'ansi7', '', 'diff_add_word' }, { "',", 'ansi7', '', 'diff_add' }, { ' -- fg', 'ansi8', '', 'diff_add' },
    { '            ', 'ansi7', '', 'diff_add' } }, 'diff_add')
  add({})
  add({ { ' ! ', 'white', '', 'bash_band' }, { 'git status -s', 'fg', '', 'bash_band' }, { '                                 ', 'fg', '', 'bash_band' } }, 'bash_band')
  add({ { '   ⎿   M hax0r/palettes.lua', 'dim' } })
  add({})
  add({ { ' ✻ ', 'claude' }, { 'Thin', 'claude' }, { 'kin', 'claude_shimmer' }, { 'g… ', 'claude' }, { '(esc to interrupt)', 'dim' } })
  add({})
  add({ { ' Do you want to make this edit to palettes.lua?', 'fg', 'b' } })
  add({ { ' ❯ 1. Yes', 'permission' } })
  add({ { '   2. Yes, allow all edits this session', 'fg' } })
  add({ { '   3. No', 'fg' } })
  add({})
  add({ { ' ╭───────────────────────────────────────────╮', 'dim' } })
  add({ { ' │ > ', 'dim' }, { 'Try "fix lint errors"', 'dim' }, { '                    │', 'dim' } })
  add({ { ' ╰───────────────────────────────────────────╯', 'dim' } })
  add({ { '   ⏵⏵ accept edits on', 'white' }, { ' (shift+tab to cycle)', 'dim' }, { '   ', 'fg' },
    { '▰▰▰▰▰', 'normal' }, { '▱▱▱', 'gray' }, { ' 62%', 'dim' } })
  return table.concat(rows)
end

-- The shell: Starship's prompt, git's own colors, a failed command
local function shell_mock(c)
  local rows = {}
  local function add(parts) table.insert(rows, line(c, parts)) end
  local prompt = { { '❯ ', 'ansi5' } }
  add({ { '~/.config/hax0r', 'ansi4' }, { ' main', 'ansi8' }, { ' *', 'ansi15' }, { ' 2s', 'ansi3' } })
  add({ prompt[1], { 'git status -s', 'fg' } })
  add({ { ' M', 'ansi1' }, { ' palettes.lua', 'fg' } })
  add({ { 'A ', 'ansi2' }, { ' page-full.lua', 'fg' } })
  add({ { '??', 'ansi1' }, { ' notes.md', 'fg' } })
  add({ prompt[1], { 'git log --oneline -2', 'fg' } })
  add({ { 'a3f9c21 (', 'ansi3' }, { 'HEAD -> ', 'ansi6', 'b' }, { 'main', 'ansi2', 'b' }, { ', ', 'ansi3' },
    { 'origin/main', 'ansi1', 'b' }, { ')', 'ansi3' }, { ' feat: add Dark Modern', 'fg' } })
  add({ { '9a1487e', 'ansi3' }, { ' chore: tidy palettes', 'fg' } })
  add({ prompt[1], { 'false', 'fg' } })
  add({ { '~/.config/hax0r', 'ansi4' }, { ' main', 'ansi8' }, { ' *', 'ansi15' } })
  add({ { '❯ ', 'error' } })
  return table.concat(rows)
end

-- The 16 terminal colors, then the diff and error slots hax0r adds
local function ansi_strip(c)
  local cells = {}
  for i = 0, 15 do
    table.insert(cells, ('<i title="%d %s" style="background:%s"></i>'):format(i, c.ansi[i], c.ansi[i]))
  end
  return ('<div class="strip" style="background:%s">%s</div>'):format(c.bg, table.concat(cells))
end

-- delta, run for real on a small change with the settings `hax0r build` wrote for this theme, and
-- its ANSI output drawn in the theme's terminal colors
local function xterm(n)
  if n < 16 then return nil end
  if n >= 232 then
    local v = 8 + (n - 232) * 10
    return ('#%02x%02x%02x'):format(v, v, v)
  end
  n = n - 16
  local steps = { 0, 95, 135, 175, 215, 255 }
  return ('#%02x%02x%02x'):format(steps[math.floor(n / 36) + 1], steps[math.floor(n / 6) % 6 + 1], steps[n % 6 + 1])
end

local function ansi_html(c, text)
  text = text:gsub('\27%].-\7', ''):gsub('\27%].-\27\\', '')
  local state = {}
  local function color_of(slot)
    return c.ansi[slot] or (slot == 22 and c.diff_add) or (slot == 28 and c.diff_add_word) or (slot == 52 and c.diff_del)
      or (slot == 88 and c.diff_del_word) or (slot == 196 and c.error) or xterm(slot)
  end
  local function sgr(params)
    local codes = {}
    for n in (params == '' and '0' or params):gmatch('[^;]+') do table.insert(codes, tonumber(n)) end
    local i = 1
    while i <= #codes do
      local n = codes[i]
      if n == 0 then state = {}
      elseif n == 1 then state.bold = true
      elseif n == 2 then state.dim = true
      elseif n == 3 then state.italic = true
      elseif n == 4 then state.ul = true
      elseif n == 22 then state.bold, state.dim = nil, nil
      elseif n == 23 then state.italic = nil
      elseif n == 24 then state.ul = nil
      elseif n >= 30 and n <= 37 then state.fg = c.ansi[n - 30]
      elseif n >= 90 and n <= 97 then state.fg = c.ansi[n - 82]
      elseif n == 39 then state.fg = nil
      elseif n >= 40 and n <= 47 then state.bg = c.ansi[n - 40]
      elseif n >= 100 and n <= 107 then state.bg = c.ansi[n - 92]
      elseif n == 49 then state.bg = nil
      elseif (n == 38 or n == 48) and codes[i + 1] == 5 then
        state[n == 38 and 'fg' or 'bg'] = color_of(codes[i + 2]); i = i + 2
      elseif (n == 38 or n == 48) and codes[i + 1] == 2 then
        state[n == 38 and 'fg' or 'bg'] = ('#%02x%02x%02x'):format(codes[i + 2], codes[i + 3], codes[i + 4]); i = i + 4
      end
      i = i + 1
    end
  end
  local rows = {}
  for raw in (text .. '\n'):gmatch('(.-)\n') do
    -- \27[K clears to the end of the line in the current background: delta's bands reach the edge
    local parts, pos, fill = {}, 1, nil
    while pos <= #raw do
      local s, e, params, kind = raw:find('\27%[([%d;]*)(%a)', pos)
      local chunk = raw:sub(pos, (s or #raw + 1) - 1)
      if #chunk > 0 then
        local attrs = (state.bold and 'b' or '') .. (state.italic and 'i' or '') .. (state.ul and 'u' or '') .. (state.dim and 'f' or '')
        table.insert(parts, { chunk, state.fg or c.fg, attrs, state.bg })
      end
      if not s then break end
      if kind == 'm' then sgr(params) elseif kind == 'K' then fill = state.bg end
      pos = e + 1
    end
    table.insert(rows, line(c, parts, fill))
  end
  return table.concat(rows)
end

local function delta_mock(c)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  local function run(cmd)
    local result = vim.fn.system(cmd)
    assert(vim.v.shell_error == 0, result)
    return result
  end
  local function write(path, lines)
    local f = assert(io.open(dir .. '/' .. path, 'w'))
    f:write(table.concat(lines, '\n') .. '\n')
    f:close()
  end
  local before = {
    "import { readFile } from 'node:fs/promises'",
    '',
    '// Load a theme by name, or null if it has no file',
    'const MAX_THEMES = 12',
    'export async function load(name: string): Promise<Theme> {',
    "  const text = await readFile(`themes/${name}.json`, 'utf8')",
    '  return JSON.parse(text) as Theme',
    '}',
  }
  local after = vim.deepcopy(before)
  after[4] = 'const MAX_THEMES = 13'
  after[7] = '  if (!text) return null'
  table.insert(after, 8, '  return JSON.parse(text) as Theme')
  write('app.ts', before)
  run({ 'git', '-C', dir, 'init', '-q' })
  run({ 'git', '-C', dir, 'add', '.' })
  run({ 'git', '-C', dir, '-c', 'user.name=hax0r', '-c', 'user.email=hax0r@localhost', 'commit', '-qm', 'before' })
  write('app.ts', after)
  local diff = run({ 'git', '-C', dir, '-c', 'color.ui=never', 'diff', '--no-ext-diff' })
  -- the [delta] section of this theme's gitconfig, as delta's command-line flags
  local f = assert(io.open(('%s/hax0r/delta/%s.gitconfig'):format(config, name)))
  local text = f:read('a')
  f:close()
  local cmd = { 'delta', '--no-gitconfig', '--paging=never', '--width=72' }
  for key, value in (text:match('%[delta%]\n(.*)') or ''):gmatch('\t([%w-]+) = ([^\n]+)') do
    value = value:gsub('^"(.*)"$', '%1')
    if key == 'syntax-theme' then value = c.delta_syntax or 'ansi' end
    table.insert(cmd, '--' .. key)
    if value ~= 'true' then table.insert(cmd, value) end
  end
  local result = vim.fn.system(cmd, diff)
  assert(vim.v.shell_error == 0, result)
  vim.fn.delete(dir, 'rf')
  return ansi_html(c, result)
end

-- Another app's file from `hax0r build`, each color in it shown as a swatch
local function built_file(path, keep)
  local f = io.open(path)
  if not f then return '<p class="note">not built yet</p>' end
  local rows = {}
  for text in f:lines() do
    if not text:match('^%s*#') and not text:match('^%s*//') and (not keep or text:match(keep)) and text:match('%S') then
      text = esc(text):gsub('%%23(%x%x%x%x%x%x)', '#%1'):gsub('#%x%x%x%x%x%x', function(hex) return chip(hex:lower()) end)
      text = text:gsub('%[(%d+), (%d+), (%d+)%]', function(r, g, b)
        return chip(('#%02x%02x%02x'):format(tonumber(r), tonumber(g), tonumber(b)))
      end)
      table.insert(rows, '<div>' .. text .. '</div>')
    end
  end
  f:close()
  return ('<div class="file">%s</div>'):format(table.concat(rows))
end

local function figure(caption, body, class)
  return ('<figure class="%s"><figcaption>%s</figcaption><div class="scroll">%s</div></figure>'):format(class or 'app', caption, body)
end

local function mock(c, body)
  return ('<div class="mock" style="background:%s">%s</div>'):format(c.bg, body)
end

-- The open choices: each draws its mock once per option, as rows, Now first
local function choice(id, heading, about, draw, options)
  local rows = {}
  for _, o in ipairs(options) do
    local c = copy(C, o.set)
    table.insert(rows, ('<tr><th class="opt">%s<small>%s</small></th><td>%s</td></tr>'):format(esc(o.name), o.about, draw(c, o)))
  end
  return ([[
<section class="part" id="%s">
  <h3>%s</h3>
  <p>%s</p>
  <div class="scroll"><table class="grid"><tbody>%s</tbody></table></div>
</section>]]):format(id, heading, about, table.concat(rows))
end

local function claude_short(c)
  local rows = {}
  local function add(parts, back) table.insert(rows, line(c, parts, back)) end
  add({ { ' ❯ ', 'fg', '', 'prompt_band' }, { 'make the code text match nvim', 'fg', '', 'prompt_band' }, { '              ', 'fg', '', 'prompt_band' } }, 'prompt_band')
  add({})
  add({ { ' ● ', 'claude' }, { 'Setting ', 'fg' }, { 'ansi 7', 'ansi12' }, { ' in ', 'fg' }, { 'palettes.lua', 'ansi12' }, { ':', 'fg' } })
  add({ { "   [7] = '#cccccc',", 'ansi7' }, { ' -- code text', 'ansi8' } })
  add({ { ' ✻ ', 'claude' }, { 'Thin', 'claude' }, { 'kin', 'claude_shimmer' }, { 'g… ', 'claude' }, { '(esc to interrupt)', 'dim' } })
  add({})
  add({ { '~/.config/hax0r', 'ansi4' }, { ' main', 'ansi8' }, { ' *', 'ansi15' }, { ' 2s', 'ansi3' } })
  add({ { '❯ ', 'ansi5' } })
  return mock(c, table.concat(rows))
end

local function permission_mock(c)
  local rows = {}
  local function add(parts) table.insert(rows, line(c, parts)) end
  add({ { ' Do you want to make this edit to palettes.lua?', 'fg', 'b' } })
  add({ { ' ❯ 1. Yes', 'permission' } })
  add({ { '   2. Yes, allow all edits this session', 'fg' } })
  add({ { '   3. No', 'fg' } })
  add({})
  add({ { ' > /the', 'fg' }, { 'me', 'dim' } })
  add({ { '   /theme', 'suggestion' }, { '   Change the theme', 'suggestion' } })
  add({ { '   /terminal-setup', 'dim' }, { '   Set up the terminal', 'dim' } })
  return mock(c, table.concat(rows))
end

local function terminal_mock(c)
  return ansi_strip(c) .. mock(c, shell_mock(c))
end

-- The June port in ~/.config/Dark Modern: Ghostty's Dark Modern, from iTerm2-Color-Schemes
local PORT = {
  [0] = '#272727', '#f74949', '#2ea043', '#9e6a03', '#0078d4', '#d01273', '#1db4d6', '#cccccc',
  '#5d5d5d', '#dc5452', '#23d18b', '#f5f543', '#3b8eea', '#d670d6', '#29b8db', '#e5e5e5',
}

-- Claude Code's keys that read these colors (generate.lua's claude_keys), so the options below
-- reach the mocks under their palette names
C.claude = C.claude or C.brand
C.permission = C.permission or C.selection
C.suggestion = C.suggestion or C.selection

local CLAUDE_ORANGE, CLAUDE_SHIMMER = '#d77757', '#eb9f7f' -- Claude Code's own dark theme

local CHOICES = {
  choice('delta', 'delta’s syntax colors',
    'delta can’t read palettes.lua’s syntax table, so it uses one of its own themes. Its Visual Studio Dark+ is an older Dark+ than VS Code’s (strings #d69d85, comments #608b4e, punctuation #dcdcdc), and it won’t follow a change to the syntax colors here. ansi uses the terminal’s 16 colors, so it follows those, but by its own rules: keywords in slot 5, numbers in slot 3. Either way the bands behind added and removed lines are VS Code’s.',
    function(c) return mock(c, delta_mock(c)) end, {
      { name = 'Now: the terminal’s colors', about = 'delta’s ansi' },
      { name = 'Dark+', about = 'delta’s Visual Studio Dark+', set = { delta_syntax = 'Visual Studio Dark+' } },
    }),
  choice('code', 'Claude Code’s code text, comments and inline code',
    'Claude Code draws these in terminal slots 7, 8 and 12, so they follow the terminal’s colors, not nvim’s. The one-color themes set those slots to the theme’s text, comment and selection colors so Claude Code matches nvim. Dark Modern keeps VS Code’s terminal colors for now, which is how Claude Code looks in VS Code’s own terminal. Changing a slot changes it for every program: Starship’s branch name is slot 8, so it turns green with the comments.',
    claude_short, {
      { name = 'Now: VS Code’s terminal', about = '7 #e5e5e5 · 8 #666666 · 12 #3b8eea' },
      { name = 'Match nvim', about = '7 fg #cccccc · 8 comment #6a9955 · 12 Dark+’s inline code #ce9178',
        set = { ansi = { [7] = C.fg, [8] = C.syntax.comment, [12] = C.syntax.raw } } },
      { name = 'Text and comments only', about = '7 #cccccc · 8 #6a9955 · 12 stays #3b8eea',
        set = { ansi = { [7] = C.fg, [8] = C.syntax.comment } } },
    }),
  choice('claude', 'Claude’s color',
    'The ● before Claude’s replies, the ✻ while it works and its name, with the shimmer running across it. One-color themes use their brightest shade, which in Dark Modern would be white.',
    claude_short, {
      { name = 'Now: Dark Modern’s blue', about = 'focus #0078d4, shimmer link #4daafc' },
      { name = 'White', about = 'bright #ffffff, shimmer #85b6ff', set = { claude = '#ffffff', claude_shimmer = '#85b6ff' } },
      { name = 'Link blue', about = 'link #4daafc, shimmer #85b6ff', set = { claude = '#4daafc' } },
      { name = 'Claude’s own orange', about = 'Claude Code’s dark theme: #d77757, shimmer #eb9f7f',
        set = { claude = CLAUDE_ORANGE, claude_shimmer = CLAUDE_SHIMMER } },
    }),
  choice('ansi', 'The terminal’s 16 colors',
    'What Ghostty, Starship, git, ls and every other terminal program draw with. Now: VS Code’s own terminal defaults, which Dark Modern doesn’t change. The other: the Dark Modern you had in Ghostty in June (~/.config/Dark Modern), a port that swaps in some of Dark Modern’s UI colors (its blue, the gutter’s green and red) and a dark slot 0.',
    terminal_mock, {
      { name = 'Now: VS Code’s terminal', about = 'terminal.ansi* defaults' },
      { name = 'June’s Ghostty port', about = 'from iTerm2-Color-Schemes', set = { ansi = PORT } },
    }),
  choice('permission', 'Permission questions and suggestions',
    'The option a permission question has selected, and the slash commands that match what you’ve typed. Now: the color VS Code’s chat uses for slash commands.',
    permission_mock, {
      { name = 'Now: chat’s slash commands', about = 'chat.slashCommandForeground #85b6ff' },
      { name = 'Link blue', about = 'textLink.foreground #4daafc', set = { permission = '#4daafc', suggestion = '#4daafc' } },
      { name = 'White', about = 'bright #ffffff', set = { permission = '#ffffff', suggestion = '#ffffff' } },
    }),
  choice('band', 'The band behind your prompts',
    'Claude Code puts each of your prompts on a band, so you can find them while scrolling. Now: the band VS Code’s chat puts behind your messages, its selection blue @ 30%.',
    claude_short, {
      { name = 'Now: chat’s message band', about = 'chat.requestBubbleBackground, #264f78 @ 30% = ' .. C.prompt_band },
      { name = 'Code block gray', about = 'textCodeBlock.background #2b2b2b', set = { prompt_band = '#2b2b2b' } },
      { name = 'Input gray', about = 'input.background #313131', set = { prompt_band = '#313131' } },
    }),
}

local function apps()
  local hax0r = config .. '/hax0r/'
  local others = {
    figure('lazygit', built_file(hax0r .. 'lazygit/' .. name .. '.yml'), 'file-fig'),
    figure('fzf', (built_file(hax0r .. 'fzf/' .. name):gsub(',', ', ')), 'file-fig'),
    figure('tmux', built_file(config .. '/tmux/themes/hax0r-' .. name .. '.conf'), 'file-fig'),
    figure('Chrome', built_file(hax0r .. 'chrome/' .. name .. '.json', '%['), 'file-fig'),
    figure('Raycast', (built_file(hax0r .. 'raycast/' .. name):gsub(',', ', ')), 'file-fig'),
  }
  return ([[
<section class="part" id="apps">
  <h3>In each app</h3>
  <p>VS Code gets Dark Modern itself: its theme is built from VS Code’s own files, and every color matches the original. nvim, Claude Code and the shell are mocks drawn from palettes.lua by each app’s rules. delta’s is delta’s own output. The rest list the files <code>hax0r build</code> wrote.</p>
  <div class="apps">%s%s</div>
  <div class="apps">%s%s</div>
  <div class="apps">%s</div>
  <div class="apps files">%s</div>
</section>]]):format(
    figure('VS Code', mock(C, vscode_mock(C)), 'app wide'),
    figure('nvim', mock(C, nvim_mock(C)), 'app'),
    figure('Claude Code, in Ghostty', mock(C, claude_mock(C))),
    figure('The shell, in Ghostty', ansi_strip(C) .. mock(C, shell_mock(C))),
    figure('delta: git diff', mock(C, delta_mock(C))),
    table.concat(others))
end

local function picked()
  local rows = {}
  for _, k in ipairs({ 'normal', 'bold', 'white', 'selection', 'gray', 'prompt_band', 'bash_band', 'faint', 'success', 'border_shimmer' }) do
    table.insert(rows, ('<tr><td><code>%s</code></td><td>%s</td></tr>'):format(k, chip(C[k])))
  end
  return table.concat(rows)
end

local page = table.concat({ [[
<meta charset="utf-8">
<title>hax0r Dark Modern</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;600&family=JetBrains+Mono:ital,wght@0,400;0,700;1,400&display=swap">
<style>
/* A neutral gray bench, so the theme's own colors are the only color on the page */
:root {
  --bench: #e4e4e4; --ink: #1a1a1a; --muted: #5c5c5c; --rule: #c6c6c6; --raise: #eeeeee;
  --sans: "IBM Plex Sans", system-ui, -apple-system, sans-serif;
  --mono: "JetBrains Mono", ui-monospace, "SF Mono", Menlo, monospace;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) { --bench: #151515; --ink: #e6e6e6; --muted: #9a9a9a; --rule: #2e2e2e; --raise: #1d1d1d; color-scheme: dark }
}
:root[data-theme="dark"] { --bench: #151515; --ink: #e6e6e6; --muted: #9a9a9a; --rule: #2e2e2e; --raise: #1d1d1d; color-scheme: dark }
body {
  background: var(--bench); color: var(--ink); font: 15px/1.55 var(--sans); margin: 0;
  padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px));
  padding-block: 40px 64px;
}
main { max-width: 1320px; margin-inline: auto; display: grid; gap: 48px }
h1, h2, h3 { text-wrap: balance; margin: 0 }
h1 { font: 600 28px/1.2 var(--mono); letter-spacing: -0.01em }
.intro { display: grid; gap: 10px; max-width: 72ch }
.intro p, .part > p { margin: 0; color: var(--muted) }
code { font: 0.92em var(--mono) }
.part { display: grid; gap: 10px; border-top: 1px solid var(--rule); padding-top: 24px; min-width: 0 }
.part h3 { font: 700 18px/1.3 var(--mono) }
.part > p { font-size: 14px; max-width: 80ch }
.apps { display: flex; flex-wrap: wrap; gap: 20px; align-items: flex-start }
figure { margin: 0; display: grid; gap: 6px; min-width: 0; max-width: 100% }
figcaption { font: 600 11px/1.4 var(--sans); text-transform: uppercase; letter-spacing: 0.08em; color: var(--muted) }
.scroll { overflow-x: auto; max-width: 100% }
.mock { padding-block: 6px; border-radius: 3px; font: 13px/1.6 var(--mono); width: max-content }
.ln { white-space: pre; min-height: 1.6em }
.split { display: flex }
.split .ln { flex: 1 }
.split .ln.side { flex: none; width: 24ch }
.strip { display: inline-flex; gap: 4px; padding: 8px; border-radius: 3px; margin-bottom: 6px }
.strip i { width: 22px; height: 22px; border-radius: 2px }
.file { font: 12px/1.7 var(--mono); background: var(--raise); border: 1px solid var(--rule); border-radius: 4px; padding: 8px 12px; max-width: 64ch; overflow-wrap: anywhere }
.files figure { flex: 1 1 300px }
.chip { display: inline-flex; align-items: center; gap: 4px; font: 12px var(--mono); white-space: nowrap }
.chip i { width: 11px; height: 11px; border-radius: 2px; box-shadow: 0 0 0 1px var(--rule) }
table.grid { border-collapse: collapse }
table.grid th, table.grid td { vertical-align: top; padding: 12px 16px 12px 0; border-top: 1px solid var(--rule) }
th.opt { text-align: left; font: 600 13px var(--sans); width: 22ch; min-width: 16ch }
th.opt small { display: block; margin-top: 2px; font: 400 11.5px/1.45 var(--mono); color: var(--muted) }
table.picked td { padding: 3px 18px 3px 0; border-top: 1px solid var(--rule); font-size: 13px }
footer { color: var(--muted); font-size: 13px; max-width: 72ch }
</style>
<main>
  <div class="intro">
    <h1>hax0r ]], name, [[</h1>
    <p>]], esc(C.title), [[ in every app hax0r themes, drawn from <code>palettes.lua</code>]],
  label and (' at <code>' .. esc(label) .. '</code>') or '', [[ in exact colors. First, the theme in each app. Then the choices still open: colors for jobs VS Code has no color for, each drawn as it’s set now and with the other options.</p>
  </div>
]], apps(), [[
  <section class="part" id="choices">
    <h3>Still open</h3>
    <p>Everything else is VS Code’s own color. These are the ones that aren’t, picked to start with:</p>
    <table class="picked"><tbody>]], picked(), [[</tbody></table>
  </section>
]], table.concat(CHOICES, '\n'), [[
  <footer>Built by <code>~/.config/hax0r/page-full.lua</code>, which reads <code>palettes.lua</code> and the files <code>hax0r build</code> wrote.</footer>
</main>
]] })

local f = assert(io.open(out, 'w'))
f:write(page)
f:close()
print('wrote ' .. out)
