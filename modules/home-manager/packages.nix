{ pkgs, pkgs-unstable, ... }:

{

  home.packages = [

    # Dev stuff
    pkgs.gcc

    # Terminal Tools
    pkgs.zsh
    pkgs.fastfetch
    pkgs.zip
    pkgs.fzf
    pkgs.tree
    pkgs.nnn # terminal file manager

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

    ## App Launcher
    pkgs.fuzzel
    pkgs.walker
    # pkgs.rofi
    # pkgs.anyun

    pkgs.wlogout
    # pkgs.swappy # screenshot editing tool
    pkgs.cava
    pkgs.wofi
    pkgs.mako
    
    # Work stuff
#    pkgs.obsidian
#    pkgs.teams-for-linux
#    pkgs.zoom-us
#    pkgs.libreoffice-qt
#    pkgs.hunspell
 
    # Connectivity
    pkgs.blueberry

    # Social
    pkgs-unstable.telegram-desktop
    pkgs-unstable.vesktop
#    pkgs.discord

    # Download Managers

    # Utils
#    pkgs.viewnior
#    pkgs.catppuccin-cursors.macchiatoBlue
#    pkgs.catppuccin-gtk
#    pkgs.papirus-folders
  ];

}
