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
packages/                    # package lists, shared + per-host  (packages/README.md)
  pacman.txt  aur.txt
  pacman.<hostname>.txt  aur.<hostname>.txt
system/                      # root-owned config, applied with sudo  (system/README.md)
  etc/…                      #   copied to /etc  (etc/greetd/config.toml -> /etc/greetd/config.toml)
  services.txt               #   systemd units to enable
  hosts/<hostname>/          #   per-host etc/ + services.txt
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
./install.sh                  # enables [multilib], installs pacman + AUR packages,
                              # /etc configs (system/), services, oh-my-zsh, tmux TPM
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

One repo, one branch, many machines. Nothing is duplicated per host; each host
only overrides what actually differs. There are four independent layers, all
keyed off the hostname (`hostnamectl --static`) or off machine-local chezmoi
data:

| Layer | Mechanism | Where |
| --- | --- | --- |
| Packages | `pacman.<hostname>.txt`, `aur.<hostname>.txt` appended to the shared lists | `packages/` |
| `/etc` + services | `hosts/<hostname>/etc/…`, `hosts/<hostname>/services.txt` | `system/` |
| Dotfile *contents* | `*.tmpl` templates branching on host data | `home/` |
| Whole dotfiles on/off | `.chezmoiignore` (itself a template) | `home/` |

### Setting up a new host, start to finish

```bash
hostnamectl set-hostname rostam        # pick the name FIRST: everything keys off it
git clone https://github.com/sa-akhavani/dotfiles.git ~/dotfiles
cd ~/dotfiles && git checkout arch-v3
./install.sh                           # reads packages/*.rostam.txt + system/hosts/rostam/
chezmoi init --apply --source ~/dotfiles
```

`chezmoi init` prompts once for this host's data (currently **GPU vendor**),
stores it in `~/.config/chezmoi/chezmoi.toml` under `[data]`, and reuses it for
every later `chezmoi apply` — you are never asked again on that machine.

### 1. Machine-local data (the prompts)

`home/.chezmoi.toml.tmpl` defines what each host is asked. Add a variable by
adding another `promptStringOnce`:

```gotmpl
{{- $gpu    := promptStringOnce . "gpu"    "GPU vendor (intel / amd / nvidia)" "intel" }}
{{- $laptop := promptBoolOnce   . "laptop" "Is this a laptop?" true }}

[data]
    gpu    = {{ $gpu | quote }}
    laptop = {{ $laptop }}
```

Change an answer later without re-initializing: edit
`~/.config/chezmoi/chezmoi.toml` and run `chezmoi apply`. (An older machine that
predates a new variable just needs the key added there by hand.)

### 2. Per-host file contents (templates)

Rename a file to `*.tmpl` and branch. Available: your own `[data]` keys plus
built-ins like `.chezmoi.hostname`, `.chezmoi.os`, `.chezmoi.arch`.

Existing example — `home/dot_config/hypr/env_nvidia.conf.tmpl` emits the NVIDIA
env vars only when `gpu = "nvidia"` and a comment otherwise, so `hyprland.conf`
can `source` it unconditionally on every host.

Per-host monitor layout, the common case:

```gotmpl
{{- if eq .chezmoi.hostname "rostam" }}
monitor = DP-1, 3440x1440@144, 0x0, 1
{{- else if eq .chezmoi.hostname "sohrab" }}
monitor = eDP-1, 1920x1080@60, 0x0, 1
{{- else }}
monitor = , preferred, auto, 1      # sane fallback for an unknown host
{{- end }}
```

Preview what a template renders as before applying:
`chezmoi cat ~/.config/hypr/monitor.conf`, or `chezmoi diff` for everything.

### 3. Skipping whole files on some hosts

`home/.chezmoiignore` is itself a template, evaluated per host — list a path to
leave it unmanaged there:

```gotmpl
{{ if ne .chezmoi.hostname "sohrab" }}
# desktops have no battery — comments must be on their own line, chezmoi does
# not strip a trailing `#` and would make it part of the pattern
.config/waybar/modules/battery.jsonc
{{ end }}
```

### 4. Secrets / anything not committed

Keep host-specific secrets out of the repo: reference them from templates via
`{{ (bitwarden ... ) }}`/`{{ env "…" }}`, or keep them in
`~/.config/chezmoi/chezmoi.toml`, which is machine-local and never committed.

### Where should a difference go?

- Different **package** on one host → `packages/pacman.<host>.txt`
- Different **`/etc` file or service** → `system/hosts/<host>/…`
- Same file, different **contents** → make it a `.tmpl`
- File that should not exist at all → `.chezmoiignore`

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

To add a **package**: append it to `packages/pacman.txt` (or `aur.txt`, or the
per-host variant) and re-run `./install.sh` — or just `sudo pacman -S <pkg>` /
`yay -S <pkg>` and add it to the list afterwards so the next machine gets it.

To add a **`/etc` file or a service**: put the file under `system/etc/` at its
real path, or the unit name in `system/services.txt`, then re-run `./install.sh`.
See [`system/README.md`](system/README.md).

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

### Steam / 32-bit packages
`steam` lives in the official **`multilib`** repo (not the AUR). `install.sh`
enables `multilib` for you — it uncomments the `[multilib]` section of
`/etc/pacman.conf` (backing the file up to `/etc/pacman.conf.dotfiles-bak` the
first time) and leaves `multilib-testing` off. To do it by hand instead:

```bash
sudo sed -i '/^#\[multilib\]$/,/^#Include/ s/^#//' /etc/pacman.conf
sudo pacman -Sy
```

Your GPU's 32-bit drivers are host-specific and live in
`packages/pacman.<hostname>.txt` — see [`packages/README.md`](packages/README.md).
Getting this wrong is the usual cause of Steam launching to a black window.

### Rootless Docker
`install.sh` sets up rootless docker. A re-login is required for the user socket
to come up. Verify with `docker info` (should show `rootless`).
