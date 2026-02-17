# My Developr Setup Dotfiles

My development setup tools and dotfiles.

## Overview

| **Tool / Environment** | **Description**                                |
| ---------------------- | ---------------------------------------------- |
| **OS**                 | [NixOS](https://nixos.org/)                    |
| **Terminal**           | [WezTerm](https://github.com/wez/wezterm)      |
| **Multiplexer**        | [tmux](https://github.com/tmux/tmux)           |
| **Text Editor**        | [neovim](https://github.com/neovim/neovim)     |
| **Shell**              | [zsh](https://github.com/ohmyzsh/ohmyzsh)      |
| **Window Manager**     | [Hyprland](https://github.com/hyprwm/Hyprland) |
| **Display Manager**    | [tuigreet](https://github.com/apognu/tuigreet) |

## Installation

To replicate my setup:

1. **Install NixOS**: Follow the [official installation guide](https://nixos.wiki/wiki/NixOS_Installation_Guide) or [manual](https://nixos.org/manual/nixos/stable/#ch-installation).
2. **Add a new user to configuration.nix, add `git` and `vim` to pkgs.**
3. **Clone this repository.**
4. **Change `hardware-configuration.nix` file for your own `host`.**
5. **Add the new hostname to flake.nix**
6. **Change version number if necessary**
7. **Run the `nixos-rebuild switch --flake ./` command while in the cloned repository directory.**
8. **Copy your Pictures folder to your home directory.**

```bash
git clone https://github.com/sa-akhavani/dotfiles.git && cd dotfiles
Generate new pair of ssh keys `ssh-keygen -t ed25519`
sudo nixos-rebuild switch --flake .#<hostname>
cp -r ./Pictures ~/
```

## NixOS

I was an Ubuntu user for a long time (7+ years) but eventually decided to migrate to Arch Linux.
Loved Arch Linux because of the amount of control I had in it. But my os and packages broke multiple times due to updates which was really frustrating.
That's why I decided to switch to NixOS and try the declarative approach.

## ToDo

#### Tmux

- [ ] Fix tmux continuum plugin issues
- [ ] Update tmux status bar

#### Misc

- Use walker app manager instead of fuzzel
- Modularize home.nix and move most of it to `modules/programs`

#### Spotify (Linux)

While setting up the Spotify client for Linux, I encountered a few quirks.
If you're using NetworkManager with iwd together (don't do that:D),
you have to stop NetworkManager service to be able to use spotify.

Also, hyprland windows don't have a menu. bar. To toggle offline mode, you can press `Ctrl-Shift-o`.

#### Fonts

I use `FiraCode` font mainly.
Do not install patched nerdfonts. I install FiraCode alone, then install
`Symbols Nerd Font Mono` separately from their releases.
check: https://github.com/ryanoasis/nerd-fonts/releases

#### Three Finger Drag Gesture

You need to install `ydotool` and `fusuma` and configure them.

#### Error: Path not found issue

If you are using `nix-rebuild switch` but having issues with path not found for modules that are defined in a relative path and imported in configuration.nix or flake.nix, the issue is that those files are not "commited" or "tracked" in the git repository. Commit or add them and then run the command again!
