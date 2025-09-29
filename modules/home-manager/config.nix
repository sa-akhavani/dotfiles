let
  configDir = ./config;
in
{
  home.file = {
    ".config/fastfetch".source = "${configDir}/fastfetch";
    ".config/btop".source = "${configDir}/btop";

    # ".config/tmux".source = "${configDir}/tmux";
    ".config/wezterm".source = "${configDir}/wezterm";
    ".config/kitty".source = "${configDir}/kitty";

    ".config/nvim".source = "${configDir}/nvim";

    ".config/hypr".source = "${configDir}/hypr";
    ".config/waybar".source = "${configDir}/waybar";
    ".config/cava".source = "${configDir}/cava";
    ".config/wofi".source = "${configDir}/wofi";
    ".config/mako".source = "${configDir}/mako";

    #      ".config/wlogout".source = "${configDir}/wlogout";
    #      ".config/swappy".source = "${configDir}/swappy";
  };
}
