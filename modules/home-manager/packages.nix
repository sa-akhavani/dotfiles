{ pkgs, pkgs-unstable, ... }:

{

  home.packages = [

    # Dev stuff
    pkgs.gcc
    pkgs.nodejs_22
    pkgs.python313

    # LSP Servers
    pkgs.ruff		# Extremely fast Python linter and code formatter

    pkgs.hyprls  # Hyprland LSP
    pkgs.nil                  # Nix
    pkgs.nixfmt-rfc-style  # Nix formatter

    pkgs.typescript-language-server	# Typescript
    pkgs.prettierd	# JavaScript, TypeScript, GraphQL, CSS, HTML and YAML

    pkgs.lua-language-server  # Lua
    pkgs.stylua                     # Lua formatter

    pkgs.rustfmt                  # Rust formatter
   

    # Terminal Tools
    pkgs.zsh
    pkgs.fastfetch
    pkgs.zip
    pkgs.fzf
    pkgs.tree
    pkgs.lsd          # Fancy ls

    # Hypr Ecosystem
    pkgs.hyprlock
    pkgs.hyprpaper
    pkgs.hypridle
    pkgs.hyprsunset
    pkgs.hyprpicker
    pkgs.hyprshot
    pkgs.hyprpolkitagent

    # Clipboard
    pkgs.wl-clipboard
    pkgs.cliphist

    # GUI Utilities
    ## Status Bar
    pkgs.ashell
    pkgs.waybar
    pkgs.wlogout
    pkgs.lm_sensors	# Reading hardware sensors

    ## App Launcher
    pkgs.fuzzel
    pkgs.walker
    # pkgs.rofi
    # pkgs.anyun

    # Notification Manager
    pkgs.mako		

    ## File Manager
    pkgs.nnn 		# Terminal file manager
    pkgs.nemo		# File Manager
    # pkgs.xfce.thunar	# File Manager
    pkgs.viewnior 	# Image Viewer
 
    # Audio
    pkgs.easyeffects	# Audio effects for PipeWire applications

    ## Misc
    # pkgs.swappy 	# Screenshot editing tool
    pkgs.cava
#    pkgs.wofi

    # Work stuff
    pkgs.obsidian
    pkgs.teams-for-linux
    pkgs.zoom-us
#    pkgs.libreoffice-qt
#    pkgs.hunspell
 
    # Social
    pkgs-unstable.telegram-desktop
    pkgs-unstable.vesktop
#    pkgs.discord

    # Players
    pkgs.jellyfin-media-player
    pkgs.vlc

    # PDF Viewer
    pkgs.zathura

    # Download Managers
    pkgs.axel

    # Utils
#    pkgs.catppuccin-cursors.macchiatoBlue
#    pkgs.catppuccin-gtk
#    pkgs.papirus-folders
  ];

}
