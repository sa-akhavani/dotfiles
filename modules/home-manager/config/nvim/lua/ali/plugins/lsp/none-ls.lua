return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvimtools/none-ls-extras.nvim",
  },
  config = function()
    local null_ls = require("null-ls")
    -- make sure to install the formatter / linter using mason too! putting it here is not enough. --
    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.stylua, -- lua formatter
        null_ls.builtins.formatting.black,     -- python formatter
        null_ls.builtins.formatting.isort,     -- python formatter
        null_ls.builtins.formatting.prettierd, -- js formatter
        require('none-ls.diagnostics.eslint_d'),    -- js linter. use this type of coding to use none-ls-extras
        -- null_ls.builtins.diagnostics.eslint_d, -- js linter
      }
    })
    vim.keymap.set('n', '<leader>gf', vim.lsp.buf.format, {});
  end
}
