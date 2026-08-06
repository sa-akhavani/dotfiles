#!/usr/bin/env bash
#
# Mark every package listed in pkg-promote.txt as EXPLICITLY installed.
#
# Why this exists: a package this repo declares, but that pacman recorded as a
# dependency, turns into an orphan in `pacman -Qdtq` the moment whatever pulled
# it in goes away. A routine orphan cleanup then deletes something the repo says
# the machine needs — `vlc` has been sitting in exactly that state. Promoting
# these is what makes `pacman -Qdtq` safe to act on, and it is the fix that
# pkg-diff.sh's third section tells you to run.
#
# The inverse of bin/pkg-demote.sh, which reads the same style of list.
#
# Nothing is installed, removed or downloaded. The only thing that changes is
# the install-reason field in pacman's local database, and bin/pkg-demote.sh
# reverses it.
#
# Usage:
#   ./bin/pkg-promote.sh                    # preview only — the default
#   ./bin/pkg-promote.sh --apply            # actually change the install reasons
#   ./bin/pkg-promote.sh --file other.txt   # read a different list
#
# Previewing needs no sudo, so the default mode is safe to run anywhere.
# Exit status: 0 = fine (nothing to do, or preview printed), 1 = a problem.
#

set -euo pipefail

APPLY=0
LIST=""

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)  APPLY=1; shift ;;
    --file)   LIST="${2:-}"; [[ -n "$LIST" ]] || { echo "--file needs a path" >&2; exit 1; }; shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown argument: $1 (try --help)" >&2; exit 1 ;;
  esac
done

# Same refusal install.sh makes: run as yourself, the script calls sudo itself.
# Running the whole thing as root would also make `sudo` a no-op we can't audit.
if [[ "$EUID" -eq 0 ]]; then
  echo "Run this as your normal user, not root — it calls sudo itself." >&2
  exit 1
fi

REPO_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
HOSTNAME_SHORT="$(hostnamectl --static 2>/dev/null || cat /etc/hostname 2>/dev/null || echo unknown)"
SHARED_DIR="$REPO_DIR/shared"
HOST_DIR="$REPO_DIR/hosts/$HOSTNAME_SHORT"
LIST="${LIST:-$REPO_DIR/pkg-promote.txt}"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

[[ -f "$LIST" ]] || { echo "no such list: $LIST" >&2; exit 1; }

# Same comment/blank-line stripping install.sh's read_list does.
strip_list() {
  local f
  for f in "$@"; do
    [[ -f "$f" ]] && sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' "$f"
  done
  return 0
}

DECLARED="$(strip_list "$SHARED_DIR/pacman.txt" "$HOST_DIR/pacman.txt" \
                       "$SHARED_DIR/aur.txt"    "$HOST_DIR/aur.txt" | sort -u)"

TODO=()        # actually needs changing
ALREADY=()     # already explicit, nothing to do
MISSING=()     # in the list but not installed here
UNDECLARED=()  # would just move the drift to pkg-diff's second section

while read -r pkg; do
  [[ -n "$pkg" ]] || continue
  if ! pacman -Qq "$pkg" &>/dev/null; then
    MISSING+=("$pkg")
    continue
  fi
  # -Qqe lists explicitly-installed packages; a hit means it is already correct.
  if pacman -Qqe "$pkg" &>/dev/null; then
    ALREADY+=("$pkg")
    continue
  fi
  grep -qxF "$pkg" <<<"$DECLARED" || UNDECLARED+=("$pkg")
  TODO+=("$pkg")
done < <(strip_list "$LIST" | sort -u)

printf 'Host: %s   list: %s\n' "$HOSTNAME_SHORT" "$LIST"

[[ ${#ALREADY[@]} -gt 0 ]] && { bold "Already explicit (${#ALREADY[@]}) — nothing to do"; printf '      %s\n' "${ALREADY[@]}"; }

if [[ ${#MISSING[@]} -gt 0 ]]; then
  bold "Not installed on this host (${#MISSING[@]}) — skipped"
  printf '      %s\n' "${MISSING[@]}"
  dim "  These lists are shared across hosts, so this is normal and not an error."
fi

# Promoting an undeclared package does not fix drift, it relabels it: pkg-diff
# stops reporting it in section 3 and starts reporting it in section 2 instead.
if [[ ${#UNDECLARED[@]} -gt 0 ]]; then
  bold "Not declared in this repo (${#UNDECLARED[@]}) — promoting anyway"
  printf '      %s\n' "${UNDECLARED[@]}"
  warn "These will move from pkg-diff section 3 to section 2, not disappear."
  dim "  Declare them in shared/pacman.txt or hosts/$HOSTNAME_SHORT/pacman.txt too."
fi

if [[ ${#TODO[@]} -eq 0 ]]; then
  bold "Nothing to promote."
  exit 0
fi

bold "Will mark as explicitly installed (${#TODO[@]})"
printf '      %s\n' "${TODO[@]}"

if [[ "$APPLY" -eq 0 ]]; then
  dim "  preview only — re-run with --apply to make the change"
  exit 0
fi

sudo pacman -D --asexplicit "${TODO[@]}"
ok "Promoted ${#TODO[@]} package(s). Verify with: ./bin/pkg-diff.sh"
