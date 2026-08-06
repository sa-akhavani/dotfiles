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
| Terminal | [WezTerm](https://github.com/wez/wezterm) (`wezterm-git`, see `shared/aur.txt`) |
| Multiplexer | [tmux](https://github.com/tmux/tmux) (+ TPM) |
| Editor | [Neovim](https://github.com/neovim/neovim) (lazy.nvim) |
| Shell | [zsh](https://github.com/ohmyzsh/ohmyzsh) + oh-my-zsh |
| Status Bar | [Waybar](https://github.com/Alexays/Waybar) — the AUR `waybar-cava` build |
| Notifications | [mako](https://github.com/emersion/mako) |
| Launcher | [walker](https://github.com/abenz1267/walker) + [elephant](https://github.com/abenz1267/elephant) (`$mainMod+R`; clipboard history on `$mainMod+V`) |
| Lock / Idle | [hyprlock](https://github.com/hyprwm/hyprlock) + [hypridle](https://github.com/hyprwm/hypridle) |
| File Manager | [yazi](https://github.com/sxyazi/yazi) (TUI) / [Thunar](https://docs.xfce.org/xfce/thunar/start) (`$mainMod+E`) |
| Audio | PipeWire + WirePlumber |
| Dotfile manager | [chezmoi](https://www.chezmoi.io/) |

## Repository layout

chezmoi's source directory is `home/` (set by `.chezmoiroot`). chezmoi naming
conventions: `dot_` → `.`, `executable_` → `chmod +x`.

```
.chezmoiroot                 # -> "home" (chezmoi source dir)
install.sh                   # pacman/AUR installer + system services (idempotent)
README.md  MAINTENANCE.md  todo.md
bin/                         # repo maintenance helpers, all read-only
  pkg-diff.sh                #   drift: repo lists vs. what is installed here
  validate-packages.sh       #   every declared name still resolves; no conflicts
.github/workflows/ci.yml     # bash -n + shellcheck + the two checks above
shared/                      # applied on EVERY host  (shared/README.md)
  pacman.txt  aur.txt  npm.txt   # package lists
  etc/…                      #   copied to /etc  (etc/greetd/config.toml -> /etc/greetd/config.toml)
  services.txt               #   systemd units to enable
hosts/<hostname>/            # applied on ONE host, additive  (hosts/README.md)
  pacman.txt  aur.txt  npm.txt   # appended to the shared lists
  etc/…  services.txt        #   applied after the shared ones, so they win
home/                        # chezmoi source: everything here maps into $HOME
  .chezmoiignore
  .chezmoi.toml.tmpl         # -> per-host prompts (currently: gpu)
  dot_zshrc                  # -> ~/.zshrc
  dot_gitconfig              # -> ~/.gitconfig
  Pictures/                  # -> ~/Pictures  (wallpapers + lockscreen images)
  dot_config/                # -> ~/.config
    hypr/  waybar/  nvim/  wezterm/  mako/  cava/  walker/  tmux/
    fastfetch/  btop/  lsd/  wlogout/  swappy/  nwg-look/  Thunar/
    gtk-3.0/settings.ini  gtk-4.0/settings.ini
    hypr/scripts/executable_*.sh    # marked executable by chezmoi
```

The wallpapers live **inside** `home/` on purpose: `hypr/hyprpaper.conf` and the
lockscreen script read `~/Pictures/Wallpapers` and `~/Pictures/Lockscreen`, and
chezmoi can only deploy what is under its source root. A top-level `Pictures/`
was invisible to both chezmoi and `install.sh`, so those paths never existed on a
fresh machine and hyprpaper preloaded a missing file.

## Installation (fresh machine)

### 1. Base Arch install — use `archinstall`

Boot the official ISO and run the guided installer that ships with it:

```bash
archinstall
```

It is much faster than the [manual
guide](https://wiki.archlinux.org/title/Installation_guide) and gets partitioning,
`fstab`, the bootloader, the initramfs and CPU microcode right on its own. The
answers that matter for this repo:

| archinstall screen | Answer |
| --- | --- |
| Bootloader | **systemd-boot** |
| Disk configuration → filesystem | **ext4** (btrfs if you want snapshots — see MAINTENANCE.md) |
| Profile | **Minimal** — no desktop |
| Audio | **Pipewire** |
| Network configuration | **NetworkManager** |
| Kernels | `linux` (`install.sh` adds `linux-lts` as a fallback) |
| Additional packages | `git` — enough to clone this repo |
| User account | `ali`, **in the `wheel` group** (sudo) |
| Hostname | see the box below — everything per-host keys off it |
| Timezone / locale / keymap | `America/New_York`, `en_US.UTF-8`, `us` |

Pick the **Minimal** profile, not a desktop one: a desktop profile installs its
own greeter and compositor, which then fight greetd + Hyprland. Everything
graphical in this setup comes from `install.sh`.

> **The hostname is load-bearing.** All four per-host layers key off
> `hostnamectl --static`. This machine is **`sohrab`**, and
> `hosts/sohrab/pacman.txt` is what gives it its Intel Vulkan drivers,
> microcode and VA-API drivers. If you pick a different name, rename that
> directory to match — `install.sh` prints a loud warning when no per-host list
> matches, because a host without one silently gets no GPU drivers.

If you install by hand instead, note that `archinstall` would otherwise have
installed the CPU microcode for you; the shared package list declares
`linux-firmware`, `sof-firmware`, `efibootmgr` and `linux-lts`, and the per-host
list declares the microcode, so a re-run of `./install.sh` fills those gaps.

### 2. Clone and run the installer
```bash
git clone https://github.com/sa-akhavani/dotfiles.git ~/dotfiles
cd ~/dotfiles
git checkout arch-v3          # this branch
./install.sh --dry-run        # optional: print every change, apply nothing
./install.sh                  # enables [multilib], installs pacman + AUR packages,
                              # /etc configs (shared/etc), services, oh-my-zsh, tmux TPM
```

| Flag | Effect |
| --- | --- |
| *(none)* | everything: packages, `/etc`, services, oh-my-zsh, TPM |
| `--no-aur` | official repo packages + services only; skips `yay` and the AUR |
| `--dry-run` | prints every command it *would* run and changes nothing (needs no sudo password) |
| `--help` | usage |

### 3. Apply the dotfiles with chezmoi
`chezmoi` is installed by `install.sh`. Point it at this repo and apply:
```bash
chezmoi init --apply --source ~/dotfiles
```
On first init you'll be asked **once** for this host's GPU vendor
(`intel` / `amd` / `nvidia`) — see [Multi-host support](#multi-host-support).
This writes everything under `home/` into `$HOME`.

### 4. Quiet the boot messages — manual, one-time, per machine

Without this, boot output is printed **on top of the tuigreet login screen**.
`greetd` takes over VT 1 about 5.8s into boot, but systemd is still starting
services and printing `[ OK ] Started …` to `/dev/console` — which *is* VT 1 —
for well over a second after tuigreet has drawn its UI there. Neither knows the
other is on that screen.

This is not automated, and it is not in `shared/etc/` even on the hosts where the
file it touches *does* live under `/etc`: the command line is generated per
machine by `archinstall` and carries that machine's own root `PARTUUID`, so there
is nothing here that could safely be copied over it.

**Where you edit it depends on how the host boots.** Both shapes below are
systemd-boot; the difference is whether the kernel command line sits in a loader
entry or is baked *inside* a unified kernel image (UKI):

```bash
bootctl status | grep 'Current Entry'
#   …_linux.conf    → type-1 loader entry, edit /boot        → (A)
#   arch-linux.efi  → UKI, edit /etc/kernel/cmdline          → (B)   ← sohrab
grep -l default_uki /etc/mkinitcpio.d/*.preset    # same answer, from the other end
```

In both cases you append the same two words to the existing command line and keep
everything already on it, especially `root=PARTUUID=…`. `quiet` is what silences
systemd (it treats it as `systemd.show_status=false`) and handles most of the
noise; `loglevel=3` covers the kernel's own messages.

#### (A) Type-1 loader entries

```bash
ls /boot/loader/entries/          # e.g. 2025-02-03_21-29-45_linux.conf
sudo nvim /boot/loader/entries/<timestamp>_linux.conf
```

Append to the existing `options` line:

```
options root=PARTUUID=4c5e22a8-… zswap.enabled=0 rw rootfstype=ext4 quiet loglevel=3
```

- **Leave the `*_linux-fallback.conf` entry alone.** Verbose output is the entire
  point of a fallback entry — that is the one you boot when something is broken.
- It survives kernel upgrades: these `.conf` files are static, and pacman replaces
  `vmlinuz-linux` and the initramfs but never rewrites them.

#### (B) UKI — `/etc/kernel/cmdline` + `mkinitcpio -P`  (this host)

`sohrab` has no `/boot/loader/entries/*.conf` at all. `/etc/mkinitcpio.d/linux.preset`
sets `default_uki="/boot/EFI/Linux/arch-linux.efi"`, and mkinitcpio embeds
`/etc/kernel/cmdline` into that `.efi` when it builds it.

```bash
sudo cp /etc/kernel/cmdline /etc/kernel/cmdline.bak    # one line, no PARTUUID retyping
sudo nvim /etc/kernel/cmdline
sudo mkinitcpio -P                                     # rebakes arch-linux.efi
```

```
root=PARTUUID=43f5dd7c-… zswap.enabled=0 rw rootfstype=ext4 quiet loglevel=3
```

- **Editing the file changes nothing on its own** — the command line lives inside
  the `.efi`, so `mkinitcpio -P` is the step that actually applies it. Reboot
  without it and `/proc/cmdline` is unchanged.
- It survives kernel upgrades for the same reason it needs that command now:
  pacman's mkinitcpio hook re-runs the presets and re-reads `/etc/kernel/cmdline`
  on every kernel update, so the edit is picked up again each time.
- **The fallback UKI goes quiet too**, unlike (A): `arch-linux-fallback.efi` is
  built from the same `/etc/kernel/cmdline`. To keep a verbose rescue image, give
  the fallback preset its own file in `/etc/mkinitcpio.d/linux.preset` —
  `fallback_options="--cmdline /etc/kernel/fallback-cmdline"` — remembering that
  the preset is pacman-owned and will throw `.pacnew` files at you.
- `/etc/cmdline.d/*.conf` drop-ins are read **only when `/etc/kernel/cmdline` does
  not exist**, so don't split the command line across both.

#### Either way

- Nothing is lost, only hidden: `journalctl -b` still has the full boot.
- On a host booting **GRUB** instead, this is `GRUB_CMDLINE_LINUX_DEFAULT` in
  `/etc/default/grub` followed by `sudo grub-mkconfig -o /boot/grub/grub.cfg`.

Check it took effect after rebooting:
```bash
cat /proc/cmdline                 # should now end in: quiet loglevel=3
```

If output *still* lands on the greeter, the bigger hammer is to move the greeter
off VT 1 entirely: `vt = 1` → `vt = 7` in `shared/etc/greetd/config.toml`. Then
boot messages and the greeter cannot collide regardless of timing.

### 5. Reboot and finish plugin setup
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
| Packages | `pacman.txt`, `aur.txt`, `npm.txt` appended to the shared lists | `hosts/<hostname>/` |
| `/etc` + services | `etc/…`, `services.txt` applied after the shared ones | `hosts/<hostname>/` |
| Dotfile *contents* | `*.tmpl` templates branching on host data | `home/` |
| Whole dotfiles on/off | `.chezmoiignore` (itself a template) | `home/` |

Known hosts:

| Host | Hardware | Role |
| --- | --- | --- |
| **`rostam`** | desktop PC — AMD CPU, NVIDIA RTX 2080 Super, dual-boots Windows | gaming, video calls, OBS streaming |
| **`sohrab`** | this Intel NUC — Intel integrated graphics/i915, ext4, systemd-boot booting a UKI | everyday workstation, no gaming |
| **`giv`** | Dell laptop — Intel CPU, onboard Intel graphics | portable; Steam for light play only |

### Setting up a new host, start to finish

```bash
hostnamectl set-hostname <host>        # pick the name FIRST: everything keys off it
git clone https://github.com/sa-akhavani/dotfiles.git ~/dotfiles
cd ~/dotfiles && git checkout arch-v3
mkdir -p hosts/<host>
# start from the closest existing host, then edit: GPU drivers + microcode
cp hosts/rostam/pacman.txt hosts/<host>/pacman.txt
./install.sh                           # reads shared/ + hosts/<host>/
chezmoi init --apply --source ~/dotfiles
```

Then the one step nothing here can do for you: append `quiet loglevel=3` to the
kernel command line — in the loader entry or in `/etc/kernel/cmdline` followed by
`mkinitcpio -P`, depending on how that host boots — or boot messages will print
over the login screen — see
[step 4 of the installation](#4-quiet-the-boot-messages--manual-one-time-per-machine).

Create the per-host package list **before** the first `./install.sh`, not after:
it is the only place the GPU/Vulkan drivers and the CPU microcode are declared.
`install.sh` warns when no list matches the hostname, and lists the ones that do
exist, but it cannot guess which GPU the machine has.

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

Existing example — `home/dot_config/hypr/env_nvidia.lua.tmpl` emits the NVIDIA
env vars only when `gpu = "nvidia"` and a comment otherwise, so `hyprland.lua`
can `require` it unconditionally on every host.

Per-host monitor layout, the common case:

```gotmpl
{{- if eq .chezmoi.hostname "rostam" }}
hl.monitor({ output = "DP-1", mode = "3440x1440@144", position = "0x0", scale = 1 })
{{- else if eq .chezmoi.hostname "sohrab" }}
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
{{- else }}
-- sane fallback for an unknown host
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
{{- end }}
```

Preview what a template renders as before applying:
`chezmoi cat ~/.config/hypr/monitor.lua`, or `chezmoi diff` for everything.

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

(CI enforces that own-line rule; see [Verifying a change](#verifying-a-change).)

### 4. Secrets / anything not committed

Keep host-specific secrets out of the repo: reference them from templates via
`{{ (bitwarden ... ) }}`/`{{ env "…" }}`, or keep them in
`~/.config/chezmoi/chezmoi.toml`, which is machine-local and never committed.

### Where should a difference go?

- Different **package** on one host → `hosts/<host>/pacman.txt`
- Different **`/etc` file or service** → `hosts/<host>/…`
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
| `dotsync` | `chezmoi re-add`, with a check that the repo is not ahead of `$HOME` |
| `upcheck` | `checkupdates; yay -Qua` — preview both halves of an upgrade, change nothing |
| `upgrade` | `sudo pacman -Syu && yay -Sua` — upgrade repos first, then the AUR |
| `orphans` | `pacman -Qdtq` — list packages nothing depends on any more |
| `orphanclean` | remove them; re-run until `orphans` is empty |
| `cleanup` | trim the pacman + yay caches, keeping the 3 newest versions |
| `pacmerge` | `pacdiff` in `nvim -d` — merge `.pacnew` files an upgrade left behind |

The AUR half of `upgrade` is `yay -Sua`, **not** `-Syu`: `-Syu` there re-syncs and
redoes the repo half pacman just did. Doing them as two steps also makes it
obvious which half broke.

`orphans` is separate from `orphanclean` deliberately: a package this repo
declares can be recorded by pacman as a *dependency*, and then it is
indistinguishable from a real orphan in `pacman -Qdtq` (`vlc` was one cleanup
away from being deleted). Run `./bin/pkg-diff.sh` to see which ones those are.
See [MAINTENANCE.md](MAINTENANCE.md) for what actually breaks Arch upgrades,
orphan/cache cleanup, and how to roll a package back.

Typical loop: `chezmoi edit <file>` → `chezmoi apply` → `chezmoi cd && git commit -am ... && git push`.

To add a **package**: append it to `shared/pacman.txt` (or `aur.txt`, or the
per-host variant) and re-run `./install.sh` — or just `sudo pacman -S <pkg>` /
`yay -S <pkg>` and add it to the list afterwards so the next machine gets it.

To add a **`/etc` file or a service**: put the file under `shared/etc/` at its
real path, or the unit name in `shared/services.txt`, then re-run `./install.sh`.
See [`shared/README.md`](shared/README.md).

### Keeping the lists honest

Nothing stops the machine and the repo from drifting apart: a package installed
by hand is not declared, and an AUR build that failed during `install.sh` scrolls
past unnoticed. Both directions are reported by:

```bash
./bin/pkg-diff.sh          # read-only; exits 1 when there is drift
```

| It reports | What to do |
| --- | --- |
| Declared but not installed | re-run `./install.sh`, or `yay -S <name>` without `--noconfirm` to see the real error |
| Explicitly installed but not declared | add it to `shared/` (or `hosts/<hostname>/`), or `sudo pacman -Rns <name>` |
| Declared but installed as a *dependency* | `sudo pacman -D --asexplicit <names>` — otherwise `pacman -Qdt` lists them as orphans and a routine cleanup deletes packages this repo says you need |

### Verifying a change

There is no test suite, so:

```bash
bash -n install.sh                 # after every edit to it
./install.sh --dry-run             # what a real run would do; needs no password
./bin/validate-packages.sh         # every declared name still resolves, no conflicts
shellcheck --severity=warning install.sh bin/*.sh
chezmoi diff                       # what an apply would change in $HOME
```

`.github/workflows/ci.yml` runs the same checks on every push (and weekly, since
package names rot on their own — that is how five packages in this repo were
found to have moved from the AUR into `[extra]`).

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

### Launcher: walker + elephant
`$mainMod+R` opens walker; `$mainMod+V` opens the clipboard history. Both
replaced fuzzel (and, for the clipboard, cliphist) — neither is installed now.

**Walker is only a frontend.** Everything it lists comes from the `elephant`
daemon, and every data source is a *separate* package that drops a plugin into
`/usr/lib/elephant`. Installing `elephant` on its own gives a launcher that
finds nothing at all. Check with:

```bash
elephant listproviders     # empty output = no providers installed
pgrep -a elephant          # nothing = the daemon is not running
```

Elephant is started from the `hyprland.start` autostart block in
`hypr/hyprland.lua`, so it comes up with the session. (`elephant service enable`
would instead install a systemd *user* unit; `shared/services.txt` only handles
root units, which is why this repo autostarts it from the compositor — the same
way waybar and hypridle start.)

Type a prefix to restrict the search to one provider:

| Prefix | Provider | Package |
| --- | --- | --- |
| *(none)* | applications, calculator, web search | `elephant-desktopapplications`, `elephant-calc`, `elephant-websearch` |
| `>` | run any command in `$PATH` | `elephant-runner` |
| `:` | clipboard history | `elephant-clipboard` |
| `=` | calculator | `elephant-calc` |
| `@` | web search | `elephant-websearch` |
| `;` | list the available providers | `elephant-providerlist` |

`runner` is deliberately kept off the no-prefix search: it matches every
executable in `$PATH` and would bury the application results. Move it into
`providers.default` in `home/dot_config/walker/config.toml` if you disagree.

Config is a **partial** override merged over walker's built-in default (the
packaged copy is at `/etc/xdg/walker/config.toml` if you want to see everything
that is settable). The gruvbox theme is the exception: a theme's `style.css`
*replaces* the default stylesheet rather than extending it, so
`walker/themes/gruvbox/style.css` is a full copy of the default with only the
`@define-color` lines changed. Re-diff it against
`/etc/xdg/walker/themes/default/style.css` after a walker update.

### Waybar + Cava
The official `waybar` package ships without the cava module, so this repo uses
the AUR `waybar-cava` build (+ `libcava`) instead.

**`waybar` is therefore not in `shared/pacman.txt`, and must not be added
back.** `waybar-cava` declares `conflicts=waybar provides=waybar`, and pacman
refuses to remove a conflicting installed package when it is running under
`--noconfirm` — so declaring both makes the AUR half of `install.sh` abort.
`./bin/validate-packages.sh` fails the build if the pair ever comes back.

On a machine that already has the official package, the swap needs one
interactive command (answer *yes* to replacing `waybar`):

```bash
yay -S waybar-cava        # deliberately NOT --noconfirm
```

For the cava audio source use `method = pipewire` (not alsa); it auto-picks the
output sink. See <https://github.com/karlstav/cava>.

### Fonts
Uses FiraCode (`ttf-fira-code`) with its patched Nerd Font build
(`ttf-firacode-nerd`), the standalone glyph set `Symbols Nerd Font Mono`
(`ttf-nerd-fonts-symbols-mono`, what yazi and the Waybar modules fall back to),
Noto, Liberation, and Vazirmatn for Persian (`vazirmatn-fonts` — the old
`ttf-vazir` was deleted from the AUR when upstream renamed the project). Avoid
mixing multiple patched Nerd Font variants.

A theme named by a config has to be installed too, or it silently falls back.
Nothing names one at the moment: `fuzzel.ini` set `icon-theme=Papirus-Dark` and
is gone (walker takes its icons from the GTK icon theme instead), and the
`Bibata-Modern-Classic` line in `gtk-3.0/settings.ini` is commented out.
`papirus-icon-theme` is still declared; `bibata-cursor-theme` is not.

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
`hosts/<hostname>/pacman.txt` — see [`hosts/README.md`](hosts/README.md).
Getting this wrong is the usual cause of Steam launching to a black window.

### Rootless Docker
`install.sh` sets up rootless docker. A re-login is required for the user socket
to come up. Verify with `docker info` (should show `rootless`).

Two things are easy to get wrong here, both handled by the installer now:

- **`dockerd-rootless-setuptool.sh` is not part of Arch's `docker` package.** It
  ships only in `docker-rootless-extras` (AUR), which is why that package is in
  `shared/aur.txt`. Without it there is nothing to set up, and an installer
  that disables `docker.service` on the assumption that rootless will replace it
  leaves the host with no working Docker at all. `install.sh` now only disables
  the root daemon once the rootless tooling is actually present, and enables the
  root `docker.service` otherwise (including on `--no-aur` runs).
- **Arch ships no `/etc/subuid` / `/etc/subgid`.** Rootless Docker needs a
  sub-uid/sub-gid range for your user and the setup tool's own preflight check
  fails without one, so `install.sh` adds `100000-165535` via
  `usermod --add-subuids/--add-subgids` first.
