-- kanagawa is the active theme; tokyonight is kept as the one alternate that is
-- still actively maintained and already had a tuned palette here.
--
-- Dropped: bluz71/vim-nightfly-guicolors (repo renamed to vim-nightfly-colors,
-- so the old URL only survived as a redirect), tomasiser/vim-code-dark and
-- joshdick/onedark.vim — all three unused, and all three vimscript themes that
-- predate treesitter highlight groups, so they under-highlight everything
-- lua/plugins/treesitter.lua now parses.
return {
	{
		"folke/tokyonight.nvim",
		priority = 1000, -- load before all the other start plugins
		lazy = true,
		opts = { style = "night" },
	},
	{
		"rebelot/kanagawa.nvim",
		priority = 1000,
		config = function()
			require("kanagawa").setup({
				compile = false, -- enable compiling the colorscheme
				undercurl = true, -- enable undercurls
				commentStyle = { italic = true },
				functionStyle = {},
				keywordStyle = { italic = true },
				statementStyle = { bold = true },
				typeStyle = {},
				transparent = false, -- do not set background color
				dimInactive = false, -- dim inactive window `:h hl-NormalNC`
				terminalColors = true, -- define vim.g.terminal_color_{0,17}
				theme = "wave", -- used when 'background' is not set
				background = { -- map the value of 'background' to a theme
					dark = "wave", -- try "dragon" !
					light = "lotus",
				},
			})
			vim.cmd("colorscheme kanagawa")
			-- vim.cmd("colorscheme kanagawa-dragon")
			-- vim.cmd("colorscheme kanagawa-lotus")
		end,
	},
}
