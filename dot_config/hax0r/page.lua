-- `nvim -l ~/.config/hax0r/page.lua <out.html> [label]`: a web page of the hax0r themes drawn from
-- palettes.lua in exact colors, for judging colors by eye where a terminal can't show them. It
-- draws the new themes under consideration (MONO and DUO, built by palettes.lua's derive helpers),
-- the single colors in CHOICES and how each app shows diffs, each now next to the other options
-- considered, then for each theme in SHOW the `hax0r preview` panel and every place an app uses a
-- git, diff or problem color, with colors that can't be told apart flagged. To weigh a change, add
-- an option row to CHOICES or DIFFS (or a section of its own) that draws it next to Now. label
-- names the version shown, like a commit.
local config = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. '/.config')
local P = dofile(config .. '/hax0r/palettes.lua')
local D = P.derive
local out = assert(arg[1], 'usage: nvim -l page.lua <out.html> [label]')
local label = arg[2]
local SHOW = { 'amber', 'red', 'green' }
local SAME = 1.15 -- two colors closer than this contrast ratio read as the same color
local APART = 0.06 -- in a dual theme, two colors at least this far apart (OKLab) read as different colors anyway

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
    line(c, { nr(1), { '-- palette for the hax0r theme', 'comment', 'i' } }),
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
      { "',", 'fg', '', c.diff_del }, { ' -- old green', 'comment', 'i', c.diff_del } }, c.diff_del),
    line(c, { { '  3 ', 'dim', '', c.diff_add }, { "+  fg = '", 'fg', '', c.diff_add }, { '#19e20e', 'normal', '', c.diff_add_word },
      { "',", 'fg', '', c.diff_add }, { ' -- brighter', 'comment', 'i', c.diff_add } }, c.diff_add),
    line(c, {}),
    line(c, { { (' contrast: text %s  comments %s  bright %s  error %s'):format(ratio('fg'), ratio('comment'), ratio('bright'), ratio('error')), 'dim' } }),
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
      { 'ignored', 'Ignored', file('.DS_Store', '', 'ignored'), cmp = 'files' },
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

local function table_for(c, by_hue)
  local html, clashes = {}, {}
  for _, g in ipairs(GROUPS) do
    table.insert(html, ('<tr class="group"><th colspan="4"><span>%s</span> %s</th></tr>'):format(g.title, g.note))
    for _, r in ipairs(g.rows) do
      local key = r[1]
      local same = {}
      for _, o in ipairs(g.rows) do
        if o ~= r and o.cmp == r.cmp and o[1] ~= key and contrast(c[o[1]], c[key]) < SAME
            and not (by_hue and D.distance(c[o[1]], c[key]) >= APART) then
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

-- A color under test, with its contrast against each color it has to stand apart from.
-- against: { palette key, what that color is }
local function verdict(c, v, against)
  local parts = {}
  for _, a in ipairs(against) do
    local r = contrast(v, c[a[1]])
    local text = ('%.2f:1 %s'):format(r, a[2])
    table.insert(parts, r < SAME and ('<b>≈ ' .. text .. '</b>') or text)
  end
  return ('<div class="cap">%s<small>%s</small></div>'):format(chip(v), table.concat(parts, '<br>'))
end

-- VS Code's explorer, then nvim, with hover in the color under test. The explorer rows: a folder,
-- the selection while the sidebar isn't focused (dark), an ignored folder, the row under the
-- mouse, the selection while it's focused (fg). nvim's cursor is on line 12, with 'Visual' selected.
local function hover_mock(c, hover)
  return table.concat({
    line(c, { { '  › public', 'fg' } }),
    line(c, { { '  › src', 'fg' } }, 'dark'),
    line(c, { { '  › test-results', 'ignored' } }),
    line(c, { { '    index.html', 'bright' } }, hover),
    line(c, { { '    package.json', 'bg' } }, 'fg'),
    line(c, { { '    vite.config.ts', 'fg' } }),
    line(c, {}),
    line(c, { { ' 11 ', 'dim' }, { 'local function', 'bold', 'b' }, { ' ', 'fg' }, { 'hl', 'normal' }, { '(group, opts)', 'fg' } }),
    line(c, { { ' 12 ', 'bright' }, { '  vim.api.', 'fg' }, { 'nvim_set_hl', 'normal' }, { '(0, group, opts)', 'fg' } }, hover),
    line(c, { { ' 13 ', 'dim' }, { 'end', 'bold', 'b' } }),
    line(c, { { ' 14 ', 'dim' }, { 'hl', 'normal' }, { '(', 'fg' }, { "'Visual'", 'normal', '', 'selection_tint' },
      { ', { bg = c.tint })', 'fg' } }),
  })
