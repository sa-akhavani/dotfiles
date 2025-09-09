-- Lightweight yet powerful formatter plugin for Neovim
return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			c = { "clang_format", lsp_format = "fallback" },
			cpp = { "clang_format", lsp_format = "fallback" },
			json = { "prettierd" },
			rust = { "rustfmt", lsp_format = "fallback" },
			python = { "ruff", lsp_format = "fallback" },
			markdown = { "prettierd", lsp_format = "fallback" },
			nix = { "nixfmt" },
		        javascript = { "prettierd", lsp_format = "fallback" },
		},
		format_on_save = {
			timeout_ms = 2000,
			lsp_format = "fallback",
		},
	},

	vim.api.nvim_create_user_command("FormatBuffer", function()
		require("conform").format({ bufnr = vim.api.nvim_get_current_buf() })
	end, {}),
}
