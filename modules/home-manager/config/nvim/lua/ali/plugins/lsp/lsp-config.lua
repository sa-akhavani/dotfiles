return {
  -- A plugin that provides a way to manage LSP servers and their configurations.
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  -- mason-lspconfig.nvim is a plugin that provides a way to ensure that LSP servers are installed and configured.
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
	  "ruff", --python
          "tsserver",
        }
      })
    end
  },
  -- nvim-lspconfig is a plugin that provides configurations for built-in LSP client in Neovim.
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({})
      lspconfig.ruff.setup({})
      lspconfig.tsserver.setup({})

      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
      vim.keymap.set({ 'n' }, '<leader>ca', vim.lsp.buf.code_action, {})
    end
  },
  -- code actions now have a menu that could be selected using telescope format
  {
    "nvim-telescope/telescope-ui-select.nvim",
    depends = {
      "nvim-telescope/telescope.nvim"
    },
    config = function()
      require("telescope").setup {
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {
            }
          }
        }
      }
      require("telescope").load_extension("ui-select")
    end
  }
}
