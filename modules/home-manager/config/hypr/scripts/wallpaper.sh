#!/bin/bash

# Wallpapers Directory
dir=~/Pictures/Wallpaper
# dir="${HOME}/.local/share/walls"

# Get the current desktop session
current_session=$XDG_CURRENT_DESKTOP

# Define the function for setting wallpapers in Hyprland
BG="$(find "$dir" -name '*.jpg' -o -name '*.png' | shuf -n1)"

# SWWW
PROGRAM="swww-daemon"
trans_type="simple"

# Check if the program is running
if pgrep "$PROGRAM" >/dev/null; then
  swww img "$BG" --transition-fps 244 --transition-type $trans_type --transition-duration 1
else
  swww init && swww img "$BG" --transition-fps 244 --transition-type $trans_type --transition-duration 1
fi

