# CLAUDE.md

Context for Claude Code working in this repo. Read this before making changes.

## What this repo is

Ali's **Arch Linux** dotfiles: Hyprland (Wayland) + greetd/tuigreet + zsh + tmux +
Neovim + Waybar. Two halves, deliberately separated:

- **Packages and system state** → `install.sh` (pacman/AUR/systemd, run with sudo)
- **Dotfiles** → **chezmoi**, source directory `home/` (set by `.chezmoiroot`)

Current branch is **`arch-v3`**; `master`/`nixos` hold the previous **NixOS flake**
this was migrated from. Several comments reference the Nix module a config came
from (`services/ssh.nix`, `configuration.nix`) — that's intentional provenance,
keep it. The Arch branch is 100% Nix-free; don't reintroduce Nix.

Remote: `git@github.com:sa-akhavani/dotfiles.git`

## Layout

```
install.sh              idempotent post-install script (packages, /etc, services)
README.md               user-facing setup + day-to-day docs
MAINTENANCE.md          updating/cleaning/rollback reference (pacman, orphans, cache)
todo.md                 Ali's running todo — plain lines, he edits it himself
packages/               package lists, one name per line   (packages/README.md)
  pacman.txt aur.txt              shared by all hosts
  pacman.<host>.txt aur.<host>.txt  per-host extras, ADDITIVE
system/                 root-owned config applied with sudo  (system/README.md)
  etc/…                 mirrors /  → system/etc/greetd/config.toml = /etc/greetd/config.toml
  services.txt          systemd units to enable
  hosts/<host>/         per-host etc/ + services.txt
home/                   chezmoi source → $HOME
  .chezmoi.toml.tmpl    per-host prompts (currently: gpu)
  .chezmoiignore        what NOT to manage (is itself a template)
  dot_zshrc dot_gitconfig dot_config/…
Pictures/               wallpapers + lockscreen images
```

`<host>` is always `hostnamectl --static`.

## Conventions that matter

**chezmoi naming**: `dot_foo` → `.foo`, `executable_foo.sh` → `foo.sh` +x,
`foo.tmpl` → Go-template-rendered. Edit files **in `home/`**, never in `~/.config`
directly — a `chezmoi apply` would overwrite that. `chezmoi diff` / `chezmoi cat`
preview; `update` is aliased to `chezmoi apply`.

**Per-host differences** — four independent layers, pick the narrowest that works:

| Difference | Goes in |
| --- | --- |
| A package | `packages/pacman.<host>.txt` |
| An `/etc` file or a service | `system/hosts/<host>/…` |
| Same file, different contents | make it `*.tmpl`, branch on `.chezmoi.hostname` or `[data]` keys |
| File shouldn't exist at all | `.chezmoiignore` |

Machine-local answers (`gpu`) live in `~/.config/chezmoi/chezmoi.toml`, which is
**not** in this repo — so also the right place for host secrets.

**Comment style**: comments explain *why*, especially where something is
load-bearing or counter-intuitive (`return 0` guarding `set -e`, one `yay` call
per package, `start-hyprland` vs `Hyprland`). Match that density; don't strip
those comments, and don't narrate the obvious.

## `install.sh` invariants

Breaking any of these has bitten before:

- `set -euo pipefail`, and it must stay **idempotent** — safe to re-run.
- Refuses to run as root; calls `sudo` itself.
- **Never let one bad package abort the run.** `pac_install` retries
  individually after a failed batch; `aur_install` calls `yay` once per package
  (a batch shares one `pacman -U` transaction, so one failure rolls back
  everything already built). Failures accumulate in `FAILED` and are re-reported
  in the summary, because warnings scroll past in thousands of lines of build
  output.
- Anything that can legitimately be absent (a group, a systemd unit, a per-host
  file) must be probed first, not assumed — under `set -e` a failed probe would
  skip the rest of the script. `read_list` ends with `return 0` for exactly this.
- `install_system_tree` resolves paths relative to its argument (**not** to
  `$1/etc`), so the leading `etc/` carries into the destination. It writes
  `root:root 0644` only — files needing another mode must be handled explicitly.
  It skips unchanged files, backs a differing pre-existing file up **once** to
  `<path>.dotfiles-bak`, and never deletes anything.
- `.in` files under `system/` are templates: `@USER_NAME@`, `@HOSTNAME@`.
- multilib is enabled before the first `-Syu`, guarded by `pacman-conf
  --repo-list`, with the sed anchored `^#\[multilib\]$` so `multilib-testing`
  stays off.

## How to verify changes here

There is no test suite. `sudo` **requires a password**, so Claude cannot run
anything that modifies the system — hand Ali the command instead (he can run it
with a `! ` prefix).

- `bash -n install.sh` after every edit.
- For `/etc` logic, extract the function and run it against a fake root with a
  `sudo` stub — this caught a real bug where files would have landed in
  `/greetd/config.toml` instead of `/etc/greetd/config.toml`. Test fresh run,
  re-run (must be quiet), conflict (backs up), and second conflict (must not
  clobber the backup).
- For `sed` on system files, run it against a copy in the scratchpad and `diff`.
- Verify package facts against `https://archlinux.org/packages/search/json/?name=<pkg>`
  rather than from memory (repo, version, deps).

## Gotchas already discovered

- **`steam` is in the official `multilib` repo, not the AUR.**
- Packages depending on virtual providers (`vulkan-driver`, `lib32-vulkan-driver`,
  `lib32-libgl`) make `pacman --noconfirm` pick the *first* provider — often the
  wrong vendor's driver. Name the host's GPU drivers explicitly in the per-host
  package file so they're in the same transaction.
- `.chezmoiignore` does **not** strip trailing `#` comments — a comment on the
  same line becomes part of the pattern. Own line only.
- `pacman -Qdtq` orphans include packages declared in `packages/*.txt` that were
  pulled in as dependencies (e.g. `vlc`). Cross-check before removing; see
  MAINTENANCE.md.
- makepkg sources `/etc/makepkg.conf.d/*.conf` after `makepkg.conf`, and
  `in_opt_array` scans **backwards**, so a later `OPTIONS+=(!debug)` wins.
- Launch Hyprland via `start-hyprland`, not the `Hyprland` binary.
- Host `archlinux` (this laptop): Dell, Intel CometLake i915, **ext4** root (so no
  btrfs snapshots), systemd-boot, user `ali`. README's setup example says hostname
  `sohrab` — that's the intended name, not the current one.

## Working agreements

- **A question is a question.** When Ali asks "is there a safer way to…" or "is
  there an equivalent of…", answer in chat and stop — don't start editing, even
  if the answer maps onto a `todo.md` line. Propose the change and wait. Read-only
  investigation (inspecting his system, dry runs, cross-checks) is welcome and
  makes answers concrete.
- Don't commit or push unless asked.
- `todo.md` is his file and he edits it during sessions — re-read before touching,
  and only remove lines that are genuinely done.
- Don't add packages, tools or config he didn't ask for.
