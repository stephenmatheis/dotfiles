vim.cmd.highlight('clear')

if vim.fn.exists('syntax_on') == 1 then
  vim.cmd.syntax('reset')
end

vim.o.background = 'dark'
vim.g.colors_name = 'hax0r'

local c = {
  -- HaX0R Gr33N, ordered like ghostty's port, values from the original .itermcolors
  dark_green = '#001f0b',     -- ansi 0
  green = '#15d00d',          -- ansi 1-6
  white = '#fafafa',          -- ansi 7
  black = '#001510',          -- ansi 8 (ghostty: #334843, contrast-adjusted)
  bright_green = '#19e20e',   -- ansi 9-14
  bright_white = '#fefefe',   -- ansi 15
  bg = '#020f01',             -- background
  fg = '#16b10e',             -- foreground
  cursor = '#15d00d',         -- cursor
  cursor_text = '#ffffff',    -- cursor text
  selection = '#d4ffc1',      -- selection background
  selection_text = '#fdfdfd', -- selection foreground (ghostty: #b0b0b0, contrast-adjusted)
  -- HaX0R Gr33N, iTerm only
  bold = '#19e30f',           -- bold
  link = '#00e8ca',           -- link
  dim_green = '#0b8700',      -- badge #14ff00 @ 50% over bg
  cursor_line = '#2e4640',    -- cursor guide #b3ecff @ 25% over bg
  -- HaX0R Gr33N, ghostty port
  ghostty_black = '#334843',  -- ansi 8, contrast-adjusted from #001510
  -- HaX0R R3D
  red = '#ff1111',            -- ansi 9
  dim_red = '#b00d0d',        -- ansi 1
  -- Added: no hax0r theme has a warning color
  amber = '#ffb000',          -- amber phosphor, green screen's monochrome sibling
  -- Added: Gr33N's solid selection, tinted down
  selection_tint = '#1b2c18', -- selection @ 12% over bg
  -- Added: VS Code's panel outline, fg @ 15%, for borders
  border = '#052703',         -- fg @ 15% over bg
  float_border = '#03350b',   -- fg @ 15% over dark_green
  -- Added: Claude Code's faint text, a brighter cursor guide
  faint = '#496767',          -- cursor guide #b3ecff @ 40% over bg
  -- Added: the diff colors VS Code and Claude Code use (ghostty palette slots 22/28/52/88)
  diff_green = '#003300',      -- added line, as bright as diff_red
  diff_green_word = '#004c00', -- added word, as bright as diff_red_word
  diff_red = '#5f0000',        -- removed line, xterm's 52
  diff_red_word = '#870000',   -- removed word, xterm's 88
}

local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Chrome
hl('Normal', { fg = c.fg, bg = c.bg })
hl('Cursor', { fg = c.cursor_text, bg = c.cursor })
hl('LineNr', { fg = c.dim_green })
hl('CursorLineNr', { fg = c.bright_green })
hl('CursorLine', { bg = c.cursor_line })
hl('CursorColumn', { bg = c.cursor_line })
hl('ColorColumn', { bg = c.dark_green })
hl('SignColumn', { fg = c.dim_green })
hl('EndOfBuffer', { fg = c.dim_green })
hl('NonText', { fg = c.dim_green })
hl('StatusLine', { fg = c.bright_green, bg = c.dark_green })
hl('StatusLineNC', { fg = c.dim_green, bg = c.dark_green })
hl('WinBar', { link = 'StatusLine' })
hl('WinBarNC', { link = 'StatusLineNC' })
hl('WinSeparator', { fg = c.border }) -- not dim_green: the faint outline VS Code draws around its panels, so splits don't shout
hl('Directory', { fg = c.bright_green })

-- Code
hl('Comment', { fg = c.dim_green, italic = true })
hl('String', { fg = c.green })
hl('Function', { fg = c.green })
hl('Statement', { fg = c.bold, bold = true })
hl('Constant', { fg = c.green })
hl('Identifier', { fg = c.fg }) -- not green like the vim port: keeps fields plain
hl('Type', { fg = c.bright_green })
hl('Special', { fg = c.bright_green })
hl('PreProc', { fg = c.bright_green })
hl('Operator', { fg = c.fg }) -- not white like the vim port: too loud in a green theme
hl('Delimiter', { fg = c.fg })
hl('@variable', { fg = c.fg })
hl('Error', { fg = c.red })
hl('Todo', { fg = c.white, bold = true })
hl('Title', { fg = c.bold, bold = true })
hl('Underlined', { fg = c.link, underline = true })
hl('Conceal', { fg = c.dim_green })

-- Interaction
hl('Visual', { bg = c.selection_tint }) -- not solid selection: a big selection glared, so tint it and keep each character's own color
hl('Search', { fg = c.bg, bg = c.fg })
hl('CurSearch', { fg = c.bg, bg = c.bright_green })
hl('IncSearch', { fg = c.bg, bg = c.bright_green })
hl('MatchParen', { fg = c.bold, bold = true, underline = true })
hl('Pmenu', { fg = c.fg, bg = c.dark_green })
hl('PmenuSel', { fg = c.bg, bg = c.fg })
hl('PmenuThumb', { bg = c.dim_green })
hl('QuickFixLine', { fg = c.bold, bold = true })

-- Messages
hl('ErrorMsg', { fg = c.red })
hl('WarningMsg', { fg = c.amber })
hl('OkMsg', { fg = c.green })
hl('ModeMsg', { fg = c.bright_green })
hl('MoreMsg', { fg = c.bright_green })
hl('Question', { fg = c.bright_green })
hl('NvimInternalError', { fg = c.bg, bg = c.red })

-- Diagnostics
hl('DiagnosticError', { fg = c.red })
hl('DiagnosticWarn', { fg = c.amber })
hl('DiagnosticInfo', { fg = c.bright_green })
hl('DiagnosticHint', { fg = c.dim_green })
hl('DiagnosticOk', { fg = c.green })
hl('DiagnosticUnderlineError', { undercurl = true, sp = c.red })
hl('DiagnosticUnderlineWarn', { undercurl = true, sp = c.amber })
hl('DiagnosticUnderlineInfo', { undercurl = true, sp = c.bright_green })
hl('DiagnosticUnderlineHint', { undercurl = true, sp = c.dim_green })
hl('DiagnosticUnderlineOk', { undercurl = true, sp = c.green })
hl('DiagnosticDeprecated', { strikethrough = true })

-- Diff
-- not dark_green, cursor_line and red text: the bands VS Code and Claude Code draw. nvim's diff doesn't
-- know which side is older, so lines on one side only are DiffAdd, and the gap across from them is DiffDelete
hl('DiffAdd', { bg = c.diff_green })
hl('DiffChange', { bg = c.diff_green })
hl('DiffText', { bg = c.diff_green_word })
hl('DiffDelete', { fg = c.diff_red_word, bg = c.diff_red })

-- Spell
hl('SpellBad', { undercurl = true, sp = c.red })
hl('SpellCap', { undercurl = true, sp = c.amber })
hl('SpellRare', { undercurl = true, sp = c.bright_green })
hl('SpellLocal', { undercurl = true, sp = c.dim_green })

-- Floats and Folds
hl('NormalFloat', { fg = c.fg, bg = c.dark_green })
hl('FloatBorder', { fg = c.float_border, bg = c.dark_green }) -- not dim_green: VS Code's faint panel outline, as it looks over a float
hl('FloatTitle', { fg = c.bold, bg = c.dark_green, bold = true })
hl('FloatShadow', { bg = c.black, blend = 80 })
hl('FloatShadowThrough', { bg = c.black, blend = 100 })
hl('Folded', { fg = c.dim_green, bg = c.dark_green })
hl('FoldColumn', { fg = c.dim_green })

-- Plugins
-- 1. Rainbow Delimiters
hl('RainbowDelimiterRed', { fg = c.bright_green })
hl('RainbowDelimiterYellow', { fg = c.fg })
hl('RainbowDelimiterBlue', { fg = c.bright_green })
hl('RainbowDelimiterOrange', { fg = c.fg })
hl('RainbowDelimiterGreen', { fg = c.bright_green })
hl('RainbowDelimiterViolet', { fg = c.fg })
hl('RainbowDelimiterCyan', { fg = c.bright_green })

-- 2. Git Signs
hl('Added', { fg = c.bright_green })
hl('Changed', { fg = c.white })
hl('Removed', { fg = c.red })
hl('GitSignsStagedAdd', { fg = c.dim_green })
hl('GitSignsStagedChange', { fg = c.faint }) -- not ghostty_black: it read at 2.01:1, so use Claude Code's faint text
hl('GitSignsStagedDelete', { fg = c.dim_red })
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
-- Hunk previews, like VS Code: removed lines keep their text color on the red band (DiffDelete's
-- dark red fg is for the gap's dashes), and changed words get the word colors instead of reverse video
hl('GitSignsDeletePreview', { bg = c.diff_red })
hl('GitSignsDeleteVirtLn', { bg = c.diff_red })
hl('GitSignsAddInline', { bg = c.diff_green_word })
hl('GitSignsChangeInline', { bg = c.diff_green_word })
hl('GitSignsDeleteInline', { bg = c.diff_red_word })

-- 3. Indent
hl('IblIndent', { fg = c.dim_green })
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
hl('MasonMutedBlock', { fg = c.fg, bg = c.dim_green })
hl('MasonMutedBlockBold', { fg = c.fg, bg = c.dim_green, bold = true })

-- 5. Mini Icons
-- Gr33N sets every ansi hue (1-6) to green, so every icon hue is green too
hl('MiniIconsRed', { fg = c.green })
hl('MiniIconsOrange', { fg = c.green })
hl('MiniIconsYellow', { fg = c.green })
hl('MiniIconsGreen', { fg = c.green })
hl('MiniIconsCyan', { fg = c.green })
hl('MiniIconsAzure', { fg = c.green })
hl('MiniIconsBlue', { fg = c.green })
hl('MiniIconsPurple', { fg = c.green })
hl('MiniIconsGrey', { fg = c.fg })

-- 6. Fzf Lua
-- fzf-lua draws its borders like Normal (fg) by default, so give them the faint border too
hl('FzfLuaBorder', { fg = c.border, bg = c.bg })
hl('FzfLuaPreviewBorder', { link = 'FzfLuaBorder' })
-- fzf-lua picks named colors for these (Brown1, CadetBlue1, PaleVioletRed1...), so map them in:
-- numbers like LineNr, keys and the current buffer bright, the rest plain
hl('FzfLuaHeaderBind', { fg = c.bright_green })
hl('FzfLuaHeaderText', { fg = c.fg })
hl('FzfLuaPathLineNr', { link = 'LineNr' })
hl('FzfLuaPathColNr', { link = 'LineNr' })
hl('FzfLuaBufNr', { link = 'LineNr' })
hl('FzfLuaBufFlagCur', { fg = c.bright_green })
hl('FzfLuaBufFlagAlt', { fg = c.fg })
hl('FzfLuaLivePrompt', { fg = c.bright_green })
hl('FzfLuaLiveSym', { fg = c.bright_green })
hl('FzfLuaTabTitle', { fg = c.bright_green, bold = true })
hl('FzfLuaTabMarker', { fg = c.bright_green, bold = true })
-- the fzf window's statusline in split layouts, borrowed from fzf.vim; drawn like StatusLine
hl('fzf1', { fg = c.bright_green, bg = c.dark_green })
hl('fzf2', { fg = c.fg, bg = c.dark_green })
hl('fzf3', { fg = c.fg, bg = c.dark_green })
-- FzfLuaBackdrop keeps fzf-lua's black: it only dims the editor behind the picker

-- Terminal
vim.g.terminal_color_0 = c.dark_green
vim.g.terminal_color_1 = c.green
vim.g.terminal_color_2 = c.green
vim.g.terminal_color_3 = c.green
vim.g.terminal_color_4 = c.green
vim.g.terminal_color_5 = c.green
vim.g.terminal_color_6 = c.green
vim.g.terminal_color_7 = c.fg -- not white: match ghostty's palette, which uses fg so Claude Code's plain code text matches nvim's variables
vim.g.terminal_color_8 = c.dim_green -- not black: match ghostty's palette, which uses dim_green so comments stay readable
vim.g.terminal_color_9 = c.bright_green
vim.g.terminal_color_10 = c.bright_green
vim.g.terminal_color_11 = c.bright_green
vim.g.terminal_color_12 = c.selection -- not bright_green: match ghostty's palette, which uses mint so inline code stands out
vim.g.terminal_color_13 = c.bright_green
vim.g.terminal_color_14 = c.bright_green
vim.g.terminal_color_15 = c.bright_white
