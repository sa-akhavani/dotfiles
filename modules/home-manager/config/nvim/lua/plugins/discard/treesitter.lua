return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "windwp/nvim-ts-autotag",
    },
    config = function()
      -- import nvim-treesitter plugin
      local treesitter = require("nvim-treesitter.configs")
      treesitter.setup({
        -- enable syntax highlighting
        highlight = {
          enable = true,
          -- disable = { "markdown" },
          additional_vim_regex_highlighting = false,
        },
        -- enable indentation
        indent = {
          enable = true,
        },
        -- enable autotagging (w/ nvim-ts-autotag plugin)
        autotag = {
          enable = true,
        },
        autopairs = { enable = true },
        -- ensure these language parsers are installed
        ensure_installed = {
          "bash",
          "c",
          "gitignore",
          "json",
          "javascript",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "vimdoc",
        },
        -- auto install language parsers
        auto_install = true,
        -- -- incremental selection. automatically select areas of code
        -- incremental_selection = {
        --   enable = true,
        --   keymaps = {
        --    init_selection = "<C-space>",
        --    node_incremental = "<C-space>",
        --    scope_incremental = false,
        --    node_decremental = "<bs>",
        --  },
        -- },
      })

      -- enable nvim-ts-context-commentstring plugin for commenting tsx and jsx
      require("ts_context_commentstring").setup({})
    end,
  },
}
