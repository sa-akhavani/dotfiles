#!/usr/bin/env bash
#
# Mark every package listed in pkg-demote.txt as installed AS A DEPENDENCY.
#
# Why this exists: a library that got recorded as explicitly installed sits in
# pkg-diff.sh's "explicitly installed but NOT declared" section forever, looking
# like drift that needs a decision. It doesn't — it needs its install reason
# corrected. Demoting also lets pacman clean it up on its own once whatever
# needed it is gone. `libpulse` is the canonical case: 22 packages depend on it,
# it cannot be removed, and declaring it would be a lie.
#
# The inverse of bin/pkg-promote.sh, which reads the same style of list.
#
# Two classes of package are REFUSED rather than demoted, because demoting them
# is how you lose a package by accident:
#
#   1. Nothing requires it. Demoting would make it an orphan, and the next
#      `pacman -Rns $(pacman -Qdtq)` would delete it. Remove it deliberately or
#      declare it instead.
#   2. This repo declares it. Declared-plus-dependency is exactly the state that
#      leaves `vlc` one orphan cleanup away from being uninstalled.
#
# Nothing is installed, removed or downloaded. The only thing that changes is
# the install-reason field in pacman's local database, and bin/pkg-promote.sh
# reverses it.
#
# Usage:
#   ./bin/pkg-demote.sh                    # preview only — the default
#   ./bin/pkg-demote.sh --apply            # actually change the install reasons
#   ./bin/pkg-demote.sh --file other.txt   # read a different list
#
# Previewing needs no sudo, so the default mode is safe to run anywhere.
# Exit status: 0 = fine, 1 = something was refused (see above) or a bad argument.
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
if [[ "$EUID" -eq 0 ]]; then
  echo "Run this as your normal user, not root — it calls sudo itself." >&2
  exit 1
fi

REPO_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
HOSTNAME_SHORT="$(hostnamectl --static 2>/dev/null || cat /etc/hostname 2>/dev/null || echo unknown)"
SHARED_DIR="$REPO_DIR/shared"
HOST_DIR="$REPO_DIR/hosts/$HOSTNAME_SHORT"
LIST="${LIST:-$REPO_DIR/pkg-demote.txt}"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }
bad()  { printf '\033[1;31m[x]\033[0m %s\n' "$*"; }
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

# pacman -Qi only wraps long values when stdout is a tty; inside this pipeline
# it never is, so every field is exactly one line and this stays reliable.
qi_field() {
  pacman -Qi "$1" 2>/dev/null | awk -F' *: *' -v f="$2" '$1 == f { print $2; exit }'
}

DECLARED="$(strip_list "$SHARED_DIR/pacman.txt" "$HOST_DIR/pacman.txt" \
                       "$SHARED_DIR/aur.txt"    "$HOST_DIR/aur.txt" | sort -u)"

TODO=()         # actually needs changing
ALREADY=()      # already a dependency, nothing to do
MISSING=()      # in the list but not installed here
ORPHANRISK=()   # refused: demoting would orphan it
ISDECLARED=()   # refused: the repo declares it

while read -r pkg; do
  [[ -n "$pkg" ]] || continue
  if ! pacman -Qq "$pkg" &>/dev/null; then
    MISSING+=("$pkg")
    continue
  fi
  # -Qqd lists packages installed as dependencies; a hit means already correct.
  if pacman -Qqd "$pkg" &>/dev/null; then
    ALREADY+=("$pkg")
    continue
  fi
  if grep -qxF "$pkg" <<<"$DECLARED"; then
    ISDECLARED+=("$pkg")
    continue
  fi
  # `pacman -Qdt` treats an optional dependency as "required", so a package that
  # is merely an optdep of something installed is NOT an orphan. Both fields
  # have to be None before demoting is actually dangerous.
  if [[ "$(qi_field "$pkg" 'Required By')" == "None" \
     && "$(qi_field "$pkg" 'Optional For')" == "None" ]]; then
    ORPHANRISK+=("$pkg")
    continue
  fi
  TODO+=("$pkg")
done < <(strip_list "$LIST" | sort -u)

printf 'Host: %s   list: %s\n' "$HOSTNAME_SHORT" "$LIST"
REFUSED=0

[[ ${#ALREADY[@]} -gt 0 ]] && { bold "Already a dependency (${#ALREADY[@]}) — nothing to do"; printf '      %s\n' "${ALREADY[@]}"; }

if [[ ${#MISSING[@]} -gt 0 ]]; then
  bold "Not installed on this host (${#MISSING[@]}) — skipped"
  printf '      %s\n' "${MISSING[@]}"
  dim "  These lists are shared across hosts, so this is normal and not an error."
fi

if [[ ${#ORPHANRISK[@]} -gt 0 ]]; then
  REFUSED=1
  bold "REFUSED — nothing requires these, demoting would orphan them (${#ORPHANRISK[@]})"
  printf '      %s\n' "${ORPHANRISK[@]}"
  bad "The next 'pacman -Rns \$(pacman -Qdtq)' would delete them."
  dim "  Either remove them on purpose, or declare them and use pkg-promote.sh."
fi

if [[ ${#ISDECLARED[@]} -gt 0 ]]; then
  REFUSED=1
  bold "REFUSED — this repo declares these (${#ISDECLARED[@]})"
  printf '      %s\n' "${ISDECLARED[@]}"
  bad "Declared + dependency is the state that puts a package one cleanup away"
  bad "from deletion. Undeclare it first, or leave it explicit."
fi

if [[ ${#TODO[@]} -eq 0 ]]; then
  bold "Nothing to demote."
  exit "$REFUSED"
fi

bold "Will mark as installed-as-dependency (${#TODO[@]})"
for pkg in "${TODO[@]}"; do
  printf '      %-24s required by: %s\n' "$pkg" "$(qi_field "$pkg" 'Required By')"
done

if [[ "$APPLY" -eq 0 ]]; then
  dim "  preview only — re-run with --apply to make the change"
  exit "$REFUSED"
fi

sudo pacman -D --asdeps "${TODO[@]}"
ok "Demoted ${#TODO[@]} package(s). Verify with: ./bin/pkg-diff.sh"
exit "$REFUSED"
