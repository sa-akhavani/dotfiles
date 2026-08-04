# Package lists

`install.sh` builds the install set from these plain-text files (one package per
line; blank lines and `#` comments ignored):

| File | Scope |
| --- | --- |
| `pacman.txt` | official-repo packages installed on **every** host |
| `aur.txt` | AUR packages installed on **every** host |
| `pacman.<hostname>.txt` | extra official-repo packages for one host (optional) |
| `aur.<hostname>.txt` | extra AUR packages for one host (optional) |

`<hostname>` matches `hostnamectl --static`. Host files are **additive** — they
are appended to the shared lists, never replace them.

## Example: an NVIDIA desktop host named `rostam`

`packages/pacman.rostam.txt`:
```
nvidia-dkms
nvidia-utils
lib32-nvidia-utils
egl-wayland
```
Then on that host, `./install.sh` installs the shared list **plus** these.
(Remember to also set `gpu = "nvidia"` when `chezmoi init` prompts, so the
Hyprland env template renders the NVIDIA vars — see the top-level README.)
