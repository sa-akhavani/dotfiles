-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins.
-- `plugins.copilot` needs its own import line because lazy.nvim's `import` only
-- recurses into subdirectories that contain an init.lua.
require("lazy").setup({
	spec = {
		{ import = "plugins" },
		{ import = "plugins.copilot" },
	},
	-- lazy-lock.json is tracked by chezmoi, so all three hosts resolve to the
	-- same plugin commits. The update path is deliberately manual:
	--   :Lazy sync      then    ./bin/dotsync.sh
	-- to pull the regenerated lock back into the repo. An automatic update
	-- checker would let each host drift on its own schedule, which is exactly
	-- what tracking the lockfile is meant to prevent.
	checker = {
		enabled = false,
	},
	change_detection = {
		notify = false,
	},
	performance = {
		rtp = {
			disabled_plugins = { "netrwPlugin", "tohtml", "tutor" },
		},
	},
})
