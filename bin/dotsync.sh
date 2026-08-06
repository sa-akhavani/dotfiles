#!/usr/bin/env bash
#
# Pull changes made directly in $HOME back into this repo, so editing
# ~/.config/something by hand is not silently lost on the next `chezmoi apply`.
#
# This is `chezmoi re-add`, wrapped in the one safety check it does not do for
# itself. re-add copies DESTINATION over SOURCE. If you edited a file in the
# repo and have not applied it yet, a bare re-add overwrites your repo edit with
# the old content still sitting in $HOME — silently, and with no undo beyond git.
#
# `chezmoi status` prints two columns and they distinguish the two cases:
#
#   col1  destination changed since chezmoi last wrote it   -> re-add captures it
#   col2  destination differs from target, apply will change it
#
# So "col1 blank, col2 set" means only the SOURCE moved: an apply is pending and
# re-adding would throw it away. Those entries are refused; everything else is
# a genuine $HOME edit and gets pulled in.
#
# Two limits worth knowing, both chezmoi's, not this script's:
#   * re-add only touches files chezmoi ALREADY manages. A brand-new file needs
#     `chezmoi add <path>` once — nothing can guess you wanted it tracked.
#   * templates are never overwritten (env_nvidia.conf.tmpl, .chezmoi.toml.tmpl),
#     because the rendered output cannot be turned back into a template.
#
# Nothing is committed or pushed: the repo is left dirty for you to review.
#
# Usage:
#   ./bin/dotsync.sh            # show what would be pulled back, change nothing
#   ./bin/dotsync.sh --apply    # actually re-add
#
# Exit status: 0 = fine, 1 = refused (pending apply) or a bad argument.
#

set -euo pipefail

APPLY=0

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)   APPLY=1; shift ;;
    -h|--help) usage ;;
    *) echo "unknown argument: $1 (try --help)" >&2; exit 1 ;;
  esac
done

REPO_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }
bad()  { printf '\033[1;31m[x]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

command -v chezmoi >/dev/null 2>&1 || { echo "chezmoi is not installed" >&2; exit 1; }

CHANGED=()   # edited in $HOME -> re-add pulls these back
PENDING=()   # source is ahead -> re-adding would clobber the repo

while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  c1="${line:0:1}"
  c2="${line:1:1}"
  path="${line:3}"
  if [[ "$c1" == " " && "$c2" != " " ]]; then
    PENDING+=("$path")
  elif [[ "$c1" != " " ]]; then
    CHANGED+=("$path")
  fi
done < <(chezmoi --source "$REPO_DIR" status)

printf 'repo: %s\n' "$REPO_DIR"

if [[ ${#PENDING[@]} -gt 0 ]]; then
  bold "REFUSED — an apply is pending for these (${#PENDING[@]})"
  printf '      %s\n' "${PENDING[@]}"
  bad "The repo is ahead of \$HOME here. Re-adding would overwrite the repo"
  bad "version with the older copy still in \$HOME."
  dim "  run 'chezmoi --source $REPO_DIR apply' first, then re-run this"
  exit 1
fi

if [[ ${#CHANGED[@]} -eq 0 ]]; then
  bold "Nothing to sync — \$HOME and the repo agree."
  exit 0
fi

bold "Changed in \$HOME, will be pulled into the repo (${#CHANGED[@]})"
printf '      %s\n' "${CHANGED[@]}"

if [[ "$APPLY" -eq 0 ]]; then
  dim "  preview only — re-run with --apply to pull them in"
  dim "  see the actual content diff with: chezmoi --source $REPO_DIR diff --reverse"
  exit 0
fi

chezmoi --source "$REPO_DIR" re-add
ok "Pulled ${#CHANGED[@]} file(s) into the repo."

bold "Repo status — review and commit yourself"
git -C "$REPO_DIR" status --short
dim "  nothing was committed or pushed; that stays a deliberate act"
