-- Lightweight yet powerful formatter plugin for Neovim
--
-- Every tool named here has to exist on PATH; they are declared in
-- shared/pacman.txt (stylua, ruff, codespell, clang) and shared/npm.txt
-- (prettier, eslint_d). `prettier`, not `prettierd` — the daemon is AUR-only
-- and the repo prefers not to add a package for it.
return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo", "FormatBuffer" },
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_format", lsp_format = "fallback" },
			json = { "prettier" },
			jsonc = { "prettier" },
			markdown = { "prettier", lsp_format = "fallback" },
			yaml = { "prettier", lsp_format = "fallback" },
			html = { "prettier" },
			css = { "prettier" },
			javascript = { "prettier", lsp_format = "fallback" },
			javascriptreact = { "prettier", lsp_format = "fallback" },
			typescript = { "prettier", lsp_format = "fallback" },
			typescriptreact = { "prettier", lsp_format = "fallback" },
			c = { "clang_format", lsp_format = "fallback" },
			cpp = { "clang_format", lsp_format = "fallback" },
			rust = { "rustfmt", lsp_format = "fallback" },

			-- These two must live INSIDE formatters_by_ft. As sibling keys of
			-- it they were silently discarded, because conform's setup only
			-- ever reads opts.formatters_by_ft.
			--
			-- "*" runs on every filetype, in addition to the entries above.
			["*"] = { "codespell" },
			-- "_" runs only on filetypes with no entry above.
			["_"] = { "trim_whitespace" },
		},

		format_on_save = {
			timeout_ms = 2000,
			lsp_format = "fallback",
		},

		-- All three of these are read off the table passed to setup(), so they
		-- have to be inside `opts`; at plugin-spec level lazy.nvim never passes
		-- them on and they do nothing.
		log_level = vim.log.levels.ERROR, -- `:ConformInfo` shows the log location
		notify_on_error = true,
		notify_no_formatters = true,
	},
	config = function(_, opts)
		require("conform").setup(opts)

		vim.api.nvim_create_user_command("FormatBuffer", function()
			require("conform").format({ bufnr = vim.api.nvim_get_current_buf() })
		end, { desc = "Format the current buffer with conform" })
	end,
}
