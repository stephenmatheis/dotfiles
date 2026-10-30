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
hl('LineNr', { fg = c.dim })
hl('CursorLineNr', { fg = c.bright })
hl('CursorLine', { bg = c.cursor_line })
hl('CursorColumn', { bg = c.cursor_line })
hl('ColorColumn', { bg = c.dark })
hl('SignColumn', { fg = c.dim })
hl('EndOfBuffer', { fg = c.dim })
hl('NonText', { fg = c.dim })
hl('StatusLine', { fg = c.bright, bg = c.dark })
hl('StatusLineNC', { fg = c.dim, bg = c.dark })
hl('WinBar', { link = 'StatusLine' })
hl('WinBarNC', { link = 'StatusLineNC' })
hl('WinSeparator', { fg = c.border }) -- not dim: the faint outline VS Code draws around its panels, so splits don't shout
hl('Directory', { fg = c.bright })

-- Code
hl('Comment', { fg = c.dim, italic = true })
hl('String', { fg = c.normal })
hl('Function', { fg = c.normal })
hl('Statement', { fg = c.bold, bold = true })
hl('Constant', { fg = c.normal })
hl('Identifier', { fg = c.fg }) -- not normal like the vim port: keeps fields plain
hl('Type', { fg = c.bright })
hl('Special', { fg = c.bright })
hl('PreProc', { fg = c.bright })
hl('Operator', { fg = c.fg }) -- not white like the vim port: too loud in a one-color theme
hl('Delimiter', { fg = c.fg })
hl('@variable', { fg = c.fg })
hl('Error', { fg = c.error })
hl('Todo', { fg = c.white, bold = true })
hl('Title', { fg = c.bold, bold = true })
hl('Underlined', { fg = c.link, underline = true })
hl('Conceal', { fg = c.dim })

-- Interaction
hl('Visual', { bg = c.selection_tint }) -- not solid selection: a big selection glared, so tint it and keep each character's own color
hl('Search', { fg = c.bg, bg = c.fg })
hl('CurSearch', { fg = c.bg, bg = c.bright })
hl('IncSearch', { fg = c.bg, bg = c.bright })
hl('MatchParen', { fg = c.bold, bold = true, underline = true })
hl('Pmenu', { fg = c.fg, bg = c.dark })
hl('PmenuSel', { fg = c.bg, bg = c.fg })
hl('PmenuThumb', { bg = c.dim })
hl('QuickFixLine', { fg = c.bold, bold = true })

-- Messages
hl('ErrorMsg', { fg = c.error })
hl('WarningMsg', { fg = c.warning })
hl('OkMsg', { fg = c.normal })
hl('ModeMsg', { fg = c.bright })
hl('MoreMsg', { fg = c.bright })
hl('Question', { fg = c.bright })
hl('NvimInternalError', { fg = c.bg, bg = c.error })

-- Diagnostics
hl('DiagnosticError', { fg = c.error })
hl('DiagnosticWarn', { fg = c.warning })
hl('DiagnosticInfo', { fg = c.bright })
hl('DiagnosticHint', { fg = c.dim })
hl('DiagnosticOk', { fg = c.normal })
hl('DiagnosticUnderlineError', { undercurl = true, sp = c.error })
hl('DiagnosticUnderlineWarn', { undercurl = true, sp = c.warning })
hl('DiagnosticUnderlineInfo', { undercurl = true, sp = c.bright })
hl('DiagnosticUnderlineHint', { undercurl = true, sp = c.dim })
hl('DiagnosticUnderlineOk', { undercurl = true, sp = c.normal })
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
hl('NormalFloat', { fg = c.fg, bg = c.dark })
hl('FloatBorder', { fg = c.float_border, bg = c.dark }) -- not dim: VS Code's faint panel outline, as it looks over a float
hl('FloatTitle', { fg = c.bold, bg = c.dark, bold = true })
hl('FloatShadow', { bg = c.black, blend = 80 })
hl('FloatShadowThrough', { bg = c.black, blend = 100 })
hl('Folded', { fg = c.dim, bg = c.dark })
hl('FoldColumn', { fg = c.dim })

-- Plugins
-- 1. Rainbow Delimiters
hl('RainbowDelimiterRed', { fg = c.bright })
hl('RainbowDelimiterYellow', { fg = c.fg })
hl('RainbowDelimiterBlue', { fg = c.bright })
hl('RainbowDelimiterOrange', { fg = c.fg })
hl('RainbowDelimiterGreen', { fg = c.bright })
hl('RainbowDelimiterViolet', { fg = c.fg })
hl('RainbowDelimiterCyan', { fg = c.bright })

-- 2. Git Signs
-- added is the theme's bright and removed its dim, in every theme; see palettes.lua
hl('Added', { fg = c.added })
hl('Changed', { fg = c.white })
hl('Removed', { fg = c.removed })
hl('GitSignsStagedAdd', { fg = c.added_dim })
hl('GitSignsStagedChange', { fg = c.faint }) -- not ghostty's ansi 8: it read at 2.01:1, so use Claude Code's faint text
hl('GitSignsStagedDelete', { fg = c.removed_dim })
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
-- Hunk previews, like VS Code: removed lines keep their text color on the removed band (DiffDelete's
-- dim fg is for the gap's dashes), and changed words get the word colors instead of reverse video
hl('GitSignsDeletePreview', { bg = c.diff_del })
hl('GitSignsDeleteVirtLn', { bg = c.diff_del })
hl('GitSignsAddInline', { bg = c.diff_add_word })
hl('GitSignsChangeInline', { bg = c.diff_add_word })
hl('GitSignsDeleteInline', { bg = c.diff_del_word })

-- 3. Indent
hl('IblIndent', { fg = c.dim })
hl('IblScope', { fg = c.fg })

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
-- every hax0r theme sets ansi hues 1-6 to one color, so every icon hue is that color too
hl('MiniIconsRed', { fg = c.normal })
hl('MiniIconsOrange', { fg = c.normal })
hl('MiniIconsYellow', { fg = c.normal })
hl('MiniIconsGreen', { fg = c.normal })
hl('MiniIconsCyan', { fg = c.normal })
hl('MiniIconsAzure', { fg = c.normal })
hl('MiniIconsBlue', { fg = c.normal })
hl('MiniIconsPurple', { fg = c.normal })
hl('MiniIconsGrey', { fg = c.fg })

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
