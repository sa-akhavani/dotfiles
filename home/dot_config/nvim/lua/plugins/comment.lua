-- Neovim has had built-in commenting since 0.10 (`gc` operator, `gcc` line,
-- `gc` in visual) so numToStr/Comment.nvim — untouched upstream since Aug 2024
-- — is no longer carried. The built-in uses 'commentstring', which is per
-- *filetype* and therefore wrong inside embedded languages: `//` everywhere in
-- a .tsx file, including the JSX where it has to be `{/* */}`.
--
-- This plugin recomputes 'commentstring' from the treesitter node under the
-- cursor. Its own CursorHold autocmd is disabled in favour of the native
-- integration below, which computes it only when commenting actually happens.
return {
	"JoosepAlviste/nvim-ts-context-commentstring",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		require("ts_context_commentstring").setup({
			enable_autocmd = false,
		})

		-- Neovim asks vim.filetype.get_option() for 'commentstring' whenever it
		-- comments; wrapping it is the documented hook for the built-in.
		local get_option = vim.filetype.get_option
		vim.filetype.get_option = function(filetype, option)
			if option ~= "commentstring" then
				return get_option(filetype, option)
			end
			return require("ts_context_commentstring.internal").calculate_commentstring()
				or get_option(filetype, option)
		end
	end,
}
