-- https://www.youtube.com/watch?v=vdn_pKJUda8
-- https://github.com/josean-dev/dev-environment-files/blob/main/.config/nvim/lua/josean/lazy.lua

-- https://github.com/LunarVim/Neovim-from-scratch/

-- globals first: plugin specs and options both read vim.g values set here.
require("core.globals")
require("core.options")
require("core.keymaps")
require("core.autocmds")
require("core.lsp")
require("config.lazy")
