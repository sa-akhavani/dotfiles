#!/usr/bin/env bash
#
# Report drift between the package lists in this repo and what is actually
# installed on this host
#
# Read-only: no sudo, nothing is installed or removed. It prints the commands
# that would fix each kind of drift and leaves running them to you.
#
# Usage:
#   ./bin/pkg-diff.sh              # full report
#   ./bin/pkg-diff.sh --quiet      # only print sections that have findings
#
# Exit status: 0 = no drift, 1 = drift found (so it can gate a commit or CI).
#

set -euo pipefail

QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1

REPO_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
HOSTNAME_SHORT="$(hostnamectl --static 2>/dev/null || cat /etc/hostname 2>/dev/null || echo unknown)"
SHARED_DIR="$REPO_DIR/shared"
HOST_DIR="$REPO_DIR/hosts/$HOSTNAME_SHORT"

# Packages that are legitimately installed without being declared: the base
# install's meta packages and the AUR helper install.sh bootstraps itself.
EXPECTED_UNDECLARED=(base base-devel yay)

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }

# Same comment/blank-line stripping install.sh's read_list does.
strip_list() {
  local f
  for f in "$@"; do
    [[ -f "$f" ]] && sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$f"
  done
  return 0
}

declared_pkgs() {
  strip_list "$SHARED_DIR/pacman.txt" "$HOST_DIR/pacman.txt" \
             "$SHARED_DIR/aur.txt"    "$HOST_DIR/aur.txt" \
    | sort -u
}

DECLARED="$(declared_pkgs)"
INSTALLED="$(pacman -Qq | sort)"
EXPLICIT="$(pacman -Qqe | sort)"
DEPENDENCY="$(pacman -Qqd | sort)"
DRIFT=0

# A section prints its heading only when it has findings under --quiet.
report() {
  local heading="$1" fix="$2" body="$3"
  if [[ -z "$body" ]]; then
    if [[ "$QUIET" -eq 0 ]]; then
      bold "$heading"
      printf '      none\n'
    fi
    return 0
  fi
  DRIFT=1
  bold "$heading"
  printf '%s\n' "$body" | sed 's/^/      /'
  dim "  fix: $fix"
}

printf 'Host: %s   lists: %s + %s\n' "$HOSTNAME_SHORT" "$SHARED_DIR" "$HOST_DIR"

# 1. Declared but missing. Usually an AUR build that failed during install.sh:
#    the failure scrolls past in thousands of lines of build output, so this is
#    where it actually becomes visible.
report "Declared in this repo but NOT installed" \
       "./install.sh   (or 'yay -S <name>' without --noconfirm to see the real error)" \
       "$(comm -23 <(printf '%s\n' "$DECLARED") <(printf '%s\n' "$INSTALLED"))"

# 2. Installed on purpose but undeclared — a fresh machine would not get these.
#    Either declare them in shared/ or hosts/<hostname>/, or uninstall them here.
report "Explicitly installed but NOT declared (a new host would not get these)" \
       "add to shared/pacman.txt (or hosts/$HOSTNAME_SHORT/pacman.txt), or 'sudo pacman -Rns <name>'" \
       "$(comm -13 <(printf '%s\n' "$DECLARED") <(printf '%s\n' "$EXPLICIT") \
          | grep -vxF "$(printf '%s\n' "${EXPECTED_UNDECLARED[@]}")" || true)"

# 3. Declared, installed, but marked as a dependency. These are the dangerous
#    ones: 'pacman -Qdt' lists them as orphans the moment whatever pulled them
#    in goes away, so a routine orphan cleanup silently deletes packages this
#    repo says the machine needs (this is why MAINTENANCE.md §2 says to check).
report "Declared but installed as a dependency (would show up as orphans)" \
       "sudo pacman -D --asexplicit <names>" \
       "$(comm -12 <(printf '%s\n' "$DECLARED") <(printf '%s\n' "$DEPENDENCY"))"

# 4. Global npm packages, same idea. npm is only used for tooling with no
#    pacman/AUR equivalent, so this list should stay short.
if command -v npm >/dev/null 2>&1; then
  declared_npm="$(strip_list "$SHARED_DIR/npm.txt" "$HOST_DIR/npm.txt" | sort -u)"
  installed_npm="$(npm ls -g --depth=0 --parseable 2>/dev/null \
                   | sed -n 's|.*/node_modules/||p' | sort -u)"
  report "Declared in shared/npm.txt but NOT installed globally" \
         "./install.sh   (or 'sudo npm install -g <name>')" \
         "$(comm -23 <(printf '%s\n' "$declared_npm") <(printf '%s\n' "$installed_npm"))"
fi

if [[ "$DRIFT" -eq 0 ]]; then
  bold "No drift: the machine matches the repo."
else
  bold "Drift found (see above)."
fi
exit "$DRIFT"
