# Package lists

`install.sh` builds the install set from these plain-text files (one package per
line; blank lines and `#` comments ignored):

| File | Scope |
| --- | --- |
| `pacman.txt` | official-repo packages installed on **every** host |
| `aur.txt` | AUR packages installed on **every** host |
| `npm.txt` | global npm packages installed on **every** host |
| `pacman.<hostname>.txt` | extra official-repo packages for one host (optional) |
| `aur.<hostname>.txt` | extra AUR packages for one host (optional) |
| `npm.<hostname>.txt` | extra global npm packages for one host (optional) |

`<hostname>` matches `hostnamectl --static`. Host files are **additive** — they
are appended to the shared lists, never replace them.

Anything that is *not* a package name — `/etc` files, systemd units — lives in
`system/` instead; see `system/README.md`.

Only reach for `npm.txt` when there is no official or AUR package worth using:
`sudo npm -g` writes root-owned trees into `/usr/lib/node_modules` that pacman
knows nothing about, so they never appear in a package audit and survive
uninstalls.

## Validate a list before trusting it

```bash
./bin/validate-packages.sh      # from the repo root; read-only, no sudo
```

It resolves every name in every list (including other hosts') against the real
`core`/`extra`/`multilib` databases and the AUR RPC, and fails on:

- a name that no longer exists anywhere — renamed, dropped, or `[testing]`-only;
- a name in the wrong half (an official package listed in `aur.txt`, or the reverse);
- an AUR package that **conflicts** with a declared official package (see below).

Not hypothetical: `hyprsunset`, `hyprshot`, `hyprpolkitagent`, `stylua` and
`ttf-firacode-nerd` all graduated from the AUR into `[extra]` and were then
deleted from the AUR, and `ttf-vazir` disappeared outright when upstream renamed
the project to Vazirmatn. All six were still listed here as AUR packages.

`./bin/pkg-diff.sh` is the complement: it compares these lists against what is
actually installed on the current machine, in both directions.

## Conflicts: never declare both halves of a replacement

pacman refuses to remove an installed conflicting package when it cannot ask —
which is exactly the situation under `--noconfirm`. So when an AUR package
*replaces* an official one, only the AUR name may be declared:

| Declared (AUR) | Must NOT be in `pacman.txt` | Why |
| --- | --- | --- |
| `waybar-cava` | `waybar` | `conflicts=waybar provides=waybar`; the official build has no cava module |
| `wezterm-git` | `wezterm` | stable 20240203 never maps a window under Hyprland 0.56 |
| `walker-bin` | `walker` | prebuilt binary instead of a from-source build |

Getting this wrong does not fail cleanly — it aborts the AUR half of the run
partway through, after `yay` has already spent time building things.

## GPU drivers, microcode and other per-host packages

Graphics drivers are deliberately **not** in the shared lists: `steam` (and
Vulkan generally) depends on virtual packages like `vulkan-driver` /
`lib32-vulkan-driver`, and with `--noconfirm` pacman resolves those to whichever
provider comes first — possibly another vendor's driver. Put the right ones in
your host file:

| GPU | packages |
| --- | --- |
| Intel | `vulkan-intel` `lib32-mesa` `lib32-vulkan-intel` `intel-media-driver` |
| AMD | `vulkan-radeon` `lib32-mesa` `lib32-vulkan-radeon` |
| NVIDIA | `nvidia-dkms` `nvidia-utils` `lib32-nvidia-utils` `egl-wayland` |

CPU **microcode** belongs here for the same reason — it is vendor-specific:
`intel-ucode` or `amd-ucode`. (`archinstall` installs it during a fresh install;
declaring it keeps a manual install, and any later re-run, honest.)

A host with no matching `pacman.<hostname>.txt` therefore gets **no** GPU drivers
and **no** microcode. `install.sh` warns loudly and records it in the end-of-run
summary instead of continuing silently, but it cannot guess the hardware — create
the file before the first run.

## Example: an NVIDIA desktop host named `rostam`

`packages/pacman.rostam.txt`:
```
nvidia-dkms
nvidia-utils
lib32-nvidia-utils
egl-wayland
amd-ucode
```
Then on that host, `./install.sh` installs the shared list **plus** these.
(Remember to also set `gpu = "nvidia"` when `chezmoi init` prompts, so the
Hyprland env template renders the NVIDIA vars — see the top-level README.)
