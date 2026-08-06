-- Indent guides. `scope` underlines the current indent block, which is the part
-- that actually helps in deeply nested Python/Lua.
return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		indent = { char = "│" },
		scope = { enabled = true, show_start = false, show_end = false },
		exclude = {
			filetypes = { "help", "alpha", "oil", "lazy", "gitcommit", "markdown" },
		},
	},
}
