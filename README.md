# My Developr Setup Dotfiles

My development setup tools and dotfiles.
Fast, minimal, and feature-packed, yet aesthetically pleasing environment optimized for software engineering and devops.

## Overview

| **Tool / Environment** | **Description**                                |
| ---------------------- | ---------------------------------------------- |
| **OS**                 | [NixOS](https://nixos.org/)                    |
| **Terminal**           | [WezTerm](https://github.com/wez/wezterm)      |
| **Multiplexer**        | [tmux](https://github.com/tmux/tmux)           |
| **Text Editor**        | [neovim](https://github.com/neovim/neovim)     |
| **Shell**              | [zsh](https://github.com/ohmyzsh/ohmyzsh)      |
| **Window Manager**     | [Hyprland](https://github.com/hyprwm/Hyprland) |
| **Display Manager**    | [ly](https://github.com/fairyglade/ly)         |

## Installation

To replicate my setup:

1. **Install NixOS**: Follow the [official installation guide](https://nixos.wiki/wiki/NixOS_Installation_Guide).
2. **Clone this repository.**
3. **Change `hardware-configuration.nix` file for your own `host`.**
4. **Run the `nixos-rebuild switch --flake ./` command while in the cloned repository directory.**

```bash
git clone https://github.com/sa-akhavani/dotfiles.git && cd dotfiles
sudo nixos-rebuild switch --flake ./
```

## Setup

### NixOS

I was an Ubuntu user for a long time (7+ years) but eventually decided to migrate to Arch Linux.
Loved Arch Linux because of the amount of control I had in it. But my os and packages broke multiple times due to updates which was really frustrating.
That's why I decided to switch to NixOS and try the declarative approach.

### Hyprland (Wayland)

Now that Wayland is becoming stable and lots of people are creating packages for it,
Hyprland is an amazing tiling window manager for wayland.
It's highly customizablity and native Wayland support significantly enhance my workflow compared to traditional X11 setups.

### Display Manager (Ly)

I Have tried KDE and GNOME display managers in Ubuntu and Kubuntu
But both of them are extremely bloated.
So I chose `Ly` as my display manager, keeping everything minimal.

## Shell and Prompt Engine (ZSH)

### ZSH

- ZSH with Oh My ZSH

## Terminal and Multiplexer (Wezterm, Tmux)

### Wezterm

- Wezterm: a GPU-Accelared cross-platform terminal emulator that supports font ligatures
- Tmux: Highly customizable terminal multiplexer

### Editor (Neovim)

- My go-to editor is Neovim, a highly customizable and modern vim-based editor.
- I mainly use Neovim but I also other IDEs if I am working on a project with a huge codebase.

## ToDo

#### Waybar

- [ ] Fix waybar keyboard layout change in multiple keyboards

#### Tmux

- [ ] Fix tmux continuum plugin issues
- [ ] Update tmux status bar

#### Misc

- Use walker app manager instead of fuzzel
- Fix jack 3.5 output not being detected
- Modularize home.nix and move most of it to `modules/programs`

## Misc

### Neovim and Tmux

I should read this: https://www.bugsnag.com/blog/tmux-and-vim/

### Spotify (Linux)

While setting up the Spotify client for Linux, I encountered a few quirks.
If you're using NetworkManager with iwd together (don't do that:D),
you have to stop NetworkManager service to be able to use spotify.

Also, hyprland windows don't have a menu. bar. To toggle offline mode, you can press `Ctrl-Shift-o`.

### Fonts

I use `FiraCode` font mainly.
Do not install patched nerdfonts. I install FiraCode alone, then install
`Symbols Nerd Font Mono` separately from their releases.
check: https://github.com/ryanoasis/nerd-fonts/releases

### Three Finger Drag Gesture

You need to install `ydotool` and `fusuma` and configure them.

### Error: Path not found issue

If you are using `nix-rebuild switch` but having issues with path not found for modules that are defined in a relative path and imported in configuration.nix or flake.nix, the issue is that those files are not "commited" or "tracked" in the git repository. Commit or add them and then run the command again!
