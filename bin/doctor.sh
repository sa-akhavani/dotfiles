#!/usr/bin/env bash
#
# Check this host's SYSTEM STATE against what the repo assumes about it.
#
# Deliberately not a package checker — that is bin/pkg-diff.sh, and there is no
# overlap. What this covers is everything install.sh sets up but never verifies
# afterwards, plus the manual steps that live outside the repo entirely (the
# kernel command line in /boot being the standing example: it is per-machine, it
# is documented in README installation step 4, and nothing has ever told you
# when a host was missing it).
#
# Read-only: no sudo, nothing is written, nothing is installed. Every check
# degrades to a warning when it cannot read something rather than failing.
#
# Usage:
#   ./bin/doctor.sh            # full report
#   ./bin/doctor.sh --quiet    # only sections that found something
#   ./bin/doctor.sh --strict   # exit non-zero on warnings too
#
# Exit status: 0 = healthy, 1 = at least one FAIL (or, under --strict, a warn).
#
# NOT wired into .github/workflows/ci.yml on purpose: every check is about the
# machine it runs on, so a GitHub runner would fail all of them. CI still lints
# it, because that workflow shellchecks bin/*.sh as a glob.
#

set -euo pipefail

QUIET=0
STRICT=0

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet)   QUIET=1; shift ;;
    --strict)  STRICT=1; shift ;;
    -h|--help) usage ;;
    *) echo "unknown argument: $1 (try --help)" >&2; exit 1 ;;
  esac
done

REPO_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
HOSTNAME_SHORT="$(hostnamectl --static 2>/dev/null || cat /etc/hostname 2>/dev/null || echo unknown)"
SHARED_DIR="$REPO_DIR/shared"
HOST_DIR="$REPO_DIR/hosts/$HOSTNAME_SHORT"
# Same expansion install.sh uses, so .in placeholders render identically.
USER_NAME="${SUDO_USER:-$USER}"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }

FAILS=0
WARNS=0

# A section buffers its lines so that --quiet can drop the whole thing when it
# turned up nothing.
SECTION_TITLE=""
SECTION_LINES=()
SECTION_FOUND=0

