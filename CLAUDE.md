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
                        flags: --no-aur, --dry-run, --help
README.md               user-facing setup + day-to-day docs
MAINTENANCE.md          updating/cleaning/rollback reference (pacman, orphans, cache)
todo.md                 Ali's running todo — plain lines, he edits it himself
bin/                    read-only maintenance helpers (safe for Claude to run)
  pkg-diff.sh           repo lists vs. what is installed here, both directions
  validate-packages.sh  every declared name resolves; no AUR/official conflicts
.github/workflows/ci.yml  bash -n, shellcheck, the two scripts above, template render
shared/                 applied on EVERY host              (shared/README.md)
  pacman.txt aur.txt npm.txt       package lists, one name per line
  etc/…                 mirrors /  → shared/etc/greetd/config.toml = /etc/greetd/config.toml
  services.txt          systemd units to enable (root units only)
hosts/<host>/           applied on ONE host, ADDITIVE       (hosts/README.md)
  pacman.txt aur.txt npm.txt       appended to the shared lists
  etc/… services.txt    applied after the shared ones, so they win
home/                   chezmoi source → $HOME
  .chezmoi.toml.tmpl    per-host prompts (currently: gpu)
  .chezmoiignore        what NOT to manage (is itself a template)
  Pictures/             → ~/Pictures; wallpapers + lockscreen images
  dot_zshrc dot_gitconfig dot_config/…
```

`Pictures/` used to be a top-level directory — outside `.chezmoiroot`, so nothing
deployed it while `hyprpaper.conf` read `~/Pictures/Wallpapers`. Anything the
configs expect in `$HOME` has to live under `home/`.

`<host>` is always `hostnamectl --static`.

## Conventions that matter

**chezmoi naming**: `dot_foo` → `.foo`, `executable_foo.sh` → `foo.sh` +x,
`foo.tmpl` → Go-template-rendered. Edit files **in `home/`**, never in `~/.config`
directly — a `chezmoi apply` would overwrite that. `chezmoi diff` / `chezmoi cat`
preview; `update` is aliased to `chezmoi apply`.

**Per-host differences** — four independent layers, pick the narrowest that works:

| Difference | Goes in |
| --- | --- |
| A package | `hosts/<host>/pacman.txt` (GPU drivers **and** CPU microcode) |
| An `/etc` file or a service | `hosts/<host>/…` |
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
- `.in` files under `shared/etc` and `hosts/*/etc` are templates: `@USER_NAME@`,
  `@HOSTNAME@`.
- multilib is enabled before the first `-Syu`, guarded by `pacman-conf
  --repo-list`, with the sed anchored `^#\[multilib\]$` so `multilib-testing`
  stays off.
- Every state-changing command goes through `run` so `--dry-run` can print it
  instead. Read-only probes stay un-wrapped (the dry run must describe *this*
  host), and `sudo_ro` drops the `sudo` from read-only `/etc` comparisons so a
  dry run needs no password. A new mutating command that skips `run` silently
  breaks `--dry-run`.
- Missing per-host *files* are tolerated, but a missing
  `hosts/<host>/pacman.txt` is a `warn` + a `FAILED_EXTRA` entry: it is the
  only place GPU drivers and microcode are declared, and silence there was how a
  host ended up with neither.
- Docker: `dockerd-rootless-setuptool.sh` is **not** in Arch's `docker` package
  (only in `docker-rootless-extras`, AUR), so `setup_docker` enables the root
  `docker.service` when rootless is unavailable and disables it only once
  rootless can replace it — never the other way round. It also creates the
  `/etc/subuid`/`/etc/subgid` ranges Arch omits, which the setup tool requires.

## How to verify changes here

There is no test suite. `sudo` **requires a password**, so Claude cannot run
anything that modifies the system — hand Ali the command instead (he can run it
with a `! ` prefix).

Everything in this list is runnable by Claude — none of it needs sudo:

- `bash -n install.sh` after every edit; `shellcheck --severity=warning
  install.sh bin/*.sh` (shellcheck is declared in `shared/pacman.txt`).
- `./install.sh --dry-run` — full walk-through of a real run, no password needed.
  Diff its output before and after a change to the installer.
- `./bin/validate-packages.sh` after touching any package list — resolves every name
  against the real `core`/`extra`/`multilib` databases and the AUR RPC, and fails
  on AUR/official conflicts.
- `./bin/pkg-diff.sh` to see how far this machine has drifted from the lists.
- chezmoi, without touching `$HOME` — render every template for every GPU value:
  ```bash
  # .toml suffix is required — chezmoi picks its config parser from the
  # extension and otherwise fails with "unknown format".
  cfg=$(mktemp --suffix=.toml); dest=$(mktemp -d)
  printf 'sourceDir = "%s"\ndestDir = "%s"\n\n[data]\n    gpu = "nvidia"\n' "$PWD" "$dest" >"$cfg"
  chezmoi --config "$cfg" --source "$PWD" --destination "$dest" apply --dry-run --verbose
  ```
  `chezmoi --config … managed` also shows exactly which paths would be deployed.
- For `/etc` logic, extract the function and run it against a fake root with a
  `sudo` stub — this caught a real bug where files would have landed in
  `/greetd/config.toml` instead of `/etc/greetd/config.toml`. Test fresh run,
  re-run (must be quiet), conflict (backs up), and second conflict (must not
  clobber the backup).
- For `sed` on system files, run it against a copy in the scratchpad and `diff`.
- Verify package facts against `https://archlinux.org/packages/search/json/?name=<pkg>`
  or the AUR RPC rather than from memory (repo, version, deps, conflicts). The
  web API rate-limits parallel requests and answers with empty results when it
  does, which reads as a screen of false "not found" errors — that is why
  `validate-packages.sh` uses the repo databases instead.

Anything that *modifies* the system still needs Ali: `sudo` requires a password,
so hand him the command (he can run it with a `! ` prefix).

## Gotchas already discovered

- **`steam` is in the official `multilib` repo, not the AUR.**
- Packages depending on virtual providers (`vulkan-driver`, `lib32-vulkan-driver`,
  `lib32-libgl`) make `pacman --noconfirm` pick the *first* provider — often the
  wrong vendor's driver. Name the host's GPU drivers explicitly in the per-host
  package file so they're in the same transaction.
- **Never declare both halves of a replacement pair.** `waybar-cava` (AUR)
  declares `conflicts=waybar provides=waybar`; pacman won't remove a conflicting
  installed package under `--noconfirm`, so declaring `waybar` too aborts the AUR
  half mid-run. Same shape for `wezterm-git`/`wezterm` and `walker-bin`/`walker`.
  `validate-packages.sh` enforces this.
- Packages migrate **out of the AUR into `[extra]`** and are then deleted from the
  AUR (`hyprsunset`, `hyprshot`, `hyprpolkitagent`, `stylua`, `ttf-firacode-nerd`
  all did; `ttf-vazir` vanished entirely, renamed upstream to `vazirmatn-fonts`).
  `yay` papers over this, so only the validator catches it.
- A config that names a *theme* needs that theme's package declared. Nothing
  does right now: `fuzzel.ini` named `Papirus-Dark` and is gone, and
  `gtk-*/settings.ini`'s `Bibata-Modern-Classic` line is commented out (so
  `bibata-cursor-theme` was dropped). Re-declare either if the line comes back.
- **Walker is only a frontend.** Every result comes from the `elephant` daemon,
  and each data source is its own `elephant-<name>` AUR package dropping a `.so`
  into `/usr/lib/elephant`. Installing `elephant` alone gives a launcher that
  finds nothing — `elephant listproviders` printing empty is the tell. Elephant
  must also already be running (`exec-once` in `hyprland.conf`).
- Walker's `~/.config/walker/config.toml` is a **partial** override merged over
  its built-in default (`PartialWalker` in `src/config.rs`); `providers.prefixes`
  entries merge by prefix. But a **theme's `style.css` fully replaces** the
  default one — `setup_css` does `load_from_file(f); return;` into a single
  CssProvider — so `themes/gruvbox/style.css` has to be a whole copy of the
  default stylesheet, not just the `@define-color` lines.
- `.chezmoiignore` does **not** strip trailing `#` comments — a comment on the
  same line becomes part of the pattern. Own line only (CI checks this).
