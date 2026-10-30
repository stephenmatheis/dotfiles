-- `nvim -l ~/.config/hax0r/page.lua <out.html> [label]`: a web page of the hax0r themes drawn from
-- palettes.lua in exact colors, for judging colors by eye where a terminal can't show them. It
-- draws how each app shows diffs now, next to the other options considered, then for each theme in
-- SHOW the `hax0r preview` panel and every place an app uses a git, diff or problem color, with
-- colors that can't be told apart flagged. To weigh a change, add an option row to DIFFS (or a
-- section of its own) that draws it next to Now. label names the version shown, like a commit.
local config = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. '/.config')
local P = dofile(config .. '/hax0r/palettes.lua')
local out = assert(arg[1], 'usage: nvim -l page.lua <out.html> [label]')
local label = arg[2]
local SHOW = { 'white', 'black' }
local SAME = 1.15 -- two colors closer than this contrast ratio read as the same color

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

-- parts: { text, color role or hex, attrs, background, undercurl or outline color }
-- attrs: b bold, i italic, u underline, s strikethrough, ~ undercurl, o outline
local function span(c, p, back)
  local text, color, attrs, bg = p[1], c[p[2]] or p[2], p[3] or '', p[4] and (c[p[4]] or p[4])
  local style = { 'color:' .. color }
  if bg and bg ~= back then table.insert(style, 'background:' .. bg) end
  if attrs:find('b') then table.insert(style, 'font-weight:700') end
  if attrs:find('i') then table.insert(style, 'font-style:italic') end
  local lines = {}
  if attrs:find('u') then table.insert(lines, 'underline') end
  if attrs:find('s') then table.insert(lines, 'line-through') end
  if #lines > 0 then table.insert(style, 'text-decoration:' .. table.concat(lines, ' ')) end
  if attrs:find('o') then table.insert(style, 'box-shadow:inset 0 0 0 1px ' .. (c[p[5]] or p[5])) end
  if attrs:find('~') then
    table.insert(style, 'text-decoration:underline wavy ' .. (c[p[5]] or p[5]))
    table.insert(style, 'text-decoration-skip-ink:none;text-underline-offset:0.25em')
  end
  return ('<span style="%s">%s</span>'):format(table.concat(style, ';'), esc(text))
end

local function line(c, parts, back)
  back = back and (c[back] or back) or c.bg
  local html = {}
  for _, p in ipairs(parts) do
    table.insert(html, span(c, p, back))
  end
  return ('<div class="ln" style="background:%s">%s</div>'):format(back, table.concat(html))
end

