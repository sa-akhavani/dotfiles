# Ali's Arch Linux Dotfiles

Fast, minimal, feature-packed, yet aesthetically pleasing environment optimized
for software engineering and DevOps.

Packages and system services are installed with **pacman/AUR** (`install.sh`).
Dotfiles are managed with **[chezmoi](https://www.chezmoi.io/)** — plain,
directly-editable config files, no Nix required.

> Migrated from a full NixOS flake (see the `nixos`/`master` branches). This
> branch is 100% Nix-free.

## Overview

| Tool / Environment | Choice |
| --- | --- |
| OS | [Arch Linux](https://archlinux.org/) |
| Window Manager | [Hyprland](https://github.com/hyprwm/Hyprland) (Wayland) |
| Display Manager | [greetd](https://sr.ht/~kennylevinsen/greetd/) + [tuigreet](https://github.com/apognu/tuigreet) |
| Terminal | [WezTerm](https://github.com/wez/wezterm) / [kitty](https://sw.kovidgoyal.net/kitty/) |
| Multiplexer | [tmux](https://github.com/tmux/tmux) (+ TPM) |
| Editor | [Neovim](https://github.com/neovim/neovim) |
| Shell | [zsh](https://github.com/ohmyzsh/ohmyzsh) + oh-my-zsh |
| Status Bar | [Waybar](https://github.com/Alexays/Waybar) |
| Notifications | [mako](https://github.com/emersion/mako) |
| Launcher | [fuzzel](https://codeberg.org/dnkl/fuzzel) / [walker](https://github.com/abenz1267/walker) |
| Lock / Idle | [hyprlock](https://github.com/hyprwm/hyprlock) + [hypridle](https://github.com/hyprwm/hypridle) |
| File Manager | [yazi](https://github.com/sxyazi/yazi) / [nemo](https://github.com/linuxmint/nemo) |
| Audio | PipeWire + WirePlumber |
| Dotfile manager | [chezmoi](https://www.chezmoi.io/) |

## Repository layout

chezmoi's source directory is `home/` (set by `.chezmoiroot`). chezmoi naming
conventions: `dot_` → `.`, `executable_` → `chmod +x`.

```
.chezmoiroot                 # -> "home" (chezmoi source dir)
install.sh                   # pacman/AUR installer + system services (run once)
README.md
Pictures/                    # wallpapers + lockscreen images
home/
  .chezmoiignore
  dot_zshrc                  # -> ~/.zshrc
  dot_gitconfig              # -> ~/.gitconfig
  dot_config/                # -> ~/.config
    hypr/  waybar/  nvim/  kitty/  wezterm/  mako/  cava/  wofi/  fuzzel/
    fastfetch/  btop/  lsd/  wlogout/  swappy/  nwg-look/  Thunar/  fontconfig/
    tmux/tmux.conf
    gtk-3.0/settings.ini  gtk-4.0/settings.ini
    hypr/scripts/executable_*.sh    # marked executable by chezmoi
```

## Installation (fresh machine)

### 1. Base Arch install
Follow the [official guide](https://wiki.archlinux.org/title/Installation_guide).
Match the previous system settings:
- Boot loader: **systemd-boot** (EFI)
- Hostname: `sohrab`
- Timezone: `America/New_York`
- Locale: `en_US.UTF-8`
- Console keymap: `us`
- Create user `ali` with sudo (wheel).

### 2. Clone and run the installer
```bash
git clone https://github.com/sa-akhavani/dotfiles.git ~/dotfiles
cd ~/dotfiles
git checkout arch-v3          # this branch
./install.sh                  # installs pacman + AUR packages, services, /etc configs,
                              # oh-my-zsh, and tmux TPM
```
`./install.sh --no-aur` installs only official repo packages + services.

### 3. Apply the dotfiles with chezmoi
`chezmoi` is installed by `install.sh`. Point it at this repo and apply:
```bash
chezmoi init --apply --source ~/dotfiles
```
On first init you'll be asked **once** for this host's GPU vendor
(`intel` / `amd` / `nvidia`) — see [Multi-host support](#multi-host-support).
This writes everything under `home/` into `$HOME`.

### 4. Reboot and finish plugin setup
Reboot → greetd → pick Hyprland. Inside the session:
```bash
# tmux plugins: open tmux, then press  <prefix>(C-a) + I
```

## Multi-host support

The same repo drives multiple machines. Per-host differences are handled by
**chezmoi templates** driven by machine-local data.

- On `chezmoi init`, you answer a small prompt (currently: **GPU vendor**). The
  answer is stored in `~/.config/chezmoi/chezmoi.toml` under `[data]` and reused
  by every `chezmoi apply` — you're never asked again on that host.
- Templates (`*.tmpl`) render differently per host. Example:
  `home/dot_config/hypr/env_nvidia.conf.tmpl` emits the NVIDIA env vars only when
  `gpu = "nvidia"`, and nothing on Intel/AMD — so the file is safe to `source`
  unconditionally from `hyprland.conf`.

Change a host's answer later without a full re-init:
```bash
# edit ~/.config/chezmoi/chezmoi.toml -> [data] gpu = "nvidia", then:
chezmoi apply
```
Already-initialized machine that predates this feature? Either re-run
`chezmoi init` or just add `gpu = "…"` under `[data]` in that file.

To make another file host-specific (e.g. per-machine `monitor.conf`), rename it
to `monitor.conf.tmpl` and branch on `.gpu` or `.chezmoi.hostname`.

## Day-to-day (chezmoi workflow)

| Command / alias | Action |
| --- | --- |
| `update` | `chezmoi apply` — re-apply the source to `$HOME` |
| `chezmoi edit ~/.zshrc` | edit a file through chezmoi (edits the source under `home/`) |
| `chezmoi add ~/.config/foo` | start tracking a new config file |
| `chezmoi re-add` | pull changes you made directly in `$HOME` back into the source |
| `chezmoi cd` | drop into the source repo (`home/`) to commit/push |
| `upgrade` | `sudo pacman -Syu && yay -Syu` — upgrade all packages |

Typical loop: `chezmoi edit <file>` → `chezmoi apply` → `chezmoi cd && git commit -am ... && git push`.

To add a **package**: put it in `install.sh` (`PACMAN_PKGS`/`AUR_PKGS`) and re-run,
or just `sudo pacman -S <pkg>` / `yay -S <pkg>`.

## Notes and troubleshooting

### OpenVPN
On Arch, drop your `.conf` in `~/openvpn/basic.conf` and run
`sudo openvpn --config ~/openvpn/basic.conf`, or use
`systemctl enable --now openvpn-client@basic` with the conf in
`/etc/openvpn/client/basic.conf`.

### SSH known hosts
The `nuc-alpha` host used on NixOS lives in `~/.ssh/config`:
```
Host nuc-alpha
    Hostname 192.168.1.162
    Port 22
    User ali
```

### Waybar + Cava
The official `waybar` package ships without the cava module. This repo installs
`waybar-cava` (+ `libcava`) from the AUR, which enables it. If cava conflicts,
remove `cava libcava` first, then reinstall `libcava` and `waybar-cava`.
For the cava audio source use `method = pipewire` (not alsa); it auto-picks the
output sink. See <https://github.com/karlstav/cava>.

### Fonts
Uses FiraCode + `Symbols Nerd Font Mono` (`ttf-firacode-nerd`), Noto, Liberation
and Vazir (Persian, `ttf-vazir`). Avoid mixing multiple patched Nerd Font
variants.

### Wrong temperature in Waybar
```bash
paste <(cat /sys/class/thermal/thermal_zone*/type) <(cat /sys/class/thermal/thermal_zone*/temp) \
  | column -s $'\t' -t | sed 's/\(.\)..$/.\1°C/'
```
Point the waybar temperature module at the correct `hwmon`/thermal zone.

### Spotify
Hyprland windows have no menu bar; toggle offline mode with `Ctrl-Shift-o`.
See the [Arch wiki](https://wiki.archlinux.org/title/Spotify).

### Three-finger drag gesture
Install `ydotool` + `fusuma`, configure via `~/.config/fusuma/`. Do **not** give
ydotool sudo. Enable with `systemctl --user enable --now ydotool.service`.

### Rootless Docker
`install.sh` sets up rootless docker. A re-login is required for the user socket
to come up. Verify with `docker info` (should show `rootless`).
