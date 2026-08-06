-- nvim-lint: asynchronous linting for tools that have no language server.
--
-- Python is deliberately absent: `ruff server` is enabled in core/lsp.lua and
-- already publishes ruff's diagnostics over LSP. Listing ruff here as well
-- produced every Python warning twice.
return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		vim.env.ESLINT_D_PPID = vim.fn.getpid()
		local lint = require("lint")
		lint.linters_by_ft = {
			javascript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescript = { "eslint_d" },
			typescriptreact = { "eslint_d" },
		}
		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}
