vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.o.number = true
vim.o.relativenumber = true
vim.o.clipboard = "unnamedplus"
vim.o.foldlevelstart = 99
vim.o.signcolumn = "yes"
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.wrap = false
vim.opt.fillchars = { eob = " ", }
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.filetype.add({ extension = { mdx = 'markdown.mdx' } })

vim.keymap.set('n', '<leader>w', ':set wrap!<CR>', { silent = true, desc = "Toggle Wrap" })

vim.pack.add({
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/mason-org/mason-lspconfig.nvim',
    'https://github.com/folke/lazydev.nvim',
    { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1') },
    'https://github.com/catppuccin/nvim',
    'https://github.com/echasnovski/mini.icons',
    'https://github.com/ibhagwan/fzf-lua',
    'https://github.com/stevearc/oil.nvim',
})

local ts_langs = {
    'lua', 'vim', 'vimdoc', 'query',
    'typescript', 'tsx', 'javascript', 'jsdoc',
    'html', 'css', 'python', 'bash',
    'markdown', 'markdown_inline',
    'rust', 'toml', 'json', 'yaml',
}

require('nvim-treesitter').install(ts_langs)

vim.api.nvim_create_autocmd('FileType', {
    callback = function()
        local ok = pcall(vim.treesitter.start)

        if ok then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.wo[0][0].foldmethod = 'expr'
        end
    end,
})

require('catppuccin').setup({
    flavour = "frappe",
    transparent_background = true,
    float = {
        transparent = true,
        solid = false,
    }
})

vim.cmd.colorscheme("catppuccin")

-- <C-space> open menu
-- <C-y> accept
-- <C-n>/<C-p> cycle
-- <C-e> dismiss
require('blink.cmp').setup({
    keymap = {
       preset = 'default',
      ['<Tab>'] = { 'select_and_accept', 'fallback' },
    },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
})

require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()

require('fzf-lua').setup({ 'default' })

vim.keymap.set('n', '<leader>ff', function() require('fzf-lua').files() end, { desc = 'Find: files' })
vim.keymap.set('n', '<leader>fg', function() require('fzf-lua').live_grep() end, { desc = 'Find: live grep' })
vim.keymap.set('n', '<leader>fb', function() require('fzf-lua').buffers() end, { desc = 'Find: buffers' })
vim.keymap.set('n', '<leader>fh', function() require('fzf-lua').helptags() end, { desc = 'Find: help tags' })
vim.keymap.set('n', '<leader>fr', function() require('fzf-lua').resume() end, { desc = 'Find: resume' })
vim.keymap.set('n', '<leader>fd', function() require('fzf-lua').diagnostics_document() end,
    { desc = 'Find: diagnostics' })
vim.keymap.set('n', '<leader>/', function() require('fzf-lua').lgrep_curbuf() end, { desc = 'Find: grep current buffer' })

require('oil').setup({
    view_options = { show_hidden = true },
})

vim.keymap.set('n', '-', '<cmd>Oil<cr>', { desc = 'Open parent directory' })
vim.keymap.set('n', '<leader>e', '<cmd>Oil<cr>', { desc = 'File explorer' })

require('mason').setup()

require('lazydev').setup()

vim.lsp.config('*', {
    capabilities = require('blink.cmp').get_lsp_capabilities(nil, true),
})

vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            diagnostics = { globals = { 'vim' } },
        },
    },
})

require('mason-lspconfig').setup({
    ensure_installed = {
        'lua_ls',
        'vtsls',
        'eslint',
        'html',
        'cssls',
        'pyright',
        'ruff',
        'bashls',
        'marksman',
        'rust_analyzer',
    },
})

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(ev)
        local buf = ev.buf

        vim.keymap.set('n', 'gd', function() require('fzf-lua').lsp_definitions() end,
            { buffer = buf, desc = 'LSP: go to definition' })
        vim.keymap.set('n', 'grr', function() require('fzf-lua').lsp_references() end,
            { buffer = buf, desc = 'LSP: references' })
        vim.keymap.set('n', 'gO', function() require('fzf-lua').lsp_document_symbols() end,
            { buffer = buf, desc = 'LSP: document symbols' })
        vim.keymap.set('n', '<leader>cf', function() vim.lsp.buf.format({ async = true }) end,
            { buffer = buf, desc = 'LSP: format buffer' })
    end,
})
