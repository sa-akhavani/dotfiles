-- Highlights TODO/FIXME/HACK/NOTE/WARN comments and makes them searchable.
return {
	"folke/todo-comments.nvim",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = { signs = false },
	keys = {
		{ "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "[F]ind [t]odo comments" },
	},
}
