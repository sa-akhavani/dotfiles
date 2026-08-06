-- Diagnostics ---------------------------------------------------------------
-- Neovim 0.11 turned 'virtual_text' OFF by default; with no config at all you
-- get a sign in the gutter and nothing else, so a diagnostic is invisible until
-- you hover it. virtual_lines.current_line shows the full message under the
-- cursor line only, which stays readable in a way end-of-line virtual text does
-- not once messages get long (rust-analyzer, ty).
vim.diagnostic.config({
	severity_sort = true,
	underline = true,
	update_in_insert = false,
	virtual_lines = { current_line = true },
	float = { border = "rounded", source = true },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚 ",
			[vim.diagnostic.severity.WARN] = "󰀪 ",
			[vim.diagnostic.severity.INFO] = "󰋽 ",
			[vim.diagnostic.severity.HINT] = "󰌶 ",
		},
	},
})

-- Server config -------------------------------------------------------------
-- The bodies of these configs come from nvim-lspconfig, which ships an
-- lsp/<name>.lua for all of them (see lua/plugins/lspconfig.lua). Only genuine
-- overrides belong here.
--
-- Precedence matters: Neovim merges every lsp/<name>.lua found on the
-- runtimepath in rtp order, then merges vim.lsp.config() calls *on top* (see
-- `:h lsp-config`). So an override must be a vim.lsp.config() call — a file at
-- ~/.config/nvim/lsp/<name>.lua would be merged BEFORE nvim-lspconfig's and
-- lose. That is why this repo no longer keeps hand-copied lsp/*.lua files.

-- Without a workspace library lua_ls knows nothing about the Neovim API, so
-- editing this very config gets no completion or signature help for vim.*.
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			workspace = {
				checkThirdParty = false,
				library = { vim.env.VIMRUNTIME, "${3rd}/luv/library" },
			},
			-- stylua handles formatting via conform.
			format = { enable = false },
		},
	},
})

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
