-- Loaded first from init.lua. Anything here must be set before plugin specs
-- are evaluated, because lazy.nvim reads vim.g at spec time.

vim.g.have_nerd_font = true

-- vim-ReplaceWithRegister defaults to `gr`/`grr`, which Neovim 0.11 claimed for
-- the built-in LSP maps (grn rename, gra code-action, grr references, gri
-- implementation, grt type-definition). The plugin guards its defaults with
-- hasmapto(), so mapping its <Plug> targets ourselves in the spec's `init` is
-- what stops it installing them. See lua/plugins/init.lua.