- `pacman -Qdtq` orphans include packages declared in `shared/*.txt` and `hosts/*/*.txt` that were
  pulled in as dependencies (e.g. `vlc`). Cross-check before removing — that is
  `./bin/pkg-diff.sh`'s third section; see MAINTENANCE.md.
- makepkg sources `/etc/makepkg.conf.d/*.conf` after `makepkg.conf`, and
  `in_opt_array` scans **backwards**, so a later `OPTIONS+=(!debug)` wins.
- Launch Hyprland via `start-hyprland`, not the `Hyprland` binary.
- lazy.nvim's `{ import = "plugins" }` only recurses into subdirectories that
  contain an `init.lua` — which is why `plugins.copilot` needs its own explicit
  import line, and why the old `plugins/discard/` was dead weight, not active
  config.
- Three hosts, user `ali` on all of them; a hostname that doesn't match a
  `hosts/<host>/` directory means no GPU drivers and no microcode, so the two
  must stay in sync.
  - `sohrab` (**this machine**): **Intel NUC**, Intel integrated graphics / i915,
    **ext4** root (so no btrfs snapshots), systemd-boot. It was called
    `archlinux` until 2026-08. Everyday workstation — **no gaming**, so no
    `steam` and no `lib32-*` Vulkan/mesa here.
  - `rostam`: desktop PC, **AMD CPU + NVIDIA RTX 2080 Super**, dual-boots
    Windows. Gaming, video calls, OBS streaming — the full 32-bit stack.
  - `giv`: **Dell laptop**, Intel CPU and onboard Intel graphics. `steam` for
    light play only; the gaming extras (gamemode/mangohud/lutris/wine) are
    `rostam`-only.
- **NVIDIA is `nvidia-open-dkms` now.** Arch removed `nvidia` and `nvidia-dkms`
  from `[extra]` when NVIDIA dropped the proprietary kernel modules for Turing
  and newer; only `nvidia-open*` remains, and it covers the 2080 Super (Turing).
  DKMS means `linux-headers` must be declared alongside it, per kernel.

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
