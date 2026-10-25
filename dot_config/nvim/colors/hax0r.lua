vim.cmd.highlight('clear')

if vim.fn.exists('syntax_on') == 1 then
  vim.cmd.syntax('reset')
end

vim.o.background = 'dark'
vim.g.colors_name = 'hax0r'

local c = {
  bg = '#020f01',
  fg = '#16b10e',
  dim_green = '#334843',
  bright_green = '#19e20e',
  dark_green = '#001f0b',
  red = '#ff1111',
  dim_red = '#b00d0d',
  white = '#fafafa',
  selection = '#d4ffc1',
}

-- Chrome
vim.api.nvim_set_hl(0, 'Normal', { fg = c.fg, bg = c.bg })
vim.api.nvim_set_hl(0, 'LineNr', { fg = c.dim_green })
vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'CursorLine', { bg = c.dark_green })
vim.api.nvim_set_hl(0, 'EndOfBuffer', { fg = c.dim_green })
vim.api.nvim_set_hl(0, 'StatusLine', { fg = c.bright_green, bg = c.dark_green })
vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = c.dim_green, bg = c.dark_green })

-- Code
vim.api.nvim_set_hl(0, 'Comment', { fg = c.dim_green, italic = true })
vim.api.nvim_set_hl(0, 'String', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'Function', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'Statement', { fg = c.bright_green, bold = true })
vim.api.nvim_set_hl(0, 'Constant', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'Identifier', { fg = c.fg })
vim.api.nvim_set_hl(0, 'Type', { fg = c.fg })
vim.api.nvim_set_hl(0, 'Special', { fg = c.fg })
vim.api.nvim_set_hl(0, 'Operator', { fg = c.fg })
vim.api.nvim_set_hl(0, '@variable', { fg = c.fg })

-- Interaction
vim.api.nvim_set_hl(0, 'Visual', { fg = c.bg, bg = c.selection })
vim.api.nvim_set_hl(0, 'Search', { fg = c.bg, bg = c.fg })
vim.api.nvim_set_hl(0, 'CurSearch', { fg = c.bg, bg = c.bright_green })
vim.api.nvim_set_hl(0, 'IncSearch', { fg = c.bg, bg = c.bright_green })
vim.api.nvim_set_hl(0, 'MatchParen', { fg = c.bright_green, bold = true, underline = true})
vim.api.nvim_set_hl(0, 'Pmenu', { fg = c.fg, bg = c.dark_green })
vim.api.nvim_set_hl(0, 'PmenuSel', { fg = c.bg, bg = c.fg })
vim.api.nvim_set_hl(0, 'WinSeparator', { fg = c.dim_green })

-- Diagnostics
vim.api.nvim_set_hl(0, 'DiagnosticError', { fg = c.red })
vim.api.nvim_set_hl(0, 'DiagnosticWarn', { fg = c.dim_red })
vim.api.nvim_set_hl(0, 'DiagnosticInfo', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'DiagnosticHint', { fg = c.dim_green })
vim.api.nvim_set_hl(0, 'DiagnosticUnderlineError', { undercurl = true, sp = c.red })
vim.api.nvim_set_hl(0, 'DiagnosticUnderlineWarn', { undercurl = true, sp = c.dim_red })
vim.api.nvim_set_hl(0, 'DiagnosticUnderlineInfo', { undercurl = true, sp = c.bright_green })
vim.api.nvim_set_hl(0, 'DiagnosticUnderlineHint', { undercurl = true, sp = c.dim_green })

-- Floats and Folds
vim.api.nvim_set_hl(0, 'NormalFloat', { fg = c.fg, bg = c.dark_green })
vim.api.nvim_set_hl(0, 'FloatBorder', { fg = c.dim_green, bg = c.dark_green })
vim.api.nvim_set_hl(0, 'FloatTitle', { fg = c.bright_green, bg = c.dark_green, bold = true })
vim.api.nvim_set_hl(0, 'Folded', { fg = c.dim_green, bg = c.dark_green })
vim.api.nvim_set_hl(0, 'FoldColumn', { fg = c.dim_green })

-- Plugins
-- 1. Rainbow Delimiters
vim.api.nvim_set_hl(0, 'RainbowDelimiterRed', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'RainbowDelimiterYellow', { fg = c.fg })
vim.api.nvim_set_hl(0, 'RainbowDelimiterBlue', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'RainbowDelimiterOrange', { fg = c.fg })
vim.api.nvim_set_hl(0, 'RainbowDelimiterGreen', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'RainbowDelimiterViolet', { fg = c.fg })
vim.api.nvim_set_hl(0, 'RainbowDelimiterCyan', { fg = c.bright_green })

-- 2. Git Signs
vim.api.nvim_set_hl(0, 'Added', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'Changed', { fg = c.white })
vim.api.nvim_set_hl(0, 'Removed', { fg = c.red })

-- 3. Indent
vim.api.nvim_set_hl(0, 'IblIndent', { fg = c.dim_green })
vim.api.nvim_set_hl(0, 'IblScope', { fg = c.fg })

-- 4. Mason
vim.api.nvim_set_hl(0, 'MasonHeader', { link = 'PmenuSel' })
vim.api.nvim_set_hl(0, 'MasonHeaderSecondary', { link = 'PmenuSel' })
vim.api.nvim_set_hl(0, 'MasonHighlight', { link = 'Function' })
vim.api.nvim_set_hl(0, 'MasonHighlightBlock', { link = 'CurSearch' })
vim.api.nvim_set_hl(0, 'MasonHighlightBlockBold', { link = 'CurSearch' })


vim.api.nvim_set_hl(0, 'MasonHighlightSecondary', { link = 'Identifier' })
vim.api.nvim_set_hl(0, 'MasonHighlightBlockSecondary', { link = 'Search' })
vim.api.nvim_set_hl(0, 'MasonHighlightBlockBoldSecondary', { link = 'Search' })
vim.api.nvim_set_hl(0, 'MasonMuted', { link = 'Comment' })
vim.api.nvim_set_hl(0, 'MasonMutedBlock', { fg = c.fg, bg = c.dim_green })
vim.api.nvim_set_hl(0, 'MasonMutedBlockBold', { fg = c.fg, bg = c.dim_green, bold = true })

-- Leftovers
vim.api.nvim_set_hl(0, 'Delimiter', { fg = c.fg })
vim.api.nvim_set_hl(0, 'PreProc', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'Title', { fg = c.bright_green, bold = true })
vim.api.nvim_set_hl(0, 'Todo', { fg = c.white, bold = true })
vim.api.nvim_set_hl(0, 'Directory', { fg = c.bright_green })

-- Messages and Chrome
vim.api.nvim_set_hl(0, 'ErrorMsg', { fg = c.red })
vim.api.nvim_set_hl(0, 'WarningMsg', { fg = c.dim_red })
vim.api.nvim_set_hl(0, 'ModeMsg', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'MoreMsg', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'Question', { fg = c.bright_green })
vim.api.nvim_set_hl(0, 'NonText', { fg = c.dim_green })
vim.api.nvim_set_hl(0, 'SignColumn', { fg = c.dim_green })
vim.api.nvim_set_hl(0, 'PmenuThumb', { bg = c.dim_green })

