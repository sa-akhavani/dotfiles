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
# Package lists (loaded from packages/)
########################################
# Package names live in plain-text files so each host can differ:
#   packages/pacman.txt            shared official-repo packages
#   packages/aur.txt               shared AUR packages
#   packages/pacman.<hostname>.txt per-host official extras (optional)
#   packages/aur.<hostname>.txt    per-host AUR extras (optional)
# One package per line; blank lines and #comments ignored.

PKG_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/packages"
HOSTNAME_SHORT="$(hostnamectl --static 2>/dev/null || cat /etc/hostname 2>/dev/null || echo unknown)"

# Read "<base>.txt" + "<base>.<host>.txt", stripping comments/blank lines.
read_pkg_list() {
  local base="$1" f
  for f in "$PKG_DIR/$base.txt" "$PKG_DIR/$base.$HOSTNAME_SHORT.txt"; do
    [[ -f "$f" ]] && sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$f"
  done
}

info "Loading package lists for host '$HOSTNAME_SHORT' from $PKG_DIR"
# Package names never contain spaces/globs, so word-splitting is safe here.
# shellcheck disable=SC2207
PACMAN_PKGS=( $(read_pkg_list pacman) )
# shellcheck disable=SC2207
AUR_PKGS=( $(read_pkg_list aur) )
[[ -f "$PKG_DIR/pacman.$HOSTNAME_SHORT.txt" ]] && info "  + per-host pacman extras applied"
[[ -f "$PKG_DIR/aur.$HOSTNAME_SHORT.txt" ]] && info "  + per-host AUR extras applied"

# --- npm globals (formatters/linters that live in npm) ----------------------
NPM_PKGS=(
  eslint_d prettier js-beautify
)

########################################
# 4b/4c. Install packages
########################################
# Resilient installers: try the whole list at once (fast), and if that fails
# (e.g. a renamed/removed package name), fall back to one-by-one so every good
# package still installs and only the bad names are reported. This prevents a
# single bad name from aborting the script under `set -e`.
pac_install() {
  sudo pacman -S --needed --noconfirm "$@" && return
  warn "Batch pacman install failed; retrying individually…"
  local p
  for p in "$@"; do
    sudo pacman -S --needed --noconfirm "$p" || warn "pacman: could not install '$p' (skipped)"
  done
}
aur_install() {
  local p
  for p in "$@"; do
    yay -S --needed --noconfirm "$p" || warn "AUR: could not install '$p' (skipped)"
  done
}

info "Installing official (pacman) packages"
pac_install "${PACMAN_PKGS[@]}"

if [[ "$NO_AUR" -eq 0 ]]; then
  info "Installing AUR packages"
  aur_install "${AUR_PKGS[@]}"
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
