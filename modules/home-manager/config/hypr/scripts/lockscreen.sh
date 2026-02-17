#!/usr/bin/env bash

# copy a random image from the Lockscreen directory to the .cache directory
mkdir -p ~/.cache/wallpapers
cp ~/Pictures/Lockscreen/$(ls ~/Pictures/Lockscreen | shuf -n 1) ~/.cache/wallpapers/lock.png
hyprlock

