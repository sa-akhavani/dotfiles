#!/usr/bin/env bash
#
# Skip to a random wallpaper now (Mod+Alt+R). Startup and the timed rotation are
# hyprpaper's own job since 0.8 — see `timeout`/`order` in hyprpaper.conf — so
# this is only the manual "next one, immediately" path, not an exec-once.
#
# hyprpaper 0.8 replaced its string IPC with a typed one and dropped most of it:
# `preload`, `unload`, `reload` and `listloaded` are all gone, leaving only
# `wallpaper` and `listactive`. This script used to call `listloaded` and
# `reload`, both of which now fail with "invalid hyprpaper request" — silently,
# because nothing surfaces stderr from a keybind.

set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# listactive prints one "<monitor>: <path>" line per output; keep just the paths.
current="$(hyprctl hyprpaper listactive | sed 's/^[^:]*: //')"

# grep -F with embedded newlines means "any of these lines", so this handles one
# monitor or several. An empty $current matches only empty lines, i.e. filters
# nothing — and grep exits 1 when it filters everything, hence the `|| true`.
# -maxdepth 1 mirrors `recursive = false` in hyprpaper.conf.
wallpaper="$(find "$WALLPAPER_DIR" -maxdepth 1 -type f | grep -vxF "$current" || true)"
wallpaper="$(printf '%s\n' "$wallpaper" | shuf -n 1)"
[[ -n "$wallpaper" ]] || exit 0

# empty monitor = every output, same as the config block
hyprctl hyprpaper wallpaper ",$wallpaper"
