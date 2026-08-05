#!/usr/bin/env bash
#
# Arch Linux post-install setup for dotfiles.
#
# Run this AFTER a base Arch install (see README.md), as the normal user `ali`
# with sudo privileges. It is idempotent: safe to re-run. Uses pacman + AUR.
#
# Dotfiles themselves are managed separately by chezmoi (see README.md).
#
# Usage:
#   ./install.sh            # everything
#   ./install.sh --no-aur   # skip AUR packages (pacman + services only)
#   ./install.sh --dry-run  # print what would change, touch nothing
#

set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
NO_AUR=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
Arch Linux post-install setup. Run as your normal user; it calls sudo itself.

  ./install.sh            packages, /etc files, services — everything
  ./install.sh --no-aur   official-repo packages only (skips yay and the AUR)
  ./install.sh --dry-run  print every change that would be made, apply none
  ./install.sh --help     this text

Dotfiles are separate: apply them with chezmoi (see README.md).
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --no-aur)      NO_AUR=1 ;;
    --dry-run|-n)  DRY_RUN=1 ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)" >&2; exit 1 ;;
  esac
done

info() { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

# Every command that changes system state goes through `run`, so --dry-run can
# print it instead of executing it. Read-only probes (pacman-conf, getent,
# `systemctl cat`, …) are left un-wrapped on purpose: they must still run for
# the dry-run output to describe *this* host rather than a hypothetical one.
run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '      \033[1;34m[dry-run]\033[0m %s\n' "$*"
    return 0
  fi
  "$@"
}

# Read-only `sudo`, used for comparing against files under /etc that the user
# may not be able to read. Skipped entirely in dry-run mode so the whole script
# can be previewed without a password; an unreadable file then simply shows up
# as one that would be written.
sudo_ro() {
  if [[ "$DRY_RUN" -eq 1 ]]; then "$@"; else sudo "$@"; fi
}

require_not_root() {
  if [[ "$EUID" -eq 0 ]]; then
    echo "Do NOT run this script as root. Run as your user; it calls sudo itself." >&2
    exit 1
  fi
}
require_not_root

########################################
# Repo paths + this host's identity
########################################
REPO_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
PKG_DIR="$REPO_DIR/packages"
SYSTEM_DIR="$REPO_DIR/system"
HOSTNAME_SHORT="$(hostnamectl --static 2>/dev/null || cat /etc/hostname 2>/dev/null || echo unknown)"

# Read every file given that exists, stripping comments/blank lines. Used for
# both the package lists and the service list.
# The trailing `return 0` is load-bearing: a missing per-host file makes the
# last `[[ -f ]]` test fail, and without it the function's non-zero status
# would abort the whole script (via `set -e`) at the assignments below.
read_list() {
  local f
  for f in "$@"; do
    if [[ -f "$f" ]]; then
      sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$f"
    fi
  done
  return 0
}

########################################
# 4a. Bootstrap: multilib + base tools + yay (AUR)
########################################
# multilib (32-bit packages) must be enabled before the first -Syu, since
# `steam` and the lib32-* graphics drivers live there.
enable_multilib() {
  if pacman-conf --repo-list 2>/dev/null | grep -qx multilib; then
    info "multilib repo already enabled"
    return
  fi
  info "Enabling the [multilib] repo in /etc/pacman.conf"
  run sudo cp -n /etc/pacman.conf /etc/pacman.conf.dotfiles-bak
  # Uncomment the two lines of the [multilib] section. The `^#\[multilib\]$`
  # anchor deliberately does not match `#[multilib-testing]`, which stays off.
  run sudo sed -i '/^#\[multilib\]$/,/^#Include/ s/^#//' /etc/pacman.conf
  # Nothing was edited in dry-run mode, so re-checking would always "fail".
  # An explicit `if` rather than `[[ … ]] && return`: under `set -e` a false
  # test as the function's last command would make the function return 1.
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi
  if ! pacman-conf --repo-list 2>/dev/null | grep -qx multilib; then
    warn "Could not enable multilib automatically — uncomment the [multilib]"
    warn "section of /etc/pacman.conf by hand, then re-run this script."
    FAILED_EXTRA+=("multilib: not enabled (steam/lib32-* will be skipped)")
    return
  fi
}
# Populated before FAILED exists, so keep it separate and merge in the summary.
FAILED_EXTRA=()
enable_multilib

