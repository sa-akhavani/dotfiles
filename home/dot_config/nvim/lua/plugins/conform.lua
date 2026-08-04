-- Lightweight yet powerful formatter plugin for Neovim
return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_format", lsp_format = "fallback" },
			json = { "prettierd" },
			markdown = { "prettierd", lsp_format = "fallback" },
			yaml = { "prettierd", lsp_format = "fallback" },
			javascript = { "js_beautify", "prettierd", lsp_format = "fallback" },
			nix = { "nixfmt" },
			c = { "clang_format", lsp_format = "fallback" },
			cpp = { "clang_format", lsp_format = "fallback" },
			rust = { "rustfmt", lsp_format = "fallback" },
		},

		-- Use the "*" filetype to run formatters on all filetypes.
		["*"] = { "codespell" },

		-- Use the "_" filetype to run formatters on filetypes that don't
		-- have other formatters configured.
		["_"] = { "trim_whitespace" },

		format_on_save = {
			timeout_ms = 2000,
			lsp_format = "fallback",
		},
	},
	-- Set the log level. Use `:ConformInfo` to see the location of the log file.
	log_level = vim.log.levels.ERROR,
	-- Conform will notify you when a formatter errors
	notify_on_error = true,
	-- Conform will notify you when no formatters are available for the buffer
	notify_no_formatters = true,

	vim.api.nvim_create_user_command("FormatBuffer", function()
		require("conform").format({ bufnr = vim.api.nvim_get_current_buf() })
	end, {}),
}
