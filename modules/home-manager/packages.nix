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

    # GUI Tools
    pkgs.waybar
    pkgs.fuzzel
    pkgs.wlogout
    pkgs.hyprlock
    # pkgs.swaylock
    pkgs.swappy
    pkgs.cava
    pkgs.tree
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
#    pkgs.hyprshot
#    pkgs.catppuccin-cursors.macchiatoBlue
#    pkgs.catppuccin-gtk
#    pkgs.papirus-folders
  ];

}
