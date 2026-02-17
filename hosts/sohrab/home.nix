{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  inputs,
  ...
}:

{

  imports = [
    ../../modules/home-manager/config.nix
    ../../modules/home-manager/packages.nix
    ../../modules/programs/default.nix
  ];

  home.username = "ali";
  home.homeDirectory = "/home/ali";

  home.packages = with pkgs; [

  ];

  wayland.windowManager.hyprland = {
    enable = true;
    plugins = [
      inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
    ];
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 30;
  };

  home.file = {

  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.stateVersion = "25.11"; # Please read the comment before changing.
}
