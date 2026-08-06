return {
	"nvim-lua/plenary.nvim", -- lua functions that many plugins use

	"christoomey/vim-tmux-navigator", -- tmux & split window navigation

	{
		-- replace with register contents using motion
		"inkarkat/vim-ReplaceWithRegister",
		init = function()
			-- The plugin defaults to `gr`/`grr`, which Neovim 0.11 took for the
			-- built-in LSP maps (grn/gra/grr/gri/grt) — installing it unchanged
			-- silently kills go-to-references. Its defaults are guarded by
			-- hasmapto(), so claiming the <Plug> targets here (init runs before
			-- the plugin loads) is what suppresses them. All three mode variants
			-- have to be claimed or the unclaimed one still grabs `gr`.
			vim.keymap.set("n", "<leader>r", "<Plug>ReplaceWithRegisterOperator", { desc = "[R]eplace with register" })
			vim.keymap.set("n", "<leader>rr", "<Plug>ReplaceWithRegisterLine", { desc = "[R]eplace line with register" })
			vim.keymap.set("x", "<leader>r", "<Plug>ReplaceWithRegisterVisual", { desc = "[R]eplace with register" })
		end,
	},
}
