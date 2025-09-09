-- plugins/telescope.lua:
return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    -- {
    --   "nvim-telescope/telescope-fzf-native.nvim",
    --   build =
    --   "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
    -- },
    "nvim-tree/nvim-web-devicons",
    "BurntSushi/ripgrep",
    "sharkdp/fd",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        file_ignore_patterns = { "node_modules" },
        path_display = { "truncate " },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
            ["<C-j>"] = actions.move_selection_next, -- move to next result
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          },
        },
        layout_config = {
          vertical = { width = 0.15 },
          -- other layout configuration here
        },
        -- theme = "cursor",
      },
      pickers = {
        find_files = {
          -- theme = "dropdown",
          -- theme = "cursor",
          theme = "ivy",
        },
        grep_string = {
          theme = "ivy",
        },
        live_grep = {
          theme = "ivy",
        },
        oldfiles = {
          theme = "ivy",
        },
      },
      extensions = {
        -- fzf = {
        --   fuzzy = true,              -- false will only do exact matching
        --   override_generic_sorter = true, -- override the generic sorter
        --   override_file_sorter = true, -- override the file sorter
        --   case_mode = "smart_case",  -- or "ignore_case" or "respect_case"
        --   -- the default case_mode is "smart_case"
        -- },
      },
    })

    -- telescope.load_extension("fzf")
    -- telescope.load_extension("fd")

    -- set keymaps
    local keymap = vim.keymap -- for conciseness
    keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "[F]uzzy [f]ind files in cwd" })
    keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "[F]uzzy find [r]ecent files" })
    keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "[F]ind [s]tring in cwd" })
    keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "[F]ind string under cursor in cwd" })
  end,
}
