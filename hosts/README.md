# `hosts/<hostname>/` — the per-host layer

One directory per machine, named after `hostnamectl --static`. Everything that is
true of exactly one machine lives in its directory, and nothing else does.

```
hosts/<hostname>/
  pacman.txt      extra official-repo packages   (optional, but see below)
  aur.txt         extra AUR packages             (optional)
  npm.txt         extra global npm packages      (optional)
  etc/…           extra or overriding /etc files (optional)
  services.txt    extra systemd units            (optional)
```

Same filenames, same formats, same semantics as `shared/` — see
`shared/README.md` for how the lists are parsed and how `etc/` is copied.

Every file is **optional and additive**. `install.sh` reads `shared/` first and
this directory second, so per-host packages are appended to the shared list and a
per-host `/etc` file at the same path as a shared one is applied *last* and
therefore wins.

## Known hosts

| Host | Hardware | Role |
| --- | --- | --- |
| `rostam` | Desktop PC — AMD CPU, NVIDIA RTX 2080 Super, dual-boots Windows | gaming, video calls, OBS streaming |
| `sohrab` | Intel NUC — Intel integrated graphics (i915), ext4, systemd-boot | everyday workstation, no gaming |
| `giv` | Dell laptop — Intel CPU, onboard Intel graphics | portable; Steam for light play only |

User is `ali` on all three.

## GPU drivers, microcode and other per-host packages

Graphics drivers are deliberately **not** in the shared lists: `steam` (and
Vulkan generally) depends on virtual packages like `vulkan-driver` /
`lib32-vulkan-driver`, and with `--noconfirm` pacman resolves those to whichever
provider comes first — possibly another vendor's driver. Name the right ones
explicitly so they land in the same pacman transaction:

| GPU | packages |
| --- | --- |
| Intel | `vulkan-intel` `lib32-mesa` `lib32-vulkan-intel` `intel-media-driver` |
| AMD | `vulkan-radeon` `lib32-mesa` `lib32-vulkan-radeon` |
| NVIDIA | `nvidia-open-dkms` `linux-headers` `nvidia-utils` `lib32-nvidia-utils` `egl-wayland` |

The `lib32-*` rows are only needed where 32-bit clients run — in practice, where
`steam` is declared. `sohrab` deliberately declares neither.

**NVIDIA is `nvidia-open-*` now**, not `nvidia` / `nvidia-dkms`: NVIDIA dropped
the proprietary kernel modules for Turing and newer, and Arch removed those
packages from `[extra]` entirely. Turing (RTX 20xx) and later are supported by
the open modules. `-dkms` needs `linux-headers` for every installed kernel;
plain `nvidia-open` is prebuilt for the stock `linux` kernel only.

CPU **microcode** belongs here for the same reason — it is vendor-specific:
`intel-ucode` or `amd-ucode`. (`archinstall` installs it during a fresh install;
declaring it keeps a manual install, and any later re-run, honest.)

A host with no matching `hosts/<hostname>/pacman.txt` therefore gets **no** GPU
drivers and **no** microcode. `install.sh` warns loudly and records it in the
end-of-run summary rather than continuing silently, but it cannot guess the
hardware — create the file before the first run.

## Adding a new host

1. `mkdir hosts/$(hostnamectl --static)`
2. Create `pacman.txt` with that machine's GPU drivers and microcode from the
   table above. This is the one step that is not optional.
3. Add anything else it needs — `aur.txt`, `etc/`, `services.txt` — only if it
   genuinely differs from every other machine.
4. `./bin/validate-packages.sh` (checks every host's lists, not just this one),
   then `./install.sh --dry-run`.
5. When `chezmoi init` prompts, answer `gpu` to match — it feeds
   `home/dot_config/hypr/env_nvidia.conf.tmpl`. See the top-level README.

`hosts/rostam/pacman.txt` is the worked example to copy from — an NVIDIA + AMD
desktop, with the GPU, microcode, gaming and OBS blocks each commented with
*why* that package is there.

## Pick the narrowest layer that works

A per-host directory is only one of four ways to express a difference. In order
of preference:

| Difference | Goes in |
| --- | --- |
| A package | `hosts/<host>/pacman.txt` or `aur.txt` |
| An `/etc` file or a service | `hosts/<host>/etc/…`, `hosts/<host>/services.txt` |
| Same `$HOME` file, different contents | make it a chezmoi `*.tmpl`, branch on `.chezmoi.hostname` or a `[data]` key |
| A `$HOME` file that shouldn't exist at all | `home/.chezmoiignore` |

Machine-local *answers* (the `gpu` prompt) live in
`~/.config/chezmoi/chezmoi.toml`, which is not in this repo — so it is also the
right place for host secrets.
