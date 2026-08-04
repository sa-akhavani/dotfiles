#!/usr/bin/env bash
#
# Arch Linux post-install setup for Ali's dotfiles.
#
# Run this AFTER a base Arch install (see README.md), as the normal user `ali`
# with sudo privileges. It is idempotent: safe to re-run. It installs every
# package/service that used to live in the NixOS config on the `master` branch
# (modules/nixos/* and modules/home-manager/packages.nix), via pacman + AUR.
#
# Dotfiles themselves are managed separately by chezmoi (see README.md).
#
# Usage:
#   ./install.sh            # everything
#   ./install.sh --no-aur   # skip AUR packages (pacman + services only)
#
set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
NO_AUR=0
[[ "${1:-}" == "--no-aur" ]] && NO_AUR=1

info() { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

require_not_root() {
  if [[ "$EUID" -eq 0 ]]; then
    echo "Do NOT run this script as root. Run as your user; it calls sudo itself." >&2
    exit 1
  fi
}
require_not_root

########################################
# 4a. Bootstrap: base tools + yay (AUR)
########################################
info "Updating system and installing base tooling"
sudo pacman -Syu --needed --noconfirm base-devel git

install_yay() {
  if command -v yay >/dev/null 2>&1; then return; fi
  info "Building yay (AUR helper)"
  local tmp
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}
[[ "$NO_AUR" -eq 0 ]] && install_yay

########################################
# Package lists
########################################

# --- Official repos (pacman) ------------------------------------------------
PACMAN_PKGS=(
  # Core system tools (from configuration.nix systemPackages)
  vim neovim wget rsync btop

  # Terminal (wezterm config present in dotfiles)
  wezterm

  # Shell + terminal tools (packages.nix)
  zsh fastfetch zip unzip fzf tree lsd ripgrep fd luarocks keychain psmisc bat pacman-contrib

  # Shell/editor config stack (dotfiles managed with chezmoi)
  chezmoi tmux git-delta zsh-autosuggestions zsh-syntax-highlighting

  # GTK dark theme referenced by ~/.config/gtk-*/settings.ini
  gnome-themes-extra

  # Dev toolchains
  gcc nodejs npm postgresql python rustup uv ruff

  # LSPs / linters / formatters
  typescript-language-server lua-language-server clang codespell

  # Wayland / Hyprland core
  hyprland hyprlock hyprpaper hypridle hyprpicker
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  qt5-wayland qt6-wayland polkit
  brightnessctl grim slurp swappy
  wl-clipboard cliphist

  # Desktop shell / utilities
  waybar lm_sensors fuzzel mako
  nwg-look qt5ct qt6ct
  yazi nemo gvfs viewnior zathura zathura-pdf-mupdf

  # Audio (services/audio.nix)
  pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber rtkit
  pamixer pavucontrol easyeffects playerctl pulsemixer

  # Bluetooth (services/bluetooth.nix)
  bluez bluez-utils blueman

  # Networking (networking/*) + SSH (services/ssh.nix)
  networkmanager network-manager-applet openssh fail2ban openvpn

  # Virtualisation (virtualisation/docker.nix)
  docker docker-compose docker-buildx

  # Fonts (fonts/default.nix)
  noto-fonts noto-fonts-cjk noto-fonts-emoji
  ttf-fira-code ttf-liberation
  xkeyboard-config

  # Session / misc (configuration.nix)
  firefox dconf flatpak gnupg mtr

  # Display manager: greetd + tuigreet (all in extra repo)
  greetd greetd-tuigreet

  # Apps available in official repos (packages.nix)
  telegram-desktop signal-desktop vlc discord obsidian axel
  cava socat jq gparted ntfs-3g
)

# --- AUR (yay) --------------------------------------------------------------
AUR_PKGS=(
  # Fonts
  ttf-firacode-nerd ttf-vazir

  # Hypr ecosystem extras
  hyprsunset hyprshot hyprpolkitagent wlogout 

  # GTK/cursor theme referenced by ~/.config/gtk-*/settings.ini
  bibata-cursor-theme

  # App launcher + waybar-with-cava
  walker-bin waybar-cava libcava

  # IDEs / agents
  claude-code visual-studio-code-bin cursor-bin

  # Work / social / media (packages.nix)
  postman-bin teams-for-linux zoom slack-desktop
  jellyfin-media-player spotify google-chrome

  # Editor tooling (LSP / formatters not in official repos)
  hyprls stylua

  # Python tool
  arxiv-latex-cleaner
)

# --- npm globals (formatters/linters that live in npm) ----------------------
NPM_PKGS=(
  eslint_d prettier js-beautify
)

########################################
# 4b/4c. Install packages
########################################
info "Installing official (pacman) packages"
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

if [[ "$NO_AUR" -eq 0 ]]; then
  info "Installing AUR packages"
  yay -S --needed --noconfirm "${AUR_PKGS[@]}" || warn "Some AUR packages failed; review the output above."
else
  warn "Skipping AUR packages (--no-aur)."
fi

info "Installing global npm tooling"
sudo npm install -g "${NPM_PKGS[@]}" || warn "npm global install had issues (is nodejs installed?)."

info "Adding rustup components"
rustup default stable || true
rustup component add rust-analyzer rustfmt clippy || true

########################################
# Groups, shell
########################################
info "Configuring user groups and default shell for $USER_NAME"
sudo usermod -aG wheel,input,video,docker "$USER_NAME"
if [[ "$(getent passwd "$USER_NAME" | cut -d: -f7)" != "/usr/bin/zsh" ]]; then
  sudo chsh -s /usr/bin/zsh "$USER_NAME"
fi

########################################
# Shell framework: oh-my-zsh + tmux TPM
########################################
info "Installing oh-my-zsh (unattended)"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

info "Installing tmux plugin manager (TPM)"
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

########################################
# System config files (/etc)
########################################
info "Writing /etc config files"

# greetd -> tuigreet -> Hyprland  (from configuration.nix greetd block)
sudo mkdir -p /etc/greetd
sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --cmd Hyprland"
user = "greeter"
EOF

# Bluetooth tweaks (from services/bluetooth.nix)
sudo mkdir -p /etc/bluetooth
sudo tee /etc/bluetooth/main.conf >/dev/null <<'EOF'
[General]
Experimental = true
FastConnectable = true

[Policy]
AutoEnable = true
EOF

# SSH hardening (from services/ssh.nix)
sudo mkdir -p /etc/ssh/sshd_config.d
sudo tee /etc/ssh/sshd_config.d/10-dotfiles.conf >/dev/null <<EOF
Port 22
PasswordAuthentication no
PermitRootLogin no
AllowUsers $USER_NAME
EOF

########################################
# Enable services
########################################
info "Enabling system services"
# Resilient enable: a missing unit warns instead of aborting the whole script
# (important under `set -e`).
enable_service() {
  if systemctl list-unit-files "$1" >/dev/null 2>&1 && systemctl cat "$1" >/dev/null 2>&1; then
    sudo systemctl enable "$1" || warn "Failed to enable $1"
  else
    warn "Service $1 not found (package missing?); skipping enable."
  fi
}
enable_service greetd.service
enable_service NetworkManager.service
enable_service bluetooth.service
enable_service sshd.service
enable_service fail2ban.service

# Docker (rootless, matching virtualisation/docker.nix)
sudo systemctl disable docker.service 2>/dev/null || true   # prefer rootless
if command -v dockerd-rootless-setuptool.sh >/dev/null 2>&1; then
  systemctl --user enable docker.service 2>/dev/null || true
  dockerd-rootless-setuptool.sh install || warn "rootless docker setup needs a re-login to finish."
fi

# Flatpak + flathub
if command -v flatpak >/dev/null 2>&1; then
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
fi

info "Base install done."
cat <<'NEXT'

Next steps (see README.md for detail):
  1. Apply the dotfiles with chezmoi (this repo is the chezmoi source):
       chezmoi init --apply --source ~/dotfiles
     You'll be asked once for this host's GPU vendor (intel/amd/nvidia).
     Subsequent changes:  edit files, then `chezmoi apply` (aliased to `update`).
  2. Log out / reboot -> greetd -> Hyprland.
  3. In the Hyprland session: open tmux and press <prefix> + I to install tmux plugins (TPM).
NEXT
