-- The hax0r themes. Colors come from ~/.config/hax0r/palettes.lua, and the theme is the one
-- `hax0r <theme>` last chose (stored in ~/.local/state/hax0r/theme), Gr33N if none
local config = vim.env.XDG_CONFIG_HOME or vim.fs.normalize('~/.config')
local state = vim.env.XDG_STATE_HOME or vim.fs.normalize('~/.local/state')
local palettes = dofile(config .. '/hax0r/palettes.lua')

local name = 'green'
local file = io.open(state .. '/hax0r/theme')
if file then
  name = file:read('l') or name
  file:close()
end
local c = palettes[name] or palettes.green

vim.cmd.highlight('clear')

if vim.fn.exists('syntax_on') == 1 then
  vim.cmd.syntax('reset')
end

vim.o.background = c.light and 'light' or 'dark'
vim.g.colors_name = 'hax0r'

local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Chrome
hl('Normal', { fg = c.fg, bg = c.bg })
hl('Cursor', { fg = c.cursor_text, bg = c.cursor })
hl('LineNr', { fg = c.line_nr })
hl('CursorLineNr', { fg = c.line_nr_active })
hl('CursorLine', { bg = c.cursor_line })
hl('CursorColumn', { bg = c.cursor_line })
hl('ColorColumn', { bg = c.dark })
hl('SignColumn', { fg = c.dim })
hl('EndOfBuffer', { fg = c.nontext })
hl('NonText', { fg = c.nontext })
hl('StatusLine', { fg = c.statusline, bg = c.dark })
hl('StatusLineNC', { fg = c.dim, bg = c.dark })
hl('WinBar', { link = 'StatusLine' })
hl('WinBarNC', { link = 'StatusLineNC' })
hl('WinSeparator', { fg = c.border }) -- not dim: the faint outline VS Code draws around its panels, so splits don't shout
hl('Directory', { fg = c.directory })

-- Code: each kind in its color from the theme's syntax table, with its style (bold, italic) if
-- the theme gives it one. A one-color theme's table comes from its shades (see palettes.lua)
local function code(group, kind)
  local opts = { fg = assert(c.syntax[kind], kind) }
  for style in (c.styles[kind] or ''):gmatch('%a+') do
    opts[style] = true
  end
  hl(group, opts)
end
code('Comment', 'comment')
code('String', 'string')
code('Function', 'func')
code('Statement', 'keyword')
code('Constant', 'constant')
code('Identifier', 'variable') -- in one-color themes fg, not normal like the vim port: keeps fields plain
code('Type', 'type')
code('Special', 'special')
code('PreProc', 'preproc')
code('Operator', 'operator') -- in one-color themes fg, not white like the vim port: too loud
code('Delimiter', 'delimiter')
code('@variable', 'variable')
hl('Error', { fg = c.error })
hl('Todo', { fg = c.white, bold = true })
code('Title', 'title')
hl('Underlined', { fg = c.link, underline = true })
hl('Conceal', { fg = c.dim })

-- Code, finer: only for a full-color theme, whose syntax table tells these kinds apart. A
-- one-color theme leaves these groups to nvim's links, back to the ones above
if c.full_color then
  for kind, groups in pairs({
    keyword = { 'Keyword', '@keyword', '@keyword.function', '@keyword.operator', '@punctuation.special' },
    control = { 'Conditional', 'Repeat', 'Exception', '@keyword.conditional', '@keyword.repeat',
      '@keyword.return', '@keyword.exception', '@keyword.import', '@keyword.coroutine' },
    storage = { 'StorageClass', 'Structure', 'Typedef', '@keyword.modifier', '@keyword.type' },
    preproc = { 'Include', 'Define', 'PreCondit', '@keyword.directive', '@keyword.directive.define' },
    macro = { 'Macro', '@function.macro', '@constant.macro' },
    string = { 'Character', '@string', '@character', '@string.documentation' },
    escape = { 'SpecialChar', '@string.escape', '@character.special', '@string.special' },
    regex = { '@string.regexp' },
    number = { 'Number', 'Float', '@number', '@number.float' },
    constant = { '@constant' },
    builtin = { 'Boolean', '@boolean', '@constant.builtin', '@variable.builtin', '@variable.parameter.builtin' },
    func = { '@function', '@function.call', '@function.method', '@function.method.call',
      '@function.builtin', '@attribute', '@attribute.builtin' },
    type = { '@type', '@type.builtin', '@type.definition', '@module', '@module.builtin', '@constructor' },
    variable = { '@variable.parameter', '@variable.member', '@property' },
    operator = { '@operator', '@keyword.conditional.ternary' },
    delimiter = { '@punctuation', '@punctuation.delimiter', '@punctuation.bracket', '@constructor.lua' },
    tag = { 'Tag', '@tag', '@tag.builtin' },
    tag_bracket = { '@tag.delimiter' },
    attribute = { '@tag.attribute' },
    label = { 'Label', '@label' },
    heading = { '@markup.heading' },
    raw = { '@markup.raw' },
    quote = { '@markup.quote' },
    list = { '@markup.list' },
    strong = { '@markup.strong' },
    emphasis = { '@markup.italic' },
    inserted = { '@diff.plus' },
    deleted = { '@diff.minus' },
    modified = { '@diff.delta' },
  }) do
    for _, group in ipairs(groups) do
      code(group, kind)
    end
  end