-- The `hax0r preview` panel, row for row (preview.lua)
local function panel(name, c)
  local cl = c.cursor_line
  local nr = function(n) return { ('%3d '):format(n), 'dim' } end
  local ratio = function(k) return ('%.1f'):format(contrast(c[k], c.bg)) end
  return table.concat({
    line(c, { { ' ' .. name, 'bright', 'b' }, { '  ' .. c.title, 'fg' }, { ('  %s on %s'):format(c.fg, c.bg), 'dim' } }),
    line(c, {}),
    line(c, { nr(1), { '-- palette for the hax0r theme', 'dim', 'i' } }),
    line(c, { nr(2), { 'local function', 'bold', 'b' }, { ' ', 'fg' }, { 'hl', 'normal' }, { '(group, opts)', 'fg' } }),
    line(c, { { '  3 ', 'bright', '', cl }, { '  ', 'fg', '', cl }, { 'return', 'bold', 'b', cl }, { ' set(', 'fg', '', cl },
      { "'Normal'", 'normal', '', cl }, { ', ', 'fg', '', cl }, { 'Color', 'bright', '', cl }, { ')', 'fg', '', cl } }, cl),
    line(c, { nr(4), { '  ', 'fg' }, { 'vim.o.background', 'fg', '', c.selection_tint }, { ' = ', 'fg' }, { "'dark'", 'normal' },
      { '  E error', 'error' }, { '  W warn', 'warning' } }),
    line(c, { { ' NORMAL ', 'bright', 'b', c.dark }, { ' hax0r.lua ', 'fg', '', c.dark }, { '  [+]', 'dim', '', c.dark },
      { '  +3', 'added', '', c.dark }, { ' ~1', 'white', '', c.dark }, { ' -2', 'removed', '', c.dark } }, c.dark),
    line(c, { { '╭' .. ('─'):rep(26) .. '╮', 'float_border', '', c.dark }, { ' float', 'fg', '', c.dark } }, c.dark),
    line(c, {}),
    line(c, { { ' ❯ ', 'fg', '', c.prompt_band }, { 'make the selection softer', 'fg', '', c.prompt_band } }, c.prompt_band),
    line(c, {}),
    line(c, { { ' ! ', 'white', '', c.bash_band }, { 'git status', 'fg', '', c.bash_band } }, c.bash_band),
    line(c, {}),
    line(c, { { ' ● ', 'bright' }, { 'Set ', 'fg' }, { 'selection_tint', 'selection' }, { ' and ', 'fg' },
      { 'the docs', 'link', 'u' }, { ' (2 lines hidden)', 'faint' } }),
    line(c, { { '   ✻ Thinking… ', 'bright' }, { 'esc to interrupt', 'dim' } }),
    line(c, { { '  3 ', 'dim', '', c.diff_del }, { "-  fg = '", 'fg', '', c.diff_del }, { '#16b10e', 'normal', '', c.diff_del_word },
      { "',", 'fg', '', c.diff_del }, { ' -- old green', 'dim', 'i', c.diff_del } }, c.diff_del),
    line(c, { { '  3 ', 'dim', '', c.diff_add }, { "+  fg = '", 'fg', '', c.diff_add }, { '#19e20e', 'normal', '', c.diff_add_word },
      { "',", 'fg', '', c.diff_add }, { ' -- brighter', 'dim', 'i', c.diff_add } }, c.diff_add),
    line(c, {}),
    line(c, { { (' contrast: text %s  comments %s  bright %s  error %s'):format(ratio('fg'), ratio('dim'), ratio('bright'), ratio('error')), 'dim' } }),
  })
end

-- Every place an app uses a git, diff or problem color. Rows in the same `cmp` set have to be
-- told apart by color alone, so those are the ones checked against each other.
local function file(name, badge, key)
  return { { '  ' .. ('%-16s'):format(name), key }, { badge, key } }
end
local function sign(glyph, key, n, code)
  return { { glyph, key }, { ('%4d  '):format(n), 'dim' }, { code, 'fg' } }
end

local GROUPS = {
  {
    title = 'VS Code explorer',
    note = 'File names and badges take the color of their git state, or of their problems.',
    rows = {
      { 'added', 'Added', file('README.md', 'A', 'added'), cmp = 'files' },
      { 'added', 'Untracked', file('notes.md', 'U', 'added'), cmp = 'files' },
      { 'white', 'Modified', file('palettes.lua', 'M', 'white'), cmp = 'files', where = 'also renamed and staged modified' },
      { 'removed', 'Deleted', file('preview.lua', 'D', 'removed'), cmp = 'files' },
      { 'warning', 'Conflict', file('merge.lua', '!', 'warning'), cmp = 'files' },
      { 'faint', 'Ignored', file('.DS_Store', '', 'faint'), cmp = 'files' },
      { 'warning', 'Has warnings', file('util.lua', '1', 'warning'), cmp = 'files' },
      { 'error', 'Has errors', file('init.lua', '2', 'error'), cmp = 'files' },
    },
  },
  {
    title = 'nvim sign column',
    note = 'gitsigns, plus the +3 ~1 −2 counts in the statusline. VS Code’s gutter uses the same three unstaged colors.',
    rows = {
      { 'added', 'Added line', sign('┃', 'added', 12, "local a = 1"), cmp = 'bar' },
      { 'white', 'Changed line', sign('┃', 'white', 13, "local b = 2"), cmp = 'bar' },
      { 'removed', 'Deleted line', sign('▁', 'removed', 14, "local c = 3"), cmp = 'under' },
      { 'added_dim', 'Staged add', sign('┃', 'added_dim', 15, "local d = 4"), cmp = 'bar' },
      { 'faint', 'Staged change', sign('┃', 'faint', 16, "local e = 5"), cmp = 'bar' },
      { 'removed_dim', 'Staged delete', sign('▁', 'removed_dim', 17, "local f = 6"), cmp = 'under' },
    },
  },
  {
    title = 'Problems',
    note = 'nvim diagnostics and undercurls, VS Code squiggles and status bar, Claude Code’s error and warning text.',
    rows = {
      { 'warning', 'Warning', { { '  local ', 'fg' }, { 'x', 'fg', '~', nil, 'warning' }, { ' = 1  ', 'fg' }, { 'W unused local', 'warning' } }, cmp = 'problems' },
      { 'error', 'Error', { { '  print(', 'fg' }, { 'y', 'fg', '~', nil, 'error' }, { ')  ', 'fg' }, { 'E undefined global', 'error' } }, cmp = 'problems' },
    },
  },
  {
    title = 'Diff bands',
    note = 'The same four colors in nvim, VS Code and Claude Code (Ghostty slots 22, 28, 52 and 88).',
    rows = {
      { 'diff_add', 'Added line and word', { { "  + fg = '", 'fg' }, { '#19e20e', 'normal', '', 'diff_add_word' }, { "',", 'fg' } },
        back = 'diff_add', word = 'diff_add_word', cmp = 'bands' },
      { 'diff_del', 'Removed line and word', { { "  - fg = '", 'fg' }, { '#16b10e', 'normal', '', 'diff_del_word' }, { "',", 'fg' } },
        back = 'diff_del', word = 'diff_del_word', cmp = 'bands' },
    },
  },
}