end

-- VS Code's explorer in the wallet repo, with ignored names in the color under test. A deleted file
-- only shows in Open Editors and Source Control, struck through, but it's drawn here to compare.
local function ignored_mock(c, ignored)
  local function row(lead, name, key, badge, attrs)
    return line(c, { { lead .. name, key, attrs }, { (' '):rep(34 - #name) .. (badge or ''), key } })
  end
  return table.concat({
    row('  › ', '.claude', ignored),
    row('  › ', '.vite-hooks', 'fg'),
    row('  › ', 'dist', ignored),
    row('  › ', 'node_modules', ignored),
    row('  › ', 'src', 'fg'),
    row('  › ', 'transactions', ignored),
    row('    ', '.env', ignored),
    row('    ', 'features.md', 'white', 'M'),
    row('    ', 'old-notes.md', 'removed', 'D', 's'),
    row('    ', 'vite.config.ts', 'fg'),
  })
end

local function try_hover(pick)
  return function(c)
    local v = pick(c)
    return hover_mock(c, v), verdict(c, v, { { 'bg', 'on bg' }, { 'dark', 'vs the unfocused selection (dark)' },
      { 'selection_tint', 'vs Visual (selection_tint)' } })
  end
end

local function try_ignored(pick)
  return function(c)
    local v = pick(c)
    return ignored_mock(c, v), verdict(c, v, { { 'bg', 'on bg' }, { 'fg', 'vs other files (fg)' }, { 'removed', 'vs Deleted (dim)' } })
  end
end

-- Single colors as set now, then the other options considered. An option returns its mock and then
-- a caption, drawn under it.
local CHOICES = {
  {
    title = 'Hover background',
    note = 'cursor_line: VS Code’s hover on list rows, status bar items, menus, sticky scroll and secondary buttons (and its drop target and find range), and nvim’s CursorLine and CursorColumn. The explorer shows every state a row can be in at once: a folder, the selection while the sidebar isn’t focused, an ignored folder, the row under the mouse, and the selection while it’s focused. Below it, nvim with the cursor on line 12 and \'Visual\' selected.',
    options = {
      { 'Now', 'bright @ 30%: the theme’s color itself, in every theme', try_hover(function(c) return c.cursor_line end) },
      { 'Cyan guide @ 25%', 'before: cursor guide #b3ecff @ 25%, Gr33N’s pale cyan over each background', try_hover(function(c) return mix('#b3ecff', c.bg, 0.25) end) },
      { 'Selection @ 25%', 'each theme’s own pale color in place of the cyan, at the same 25%', try_hover(function(c) return mix(c.selection, c.bg, 0.25) end) },
      { 'White @ 18%', 'white’s rule before, from when the cyan looked out of place in gray', try_hover(function(c) return mix(c.white, c.bg, 0.18) end) },
    },
  },
  {
    title = 'Ignored files',
    note = 'ignored, VS Code’s gitDecoration.ignoredResourceForeground. Ignored names have to read dimmer than other files, and the template keeps them apart from Deleted. faint, which it used before, is still nvim’s staged change and staged delete signs; Claude Code’s subtle text moved off faint for the same reason, because a neutral gray read as off-theme. This is the wallet repo’s explorer; old-notes.md is drawn deleted to compare, though deleted files only show in Open Editors and Source Control.',
    options = {
      { 'Now', 'fg @ 60%: a darker shade of the text color', try_ignored(function(c) return c.ignored end) },
      { 'faint', 'before: white @ 40%, still nvim’s staged signs', try_ignored(function(c) return c.faint end) },
      { 'Selection @ 40%', 'faint’s strength in each theme’s pale color', try_ignored(function(c) return mix(c.selection, c.bg, 0.40) end) },
      { 'dim', 'Deleted’s color, which Claude Code’s subtle text uses', try_ignored(function(c) return c.dim end) },
    },
  },
}

local function mock_grid(d)
  local shown = d.show or SHOW
  local head = { '<th>Option</th>' }
  for _, name in ipairs(shown) do
    table.insert(head, ('<th>%s <span class="sub">%s</span></th>'):format(name, P[name].title))
  end
  local rows = {}
  for _, o in ipairs(d.options) do
    local cells = { ('<th class="opt">%s<small>%s</small></th>'):format(o[1], o[2]) }
    for _, name in ipairs(shown) do
      local c = P[name]
      local mock, caption = o[3](c)
      table.insert(cells, ('<td><div class="swatch mock" style="background:%s">%s</div>%s</td>'):format(c.bg, mock, caption or ''))
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

-- A section of option grids, one per entry in list
local function grids(id, heading, sub, meta, list)
  local parts = {}
  for _, d in ipairs(list) do
    table.insert(parts, mock_grid(d))
  end
  return ([[
<section class="theme" id="%s">
  <header>
    <h2>%s <span>%s</span></h2>
    <p class="meta">%s</p>
  </header>
  %s
</section>]]):format(id, heading, sub, meta, table.concat(parts, '\n'))
end

-- New themes under consideration, built by palettes.lua's derive helpers. A hue is OKLCH degrees, or
-- a theme's name for that theme's own hue. Each is drawn both ways palettes.lua can match Gr33N.
local function hue_of(h)
  return type(h) == 'number' and h or D.hue(P[h].normal)
end

local EQUALS = {
  { 'contrast', 'Gr33N’s contrast against the background, as amber was matched' },
  { 'lightness', 'Gr33N’s lightness only: more vivid, dimmer to read' },
}

local MONO = {}
for _, spec in ipairs({
  { 'Pink', { 355, 340, 325 } },
  { 'Purple', { 310, 300, 290 } },
  { 'Electric blue', { 266, 258, 250 } },
}) do
  for _, h in ipairs(spec[2]) do
    local name = ('%s %d°'):format(spec[1], h)
    table.insert(MONO, { name, ('hue %d'):format(h), function(equal) return D.mono(name, h, equal) end })
  end
end

local DUO = {}
for _, spec in ipairs({
  { 'Cyan + pink', 195, 350 },
  { 'Purple + amber', 300, 'amber' },
  { 'Green + amber', 'green', 'amber' },
  { 'Blue + orange', 'blue', 55 },
}) do
  local name, a, b = spec[1], hue_of(spec[2]), hue_of(spec[3])
  table.insert(DUO, { name, ('hues %.0f + %.0f'):format(a, b), function(equal) return D.duo(name, a, b, equal) end })
end

local function candidate_cell(equal, c, by_hue)
  local _, summary = table_for(c, by_hue)
  local chips = {}
  for _, k in ipairs(c.accent and { 'fg', 'dim', 'bright', 'accent', 'accent_dim' } or { 'fg', 'dim', 'normal', 'bright', 'selection' }) do
    table.insert(chips, chip(c[k]))
  end
  return ('<td><div class="scroll"><div class="panel" style="background:%s">%s</div></div><p class="meta">%s</p><ul class="clashes">%s</ul></td>'):format(
    c.bg, panel(equal, c), table.concat(chips, ' '),
    #summary > 0 and table.concat(summary) or '<li>Every pair that has to differ does.</li>')
end

local function candidates(id, heading, sub, meta, list, by_hue)
  local head = { '<th>Option</th>' }
  for _, e in ipairs(EQUALS) do
    table.insert(head, ('<th>Equal %s <span class="sub">%s</span></th>'):format(e[1], e[2]))
  end
  local rows = {}
  for _, o in ipairs(list) do
    local cells = { ('<th class="opt">%s<small>%s</small></th>'):format(o[1], o[2]) }
    for _, e in ipairs(EQUALS) do
      table.insert(cells, candidate_cell(e[1], o[3](e[1]), by_hue))
    end
    table.insert(rows, '<tr>' .. table.concat(cells) .. '</tr>')
  end
  return ([[
<section class="theme" id="%s">
  <header>
    <h2>%s <span>%s</span></h2>
    <p class="meta">%s</p>
  </header>
  <div class="table-wrap"><table class="grid cands"><thead><tr>%s</tr></thead><tbody>%s</tbody></table></div>
</section>]]):format(id, heading, sub, meta, table.concat(head), table.concat(rows))
end

-- The derive helper against the themes set by hand: green is its source, so it has to match;
-- amber was matched to Gr33N by hand; red and blue were kept deeper than a Gr33N match
local function helper_check()
  local function strip(c)
    local boxes = {}
    for _, k in ipairs({ 'fg', 'dim', 'normal', 'bright', 'selection' }) do
      table.insert(boxes, ('<i style="background:%s" title="%s %s"></i>'):format(c[k], k, c[k]))
    end
    return ('<div class="strip" style="background:%s">%s</div>'):format(c.bg, table.concat(boxes))
  end
  local rows = {}
  for _, name in ipairs({ 'green', 'amber', 'red', 'blue' }) do
    local c = P[name]
    local d = D.mono(c.title, D.hue(c.normal))
    local far = {}
    for _, k in ipairs({ 'bg', 'fg', 'dim', 'normal', 'bright', 'selection' }) do
      local dist = D.distance(c[k], d[k])
      table.insert(far, (dist >= 0.05 and '<b>%s %.2f</b>' or '%s %.2f'):format(k, dist))
    end
    table.insert(rows, ('<tr><th class="opt">%s<small>hue %.0f°</small></th><td>%s</td><td>%s</td><td class="hex"><small>%s</small></td></tr>')
      :format(name, D.hue(c.normal), strip(c), strip(d), table.concat(far, '<br>')))
  end
  return ([[
<section class="theme" id="helper-check">
  <header>
    <h2>Helper check <span>the derive helper against the themes set by hand</span></h2>
    <p class="meta">Each theme rebuilt from its own hue, so any difference is the helper’s. Green is the source, so it has to match, except where Gr33N is set differently on purpose (its cursor text and badge, and a gray and black that lean teal). Amber was matched to Gr33N by hand, so it should land close, and does. Red and blue were kept deeper than a Gr33N match on purpose, so they differ. Distance is OKLab; 0.02 is about the least anyone sees, and 0.05 or more is bold. Hover a box for its role and color.</p>
  </header>
  <div class="table-wrap"><table class="grid"><thead><tr><th>Theme</th><th>Set by hand</th><th>Rebuilt</th><th>Distance</th></tr></thead><tbody>%s</tbody></table></div>
</section>]]):format(table.concat(rows))
end

local monos = candidates('mono', 'New single-color themes', 'pink, purple and electric blue',
  ('Gr33N’s colors turned to each hue, drawn both ways. Contrast is the readable one, since blue and purple fall short of Gr33N’s contrast at its lightness. Under each: its key colors, then the pairs that can’t be told apart by color. Comments (dim) and text have to read as well as Gr33N’s (4.2:1 and 6.8:1) to be as easy on the eyes.'),
  MONO)
local duos = candidates('duo', 'New dual themes', 'a second hue for removed, errors and links',
  'The first hue is the theme; the second (accent) takes removed lines, errors and links, and Claude Code’s shimmer later on. Cyan + pink puts the warm color on errors; green + amber uses colors that already exist. Pairs that differ in hue count as told apart even when their lightness is close.',
  DUO, true)
local check = helper_check()

-- What the second hue could do in more places, drawn for the dual themes only. These are options,
-- not what's set: beyond the shimmer, the apps use it only for comments, removed lines, errors and links.
local DUAL_SHOW = { 'cyan-pink', 'pink-cyan' }

-- text in its base color with a band of shimmer swept across it, drawn at three positions.
-- Like Claude Code's sweep (2.1.314), the band is 3 characters in the plain shimmer color, not blended
local function frames(c, text, base, shimmer)
  local chars = {}
  for ch in text:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
    table.insert(chars, ch)
  end
  local out = {}
  for _, at in ipairs({ 0.1, 0.5, 0.9 }) do
    local parts = { { ' ', 'fg' } }
    for i, ch in ipairs(chars) do
      local in_band = math.abs(i - 1 - math.floor(at * #chars)) <= 1
      table.insert(parts, { ch, in_band and c[shimmer] or c[base] })
    end
    table.insert(out, line(c, parts))
  end
  return table.concat(out)
end

-- s: shimmer roles for Claude Code's spinner, its prompt border and its permission prompt, over
-- the base colors generate.lua sets (claude: bright, promptBorder: dim, permission: selection)
local function shimmer_mock(c, s)
  return table.concat({
    frames(c, '✻ Thinking… (esc to interrupt)', 'bright', s[1]),
    line(c, {}),
    frames(c, ('─'):rep(30), 'dim', s[2]),
    line(c, {}),
    frames(c, 'Do you want to make this edit?', 'selection', s[3]),
  })
end

-- o: roles for the directory, branch, git status, command time and prompt character. Starship
-- names ANSI colors, so today each is the theme's one color, except the branch (dim). A failed
-- command's prompt is palette slot 196, the theme's error color
local function starship_mock(c, o)
  local gap = { ' ', 'fg' }
  return table.concat({
    line(c, { { '~/dotfiles', o[1] }, gap, { 'main', o[2] }, gap, { '*', 'bright_white' }, gap, { '⇡1 ≡', o[3] }, gap, { '3s', o[4] } }),
    line(c, { { '❯ ', o[5] }, { 'git push', 'fg' } }),
    line(c, {}),
    line(c, { { '❯ ', 'error' }, { 'false', 'fg' }, { '  after a failed command', 'dim' } }),
  })
end

-- git colors changed lines and status letters with ANSI red and green, so red is the one to give
-- the second hue: removed and unstaged in it, added and staged in the theme's color
local function git_mock(c, red)
  local old, new = faint(red, c.bg), c.ansi[2]
  return table.concat({
    git_diff(c, { old, '' }, { new, 'b' }),
    line(c, {}),
    line(c, { { '## main...origin/main', 'fg' } }),
    line(c, { { 'M ', new }, { ' page.lua', 'fg' } }),
    line(c, { { ' M', red }, { ' palettes.lua', 'fg' } }),
    line(c, { { '??', red }, { ' notes.md', 'fg' } }),
  })
end

local DUAL = {
  {
    title = 'Claude Code shimmer',
    note = 'Claude Code sweeps a band of claudeShimmer across its spinner message, drawn in its base color. It’s drawn here at three positions, left, middle and right. The band is three characters in the plain shimmer color with no blending, read from Claude Code 2.1.314’s spinner. During tool use the whole message pulses between the two colors instead, and that code blends them if it can read them as rgb(), which would pass through a grayish lavender. In that version nothing was found using promptBorderShimmer or permissionShimmer, so those two rows may never animate. Only the dual themes changed; the single-color themes keep Before.',
    show = DUAL_SHOW,
    options = {
      { 'Before', 'claudeShimmer = selection, promptBorderShimmer = normal, permissionShimmer = bright_white',
        function(c) return shimmer_mock(c, { 'selection', 'normal', 'bright_white' }) end },
      { 'Now: second hue', 'claudeShimmer and permissionShimmer = accent_bright, promptBorderShimmer = accent',
        function(c) return shimmer_mock(c, { 'claude_shimmer', 'border_shimmer', 'permission_shimmer' }) end },
    },
  },
  {
    title = 'Starship prompt',
    note = 'Starship names ANSI colors, and in every theme those are all the theme’s one color, so the prompt is one color apart from the dim branch and the bright-white *. Two ways to give it the second hue: a new palette slot like 196 (each Ghostty theme and VS Code’s terminal would set it, to the second hue in a dual theme and to the normal color in the others, so nothing else changes), or remapping ANSI colors, which would change every terminal tool. The slot is the safer one; the mock-ups are the same either way. Picked: Now, no change.',
    show = DUAL_SHOW,
    options = {
      { 'Now', 'every named color is the theme’s one color; the branch is dim',
        function(c) return starship_mock(c, { 'normal', 'dim', 'normal', 'normal', 'normal' }) end },
      { 'Prompt only', 'the ❯ in the second hue',
        function(c) return starship_mock(c, { 'normal', 'dim', 'normal', 'normal', 'accent' }) end },
      { 'Prompt and time', 'the ❯ and the command time in the second hue',
        function(c) return starship_mock(c, { 'normal', 'dim', 'normal', 'accent', 'accent' }) end },
      { 'Git in the second hue', 'branch and status in it, the rest in the theme’s color',
        function(c) return starship_mock(c, { 'normal', 'accent_dim', 'accent', 'normal', 'normal' }) end },
    },
  },
  {
    title = 'git diff and status',
    note = 'git colors removed lines, unstaged changes and untracked files with ANSI red, and added lines and staged changes with green. Every theme makes both the one color, so only the + and − tell them apart. Giving red the second hue fixes that, but it’s the ANSI remap: red would change in every terminal tool that uses it (ripgrep matches, ls and others), and possibly in Claude Code’s code blocks. git’s config could name a palette slot instead, for git alone. Picked: Now, no change.',
    show = DUAL_SHOW,
    options = {
      { 'Now', 'ANSI red and green are both the theme’s color', function(c) return git_mock(c, c.ansi[1]) end },
      { 'ANSI red = second hue', 'removed, unstaged and untracked in the second hue', function(c) return git_mock(c, c.accent) end },
    },
  },
}
local dual = grids('dual', 'The second hue in more places', 'Claude Code’s shimmer, Starship and git',
  'Mock-ups for the two dual themes only. Of these, only Claude Code’s shimmer uses the second hue; beyond that the apps use it for comments, removed lines, errors and links. Drawn from palettes.lua by each app’s rules, not screenshots.',
  DUAL)

-- A small TypeScript file by the roles nvim and VS Code share, then what the second hue already
-- marks, to see if it still stands out. o moves roles to other palette keys: { string = 'accent' }
local SYNTAX_ROLES = { 'comment', 'string', 'func', 'const', 'keyword', 'type' }
local function syntax_mock(c, o)
  local r = { comment = 'dim', string = 'normal', func = 'normal', const = 'normal', keyword = 'bold', type = 'bright' }
  for role, key in pairs(o) do r[role] = key end
  local function code(n, parts, back)
    table.insert(parts, 1, { n and ('%2d '):format(n) or '   ', 'dim', '', back })
    for i = 2, #parts do parts[i][4] = parts[i][4] or back end
    return line(c, parts, back)
  end
  local function kw(s) return { s, r.keyword, 'b' } end
  local function fg(s) return { s, 'fg' } end
  local function str(s) return { s, r.string } end
  local function ty(s) return { s, r.type } end
  local function fn(s) return { s, r.func } end
  local function path_line(n, parts, back)
    return code(n, { fg('  '), kw('const'), fg(' path = '), unpack(parts) }, back)
  end
  local added = { str('`themes/'), { '${', 'bright' }, fg('name'), { '}', 'bright' }, str('.json`'), fg(';') }
  return table.concat({
    code(1, { { '// load a theme by name', r.comment, 'i' } }),
    code(2, { kw('import'), fg(' { read } '), kw('from'), fg(' '), str("'./files'"), fg(';') }),
    code(3, {}),
    code(4, { kw('const'), fg(' '), { 'RETRIES', r.const }, fg(' = '), { '3', r.const }, fg(';') }),
    code(5, {}),
    code(6, { kw('export async function'), fg(' '), fn('load'), fg('(') }),
    code(7, { fg('  name: '), ty('ThemeName'), fg(',') }),
    code(8, { fg('): '), ty('Promise'), fg('<'), ty('Theme'), fg('> {') }),
    path_line(9, added),
    code(10, { fg('  '), kw('const'), fg(' text = '), kw('await'), fg(' '), fn('read'), fg('(path);') }),
    code(11, { fg('  '), kw('return'), fg(' '), { 'decode', r.func, '~', nil, 'error' }, fg('(text, '), { 'RETRIES', r.const }, fg(');') }),
    code(12, { fg('}') }),
    line(c, {}),
    code(nil, { { "■ Cannot find name 'decode'.", 'error' } }),
    code(nil, { fg('See '), { 'the docs', 'link', 'u' } }),
    line(c, {}),
    path_line(9, { str("'themes/old.json'"), fg(';') }, 'diff_del'),
    path_line(9, added, 'diff_add'),
  })
end

local function syntax_option(name, about, o)
  return { name, about, function(c)
    local caps = {}
    for _, role in ipairs(SYNTAX_ROLES) do
      if o[role] then
        table.insert(caps, verdict(c, c[o[role]], { { 'bg', 'background' }, { 'error', 'errors' }, { 'link', 'links' } }))
      end
    end
    return syntax_mock(c, o), table.concat(caps)
  end }
end

local syntax = grids('syntax', 'Syntax colors', 'code in the second hue',
  'Options for the two dual themes, in nvim and VS Code. Picked: Comments. The other rows are the ones considered, with comments as they were.',
  { {
    title = 'Code in nvim and VS Code',
    note = ('Both editors share these roles: strings, functions and constants are normal, keywords bold, types bright and comments dim. Each option moves one or two of them to the second hue at a matching brightness. Below the code is what the second hue already marks: an error with its underline, a link, and VS Code’s removed and added lines, which keep their syntax colors. Under each option: the color, and its contrast against the background, errors and links, with ≈ on any pair under %.2f:1. Claude Code’s code blocks and terminal tools read ANSI colors, so with any of these they stay one color unless ANSI is remapped.'):format(SAME),
    show = DUAL_SHOW,
    options = {
      syntax_option('Before', 'no code in the second hue', {}),
      syntax_option('Strings', 'strings = accent', { string = 'accent' }),
      syntax_option('Types', 'types = accent_bright', { type = 'accent_bright' }),
      syntax_option('Strings and types', 'strings = accent, types = accent_bright', { string = 'accent', type = 'accent_bright' }),
      syntax_option('Functions', 'functions = accent', { func = 'accent' }),
      syntax_option('Constants', 'constants and numbers = accent', { const = 'accent' }),
      syntax_option('Keywords', 'keywords = accent_bright', { keyword = 'accent_bright' }),
      syntax_option('Now: comments', 'comments = accent_dim', { comment = 'accent_dim' }),
    },
  } })

local choices = grids('choices', 'Hover and ignored', 'now, and the other options considered',
  ('VS Code’s hover background and ignored files, which read as gray in amber, each drawn as it’s set now and with the other options. These are mocks drawn from palettes.lua by each app’s rules, not screenshots. Under each one: the color, and its contrast against the colors it has to stand apart from, with ≈ on any pair under %.2f:1.'):format(SAME),
  CHOICES)
local diffs = grids('diffs', 'Diffs', 'now, and the other options considered',
  'The same small change in each app that shows diffs: first as it’s set up now, then the other options. These are mocks drawn from palettes.lua by each app’s rules, not screenshots. Faint text (Claude Code’s removed lines, git’s dim) is drawn the way Ghostty draws it, halfway to the background.',
  DIFFS)

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
<meta charset="utf-8">
<title>hax0r Candidates</title>
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
.cap small b { color: var(--ink) }
th.opt { text-align: left; font: 600 13px var(--sans); width: 24ch; min-width: 16ch }
th.opt small { display: block; margin-top: 2px; font: 400 11.5px/1.45 var(--mono); color: var(--muted) }
thead .sub { font-weight: 400; text-transform: none; letter-spacing: 0; margin-left: 4px }
.swatch.mock { padding-block: 6px }
.swatch.mock .ln { width: 42ch; line-height: 1.7 }
.swatch.mock .sbs { display: flex }
.swatch.mock .sbs .ln { width: 24ch; flex: none }
.sbs .sep { width: 1px; flex: none }

.cands th.opt { width: 14ch; min-width: 12ch }
.cands td { padding-right: 24px }
.cands .meta { margin-top: 6px }
.cands .panel { width: 62ch }
ul.clashes { margin: 6px 0 0; padding-left: 18px; display: grid; gap: 2px; font-size: 12px; color: var(--muted) }
.strip { display: inline-flex; gap: 6px; padding: 10px; border-radius: 3px }
.strip i { width: 28px; height: 28px; border-radius: 2px }

footer { color: var(--muted); font-size: 13px; max-width: 70ch }
</style>

<main>
  <div class="intro">
    <h1>hax0r candidates</h1>
    <p>Drawn from <code>palettes.lua</code>%s, in exact colors. First, the syntax color options for the dual themes. Then the new single-color and dual themes under consideration, built by <code>palettes.lua</code>’s derive helpers, mock-ups of what the second hue could do in Claude Code, Starship and git, and a check of those helpers against the themes set by hand. Then VS Code’s hover background and ignored files, now next to the other options considered, how each app draws diffs, and amber, red and green as they are: the panel on the left is what <code>hax0r preview</code> shows, and the table lists every place an app shows a git, diff or problem color.</p>
    <p>“Same color as” lists the other colors in that spot that have to be told apart by color alone and are under %.2f:1 against this one. Colors that share a palette key on purpose, like Added and Untracked, aren’t listed.</p>
  </div>
  %s
  %s
  %s
  <footer>Built by <code>~/.config/hax0r/page.lua</code>, which reads <code>palettes.lua</code> and redraws <code>preview.lua</code>’s panel as HTML.</footer>
</main>
]]):format(label and (' at <code>' .. esc(label) .. '</code>') or '', SAME, table.concat({ syntax, monos, duos, dual, check, choices }, '\n'), diffs, table.concat(sections, '\n'))

local f = assert(io.open(out, 'w'))
f:write(page)
f:close()
print('wrote ' .. out)
