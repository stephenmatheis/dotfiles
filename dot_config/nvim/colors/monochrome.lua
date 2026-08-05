vim.cmd("highlight clear")
vim.g.colors_name = "mono"

local h = function(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Base
h("Normal",     { fg = "#ffffff", bg = "#000000" })
h("NormalNC",   { fg = "#ffffff", bg = "#000000" })

-- Syntax (all white — treesitter and legacy groups)
h("Comment",    { fg = "#888888", italic = true })
h("Constant",   { fg = "#ffffff" })
h("Identifier", { fg = "#ffffff" })
h("Statement",  { fg = "#ffffff", bold = true })
h("PreProc",    { fg = "#ffffff" })
h("Type",       { fg = "#ffffff" })
h("Special",    { fg = "#ffffff" })
h("String",     { fg = "#cccccc" })

-- UI chrome
h("StatusLine", { fg = "#000000", bg = "#ffffff" })
h("Visual",     { bg = "#444444" })
h("Search",     { fg = "#000000", bg = "#ffffff" })
h("CursorLine", { bg = "#111111" })
h("LineNr",     { fg = "#555555" })
