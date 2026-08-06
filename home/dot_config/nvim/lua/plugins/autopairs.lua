return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	opts = {
		-- Uses treesitter to avoid adding a closing pair when one already
		-- follows; see lua/plugins/treesitter.lua.
		check_ts = true,
		-- Don't pair a quote when the cursor is already touching a word.
		fast_wrap = {},
	},
}
