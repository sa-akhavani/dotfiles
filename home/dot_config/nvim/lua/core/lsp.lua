-- Enable LSPs
-- vim.lsp.enable('luals')
-- vim.lsp.enable('ruff')
-- vim.lsp.enable('ts_ls')
-- vim.lsp.enable('clangd')

vim.lsp.enable({
	"lua_ls",
	-- Python needs BOTH: ruff's server is lint/format only (no hover, no
	-- go-to-definition, no completion), ty supplies the type info and
	-- navigation. They overlap on nothing.
	"ruff",
	"ty",
	"ts_ls",
	"clangd",
	"rust_analyzer",
})
