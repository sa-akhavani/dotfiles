-- File explorer. The alpha dashboard and bufferline both used to reference
-- NvimTree, which was never installed — this is the replacement they point at.
--
-- oil edits a directory as a normal buffer: rename by editing the line, delete
-- with dd, create with o, then :w to commit. Nothing happens on disk until the
-- buffer is written.
return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	-- Needs to be eager so that `nvim <dir>` opens oil instead of netrw.
	lazy = false,
	opts = {
		default_file_explorer = true,
		view_options = {
			show_hidden = true,
		},
		win_options = {
			-- The dotfiles repo is full of dot_-prefixed names; the signcolumn
			-- just wastes width here.
			signcolumn = "no",
		},
	},
	keys = {
		{ "<leader>ee", "<cmd>Oil<cr>", desc = "[E]xplorer: open parent directory" },
		{ "<leader>ef", function() require("oil").open_float() end, desc = "[E]xplorer: [f]loating" },
	},
}
