-- plugins/telescope.lua:
--
-- `ripgrep` and `fd` used to be listed as dependencies here. They are not
-- plugins — lazy.nvim was cloning the Rust source repositories of both and
-- putting them on the runtimepath. The binaries telescope actually shells out
-- to come from shared/pacman.txt.
return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	cmd = "Telescope",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		-- Native fzf sorter: without it telescope falls back to a much slower
		-- pure-Lua matcher. Needs `make` and a C compiler, both already present.
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				file_ignore_patterns = { "node_modules", "%.git/" },
				-- Was "truncate " — the trailing space made it an unknown value.
				path_display = { "truncate" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous, -- move to prev result
						["<C-j>"] = actions.move_selection_next, -- move to next result
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
					},
				},
			},
			pickers = {
				find_files = { theme = "ivy" },
				grep_string = { theme = "ivy" },
				live_grep = { theme = "ivy" },
				oldfiles = { theme = "ivy" },
			},
			extensions = {
				fzf = {
					fuzzy = true, -- false will only do exact matching
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case", -- or "ignore_case" or "respect_case"
				},
			},
		})

		telescope.load_extension("fzf")
	end,
	keys = {
		{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "[F]uzzy [f]ind files in cwd" },
		{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "[F]uzzy find [r]ecent files" },
		{ "<leader>fs", "<cmd>Telescope live_grep<cr>", desc = "[F]ind [s]tring in cwd" },
		{ "<leader>fc", "<cmd>Telescope grep_string<cr>", desc = "[F]ind string under cursor in cwd" },
		{ "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "[F]ind [d]iagnostics" },
		{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "[F]ind [b]uffers" },
	},
}
