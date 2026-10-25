vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.o.number = true -- Show line numbers in a column.
vim.o.relativenumber = true
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.lsp.foldexpr()" -- fallback; the treesitter FileType autocmd below takes over where a parser exists
vim.o.foldlevelstart = 99 -- don't fold on file load
vim.o.foldcolumn = "1" -- gutter column showing fold chevrons, like an IDE
vim.o.signcolumn = "yes"
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.cursorline = true
vim.o.cursorlineopt = "number" -- highlight only the line number, no line background
vim.o.scrolloff = 10
-- turn off spaces showing as dashes
vim.o.list = false
vim.o.confirm = true
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.wrap = false
vim.opt.fillchars = { eob = " ", foldopen = "\u{f078}", foldclose = "\u{f054}", foldsep = " " }
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.filetype.add({ extension = { mdx = 'markdown.mdx' } })

vim.api.nvim_create_autocmd('UIEnter', {
    callback = function()
        vim.o.clipboard = 'unnamedplus'
    end,
})

vim.keymap.set('n', '<leader>w', ':set wrap!<CR>', { silent = true, desc = "Toggle Wrap" })
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
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/mason-org/mason-lspconfig.nvim',
    { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1') },
    'https://github.com/echasnovski/mini.icons',
    'https://github.com/ibhagwan/fzf-lua',
    'https://github.com/stevearc/oil.nvim',
    'https://github.com/lukas-reineke/indent-blankline.nvim',
    'https://github.com/stevearc/quicker.nvim',
    'https://github.com/lewis6991/gitsigns.nvim',
    'https://github.com/HiPhish/rainbow-delimiters.nvim',
    'https://github.com/luukvbaal/statuscol.nvim',
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

local fzf = require('fzf-lua')
fzf.setup { 'default', fzf_colors = true }

-- File Searching
vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Fuzzy find files" })
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "Fuzzy find open buffers" })
vim.keymap.set("n", "<leader>fr", fzf.oldfiles, { desc = "Fuzzy find recent files" })
vim.keymap.set("n", "<leader>fR", fzf.resume, { desc = "Resume last search" })

-- Text / Grep Searching
vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Live grep search string" })
vim.keymap.set("n", "<leader>fw", fzf.grep_cword, { desc = "Grep word under cursor" })
vim.keymap.set("n", "<leader>/", fzf.lgrep_curbuf, { desc = "Grep current buffer" })

-- Neovim / LSP Helpers
vim.keymap.set("n", "<leader>fh", fzf.help_tags, { desc = "Search help tags" })
vim.keymap.set("n", "<leader>fk", fzf.keymaps, { desc = "Search keymaps" })
vim.keymap.set("n", "<leader>fd", fzf.diagnostics_document, { desc = "Document diagnostics" })
vim.keymap.set("n", "<leader>fD", fzf.diagnostics_workspace, { desc = "Workspace diagnostics" })

require('oil').setup({
    view_options = { show_hidden = true },
})

vim.keymap.set('n', '-', '<cmd>Oil<cr>', { desc = 'Open parent directory' })
vim.keymap.set('n', '<leader>e', '<cmd>Oil<cr>', { desc = 'File explorer' })

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

vim.lsp.config('*', {
    capabilities = require('blink.cmp').get_lsp_capabilities(nil, true),
})

-- Show LSP color swatches as a square in front of the hex code instead of painting
-- its background, which diff highlights cover up.
vim.lsp.document_color.enable(true, nil, { style = 'virtual' })

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
        'eslint',        -- JS/TS linting
        'html',          -- HTML
        'cssls',         -- CSS
        'jsonls',        -- JSON
        'yamlls',        -- YAML
        'lemminx',       -- XML
        'marksman',      -- Markdown
        'pyright',       -- Python
        'ruff',          -- Python linting/formatting
        'rust_analyzer', -- Rust
        'bashls',        -- Shell
    },
}

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
