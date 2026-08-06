# `shared/` — everything installed on every host

`install.sh` reads this directory first, then `hosts/<hostname>/` on top of it.
Both directories hold the same kinds of thing:

| Path | What it is |
| --- | --- |
| `pacman.txt` | official-repo packages |
| `aur.txt` | AUR packages |
| `npm.txt` | global npm packages |
| `etc/…` | files copied to `/etc`, laid out mirroring `/` |
| `services.txt` | systemd units to enable |

Package/unit lists are one name per line; blank lines and `#` comments ignored.
The per-host layer is **additive** — it is appended to these lists and applied
after them, never replacing them. See `hosts/README.md`.

Only reach for `npm.txt` when there is no official or AUR package worth using:
`sudo npm -g` writes root-owned trees into `/usr/lib/node_modules` that pacman
knows nothing about, so they never appear in a package audit and survive
uninstalls.

## Validate a list before trusting it

```bash
./bin/validate-packages.sh      # from the repo root; read-only, no sudo
```

It resolves every name in `shared/` **and every host's** lists against the real
`core`/`extra`/`multilib` databases and the AUR RPC, and fails on:

- a name that no longer exists anywhere — renamed, dropped, or `[testing]`-only;
- a name in the wrong half (an official package listed in an `aur.txt`, or the reverse);
- an AUR package that **conflicts** with a declared official package (see below).

Not hypothetical: `hyprsunset`, `hyprshot`, `hyprpolkitagent`, `stylua` and
`ttf-firacode-nerd` all graduated from the AUR into `[extra]` and were then
deleted from the AUR, and `ttf-vazir` disappeared outright when upstream renamed
the project to Vazirmatn. All six were still listed as AUR packages. `neovim`
went the other way once — declared in `aur.txt`, where it has never existed.

`./bin/pkg-diff.sh` is the complement: it compares these lists against what is
actually installed on the current machine, in both directions.

## Conflicts: never declare both halves of a replacement

pacman refuses to remove an installed conflicting package when it cannot ask —
which is exactly the situation under `--noconfirm`. So when an AUR package
*replaces* an official one, only the AUR name may be declared:

| Declared (AUR) | Must NOT be in a `pacman.txt` | Why |
| --- | --- | --- |
| `waybar-cava` | `waybar` | `conflicts=waybar provides=waybar`; the official build has no cava module |
| `wezterm-git` | `wezterm` | stable 20240203 never maps a window under Hyprland 0.56 |
| `tmux-git` | `tmux` | `conflicts=tmux provides=tmux` |
| `walker-bin` | `walker` | prebuilt binary instead of a from-source build |

Getting this wrong does not fail cleanly — it aborts the AUR half of the run
partway through, after `yay` has already spent time building things.

## How `etc/` is copied

The `etc/` directory mirrors the real filesystem: `shared/etc/greetd/config.toml`
→ `/etc/greetd/config.toml`. For each file, `install.sh`:

1. renders it (see templates below),
2. compares it with what is already on disk — identical means skip, so re-runs
   are quiet,
3. if it differs and a file is already there, copies that file once to
   `<path>.dotfiles-bak` (never overwriting an existing `.dotfiles-bak`),
4. installs it `root:root`, mode `0644`, creating parent directories.

Nothing is ever deleted: removing a file from this directory does **not** remove
it from `/etc`. Do that by hand.

Preview the whole thing without touching the system — and without a sudo
password, since the dry run skips even the read-only `sudo` used for comparing:

```bash
./install.sh --dry-run
```

### Templates (`.in`)

A file whose name ends in `.in` is a template. The suffix is dropped and these
placeholders are substituted:

| Placeholder | Value |
| --- | --- |
| `@USER_NAME@` | the user running `install.sh` (`$SUDO_USER`, else `$USER`) |
| `@HOSTNAME@` | `hostnamectl --static` |

Example: `shared/etc/ssh/sshd_config.d/10-dotfiles.conf.in` →
`/etc/ssh/sshd_config.d/10-dotfiles.conf` with `AllowUsers ali`.

### Current `/etc` contents

| File | Purpose |
| --- | --- |
| `etc/greetd/config.toml` | greetd → tuigreet → `start-hyprland` |
| `etc/bluetooth/main.conf` | experimental + fast-connect + auto-enable |
| `etc/security/faillock.conf` | 5 failed password attempts before a 10-minute lock-out |
| `etc/ssh/sshd_config.d/10-dotfiles.conf.in` | no password auth, no root login, single allowed user |

`security/faillock.conf` is the only file here that pacman also owns (`pam`), so a
`pam` upgrade will drop a `faillock.conf.pacnew` beside it — see MAINTENANCE.md.

## Adding something

- **A package**: add the name to `pacman.txt` or `aur.txt`, then run
  `./bin/validate-packages.sh`.
- **A new `/etc` file**: create it at the mirrored path under `etc/` and re-run
  `./install.sh`.
- **A new service**: add the unit name to `services.txt`.
- **A file needing a non-0644 mode** (a key, a sudoers drop-in): don't put it
  here — `install.sh` hard-codes `0644`. Handle it explicitly in the script.
- **Anything true of only one machine**: it belongs in `hosts/<hostname>/`, not
  here. GPU drivers and CPU microcode *always* do.

## Services that are *not* listed in `services.txt`

`docker.service` is handled in code rather than declared here, because whether it
should be enabled depends on what got installed. `install.sh` prefers rootless
Docker, which replaces the system daemon — but the tool that sets it up
(`dockerd-rootless-setuptool.sh`) is not part of Arch's `docker` package; it only
ships in `docker-rootless-extras` (AUR). So the installer enables the root
`docker.service` when that package is absent (a `--no-aur` run, say) and disables
it only once rootless can actually take over. Listing it in `services.txt` would
enable it unconditionally.

Elephant (walker's data backend) is also not here: it runs as a **user** service,
autostarted from `hypr/hyprland.lua`, while `services.txt` only handles root
units.
