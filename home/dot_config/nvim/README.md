# Neovim Config

Requires Neovim **0.12+** (nvim-treesitter's `main` branch and `vim.lsp.config`
both need it). Plugin manager is lazy.nvim; there is no Mason — every language
server, linter and formatter is a system package declared in `shared/pacman.txt`
or `shared/npm.txt`.

## Layout

```
init.lua              requires core/* then config/lazy
lua/core/globals.lua  vim.g values that must be set before plugin specs load
lua/core/options.lua  vim.opt
lua/core/keymaps.lua  non-plugin mappings
lua/core/autocmds.lua filetype-scoped spell, yank highlight
lua/core/lsp.lua      vim.diagnostic.config, vim.lsp.config overrides, enable list
lua/config/lazy.lua   lazy.nvim bootstrap + setup
lua/plugins/*.lua     one plugin (or one group) per file
lua/plugins/copilot/  needs its own import line in config/lazy.lua, because
                      lazy's `import` only recurses into subdirectories that
                      contain an init.lua
lazy-lock.json        tracked, so all three hosts pin the same commits
```

## LSP

Servers are turned on in `lua/core/lsp.lua` with `vim.lsp.enable()`. The config
bodies come from the **nvim-lspconfig** plugin, which ships an `lsp/<name>.lua`
for ~400 servers that Neovim picks up off the runtimepath by itself — nothing
calls `require("lspconfig")`.

To add a server: install its binary (declare it in `shared/pacman.txt` /
`shared/npm.txt`), then add its name to the `vim.lsp.enable{}` list. Check it is
one of the servers nvim-lspconfig ships:
<https://github.com/neovim/nvim-lspconfig/tree/master/lsp>

To **override** one, call `vim.lsp.config("<name>", { ... })` in
`lua/core/lsp.lua`. Do not put a file in `~/.config/nvim/lsp/` — Neovim merges
every `lsp/<name>.lua` on the runtimepath in rtp order and *then* merges
`vim.lsp.config()` calls on top, so a file there is merged **before**
nvim-lspconfig's and loses. This repo used to carry hand-copied copies of those
files; they were deleted and `home/.chezmoiremove` clears them from `$HOME`.

Python deliberately runs two servers: `ruff` (lint/format only) and `ty` (types,
hover, go-to-definition). They overlap on nothing.

## Keymaps worth knowing

Leader is `<Space>`.

| Key | Does |
| --- | --- |
| `grn` `gra` `grr` `gri` `grt` `K` | Neovim 0.11 built-in LSP maps |
| `<leader>r` + motion, `<leader>rr` | replace with register (moved off `gr`) |
| `<leader>ee` / `<leader>ef` | oil file explorer, in window / floating |
| `<leader>ff` `fr` `fs` `fc` `fd` `fb` `ft` | telescope: files, recent, grep, cursor-word, diagnostics, buffers, todos |
| `<leader>gp` / `<leader>gt` | gitsigns preview hunk / toggle line blame |
| `<leader>d` / `<leader>q` | diagnostic float / diagnostics to loclist |
| `<leader>?` | which-key, buffer-local maps |
| `:FormatBuffer` | format via conform (also runs on save) |

## Updating plugins

The lockfile is tracked, and lazy's auto-update checker is off on purpose, so
updates are explicit:

```sh
nvim -c 'Lazy sync'     # or :Lazy sync inside nvim, then :TSUpdate
./bin/dotsync.sh        # chezmoi re-add — pulls the new lazy-lock.json back
```

Without the second step the new lock stays only in `$HOME` and the next
`chezmoi apply` reverts it.
