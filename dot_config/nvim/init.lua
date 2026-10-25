vim.g.mapleader = ' '
vim.o.number = true -- Show line numbers in a column.
vim.o.relativenumber = true
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.lsp.foldexpr()"
vim.o.foldlevelstart = 99 -- don't fold on file load
vim.o.foldcolumn = "1" -- gutter column showing fold chevrons, like an IDE
vim.opt.fillchars:append({ foldopen = "\u{f078}", foldclose = "\u{f054}", foldsep = " " })

vim.api.nvim_create_autocmd('UIEnter', {
  callback = function()
    vim.o.clipboard = 'unnamedplus'
  end,
})

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.cursorline = true
vim.o.scrolloff = 10
-- turn off spaces showing as dashes
vim.o.list = false
vim.o.confirm = true
-- Use <Esc> to exit terminal mode
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')
-- Map <A-j>, <A-k>, <A-h>, <A-l> to navigate between windows in any modes
vim.keymap.set({ 't', 'i' }, '<A-h>', '<C-\\><C-n><C-w>h')
vim.keymap.set({ 't', 'i' }, '<A-j>', '<C-\\><C-n><C-w>j')
vim.keymap.set({ 't', 'i' }, '<A-k>', '<C-\\><C-n><C-w>k')
vim.keymap.set({ 't', 'i' }, '<A-l>', '<C-\\><C-n><C-w>l')
vim.keymap.set({ 'n' }, '<A-h>', '<C-w>h')
vim.keymap.set({ 'n' }, '<A-j>', '<C-w>j')
vim.keymap.set({ 'n' }, '<A-k>', '<C-w>k')
vim.keymap.set({ 'n' }, '<A-l>', '<C-w>l')

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  callback = function()
    vim.hl.on_yank()
  end,
})

-- print the git blame for the current line
vim.api.nvim_create_user_command('GitBlameLine', function()
  local line_number = vim.fn.line('.') -- Get the current line number. See `:h line()`
  local filename = vim.api.nvim_buf_get_name(0)
  print(vim.system({ 'git', 'blame', '-L', line_number .. ',+1', filename }):wait().stdout)
end, { desc = 'Print the git blame for the current line' })

-- add the "nohlsearch" package to automatically disable search highlighting after
-- 'updatetime' and when going to insert mode.
vim.cmd('packadd! nohlsearch')

vim.pack.add({
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/mason-org/mason-lspconfig.nvim',
  'https://github.com/ibhagwan/fzf-lua',
  'https://github.com/nvim-mini/mini.completion',
  'https://github.com/lukas-reineke/indent-blankline.nvim',
  'https://github.com/stevearc/quicker.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/HiPhish/rainbow-delimiters.nvim',
  'https://github.com/luukvbaal/statuscol.nvim',
  -- { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
})

-- require('catppuccin').setup {}

local statuscol_builtin = require('statuscol.builtin')

require('statuscol').setup {
  segments = {
    -- fixed-width fold column: always the same column regardless of nesting depth
    { text = { statuscol_builtin.foldfunc }, click = 'v:lua.ScFa' },
    { text = { '%s' }, click = 'v:lua.ScSa' },
    { text = { statuscol_builtin.lnumfunc, ' ' }, click = 'v:lua.ScLa' },
  },
}

vim.cmd.colorscheme('hax0r')

local fzf = require('fzf-lua')
fzf.setup { fzf_colors = true }

-- File Searching
vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Fuzzy find files" })
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "Fuzzy find open buffers" })
vim.keymap.set("n", "<leader>fr", fzf.oldfiles, { desc = "Fuzzy find recent files" })

-- Text / Grep Searching
vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Live grep search string" })
vim.keymap.set("n", "<leader>fw", fzf.grep_cword, { desc = "Grep word under cursor" })

-- Neovim / LSP Helpers
vim.keymap.set("n", "<leader>fh", fzf.help_tags, { desc = "Search help tags" })
vim.keymap.set("n", "<leader>fk", fzf.keymaps, { desc = "Search keymaps" })
vim.keymap.set("n", "<leader>fd", fzf.diagnostics_workspace, { desc = "Workspace diagnostics" })

require('mini.completion').setup()
require('ibl').setup {
  indent = {
    char = '│',
  },
  scope = {
    -- show_start = false,
    -- show_end = false,
    include = {
      node_type = {
        lua = { 'table_constructor', 'arguments' },
      },
    },
  },
}
require('quicker').setup {}
require('gitsigns').setup {}
require('mason').setup {}

-- Make lua_ls aware of Neovim's runtime (the `vim` global, plugin APIs, etc.)
-- so it stops flagging `vim.*` calls as "undefined global" warnings.
vim.lsp.config('lua_ls', {
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath('config')
        and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
      then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = { version = 'LuaJIT' },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          vim.api.nvim_get_runtime_file('lua/lspconfig', false)[1],
        }
      },
    })
  end,
})

require('mason-lspconfig').setup {
  ensure_installed = {
    'lua_ls',        -- Lua
    'vtsls',         -- TypeScript/JavaScript/React
    'html',          -- HTML
    'cssls',         -- CSS
    'jsonls',        -- JSON
    'yamlls',        -- YAML
    'lemminx',       -- XML
    'marksman',      -- Markdown
    'pyright',       -- Python
    'rust_analyzer', -- Rust
    'bashls',        -- Shell
  },
}