begin() { SECTION_TITLE="$1"; SECTION_LINES=(); SECTION_FOUND=0; }
pass()  { SECTION_LINES+=("      $(printf '\033[1;32m[ok]\033[0m')   $1"); }
warn()  { SECTION_LINES+=("      $(printf '\033[1;33m[warn]\033[0m') $1"); SECTION_FOUND=1; WARNS=$((WARNS + 1)); }
fail()  { SECTION_LINES+=("      $(printf '\033[1;31m[FAIL]\033[0m') $1"); SECTION_FOUND=1; FAILS=$((FAILS + 1)); }
hint()  { SECTION_LINES+=("             $(printf '\033[2m%s\033[0m' "$1")"); }
end() {
  if [[ "$SECTION_FOUND" -eq 1 || "$QUIET" -eq 0 ]]; then
    bold "$SECTION_TITLE"
    [[ ${#SECTION_LINES[@]} -eq 0 ]] || printf '%s\n' "${SECTION_LINES[@]}"
  fi
}

# Same comment/blank-line stripping install.sh's read_list does.
strip_list() {
  local f
  for f in "$@"; do
    [[ -f "$f" ]] && sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' "$f"
  done
  return 0
}

printf 'Host: %s   repo: %s\n' "$HOSTNAME_SHORT" "$REPO_DIR"

########################################
# 1. Host identity
########################################
# A hostname with no hosts/<host>/ directory is the failure that leaves a
# machine with no GPU driver and no microcode, because that file is the only
# place either is declared.
begin "Host identity"
if [[ -d "$HOST_DIR" ]]; then
  pass "hosts/$HOSTNAME_SHORT/ exists"
  if [[ -f "$HOST_DIR/pacman.txt" ]]; then
    pass "hosts/$HOSTNAME_SHORT/pacman.txt present"
  else
    fail "hosts/$HOSTNAME_SHORT/pacman.txt is missing"
    hint "GPU drivers and CPU microcode are declared nowhere else."
  fi
else
  fail "no hosts/$HOSTNAME_SHORT/ directory in this repo"
  hint "This host gets no GPU driver and no microcode. Create it, or fix the"
  hint "hostname:  sudo hostnamectl set-hostname <one of: $(cd "$REPO_DIR/hosts" && echo */ | tr -d '/')>"
fi
end

########################################
# 2. Kernel command line
########################################
# /boot/loader/entries/*.conf is per-machine (each carries its own root
# PARTUUID), so this repo cannot mirror it and install.sh cannot fix it. The
# only thing possible is to notice.
begin "Kernel command line (/proc/cmdline)"
CMDLINE="$(cat /proc/cmdline 2>/dev/null || true)"
if [[ -z "$CMDLINE" ]]; then
  warn "could not read /proc/cmdline"
else
  for opt in quiet loglevel=3; do
    if [[ " $CMDLINE " == *" $opt "* ]]; then
      pass "$opt"
    else
      warn "$opt is missing"
      hint "Without both, systemd keeps writing [ OK ] lines to VT 1 until ~7s"
      hint "while greetd already owns it at ~5.8s, so boot log prints over the"
      hint "tuigreet login screen. Fix in /boot/loader/entries/*_linux.conf"
      hint "(README installation step 4) — not in /etc."
    fi
  done
  if [[ " $CMDLINE " == *" zswap.enabled=0 "* ]]; then
    pass "zswap.enabled=0"
  else
    warn "zswap.enabled=0 is missing"
    hint "zswap sits in front of the zram swap this repo configures and"
    hint "compresses pages a second time, on their way into a device that has"
    hint "already compressed them. Same file as above."
  fi
fi
end

########################################
# 3. Running kernel vs installed kernels
########################################
# The tell for a pending reboot is not a version string comparison (pacman
# spells it 7.1.5.arch1-2 and uname spells it 7.1.5-arch1-2) but whether the
# running kernel's module tree still exists: pacman deletes it on upgrade, and
# from that moment modprobe can no longer load anything at all.
begin "Kernel"
RUNNING="$(uname -r)"
KERNELS=()
for d in /usr/lib/modules/*/; do
  [[ -f "$d/pkgbase" ]] || continue
  KERNELS+=("$(basename "$d")")
done
if [[ -d "/usr/lib/modules/$RUNNING" ]]; then
  pass "running $RUNNING (module tree present)"
else
  warn "running $RUNNING but /usr/lib/modules/$RUNNING is gone — reboot pending"
  hint "The kernel package was upgraded under the running system. Until you"
  hint "reboot, modprobe cannot load any module that is not already loaded."
fi
if [[ ${#KERNELS[@]} -eq 0 ]]; then
  warn "no installed kernel found under /usr/lib/modules"
else
  for k in "${KERNELS[@]}"; do
    pass "installed: $k ($(cat "/usr/lib/modules/$k/pkgbase"))"
  done
fi
end

########################################
# 4. DKMS
########################################
# rostam runs nvidia-open-dkms and v4l2loopback-dkms, and this repo declares
# both `linux` and `linux-lts`. A module built for one kernel but not the other
# is invisible until the day you boot the fallback kernel to rescue the machine
# and find it has no graphics.
begin "DKMS modules"
if ! command -v dkms >/dev/null 2>&1; then
  pass "dkms is not installed on this host — nothing to check"
elif [[ ${#KERNELS[@]} -eq 0 ]]; then
  warn "skipped: no installed kernels detected"
else
  DKMS_OUT="$(dkms status 2>/dev/null || true)"
  # Module name is whatever precedes the first ',' or '/', which covers both the
  # old "mod, ver, kern, arch: state" and the new "mod/ver, kern, arch: state".
  DKMS_MODS="$(printf '%s\n' "$DKMS_OUT" | sed -e '/^[[:space:]]*$/d' -e 's/[,/].*//' | sort -u)"
  if [[ -z "$DKMS_MODS" ]]; then
    pass "no dkms modules registered"
  else
    while read -r mod; do
      [[ -n "$mod" ]] || continue
      for k in "${KERNELS[@]}"; do
        # -F throughout: kernel versions are full of dots and would otherwise
        # need regex escaping for no benefit.
        if printf '%s\n' "$DKMS_OUT" | grep -F "$k" | grep -F "$mod" | grep -qF "installed"; then
          pass "$mod built for $k"
        else
          fail "$mod is NOT built for $k"
          hint "Rebuild with: sudo dkms autoinstall -k $k"
          hint "Usually means linux-headers (or linux-lts-headers) is missing."
        fi
      done
    done <<<"$DKMS_MODS"
  fi
fi
end

########################################
# 5. Swap
########################################
begin "Swap"
SWAP_OUT="$(swapon --show=NAME,TYPE,SIZE --noheadings --bytes 2>/dev/null || true)"
if [[ -z "$SWAP_OUT" ]]; then
  fail "no swap is active"
  hint "shared/etc/systemd/zram-generator.conf is what supplies all of it."
  hint "Check: systemctl status systemd-zram-setup@zram0.service"
else
  SWAP_TOTAL=0
  HAS_ZRAM=0
  while read -r name _type size; do
    [[ -n "$name" ]] || continue
    [[ "$name" == /dev/zram* ]] && HAS_ZRAM=1
    SWAP_TOTAL=$((SWAP_TOTAL + size))
  done <<<"$SWAP_OUT"
  MEM_KB="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
  MEM_BYTES=$((MEM_KB * 1024))
  EXPECT=$((MEM_BYTES / 2))
  printf -v human '%.1f' "$(awk -v b="$SWAP_TOTAL" 'BEGIN{print b/1073741824}')"
  if [[ "$HAS_ZRAM" -eq 1 ]]; then
    pass "zram swap active, ${human}G total"
  else
    warn "swap is active but none of it is zram (${human}G total)"
  fi
  # 15% either way absorbs the difference between zram-generator's MB rounding
  # and the kernel's idea of MemTotal.
  if [[ "$SWAP_TOTAL" -lt $((EXPECT * 85 / 100)) || "$SWAP_TOTAL" -gt $((EXPECT * 115 / 100)) ]]; then
    warn "expected about half of RAM ($(awk -v b="$EXPECT" 'BEGIN{printf "%.1f", b/1073741824}')G), got ${human}G"
    hint "shared/etc/systemd/zram-generator.conf says 'zram-size = ram / 2'."
    hint "A change to it only takes effect on the next boot."
  fi
fi
end

########################################
# 6. Disk space
########################################
# /boot is a small vfat ESP holding an initramfs per kernel. Filling it up
# midway through a kernel upgrade is how a machine ends up unbootable, and the
# DKMS hosts carry the biggest initramfs images.
begin "Disk space"
check_fs() {
  local mp="$1" warn_at="$2" fail_at="$3" line pcent avail
  line="$(df -h --output=pcent,avail -- "$mp" 2>/dev/null | tail -1)" || return 0
  read -r pcent avail <<<"$line"
  pcent="${pcent%\%}"
  if [[ "$pcent" -ge "$fail_at" ]]; then
    fail "$mp is ${pcent}% full (${avail} free)"
    [[ "$mp" == /boot ]] && hint "Remove stale initramfs images; a full ESP mid-upgrade leaves the machine unbootable."
  elif [[ "$pcent" -ge "$warn_at" ]]; then
    warn "$mp is ${pcent}% full (${avail} free)"
  else
    pass "$mp is ${pcent}% full (${avail} free)"
  fi
}
check_fs / 80 90
mountpoint -q /boot 2>/dev/null && check_fs /boot 70 85
end

########################################
# 7. Services
########################################
# install.sh enables these but never looks again. A unit can be enabled and
# still have failed at boot, which is exactly the state nobody notices.
begin "Services"
# shellcheck disable=SC2207
SERVICES=( $(strip_list "$SHARED_DIR/services.txt" "$HOST_DIR/services.txt") )
if [[ ${#SERVICES[@]} -eq 0 ]]; then
  warn "no services declared — is shared/services.txt readable?"
else
  for s in "${SERVICES[@]}"; do
    enabled="$(systemctl is-enabled "$s" 2>/dev/null || true)"
    active="$(systemctl is-active "$s" 2>/dev/null || true)"
    case "$enabled" in
      enabled|enabled-runtime|static|indirect) ;;
      "") fail "$s: not found (package missing?)"; continue ;;
      *)  fail "$s: enabled=$enabled"; hint "Declared in services.txt but not enabled — run ./install.sh"; continue ;;
    esac
    case "$active" in
      active|activating) pass "$s ($enabled, $active)" ;;
      failed) fail "$s is enabled but FAILED"; hint "Look at: systemctl status $s" ;;
      *) warn "$s is $enabled but $active"; hint "Socket-activated units are fine here; others are not." ;;
    esac
  done
