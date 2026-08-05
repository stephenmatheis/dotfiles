return {
  "ibhagwan/fzf-lua",
  -- Optional dependencies
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local fzf = require("fzf-lua")

    fzf.setup({
      -- Sane defaults natively integrate ripgrep
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096",
        rg_glob = true, -- Allows filtering by filename inside the prompt
      }
    })

    -- Keymaps for Ripgrep search workflows
    vim.keymap.set("n", "<leader>sg", fzf.live_grep, { desc = "Search via Live Grep (Ripgrep)" })
    vim.keymap.set("n", "<leader>sw", fzf.grep_cword, { desc = "Search current Word under cursor" })
    vim.keymap.set("n", "<leader>sb", fzf.lgrep_curbuf, { desc = "Live grep current Buffer" })
    vim.keymap.set("n", "<leader>sg", fzf.live_grep_glob, { desc = "Live Grep with Glob patterns" })
  end
}