end

-- Interaction
hl('Visual', { bg = c.selection_tint }) -- not solid selection: a big selection glared, so tint it and keep each character's own color
hl('Search', { fg = c.search_text, bg = c.search })
hl('CurSearch', { fg = c.cur_search_text, bg = c.cur_search })
hl('IncSearch', { fg = c.cur_search_text, bg = c.cur_search })
hl('MatchParen', { fg = c.bold, bold = true, underline = true })
hl('Pmenu', { fg = c.fg, bg = c.float_bg })
hl('PmenuSel', { fg = c.menu_sel_text, bg = c.menu_sel })
hl('PmenuThumb', { bg = c.dim })
hl('QuickFixLine', { fg = c.bold, bold = true })

-- Messages
hl('ErrorMsg', { fg = c.error })
hl('WarningMsg', { fg = c.warning })
hl('OkMsg', { fg = c.success })
hl('ModeMsg', { fg = c.bright })
hl('MoreMsg', { fg = c.bright })
hl('Question', { fg = c.bright })
hl('NvimInternalError', { fg = c.bg, bg = c.error })

-- Diagnostics
hl('DiagnosticError', { fg = c.error })
hl('DiagnosticWarn', { fg = c.warning })
hl('DiagnosticInfo', { fg = c.info })
hl('DiagnosticHint', { fg = c.hint })
hl('DiagnosticOk', { fg = c.success })
hl('DiagnosticUnderlineError', { undercurl = true, sp = c.error })
hl('DiagnosticUnderlineWarn', { undercurl = true, sp = c.warning })
hl('DiagnosticUnderlineInfo', { undercurl = true, sp = c.info })
hl('DiagnosticUnderlineHint', { undercurl = true, sp = c.hint })
hl('DiagnosticUnderlineOk', { undercurl = true, sp = c.success })
hl('DiagnosticDeprecated', { strikethrough = true })

-- Diff
-- not dark, cursor_line and red text: the bands VS Code and Claude Code draw. nvim's diff doesn't
-- know which side is older, so lines on one side only are DiffAdd, and the gap across from them is DiffDelete
hl('DiffAdd', { bg = c.diff_add })
hl('DiffChange', { bg = c.diff_add })
hl('DiffText', { bg = c.diff_add_word })
hl('DiffDelete', { fg = c.diff_del_word, bg = c.diff_del })

-- Spell
hl('SpellBad', { undercurl = true, sp = c.error })
hl('SpellCap', { undercurl = true, sp = c.warning })
hl('SpellRare', { undercurl = true, sp = c.bright })
hl('SpellLocal', { undercurl = true, sp = c.dim })

-- Floats and Folds
hl('NormalFloat', { fg = c.fg, bg = c.float_bg })
hl('FloatBorder', { fg = c.float_border, bg = c.float_bg }) -- not dim: VS Code's faint panel outline, as it looks over a float
hl('FloatTitle', { fg = c.bold, bg = c.float_bg, bold = true })
hl('FloatShadow', { bg = c.black, blend = 80 })
hl('FloatShadowThrough', { bg = c.black, blend = 100 })
hl('Folded', { fg = c.dim, bg = c.dark })
hl('FoldColumn', { fg = c.dim })

