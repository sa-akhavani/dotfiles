{ pkgs, pkgs-unstable, ... }:

{

  home.packages = [

    # Dev stuff
    pkgs.gcc
    pkgs.nodejs_22
    pkgs.python313
    # pkgs.rustc
    # pkgs.cargo
    pkgs.rustup

    # LSP, Linters, Formatters
    pkgs.ruff # Python linter and code formatter
    pkgs.hyprls # Hyprland LSP
    pkgs.nil # Nix LSP
    pkgs.nixfmt-rfc-style # Nix formatter
    pkgs.typescript-language-server # Typescript LSP
    pkgs.eslint_d # Linter for js and ts
    pkgs.prettierd # JavaScript, TypeScript, GraphQL, CSS, HTML and YAML formatter
    pkgs.nodePackages.js-beautify # JS formatter
    pkgs.lua-language-server # Lua LSP
    pkgs.stylua # Lua formatter
    pkgs.clang-tools # C++ LSP and formatter
    # pkgs.rustfmt # Rust formatter
    # pkgs.rust-analyzer # Rust LSP
    pkgs.codespell # Spell checker

    # Terminal Tools
    pkgs.zsh
    pkgs.fastfetch
    pkgs.zip
    pkgs.unzip
    pkgs.fzf
    pkgs.tree
    pkgs.lsd # Fancy ls
    pkgs.ripgrep # Fast grep Alternative
    pkgs.fd # Fast find Alternative
    pkgs.luarocks # used for neovim lazy package manager
    pkgs.keychain

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
    pkgs.waybar
    pkgs.wlogout
    pkgs.lm_sensors # Reading hardware sensors

    ## App Launcher
    pkgs.fuzzel
    pkgs.walker
    # pkgs.rofi
    # pkgs.anyun

    # Notification Manager
    pkgs.mako

    ## File Manager
    pkgs.yazi # Terminal file manager
    pkgs.nemo # File Manager
    # pkgs.xfce.thunar	# File Manager
    pkgs.viewnior # Image Viewer
    pkgs.zathura # PDF Viewer

    # Audio
    pkgs.easyeffects # Audio effects for PipeWire applications
    pkgs.playerctl # Control media players from the command-line

    # Networking
    pkgs.openvpn

    ## Misc
    # pkgs.swappy 	# Screenshot editing tool
    pkgs.cava
    pkgs.socat # smart borders dependency
    pkgs.jq # smart borders dependency
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
    pkgs.spotify

    # Download Managers
    pkgs.axel

    # Utils
    pkgs.gparted # GUI Formatting tool
    pkgs.ntfs3g # NTFS Formatting driver
    #    pkgs.catppuccin-cursors.macchiatoBlue
    #    pkgs.catppuccin-gtk
    #    pkgs.papirus-folders
  ];

}
