let configDir = ./config;
in
{
  home.file = {
      ".config/fastfetch".source = "${configDir}/fastfetch";
      ".config/btop".source = "${configDir}/btop";
      ".config/waybar".source = "${configDir}/waybar";
      ".config/tmux".source = "${configDir}/tmux";
      ".config/wezterm".source = "${configDir}/wezterm";
      ".config/cava".source = "${configDir}/cava";
      ".config/wofi".source = "${configDir}/wofi";
      ".config/mako".source = "${configDir}/mako";

#      ".config/nvim".source = "${configDir}/nvim";
#      ".config/kitty".source = "${configDir}/kitty";
#      ".config/hypr".source = "${configDir}/hypr";
#      ".config/wlogout".source = "${configDir}/wlogout";
#      ".config/swaylock".source = "${configDir}/swaylock";
#      ".config/swappy".source = "${configDir}/swappy";
#
      # ".config/swayidle".source = "${configDir}/swayidle";
      # ".config/wallpapers".source = "${configDir}/wallpapers";
  };
}
