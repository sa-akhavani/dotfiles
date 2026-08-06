-- Neovim bundles parsers for only c, lua, markdown, markdown_inline, query, vim
-- and vimdoc. Every other language — including every language with an LSP
-- enabled in core/lsp.lua — falls back to legacy regex syntax without this.
--
-- This is the `main` branch, a full incompatible rewrite of the old `master`
-- one: no `ensure_installed`, no `highlight = { enable = true }`, and it does
-- not support lazy-loading. Parsers are built locally, so it needs
-- tree-sitter-cli (declared in shared/pacman.txt) and a C compiler.
local ensure_installed = {
	"bash",
	"c",
	"cpp",
	"css",
	"diff",
	"dockerfile",
	"git_config",
	"gitcommit",
	"gitignore",
	"go",
	"html",
	"javascript",
	-- No "jsonc": nvim-treesitter has no such parser (it warns and skips). The
	-- jsonc *filetype* is already mapped onto the json parser.
	"json",
	"lua",
	"luadoc",
	"make",
	"markdown",
	"markdown_inline",
	"python",
	"query",
	"regex",
	"rust",
	"sql",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
	"zsh",
}

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup({})

		-- Asynchronous and a no-op once the parsers are present, so this is safe
		-- to leave on every startup.
		require("nvim-treesitter").install(ensure_installed)

		-- The `main` branch enables no features by itself; highlighting is
		-- Neovim's and has to be started per buffer. Guarded because the
		-- FileType event fires long before a freshly installed parser exists.
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
			callback = function(args)
				local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
				if not lang or not vim.treesitter.language.add(lang) then
					return
				end

				vim.treesitter.start(args.buf, lang)

				-- Treesitter folding, opened by default rather than landing in a
				-- fully collapsed file.
				vim.wo[0][0].foldmethod = "expr"
				vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.wo[0][0].foldlevel = 99
			end,
		})
	end,
}
