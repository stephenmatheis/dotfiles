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
hl('WinSeparator', { fg = c.dim_green })
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
hl('Visual', { fg = c.bg, bg = c.selection }) -- not selection_text: 1.09:1 on selection
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
hl('WarningMsg', { fg = c.dim_red })
hl('OkMsg', { fg = c.green })
hl('ModeMsg', { fg = c.bright_green })
hl('MoreMsg', { fg = c.bright_green })
hl('Question', { fg = c.bright_green })
hl('NvimInternalError', { fg = c.bg, bg = c.red })

-- Diagnostics
hl('DiagnosticError', { fg = c.red })
hl('DiagnosticWarn', { fg = c.dim_red })
hl('DiagnosticInfo', { fg = c.bright_green })
hl('DiagnosticHint', { fg = c.dim_green })
hl('DiagnosticOk', { fg = c.green })
hl('DiagnosticUnderlineError', { undercurl = true, sp = c.red })
hl('DiagnosticUnderlineWarn', { undercurl = true, sp = c.dim_red })
hl('DiagnosticUnderlineInfo', { undercurl = true, sp = c.bright_green })
hl('DiagnosticUnderlineHint', { undercurl = true, sp = c.dim_green })
hl('DiagnosticUnderlineOk', { undercurl = true, sp = c.green })
hl('DiagnosticDeprecated', { strikethrough = true })

-- Diff
hl('DiffAdd', { bg = c.dark_green })
hl('DiffChange', { bg = c.dark_green })
hl('DiffText', { bg = c.cursor_line })
hl('DiffDelete', { fg = c.red })

-- Spell
hl('SpellBad', { undercurl = true, sp = c.red })
hl('SpellCap', { undercurl = true, sp = c.dim_red })
hl('SpellRare', { undercurl = true, sp = c.bright_green })
hl('SpellLocal', { undercurl = true, sp = c.dim_green })

-- Floats and Folds
hl('NormalFloat', { fg = c.fg, bg = c.dark_green })
hl('FloatBorder', { fg = c.dim_green, bg = c.dark_green })
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
hl('GitSignsStagedChange', { fg = c.ghostty_black })
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

-- Terminal
vim.g.terminal_color_0 = c.dark_green
vim.g.terminal_color_1 = c.green
vim.g.terminal_color_2 = c.green
vim.g.terminal_color_3 = c.green
vim.g.terminal_color_4 = c.green
vim.g.terminal_color_5 = c.green
vim.g.terminal_color_6 = c.green
vim.g.terminal_color_7 = c.white
vim.g.terminal_color_8 = c.ghostty_black -- not black: #001510 is invisible as text, match ghostty instead
vim.g.terminal_color_9 = c.bright_green
vim.g.terminal_color_10 = c.bright_green
vim.g.terminal_color_11 = c.bright_green
vim.g.terminal_color_12 = c.bright_green
vim.g.terminal_color_13 = c.bright_green
vim.g.terminal_color_14 = c.bright_green
vim.g.terminal_color_15 = c.bright_white
