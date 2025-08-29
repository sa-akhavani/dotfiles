####
# Network Manager + network-manager-applet + nmtui are alternatives
# Alternatives - iwd + iwgtk + impala (tui)
###
# sudo pacman -S iwd iwgtk impala
sudo pacman -Sy networkmanager network-manager-applet

####
# Installing dependencies and useful packages
####
sudo pacman -Sy git base-devel
sudo pacman -Sy cmake make gcc
sudo pacman -Sy fzf lsd bat
sudo pacman -Sy pacman-contrib


####
# AUR package manager - Yay
####
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si

####
yay -S nmtui nmcli
####

####
# Audio - Pipewire + Wireplumber + Coppwr + EasyEffects + Pulsemixer + Playerctl
# Pulsemixer is meant for pulseaudio but works well with pipewire too!
# https://github.com/mikeroyal/PipeWire-Guide
# https://gitlab.freedesktop.org/rncbc/qpwgraph
# https://gitlab.freedesktop.org/pipewire/helvum
# https://github.com/saivert/pwvucontrol
# Another option is qpwgraph OR Helvum
# Also check pwvucontrol
####
sudo pacman -S pipewire wireplumber
sudo pacman -S easyeffects pulsemixer
# sudo pacman -S coppwr
sudo pacman -S playerctl


####
# Xkeyboard config v2.42+ 
# Very important to have updated and correct language signs such as ZWNJ
# Zero Width Non-Joiner
# Install with pacman or copy everything in the repo below to: /usr/share/X11/xkb
# https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config
####
sudo pacman -S xkeyboard-config


####
# Terminal Wezterm + Tmux
####
yay -S wezterm-git tmux
git clone https://github.com/gpakosz/.tmux.git ~/Programs/tmux
mkdir -p ~/.config/tmux
ln -s  ~/Programs/tmux/.tmux.conf ~/.config/tmux/tmux.conf


####
# Default Shell and ohmyzsh
####
chsh -s /usr/bin/zsh # change default shell to zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" #ohmyzsh
# Install plugins
cd ~/.oh-my-zsh/custom/plugins
git clone git@github.com:zsh-users/zsh-syntax-highlighting.git
git clone git@github.com:zsh-users/zsh-autosuggestions.git

# misfortune command
yay -S misfortune


####
# Neovim
####
sudo pacman -S neovim


####
# Display Manager - Ly /SDDM
####
sudo pacman -S ly
# yay -S sddm
# sudo systemctl enable sddm


####
# Bluetooth - bluez + blueman (gui)
# https://wiki.archlinux.org/title/Bluetooth
# Check with "rfkill" command that nothing is blocked
####
sudo pacman -S bluez bluez-utils blueman


####
# XDG Desktop portal for Hyprland (must have)
####
# sudo pacman -S xdg-desktop-portal-hyprland
yay -S xdg-desktop-portal-hyprland


####
# Wayland Clipboard - wl-clipboard
# Clipboard Manager - cliphist
####
sudo pacman -S wl-clipboard cliphist


####
# Brightness Control
####
sudo pacman -S brightnessctl


####
# Notification Manager (mako/dunst)
####
# sudo pacman -S dunst
sudo pacman -S mako


####
# App Launcher
# set binding in Hyprland conf later
####
sudo pacman -S fuzzel


####
# File Managers 
## set binding in Hyprland conf later
####
sudo pacman -S thunar gvfs thunar-archive-plugin file-roller
sudo pacman -S yazi


####
# System info - Fastfetch + Btop
# Honorable mentions: conky - nitch
####
sudo pacman -S fastfetch btop


####
# Screenshot - Grom + Slurp + Swappy
####
sudo pacman -S grim slurp swappy


####
# Logout Menu
####
yay -S wlogout

####
# Lock Screen and Idle Daemon - hyprlock + hypridle
# swaylock is an alternattive
####
sudo pacman -S hyprlock hypridle


####
# Wallpaper manager
####
sudo pcaman -S swww


####
# Keychain
# https://superuser.com/questions/1727591/how-to-run-ssh-agent-in-fish-shell
# https://wiki.archlinux.org/title/SSH_keys#ssh-agent
####
sudo pacman -S keychain
# edit ~/.config/fish/conf.d/keychain.fish
# set environment variable to ssh key


####
# Remaining Must Haves
####
sudo pacman -S qt5-wayland qt6-wayland
sudo pacman -S nwg-look qt5ct qt6ct
sudo pacman -S polkit-kde-agent
# autostart it by adding this to hyprland config: exec-once=/usr/lib/polkit-kde-authentication-agent-1


####
# Waybar Setup
# Don't install waybar-git using aur
# it doesn't have support for cava module
####
sudo usermod -aG input $USER # Waybar module for keyboard status needs this
yay -S libcava #libcava is needed for waybar
yay -S waybar-cava # This is the version that has cava support

# OR, add cava support to source and build it:
# git clone https://aur.archlinux.org/waybar-git.git
# cd waybar-git
# vim PKGBUILD
# change Dcava=diabled -> Dcava=enabled
# add Dmpd=enabled
# makepkg
# Then install it using:
# pacman -U <output_package_name>




####
# Gestures - Fusuma + ydotool
####
sudo pacman -S libinput ruby ydotool
sudo gem install fusuma --no-user-instal


####
# Color picker
####
yay -S hyprpicker


####
# Fonts and Emojis
#
# https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip
# https://github.com/samuelngs/apple-emoji-linux/releases/latest/download/AppleColorEmoji.ttf
# mkdir ~/.local/share/fonts/
#
####
yay -S ttf-fira-code ttf-nerd-fonts-symbols-mono ttf-opensans
yay -S ttf-apple-emoji
yay -S vazirmatn-fonts
yay -S ttf-liberation
# yay -S vazir-code-fonts
# fc-cache -f -v # clear and regenerate font cache
# fc-list | grep "FiraCode Nerd Font" # confirming installation
# fc-list | grep "AppleColorEmoji" # confirming installation


####
# Icon theme - Papirus
####
yay -S papirus-icon-theme


####
# Fun
####
yay -S cmatrix
yay -S pipes.sh
# yay -S cava
#

####
# Applications
####
# Spotify
# yay -S spotify   # Official Client
# yay -S spotify-launcher
# pacman -S ncspot # Command Line Unofficial Spotify Client
