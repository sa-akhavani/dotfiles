-- Data only: nvim-lspconfig ships an lsp/<name>.lua for ~400 servers, which
-- Neovim 0.11+ picks up off the runtimepath by itself. Nothing here calls
-- require("lspconfig") — the servers are turned on with vim.lsp.enable() and
-- overridden with vim.lsp.config() in lua/core/lsp.lua.
--
-- This replaces six hand-copied config files that had to be re-synced from
-- upstream by hand whenever a server changed its cmd or root markers.
return {
	"neovim/nvim-lspconfig",
	lazy = false,
}