info "Updating system and installing base tooling"
# Plain -Syu is enough right after enabling multilib: pacman syncs every
# configured repo's db, including the newly added one.
run sudo pacman -Syu --needed --noconfirm base-devel git

install_yay() {
  if command -v yay >/dev/null 2>&1; then return; fi
  info "Building yay (AUR helper)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run "git clone https://aur.archlinux.org/yay.git && makepkg -si (in a temp dir)"
    return 0
  fi
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
#   packages/npm.txt               shared global npm packages
#   packages/pacman.<hostname>.txt per-host official extras (optional)
#   packages/aur.<hostname>.txt    per-host AUR extras (optional)
#   packages/npm.<hostname>.txt    per-host npm extras (optional)
# One package per line; blank lines and #comments ignored.

# Read "<base>.txt" + "<base>.<host>.txt".
read_pkg_list() {
  read_list "$PKG_DIR/$1.txt" "$PKG_DIR/$1.$HOSTNAME_SHORT.txt"
}

info "Loading package lists for host '$HOSTNAME_SHORT' from $PKG_DIR"
# Package names never contain spaces/globs, so word-splitting is safe here.
# shellcheck disable=SC2207
PACMAN_PKGS=( $(read_pkg_list pacman) )
# shellcheck disable=SC2207
AUR_PKGS=( $(read_pkg_list aur) )
# shellcheck disable=SC2207
NPM_PKGS=( $(read_pkg_list npm) )
if [[ -f "$PKG_DIR/pacman.$HOSTNAME_SHORT.txt" ]]; then
  info "  + per-host pacman extras applied"
else
  # Loud, because the per-host list is where the GPU drivers and the CPU
  # microcode live. A hostname that does not match any file here fails
  # silently: `steam` then pulls vulkan-driver / lib32-vulkan-driver, and
  # --noconfirm resolves those to whichever provider comes first — usually
  # another vendor's driver. That is the usual cause of Steam opening a black
  # window, and of a machine booting without microcode updates.
  warn "No packages/pacman.$HOSTNAME_SHORT.txt for host '$HOSTNAME_SHORT'."
  warn "    GPU/Vulkan drivers and CPU microcode are declared per host, so this"
  warn "    run will install neither. Create the file (see packages/README.md),"
  warn "    or make sure this host's hostname matches an existing one:"
  warn "      $(cd "$PKG_DIR" && ls pacman.*.txt 2>/dev/null | tr '\n' ' ')"
  FAILED_EXTRA+=("packages/pacman.$HOSTNAME_SHORT.txt: missing (no GPU drivers or microcode declared)")
fi
if [[ -f "$PKG_DIR/aur.$HOSTNAME_SHORT.txt" ]]; then
  info "  + per-host AUR extras applied"
fi

if [[ "${#PACMAN_PKGS[@]}" -eq 0 ]]; then
  echo "No packages found in $PKG_DIR/pacman.txt — is the repo intact?" >&2
  exit 1
fi
info "  ${#PACMAN_PKGS[@]} pacman, ${#AUR_PKGS[@]} AUR, ${#NPM_PKGS[@]} npm package(s)"

########################################
# 4b/4c. Install packages
########################################
# Resilient installers: try the whole list at once (fast), and if that fails
# (e.g. a renamed/removed package name), fall back to one-by-one so every good
# package still installs and only the bad names are reported. This prevents a
# single bad name from aborting the script under `set -e`.
#
# Every skipped package is also recorded in FAILED so the run ends with an
# explicit summary — otherwise a warning scrolls past in thousands of lines of
# build output and the package looks like it installed.
FAILED=()

pac_install() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run "sudo pacman -S --needed --noconfirm $*"
    return 0
  fi
  sudo pacman -S --needed --noconfirm "$@" && return
  warn "Batch pacman install failed; retrying individually…"
  local p
  for p in "$@"; do
    sudo pacman -S --needed --noconfirm "$p" \
      || { warn "pacman: could not install '$p' (skipped)"; FAILED+=("pacman:$p"); }
  done
}
# One `yay` call per package on purpose: yay installs everything it built in a
# single `pacman -U` transaction, so one bad package in a batch rolls back the
# whole set (this silently ate 11 already-built packages once).
aur_install() {
  local p
  for p in "$@"; do
    if [[ "$DRY_RUN" -eq 1 ]]; then
      run "yay -S --needed --noconfirm $p"
      continue
    fi
    yay -S --needed --noconfirm "$p" \
      || { warn "AUR: could not install '$p' (skipped)"; FAILED+=("aur:$p"); }
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

if [[ "${#NPM_PKGS[@]}" -gt 0 ]]; then
  info "Installing global npm tooling"
  run sudo npm install -g "${NPM_PKGS[@]}" || {
    warn "npm global install had issues (is nodejs installed?)."
    FAILED+=("npm:${NPM_PKGS[*]}")
  }
fi

info "Adding rustup components"
run rustup default stable || true
run rustup component add rust-analyzer rustfmt clippy || true

########################################
# Groups, shell
########################################
info "Configuring user groups and default shell for $USER_NAME"
# Only add groups that actually exist: a group from a package that failed to
# install would make usermod fail and (under `set -e`) skip everything below.
GROUPS_WANTED=(wheel input video docker)
GROUPS_ADD=()
for g in "${GROUPS_WANTED[@]}"; do
  if getent group "$g" >/dev/null 2>&1; then
    GROUPS_ADD+=("$g")
  else
    warn "Group '$g' does not exist (package missing?); not adding $USER_NAME to it."
  fi
done
if [[ "${#GROUPS_ADD[@]}" -gt 0 ]]; then
  run sudo usermod -aG "$(IFS=,; echo "${GROUPS_ADD[*]}")" "$USER_NAME" \
    || warn "Could not update groups for $USER_NAME"
fi
if [[ "$(getent passwd "$USER_NAME" | cut -d: -f7)" != "/usr/bin/zsh" ]]; then
  run sudo chsh -s /usr/bin/zsh "$USER_NAME"
fi

########################################
# Shell framework: oh-my-zsh + tmux TPM
########################################
info "Installing oh-my-zsh (unattended)"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run "curl … ohmyzsh/tools/install.sh | sh   (KEEP_ZSHRC=yes, chezmoi owns .zshrc)"
  else
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
fi

info "Installing tmux plugin manager (TPM)"
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  run git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

########################################
# System config files (/etc)
########################################
# The files themselves live in system/ as plain files (see system/README.md) so
# they can be read, diffed and edited like any other config — chezmoi cannot
# manage them because it only writes inside $HOME.

# Copy the `etc/` subtree of $1, whose layout mirrors `/`, onto the real
# filesystem:  <$1>/etc/greetd/config.toml -> /etc/greetd/config.toml.
# Paths are resolved relative to $1 (not to $1/etc) so the leading `etc/` is
# carried over verbatim.
# A `.in` file is a template: placeholders are substituted and the suffix
# dropped. Unchanged files are skipped so re-runs stay quiet; a file that
# differs is backed up once to <path>.dotfiles-bak before being overwritten.
install_system_tree() {
  local root="$1" src rel dest tmp
  [[ -d "$root/etc" ]] || return 0
  while IFS= read -r -d '' src; do
    rel="${src#"$root"/}"
    dest="/$rel"
    tmp="$(mktemp)"
    if [[ "$dest" == *.in ]]; then
      dest="${dest%.in}"
      sed -e "s|@USER_NAME@|$USER_NAME|g" \
          -e "s|@HOSTNAME@|$HOSTNAME_SHORT|g" "$src" >"$tmp"
    else
      cat "$src" >"$tmp"
    fi
    if sudo_ro cmp -s "$tmp" "$dest" 2>/dev/null; then
      printf '      %s (unchanged)\n' "$dest"
      rm -f "$tmp"
      continue
    fi
    # Keep the *first* backup only: on a later run the ".dotfiles-bak" would
    # otherwise be overwritten with a copy of what this script itself wrote,
    # losing the original.
    if sudo_ro test -e "$dest" && ! sudo_ro test -e "$dest.dotfiles-bak"; then
      run sudo cp -a "$dest" "$dest.dotfiles-bak" \
        && warn "backed up existing $dest -> $dest.dotfiles-bak"
    fi
    if run sudo install -D -o root -g root -m 0644 "$tmp" "$dest"; then
      printf '      %s\n' "$dest"
    else
      warn "Could not write $dest"
      FAILED+=("etc:$dest")
    fi
    rm -f "$tmp"
  done < <(find "$root/etc" -type f -print0)
}

info "Installing /etc config files from $SYSTEM_DIR"
install_system_tree "$SYSTEM_DIR"
# Per-host files land last so they win over a shared file at the same path.
if [[ -d "$SYSTEM_DIR/hosts/$HOSTNAME_SHORT/etc" ]]; then
  info "  + per-host /etc files for '$HOSTNAME_SHORT'"
  install_system_tree "$SYSTEM_DIR/hosts/$HOSTNAME_SHORT"
fi

########################################
# Enable services
########################################
# Unit names come from system/services.txt (+ the per-host file), same additive
# scheme as the package lists.
# shellcheck disable=SC2207
SERVICES=( $(read_list "$SYSTEM_DIR/services.txt" \
                       "$SYSTEM_DIR/hosts/$HOSTNAME_SHORT/services.txt") )

info "Enabling ${#SERVICES[@]} system service(s)"
# Resilient enable: a missing unit warns instead of aborting the whole script
# (important under `set -e`).
enable_service() {
  if systemctl list-unit-files "$1" >/dev/null 2>&1 && systemctl cat "$1" >/dev/null 2>&1; then
    run sudo systemctl enable "$1" || warn "Failed to enable $1"
  else
    warn "Service $1 not found (package missing?); skipping enable."
  fi
}
for s in "${SERVICES[@]}"; do
  enable_service "$s"
done

########################################
# Docker (rootless, matching virtualisation/docker.nix)
########################################
# `dockerd-rootless-setuptool.sh` is NOT part of Arch's `docker` package — it
# only ships in docker-rootless-extras (AUR). The old version of this block
# disabled docker.service *before* testing for that script, so on a plain Arch
# box (where the test always failed, and on any --no-aur run) it left the host
# with no usable Docker at all: root daemon disabled, rootless never set up.
# Now the root daemon is only disabled once rootless can actually replace it.
setup_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    return 0
  fi
  if ! command -v dockerd-rootless-setuptool.sh >/dev/null 2>&1; then
    warn "docker-rootless-extras (AUR) missing — keeping the root docker.service."
    enable_service docker.service
    return 0
  fi

  # Rootless needs a sub-uid/sub-gid range for the user. Arch ships neither
  # /etc/subuid nor /etc/subgid, and the setuptool's own preflight check fails
  # without them, so create the range first (65536 ids, the docker default).
  if ! grep -q "^$USER_NAME:" /etc/subuid 2>/dev/null; then
    run sudo usermod --add-subuids 100000-165535 "$USER_NAME" \
      || warn "Could not add subuids for $USER_NAME (rootless docker may fail)."
  fi
  if ! grep -q "^$USER_NAME:" /etc/subgid 2>/dev/null; then
    run sudo usermod --add-subgids 100000-165535 "$USER_NAME" \
      || warn "Could not add subgids for $USER_NAME (rootless docker may fail)."
  fi

  # Rootless and the system daemon are mutually exclusive; prefer rootless.
  run sudo systemctl disable docker.service 2>/dev/null || true
  # The user unit does not exist until the setuptool writes it, so install
  # first and enable afterwards (the old order silently did nothing).
  if run dockerd-rootless-setuptool.sh install; then
    run systemctl --user enable docker.service || true
  else
    warn "rootless docker setup needs a re-login to finish; re-run afterwards."
    FAILED+=("docker:rootless setup incomplete")
  fi
}
setup_docker

# Flatpak + flathub
if command -v flatpak >/dev/null 2>&1; then
  run sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
fi

########################################
# Summary
########################################
# A long run buries individual warnings under thousands of lines of build
# output, so re-report everything that did not install, here at the end.
FAILED+=("${FAILED_EXTRA[@]+"${FAILED_EXTRA[@]}"}")
if [[ "${#FAILED[@]}" -gt 0 ]]; then
  printf '\n\033[1;31m==> %s problem(s) during install:\033[0m\n' "${#FAILED[@]}"
  printf '      %s\n' "${FAILED[@]}"
  printf '    Re-run ./install.sh to retry, or install them individually to see\n'
  printf '    the real error (e.g. `yay -S <name>` without --noconfirm).\n'
else
  info "All packages installed."
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  info "Dry run: nothing above was actually applied. Re-run without --dry-run."
  exit 0
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
  4. Check for drift between this repo and the machine:  ./bin/pkg-diff.sh
NEXT
