-- Shows the available continuations after a prefix key. Mostly here for the
-- <leader> groups (f = find, g = git, e = explorer) and for the built-in `gr`
-- LSP maps, which are easy to forget.
return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "helix",
		spec = {
			{ "<leader>f", group = "find" },
			{ "<leader>g", group = "git" },
			{ "<leader>e", group = "explorer" },
			{ "<leader>r", group = "replace with register" },
			{ "gr", group = "lsp" },
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer-local keymaps",
		},
	},
}
