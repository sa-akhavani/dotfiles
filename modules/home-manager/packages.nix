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
    pkgs.xfce.thunar	# File Manager
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

    # Download Managers
    pkgs.axel

    # Utils
#    pkgs.catppuccin-cursors.macchiatoBlue
#    pkgs.catppuccin-gtk
#    pkgs.papirus-folders
  ];

}
