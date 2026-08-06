local augroup = vim.api.nvim_create_augroup("core_autocmds", { clear = true })

-- Spell check only where prose actually lives. 'spelllang' is set globally in
-- core/options.lua; only the toggle is per-filetype.
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "markdown", "gitcommit", "text", "rst", "tex", "plaintex" },
	callback = function()
		vim.opt_local.spell = true
	end,
})

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		vim.hl.on_yank()
	end,
})
