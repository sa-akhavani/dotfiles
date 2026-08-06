return {
	"akinsho/bufferline.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	opts = {
		options = {
			separator_style = "slant",
			-- The offset used to name NvimTree, which was never installed, so
			-- it never triggered. oil is the explorer now.
			offsets = {
				{
					filetype = "oil",
					text = "File Explorer",
					highlight = "Directory",
					separator = true,
				},
			},
		},
	},
}