fi
FAILED_UNITS="$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}' || true)"
if [[ -n "$FAILED_UNITS" ]]; then
  while read -r u; do
    [[ -n "$u" ]] || continue
    fail "systemd reports $u as failed"
  done <<<"$FAILED_UNITS"
else
  pass "no failed units system-wide"
fi
end

########################################
# 8. /etc drift
########################################
# The read-only half of install_system_tree. Per-host files win over shared
# ones, so the same path declared in both is resolved the way install.sh would
# resolve it, not reported twice.
begin "/etc files vs repo"
declare -A ETC_SRC=()
ETC_ORDER=()
collect_etc() {
  local root="$1" src rel dest
  [[ -d "$root/etc" ]] || return 0
  while IFS= read -r -d '' src; do
    rel="${src#"$root"/}"
    dest="/$rel"
    [[ "$dest" == *.in ]] && dest="${dest%.in}"
    [[ -v "ETC_SRC[$dest]" ]] || ETC_ORDER+=("$dest")
    ETC_SRC["$dest"]="$src"
  done < <(find "$root/etc" -type f -print0)
}
collect_etc "$SHARED_DIR"
collect_etc "$HOST_DIR"

if [[ ${#ETC_ORDER[@]} -eq 0 ]]; then
  warn "no /etc files found in the repo"
else
  for dest in "${ETC_ORDER[@]}"; do
    src="${ETC_SRC[$dest]}"
    rendered="$(mktemp)"
    if [[ "$src" == *.in ]]; then
      sed -e "s|@USER_NAME@|$USER_NAME|g" -e "s|@HOSTNAME@|$HOSTNAME_SHORT|g" "$src" >"$rendered"
    else
      cat "$src" >"$rendered"
    fi
    if [[ ! -e "$dest" ]]; then
      fail "$dest is missing"
      hint "Run ./install.sh to deploy it."
    elif [[ ! -r "$dest" ]]; then
      warn "$dest exists but is not readable as $USER_NAME — cannot compare"
    elif cmp -s "$rendered" "$dest"; then
      pass "$dest"
    else
      warn "$dest differs from ${src#"$REPO_DIR"/}"
      hint "diff -u '$dest' <(...) — or just re-run ./install.sh to overwrite."
      hint "If the machine is right and the repo is wrong, copy it back instead."
    fi
    rm -f "$rendered"
    # A .dotfiles-bak is written once, the first time install.sh found something
    # different already in place. Nothing ever deletes it, so its presence means
    # a conflict happened and nobody looked at it.
    if [[ -e "$dest.dotfiles-bak" ]]; then
      warn "$dest.dotfiles-bak exists — an old conflict nobody resolved"
      hint "Compare and delete it once you are satisfied nothing was lost."
    fi
  done
fi

PACNEW="$(find /etc -name '*.pacnew' -o -name '*.pacsave' 2>/dev/null || true)"
if [[ -n "$PACNEW" ]]; then
  while read -r f; do
    [[ -n "$f" ]] || continue
    warn "pending merge: $f"
  done <<<"$PACNEW"
  hint "Merge with the 'pacmerge' alias (see MAINTENANCE.md)."
else
  pass "no .pacnew / .pacsave files pending"
fi
end

########################################
# 9. chezmoi
########################################
# Two distinct failures here. The config in ~/.config/chezmoi is generated ONCE
# by `chezmoi init` and is never refreshed by `chezmoi apply`, so a change to
# .chezmoi.toml.tmpl silently does not reach a host that was initialised before
# it — which is how a host ends up with no sourceDir and a bare `chezmoi apply`
# looking in ~/.local/share/chezmoi for a repo that lives under ~/Desktop.
begin "chezmoi"
if ! command -v chezmoi >/dev/null 2>&1; then
  warn "chezmoi is not installed"
else
  EXPECT_SRC="$REPO_DIR/home"
  ACTUAL_SRC="$(chezmoi source-path 2>/dev/null || true)"
  if [[ "$ACTUAL_SRC" == "$EXPECT_SRC" ]]; then
    pass "source-path resolves to $EXPECT_SRC"
  else
    fail "source-path is '${ACTUAL_SRC:-<unset>}', expected '$EXPECT_SRC'"
    hint "A bare 'chezmoi apply' (the 'update' alias) and \$DOTFILES both use"
    hint "this. Fix by regenerating the machine-local config:"
    hint "  chezmoi init --source $REPO_DIR"
  fi
  # chezmoi itself reports a stale generated config, on stderr.
  CZ_ERR="$(chezmoi --source "$REPO_DIR" status 2>&1 >/dev/null || true)"
  if [[ "$CZ_ERR" == *"config file template has changed"* ]]; then
    fail "$HOME/.config/chezmoi/chezmoi.toml is stale vs home/.chezmoi.toml.tmpl"
    hint "chezmoi apply never regenerates it; only chezmoi init does."
    hint "  chezmoi init --source $REPO_DIR"
  else
    pass "machine-local config is current"
  fi
  # --source explicitly, so this still works when the config above is broken.
  CZ_STATUS="$(chezmoi --source "$REPO_DIR" status 2>/dev/null || true)"
  if [[ -n "$CZ_STATUS" ]]; then
    # IFS= is load-bearing: chezmoi's two status columns are positional, and a
    # bare `read` would strip the leading space that distinguishes " M" (the
    # repo is ahead) from "M " (\$HOME was hand-edited) — which is exactly what
    # the hint below tells you to act on.
    while IFS= read -r l; do
      [[ -n "$l" ]] || continue
      warn "drift: [$l]"
    done <<<"$CZ_STATUS"
    hint "Column 1 = \$HOME changed since chezmoi wrote it -> ./bin/dotsync.sh"
    hint "Column 2 = repo is ahead of \$HOME             -> chezmoi apply"
  else
    pass "\$HOME matches the repo"
  fi
fi
end

########################################
# Summary
########################################
if [[ "$FAILS" -eq 0 && "$WARNS" -eq 0 ]]; then
  bold "Healthy: $HOSTNAME_SHORT matches what the repo assumes."
  exit 0
fi

bold "Summary: $FAILS failure(s), $WARNS warning(s)."
if [[ "$FAILS" -gt 0 ]]; then
  exit 1
fi
if [[ "$STRICT" -eq 1 ]]; then
  dim "  --strict: exiting non-zero because of warnings."
  exit 1
fi
dim "  Warnings only — exiting 0. Use --strict to make them fatal."
exit 0
