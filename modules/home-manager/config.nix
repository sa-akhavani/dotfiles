{ inputs, pkgs, ... }:

let
  configDir = ./config;
  hyprsplitLib = "${pkgs.hyprlandPlugins.hyprsplit}/lib/libhyprsplit.so";
in
{
  home.file = {
    ".config/fastfetch".source = "${configDir}/fastfetch";
    ".config/btop".source = "${configDir}/btop";
    ".config/wezterm".source = "${configDir}/wezterm";
    ".config/nvim".source = "${configDir}/nvim";
    ".config/hypr".source = "${configDir}/hypr";
    ".config/waybar".source = "${configDir}/waybar";
    ".config/cava".source = "${configDir}/cava";
    ".config/wofi".source = "${configDir}/wofi";
    ".config/mako".source = "${configDir}/mako";

    # Create symlink to the plugin
    ".config/hypr-plugins/hyprsplit.so".source = hyprsplitLib;
  };
}
