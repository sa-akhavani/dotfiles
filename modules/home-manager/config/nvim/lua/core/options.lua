local opt = vim.opt

-- command line and pop up menu settings
opt.cmdheight = 1    -- more space in the neovim command line for displaying messages
opt.pumheight = 8    -- pop up menu height
opt.pumblend = 10    -- popup menu transparency
opt.showmode = false -- we don't need to see things like -- INSERT -- anymore

-- search settings
opt.smartcase = true  -- smart case
opt.hlsearch = true   -- highlight all matches on previous search pattern
opt.ignorecase = true -- ignore case in search patterns

-- line numbers
opt.relativenumber = true -- set relative numbered lines
opt.number = true         -- set numbered lines (hybrid line numbers)
opt.numberwidth = 4       -- set number column width to 2 {default 4}
opt.signcolumn = "yes"    -- always show the sign column, otherwise it would shift the text each time

-- tabs & indentation
opt.tabstop = 2        -- insert 2 spaces for a tab
opt.shiftwidth = 2     -- the number of spaces inserted for each indentation
opt.expandtab = true   -- convert tabs to spaces
opt.showtabline = 1    -- always show tabs
-- opt.autoindent = true
opt.smartindent = true -- make indenting smarter again

-- line wrapping
opt.wrap = false      -- display lines as one long line
opt.linebreak = false -- companion to wrap, don't split words
opt.cursorline = true -- highlight the current line

-- appearance
opt.termguicolors = true -- set term gui colors (most terminals support this)
opt.background = "dark"
opt.scrolloff = 10       -- minimal number of screen lines to keep above and below the cursor
opt.sidescrolloff = 10   -- minimal number of screen columns either side of cursor if wrap is `false`

-- split windows
opt.splitright = true -- force all vertical splits to go to the right of current window
opt.splitbelow = true -- force all horizontal splits to go below current window

-- general settings
opt.iskeyword:append("-")           -- hyphenated words recognized by searches
opt.mouse = "a"                     -- allow the mouse to be used in neovim
opt.swapfile = false                -- creates a swapfile
opt.undofile = true                 -- enable persistent undo
opt.backup = false                  -- creates a backup file
opt.writebackup = false             -- if a file is being edited by another program (or was written to file while editing with another program) it is not allowed to be edited
opt.guifont = "monospace:h17"       -- the font used in graphical neovim applications
opt.whichwrap = "bs<>[]hl"          -- which "horizontal" keys are allowed to travel to prev/next line
opt.clipboard:append("unnamedplus") -- allows neovim to access the system clipboard
-- opt.backspace = "indenteolstart" -- backspace

-- timeout settings
opt.timeoutlen = 500 -- time to wait for a mapped sequence to complete (in milliseconds)
opt.updatetime = 300 -- faster completion (4000ms default)

-- set color column
opt.colorcolumn = "80"
-- vim.cmd([[hi ColorColumn guibg=#FFE08C]])
-- vim.cmd([[hi ColorColumn guibg=Red]])

-- Enable Spell Check
-- https://johncodes.com/posts/2023/02-25-nvim-spell/
opt.spelllang = "en_us"
opt.spell = true

opt.completeopt = { "menuone", "noselect" } -- mostly just for cmp
opt.conceallevel = 0                        -- so that `` is visible in markdown files

-- Border for floating windows
opt.winborder = 'rounded'
