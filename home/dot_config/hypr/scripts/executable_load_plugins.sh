#!/usr/bin/env bash
sleep 0.8 # Give Hyprland a moment to fully start
# On Arch, hyprsplit is installed/enabled via hyprpm (see install.sh).
# hyprpm reload loads all currently-enabled plugins.
hyprpm reload -n