local function chip(hex)
  return ('<span class="chip"><i style="background:%s"></i>%s</span>'):format(hex, hex)
end

local function table_for(c)
  local html, clashes = {}, {}
  for _, g in ipairs(GROUPS) do
    table.insert(html, ('<tr class="group"><th colspan="4"><span>%s</span> %s</th></tr>'):format(g.title, g.note))
    for _, r in ipairs(g.rows) do
      local key = r[1]
      local same = {}
      for _, o in ipairs(g.rows) do
        if o ~= r and o.cmp == r.cmp and o[1] ~= key and contrast(c[o[1]], c[key]) < SAME then
          table.insert(same, o[2])
        end
      end
      if #same > 0 then
        clashes[g.title] = clashes[g.title] or {}
        clashes[g.title][r[2]] = true
      end
      local colors = chip(c[key]) .. (r.word and (' ' .. chip(c[r.word])) or '')
      table.insert(html, table.concat({
        '<tr>',
        ('<td class="sample">%s</td>'):format(line(c, r[3], r.back)),
        ('<td class="role"><b>%s</b><small>%s%s</small></td>'):format(r[2], key, r.where and (' · ' .. r.where) or ''),
        ('<td class="hex">%s<small>%.2f:1 on bg</small></td>'):format(colors, contrast(c[key], c.bg)),
        ('<td class="same%s">%s</td>'):format(#same > 0 and ' hit' or '', #same > 0 and ('≈ ' .. table.concat(same, ', ')) or '—'),
        '</tr>',
      }))
    end
  end
  -- One summary line per group, in table order
  local summary = {}
  for _, g in ipairs(GROUPS) do
    if clashes[g.title] then
      local names = {}
      for _, r in ipairs(g.rows) do
        if clashes[g.title][r[2]] then table.insert(names, r[2]) end
      end
      table.insert(summary, ('<li><b>%s:</b> %s</li>'):format(g.title, table.concat(names, ', ')))
    end
  end
  return table.concat(html, '\n'), summary
end

-- Diff mocks: the same small change drawn the way each app draws it, once per option. Faint
-- text (Claude Code's removed lines, git's dim) is drawn as Ghostty draws it, halfway to the
-- cell's background (faint-opacity 0.5).
local function faint(color, back) return mix(color, back, 0.5) end

-- c with its removed bands swapped, as palettes.lua would build them
local function removed_bands(c, line_p, word_p)
  local tint = mix(c.white, c.dim, 0.5)
  return setmetatable({
    diff_del = line_p == 0 and c.bg or mix(tint, c.bg, line_p),
    diff_del_word = mix(tint, c.bg, word_p),
  }, { __index = c })
end

local function claude_diff(c)
  local del, del_w, add, add_w = c.diff_del, c.diff_del_word, c.diff_add, c.diff_add_word
  local f, fw = faint(c.fg, del), faint(c.fg, del_w)
  return table.concat({
    line(c, { { '  10    ', 'dim' }, { 'local M = {}', 'fg' } }),
    line(c, { { '  11 ', 'dim', '', del }, { "-  M.fg = '", f, '', del }, { '#16b10e', fw, '', del_w }, { "'", f, '', del } }, del),
    line(c, { { '  12 ', 'dim', '', del }, { "-  M.link = '#00e8ca'", f, '', del } }, del),
    line(c, { { '  11 ', 'dim', '', add }, { "+  M.fg = '", 'fg', '', add }, { '#19e20e', 'fg', '', add_w }, { "'", 'fg', '', add } }, add),
    line(c, { { '  12 ', 'dim', '', add }, { "+  M.dim = '#0b8700'", 'fg', '', add } }, add),
    line(c, { { '  13    ', 'dim' }, { 'return M', 'fg' } }),
  })
end

-- old and new: { color, attrs } for git's color.diff.old and color.diff.new
local function git_diff(c, old, new)
  return table.concat({
    line(c, { { 'diff --git a/palettes.lua b/palettes.lua', 'fg', 'b' } }),
    line(c, { { '@@ -10,4 +10,4 @@', c.ansi[6] }, { ' local M = {}', 'fg' } }),
    line(c, { { ' local M = {}', 'fg' } }),
    line(c, { { "-M.fg = '#16b10e'", old[1], old[2] } }),
    line(c, { { "-M.link = '#00e8ca'", old[1], old[2] } }),
    line(c, { { "+M.fg = '#19e20e'", new[1], new[2] } }),
    line(c, { { "+M.dim = '#0b8700'", new[1], new[2] } }),
    line(c, { { ' return M', 'fg' } }),
  })
end

-- gitsigns' preview_hunk_inline: removed lines as virtual lines above the change.
-- o: { del_fg, del_word_attrs, add_word_attrs }
local function nvim_inline(c, o)
  local del, del_w, add, add_w = c.diff_del, c.diff_del_word, c.diff_add, c.diff_add_word
  return table.concat({
    line(c, { { '    10  ', 'dim' }, { 'local M = {}', 'fg' } }),
    line(c, { { '        ', 'fg', '', del }, { "M.fg = '", o[1], '', del }, { '#16b10e', o[1], o[2], del_w }, { "'", o[1], '', del } }, del),
    line(c, { { '        ', 'fg', '', del }, { "M.link = '#00e8ca'", o[1], '', del } }, del),
    line(c, { { ' ┃', 'white' }, { '  11  ', 'bright' }, { "M.fg = '", 'fg', '', add }, { '#19e20e', 'fg', o[3], add_w }, { "'", 'fg', '', add } }),
    line(c, { { ' ┃', 'white' }, { '  12  ', 'dim' }, { "M.dim = '#0b8700'", 'fg', '', add } }),
    line(c, { { '    13  ', 'dim' }, { 'return M', 'fg' } }),
  })
end

local function pair(c, left, lback, right, rback)
  return ('<div class="sbs">%s<i class="sep" style="background:%s"></i>%s</div>'):format(
    line(c, left, lback), c.float_border, line(c, right, rback))
end

-- nvim's side-by-side diff (:Gitsigns diffthis). nvim doesn't know which side is older, so a line
-- on one side only is DiffAdd on that side, and the gap across from it is DiffDelete
local function nvim_sbs(c, fill)
  local gap = { { '    ' .. fill:rep(16), 'diff_del_word', '', 'diff_del' } }
  local function chg(n, pre, word) return { { (' %d '):format(n), 'dim', '', 'diff_add' }, { pre, 'fg', '', 'diff_add' }, { word, 'fg', '', 'diff_add_word' }, { "'", 'fg', '', 'diff_add' } } end
  return table.concat({
    pair(c, { { ' 10 ', 'dim' }, { 'local M = {}', 'fg' } }, nil, { { ' 10 ', 'dim' }, { 'local M = {}', 'fg' } }),
    pair(c, chg(11, "M.fg = '", '#16b10e'), 'diff_add', chg(11, "M.fg = '", '#19e20e'), 'diff_add'),
    pair(c, { { ' 12 ', 'dim', '', 'diff_add' }, { "M.link = '#00e8ca'", 'fg', '', 'diff_add' } }, 'diff_add', gap, 'diff_del'),
    pair(c, gap, 'diff_del', { { ' 12 ', 'dim', '', 'diff_add' }, { "M.dim = '#0b8700'", 'fg', '', 'diff_add' } }, 'diff_add'),
    pair(c, { { ' 13 ', 'dim' }, { 'return M', 'fg' } }, nil, { { ' 13 ', 'dim' }, { 'return M', 'fg' } }),
  })
end

-- VS Code's side-by-side diff: line number, a +/- indicator column, then the text.
-- o: { removed_gutter, inserted_gutter, removed_word_outline }; gutters default to the line band
local function vscode_sbs(c, o)
  local del, add = c.diff_del, c.diff_add
  local hatch = ('repeating-linear-gradient(-45deg, %s 0 1.5px, %s 1.5px 7px)'):format(c.diff_del, c.bg)
  local rg, ig = o[1] or del, o[2] or add
  local rg_fg, ig_fg = o[1] and c.bg or c.fg, o[2] and c.bg or c.fg
  local outline = o[3] and 'o' or ''
  return table.concat({
    pair(c, { { ' 10   ', 'dim' }, { 'local M = {}', 'fg' } }, nil, { { ' 10   ', 'dim' }, { 'local M = {}', 'fg' } }),
    pair(c, { { ' 11 ', 'dim', '', del }, { '-', rg_fg, '', rg }, { ' ', 'fg', '', del }, { "M.fg = '", 'fg', '', del }, { '#16b10e', 'fg', outline, 'diff_del_word', o[3] }, { "'", 'fg', '', del } }, del,
      { { ' 11 ', 'dim', '', add }, { '+', ig_fg, '', ig }, { ' ', 'fg', '', add }, { "M.fg = '", 'fg', '', add }, { '#19e20e', 'fg', '', 'diff_add_word' }, { "'", 'fg', '', add } }, add),
    pair(c, { { ' 12 ', 'dim', '', del }, { '-', rg_fg, '', rg }, { ' ', 'fg', '', del }, { "M.link = '#00e8ca'", 'fg', '', del } }, del, { { ' ', 'fg' } }, hatch),
    pair(c, { { ' ', 'fg' } }, hatch, { { ' 12 ', 'dim', '', add }, { '+', ig_fg, '', ig }, { ' ', 'fg', '', add }, { "M.dim = '#0b8700'", 'fg', '', add } }, add),
    pair(c, { { ' 13   ', 'dim' }, { 'return M', 'fg' } }, nil, { { ' 13   ', 'dim' }, { 'return M', 'fg' } }),
  })
end

-- Each app's diff as set up now, then the other options considered. Now rows draw the bands from
-- palettes.lua; the rest of each Now row (git's colors, nvim's highlights and fillchars) is written
-- out here to match the config, so change it here when the config changes.
local DIFFS = {
  {
    title = 'Claude Code',
    note = 'Only the four band colors can be set. The + and −, the line numbers and the faint text on removed lines are Claude Code’s own. These bands are shared, so nvim and VS Code change with them.',
    options = {
      { 'Now', 'palettes.lua’s diff bands', function(c) return claude_diff(c) end },
      { 'Earlier removed band', 'removed line band 20%, word 33%, as strong as the added band', function(c) return claude_diff(removed_bands(c, 0.20, 0.33)) end },
      { 'No removed band', 'removed lines on the background, word 20%', function(c) return claude_diff(removed_bands(c, 0, 0.20)) end },
    },
  },
  {
    title = 'git diff and lazygit',
    note = 'git colors removed lines red and added lines green, and hax0r makes both of those the theme’s normal color, so without styles only the + and − tell them apart. lazygit shows git’s own colors.',
    options = {
      { 'Now', '~/.config/git/config:<br>color.diff.old = red dim<br>color.diff.new = green bold', function(c) return git_diff(c, { faint(c.ansi[1], c.bg), '' }, { c.ansi[2], 'b' }) end },
      { 'git’s defaults', 'old red, new green', function(c) return git_diff(c, { c.ansi[1], '' }, { c.ansi[2], '' }) end },
      { 'Dim removed only', 'color.diff.old = red dim', function(c) return git_diff(c, { faint(c.ansi[1], c.bg), '' }, { c.ansi[2], '' }) end },
      { 'Struck-through removed', 'color.diff.old = red strike', function(c) return git_diff(c, { c.ansi[1], 's' }, { c.ansi[2], '' }) end },
    },
  },
  {
    title = 'nvim hunk preview',
    note = 'gitsigns’ inline preview: removed lines appear as virtual lines above the change. The floating preview uses the same highlight groups.',
    options = {
      { 'Now', 'colors/hax0r.lua: GitSignsDeleteVirtLn, DeletePreview and DeleteInline fg = dim', function(c) return nvim_inline(c, { 'dim', '', '' }) end },
      { 'Text color kept', 'removed lines in their text color, like VS Code', function(c) return nvim_inline(c, { 'fg', '', '' }) end },
      { 'Dim, strike and underline', 'removed words struck through, added words underlined', function(c) return nvim_inline(c, { 'dim', 's', 'u' }) end },
    },
  },
  {
    title = 'nvim side by side',
    note = 'nvim doesn’t know which side is older, so a line on one side only is DiffAdd on that side: the removed line on the left gets the same band as the added line on the right. Position and the gap tell them apart.',
    options = {
      { 'Now', 'init.lua: fillchars diff:╱, like VS Code’s diagonal fill', function(c) return nvim_sbs(c, '╱') end },
      { 'Dashes', 'fillchars diff:-, nvim’s default', function(c) return nvim_sbs(c, '-') end },
    },
  },
  {
    title = 'VS Code side by side',
    note = 'A theme can’t style diff text here. The template doesn’t set the gutter colors, so VS Code draws the gutter like the line; the strips are an approximation of how they’d look.',
    options = {
      { 'Now', 'gutter not set, no word outline', function(c) return vscode_sbs(c, {}) end },
      { 'Gutter strips', 'diffEditorGutter.removedLineBackground = removed<br>diffEditorGutter.insertedLineBackground = added', function(c) return vscode_sbs(c, { c.removed, c.added }) end },
      { 'Removed-word outline', 'diffEditor.removedTextBorder = removed', function(c) return vscode_sbs(c, { nil, nil, c.removed }) end },
    },
  },
}

local function mock_grid(d)
  local head = { '<th>Option</th>' }
  for _, name in ipairs(SHOW) do
    table.insert(head, ('<th>%s <span class="sub">%s</span></th>'):format(name, P[name].title))
  end
  local rows = {}
  for _, o in ipairs(d.options) do
    local cells = { ('<th class="opt">%s<small>%s</small></th>'):format(o[1], o[2]) }
    for _, name in ipairs(SHOW) do
      local c = P[name]
      table.insert(cells, ('<td><div class="swatch mock" style="background:%s">%s</div></td>'):format(c.bg, o[3](c)))
    end
    table.insert(rows, '<tr>' .. table.concat(cells) .. '</tr>')
  end
  return ([[
  <div class="part">
    <h3>%s</h3>
    <p>%s</p>
    <div class="table-wrap"><table class="grid"><thead><tr>%s</tr></thead><tbody>%s</tbody></table></div>
  </div>]]):format(d.title, d.note, table.concat(head), table.concat(rows))
end

local diff_parts = {}
for _, d in ipairs(DIFFS) do
  table.insert(diff_parts, mock_grid(d))
end
local diffs = ([[
<section class="theme" id="diffs">
  <header>
    <h2>Diffs <span>now, and the other options considered</span></h2>
    <p class="meta">The same small change in each app that shows diffs: first as it’s set up now, then the other options. These are mocks drawn from palettes.lua by each app’s rules, not screenshots. Faint text (Claude Code’s removed lines, git’s dim) is drawn the way Ghostty draws it, halfway to the background.</p>
  </header>
  %s
</section>]]):format(table.concat(diff_parts, '\n'))

local sections = {}
for _, name in ipairs(SHOW) do
  local c = P[name]
  local rows, summary = table_for(c)
  table.insert(sections, ([[
<section class="theme" id="%s">
  <header>
    <h2>%s <span>%s</span></h2>
    <p class="meta">%s on %s · bright %s · white %s · dim %s</p>
  </header>
  <div class="clash">
    <h3>Can’t be told apart by color</h3>
    <ul>%s</ul>
  </div>
  <div class="cols">
    <figure class="panel-wrap">
      <figcaption>hax0r preview</figcaption>
      <div class="scroll"><div class="panel" style="background:%s">%s</div></div>
    </figure>
    <div class="table-wrap">
      <table>
        <thead><tr><th>In the app</th><th>Role · palette key</th><th>Color</th><th>Same color as</th></tr></thead>
        <tbody>%s</tbody>
      </table>
    </div>
  </div>
</section>]]):format(name, name, c.title, chip(c.fg), chip(c.bg), chip(c.bright), chip(c.white), chip(c.dim),
    #summary > 0 and table.concat(summary) or '<li>Nothing: every pair that has to differ does.</li>',
    c.bg, panel(name, c), rows))
end

local page = ([[
<title>hax0r White &amp; Black</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;600&family=JetBrains+Mono:ital,wght@0,400;0,700;1,400&display=swap">
<style>
/* Layout: a neutral gray bench, so the themes' own colors are the only color on the page.
   One section per theme: what's indistinguishable first, then the preview panel beside the table. */
:root {
  --bench: #e4e4e4;
  --ink: #1a1a1a;
  --muted: #5c5c5c;
  --rule: #c6c6c6;
  --raise: #eeeeee;
  --sans: "IBM Plex Sans", system-ui, -apple-system, sans-serif;
  --mono: "JetBrains Mono", ui-monospace, "SF Mono", Menlo, monospace;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) { --bench: #151515; --ink: #e6e6e6; --muted: #9a9a9a; --rule: #2e2e2e; --raise: #1d1d1d; color-scheme: dark }
}
:root[data-theme="dark"] { --bench: #151515; --ink: #e6e6e6; --muted: #9a9a9a; --rule: #2e2e2e; --raise: #1d1d1d; color-scheme: dark }

body {
  background: var(--bench);
  color: var(--ink);
  font: 15px/1.55 var(--sans);
  padding-left: max(16px, env(safe-area-inset-left, 0px));
  padding-right: max(16px, env(safe-area-inset-right, 0px));
  padding-block: 40px 64px;
}
main { max-width: 1240px; margin-inline: auto; display: grid; gap: 56px }
h1, h2, h3 { text-wrap: balance; margin: 0 }
h1 { font: 600 28px/1.2 var(--mono); letter-spacing: -0.01em }
.intro { display: grid; gap: 10px; max-width: 70ch }
.intro p { margin: 0; color: var(--muted) }
code { font: 0.92em var(--mono) }

.theme { display: grid; gap: 20px; border-top: 1px solid var(--rule); padding-top: 28px }
.theme header { display: grid; gap: 4px }
h2 { font: 700 22px/1.2 var(--mono) }
h2 span { font: 400 16px var(--sans); color: var(--muted); margin-left: 8px }
.meta { margin: 0; color: var(--muted); font-size: 13px; display: flex; flex-wrap: wrap; gap: 4px 6px; align-items: center }

.chip { display: inline-flex; align-items: center; gap: 5px; font: 12px var(--mono); white-space: nowrap; color: var(--ink) }
.chip i { width: 12px; height: 12px; border-radius: 2px; box-shadow: 0 0 0 1px var(--rule) }

.clash { background: var(--raise); border: 1px solid var(--rule); border-radius: 6px; padding: 12px 16px; max-width: 70ch }
.clash h3 { font: 600 11px/1.4 var(--sans); text-transform: uppercase; letter-spacing: 0.08em; color: var(--muted); margin-bottom: 6px }
.clash ul { margin: 0; padding-left: 18px; display: grid; gap: 2px }

.cols { display: flex; flex-wrap: wrap; gap: 24px; align-items: flex-start }
figure { margin: 0; display: grid; gap: 6px; min-width: 0; max-width: 100%% }
figcaption, thead th { font: 600 11px/1.4 var(--sans); text-transform: uppercase; letter-spacing: 0.08em; color: var(--muted) }
.scroll { overflow-x: auto; max-width: 100%% }
.panel { width: 62ch; padding-block: 6px; font: 13px/1.5 var(--mono) }
.ln { white-space: pre; min-height: 1.5em; padding-inline: 0 }

.table-wrap { flex: 1 1 560px; min-width: 0; overflow-x: auto }
table { border-collapse: collapse; width: 100%%; font-size: 13px }
thead th { text-align: left; padding: 0 10px 6px 0 }
td { padding: 0 10px 0 0; vertical-align: middle; border-top: 1px solid var(--rule) }
tr.group th { text-align: left; font-weight: 400; color: var(--muted); padding: 18px 0 6px; font-size: 12.5px }
tr.group th span { font: 600 12px var(--sans); color: var(--ink); margin-right: 6px }
td.sample { padding: 0; width: 1%%; }
td.sample .ln { font: 13px/2.1 var(--mono); width: 30ch; }
td.role b { display: block; font-weight: 600 }
td.role small, td.hex small { display: block; color: var(--muted); font: 11.5px var(--mono) }
td.hex { white-space: nowrap; font-variant-numeric: tabular-nums }
td.hex .chip + .chip { margin-left: 6px }
td.same { color: var(--muted) }
td.same.hit { color: var(--ink); font-weight: 600 }
td.role, td.hex, td.same { padding-block: 6px }

.part { display: grid; gap: 6px }
.part h3 { font: 700 15px/1.3 var(--mono) }
.part p { margin: 0; color: var(--muted); font-size: 13px; max-width: 80ch }
table.grid { width: auto; margin-top: 6px }
table.grid th, table.grid td { vertical-align: top; padding: 10px 14px 12px 0; border-top: 1px solid var(--rule) }
table.grid thead th { border-top: 0; padding-bottom: 4px }
th.who { text-align: left; font: 700 13px var(--mono); white-space: nowrap }
th.who small { display: block; font: 400 12px var(--sans); color: var(--muted) }
.swatch { padding-block: 4px; border-radius: 3px; overflow: hidden }
.swatch .ln { font: 13px/1.8 var(--mono); width: 37ch; padding-inline: 0 }
.cap { display: grid; gap: 1px; margin-top: 5px; font-size: 12px }
.cap small { color: var(--muted); font: 11.5px var(--mono); font-variant-numeric: tabular-nums }
.cap b { font-weight: 600 }
th.opt { text-align: left; font: 600 13px var(--sans); width: 24ch; min-width: 16ch }
th.opt small { display: block; margin-top: 2px; font: 400 11.5px/1.45 var(--mono); color: var(--muted) }
thead .sub { font-weight: 400; text-transform: none; letter-spacing: 0; margin-left: 4px }
.swatch.mock { padding-block: 6px }
.swatch.mock .ln { width: 42ch; line-height: 1.7 }
.swatch.mock .sbs { display: flex }
.swatch.mock .sbs .ln { width: 24ch; flex: none }
.sbs .sep { width: 1px; flex: none }

footer { color: var(--muted); font-size: 13px; max-width: 70ch }
</style>

<main>
  <div class="intro">
    <h1>hax0r white &amp; black</h1>
    <p>Drawn from <code>palettes.lua</code>%s, in exact colors. First, how each app draws diffs now, next to the other options considered. Then white and black as they are: the panel on the left is what <code>hax0r preview</code> shows, and the table lists every place an app shows a git, diff or problem color.</p>
    <p>“Same color as” lists the other colors in that spot that have to be told apart by color alone and are under %.2f:1 against this one. Colors that share a palette key on purpose, like Added and Untracked, aren’t listed.</p>
  </div>
  %s
  %s
  <footer>Built by <code>~/.config/hax0r/page.lua</code>, which reads <code>palettes.lua</code> and redraws <code>preview.lua</code>’s panel as HTML.</footer>
</main>
]]):format(label and (' at <code>' .. esc(label) .. '</code>') or '', SAME, diffs, table.concat(sections, '\n'))

local f = assert(io.open(out, 'w'))
f:write(page)
f:close()
print('wrote ' .. out)