-- Plugins
-- 1. Rainbow Delimiters: the plugin's colors in its order, which is the order it nests them in,
-- each given the theme's bracket colors in turn
for i, name in ipairs({ 'Red', 'Yellow', 'Blue', 'Orange', 'Green', 'Violet', 'Cyan' }) do
  hl('RainbowDelimiter' .. name, { fg = c.brackets[(i - 1) % #c.brackets + 1] })
end

-- 2. Git Signs
-- added is the theme's bright and removed its dim, in every theme; see palettes.lua. These also
-- color diff text, so the signs get their own: VS Code's change marks, which in black and white
-- are fainter grays, since there white is bright. The rest of gitsigns' groups fall back to these
hl('Added', { fg = c.added })
hl('Changed', { fg = c.changed })
hl('Removed', { fg = c.removed })
hl('GitSignsAdd', { fg = c.mark_added })
hl('GitSignsChange', { fg = c.mark_changed })
hl('GitSignsDelete', { fg = c.mark_removed })
-- Staged signs sit a step dimmer: dim, faint and faint, or about half in black and white. Not
-- ghostty's ansi 8 for changes: it read at 2.01:1, so faint, Claude Code's faint text
hl('GitSignsStagedAdd', { fg = c.staged_add })
hl('GitSignsStagedChange', { fg = c.staged_change })
hl('GitSignsStagedDelete', { fg = c.staged_delete })
hl('GitSignsStagedUntracked', { link = 'GitSignsStagedAdd' })
hl('GitSignsStagedChangedelete', { link = 'GitSignsStagedChange' })
hl('GitSignsStagedTopdelete', { link = 'GitSignsStagedDelete' })
hl('GitSignsStagedAddNr', { link = 'GitSignsStagedAdd' })
hl('GitSignsStagedChangeNr', { link = 'GitSignsStagedChange' })
hl('GitSignsStagedDeleteNr', { link = 'GitSignsStagedDelete' })
hl('GitSignsStagedUntrackedNr', { link = 'GitSignsStagedAdd' })
hl('GitSignsStagedChangedeleteNr', { link = 'GitSignsStagedChange' })
hl('GitSignsStagedTopdeleteNr', { link = 'GitSignsStagedDelete' })
hl('GitSignsStagedAddCul', { link = 'GitSignsStagedAdd' })
hl('GitSignsStagedChangeCul', { link = 'GitSignsStagedChange' })
hl('GitSignsStagedDeleteCul', { link = 'GitSignsStagedDelete' })
hl('GitSignsStagedUntrackedCul', { link = 'GitSignsStagedAdd' })
hl('GitSignsStagedChangedeleteCul', { link = 'GitSignsStagedChange' })
hl('GitSignsStagedTopdeleteCul', { link = 'GitSignsStagedDelete' })
-- Hunk previews: removed lines are dim on the removed band, like Claude Code's and git diff's, and
-- changed words get the word colors instead of reverse video
hl('GitSignsDeletePreview', { fg = c.dim, bg = c.diff_del })
hl('GitSignsDeleteVirtLn', { fg = c.dim, bg = c.diff_del })
hl('GitSignsAddInline', { bg = c.diff_add_word })
hl('GitSignsChangeInline', { bg = c.diff_add_word })
hl('GitSignsDeleteInline', { fg = c.dim, bg = c.diff_del_word })

-- 3. Indent
hl('IblIndent', { fg = c.indent })
hl('IblScope', { fg = c.indent_active })

-- 4. Mason
hl('MasonHeader', { link = 'PmenuSel' })
hl('MasonHeaderSecondary', { link = 'PmenuSel' })
hl('MasonHighlight', { link = 'Function' })
hl('MasonHighlightBlock', { link = 'CurSearch' })
hl('MasonHighlightBlockBold', { link = 'CurSearch' })
hl('MasonHighlightSecondary', { link = 'Identifier' })
hl('MasonHighlightBlockSecondary', { link = 'Search' })
hl('MasonHighlightBlockBoldSecondary', { link = 'Search' })
hl('MasonMuted', { link = 'Comment' })
hl('MasonMutedBlock', { fg = c.fg, bg = c.dim })
hl('MasonMutedBlockBold', { fg = c.fg, bg = c.dim, bold = true })

-- 5. Mini Icons
-- a one-color theme gives every icon hue its one color (see palettes.lua)
for _, name in ipairs({ 'Red', 'Orange', 'Yellow', 'Green', 'Cyan', 'Azure', 'Blue', 'Purple', 'Grey' }) do
  hl('MiniIcons' .. name, { fg = c.icons[name:lower()] })
end

-- 6. Fzf Lua
-- fzf-lua draws its borders like Normal (fg) by default, so give them the faint border too
hl('FzfLuaBorder', { fg = c.border, bg = c.bg })
hl('FzfLuaPreviewBorder', { link = 'FzfLuaBorder' })
-- fzf-lua picks named colors for these (Brown1, CadetBlue1, PaleVioletRed1...), so map them in:
-- numbers like LineNr, keys and the current buffer bright, the rest plain
hl('FzfLuaHeaderBind', { fg = c.bright })
hl('FzfLuaHeaderText', { fg = c.fg })
hl('FzfLuaPathLineNr', { link = 'LineNr' })
hl('FzfLuaPathColNr', { link = 'LineNr' })
hl('FzfLuaBufNr', { link = 'LineNr' })
hl('FzfLuaBufFlagCur', { fg = c.bright })
hl('FzfLuaBufFlagAlt', { fg = c.fg })
hl('FzfLuaLivePrompt', { fg = c.bright })
hl('FzfLuaLiveSym', { fg = c.bright })
hl('FzfLuaTabTitle', { fg = c.bright, bold = true })
hl('FzfLuaTabMarker', { fg = c.bright, bold = true })
-- the fzf window's statusline in split layouts, borrowed from fzf.vim; drawn like StatusLine
hl('fzf1', { fg = c.bright, bg = c.dark })
hl('fzf2', { fg = c.fg, bg = c.dark })
hl('fzf3', { fg = c.fg, bg = c.dark })
-- FzfLuaBackdrop keeps fzf-lua's black: it only dims the editor behind the picker

-- Terminal: the same 16 colors as Ghostty's theme, so :terminal matches it (see palettes.lua)
for i = 0, 15 do
  vim.g['terminal_color_' .. i] = c.ansi[i]
end
