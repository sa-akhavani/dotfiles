{ pkgs, pkgs-unstable, ... }:

{

  home.packages = [

    # Dev stuff
    pkgs.gcc

    # Tools
    pkgs.fastfetch
    pkgs.wlogout
    pkgs.swaylock
    pkgs.swappy
    pkgs.cava
    pkgs.tree
    pkgs.zip
    pkgs.fzf
    pkgs.wofi
    pkgs.mako
    
    
    # Work stuff
    pkgs.obsidian
    pkgs.teams-for-linux
    pkgs.zoom-us
    pkgs.libreoffice-qt
    pkgs.hunspell
 
    # Bluetooth
    pkgs.blueberry

    # Social
    pkgs.telegram-desktop
    pkgs-unstable.vesktop
    pkgs.discord

    # Download Managers

    # Utils
    pkgs.viewnior
    pkgs-unstable.hyprshot
    pkgs.catppuccin-cursors.macchiatoBlue
    pkgs.catppuccin-gtk
    pkgs.papirus-folders
  ];

}
