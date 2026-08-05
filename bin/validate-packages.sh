#!/usr/bin/env bash
#
# Validate every name in packages/ against the real Arch and AUR indexes, for
# ALL hosts (not just this one). Catches the three mistakes the package lists
# are prone to, none of which surface until a fresh install is already running:
#
#   1. a renamed/removed package — install.sh reports it and carries on, so it
#      is easy to miss in thousands of lines of build output;
#   2. a package declared in the wrong half (an official package listed as AUR,
#      or the reverse);
#   3. an AUR package that CONFLICTS with a declared official one. pacman under
#      --noconfirm refuses to remove a conflicting installed package, so the AUR
#      half of the run aborts. This is exactly what waybar + waybar-cava did.
#
# Names are resolved against the actual repo databases (core/extra/multilib —
# the three repos install.sh enables) rather than the archlinux.org search API:
# it is the authoritative list, it is three requests instead of one per package,
# and it cannot rate-limit us into a screen of false "not found" errors. A
# package that only exists in a [testing] repo is therefore correctly reported
# as missing, since install.sh never enables those.
#
# Read-only, no sudo, no local pacman database — runs anywhere, including CI.
#
# Usage: ./bin/validate-packages.sh
# Exit status: 0 = everything resolves, 1 = at least one problem.
#

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
PKG_DIR="$REPO_DIR/packages"
MIRROR="${ARCH_MIRROR:-https://geo.mirror.pkgbuild.com}"
REPOS=(core extra multilib)
PROBLEMS=()

info() { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
bad()  { printf '\033[1;31m[x]\033[0m %s\n' "$*"; PROBLEMS+=("$*"); }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

strip_list() {
  local f
  for f in "$@"; do
    [[ -f "$f" ]] && sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$f"
  done
  return 0
}

# Shared list + every per-host list, so CI validates other machines' lists too.
collect() {
  local base="$1"
  shopt -s nullglob
  strip_list "$PKG_DIR/$base.txt" "$PKG_DIR/$base."*.txt | sort -u
  shopt -u nullglob
}

OFFICIAL="$(collect pacman)"
AUR="$(collect aur)"

########################################
# Official repos
########################################
info "Fetching $(IFS=/; echo "${REPOS[*]}") databases from $MIRROR"
for repo in "${REPOS[@]}"; do
  curl -sfL --retry 3 -o "$WORK/$repo.db" "$MIRROR/$repo/os/x86_64/$repo.db" \
    || { echo "Could not download $repo.db from $MIRROR" >&2; exit 2; }
done

# A repo db is a tarball of <pkgname>-<pkgver>-<pkgrel>/desc files. Read %NAME%
# and %PROVIDES% out of the concatenated desc files: a virtual name like
# `vulkan-driver` is satisfied by a provider, so both count as resolvable.
for repo in "${REPOS[@]}"; do
  tar xzOf "$WORK/$repo.db" --wildcards '*/desc' 2>/dev/null
done | awk '
  /^%NAME%$/     { mode = "name"; next }
  /^%PROVIDES%$/ { mode = "prov"; next }
  /^%/           { mode = "";     next }
  /^$/           { mode = "";     next }
  mode == "name" { print $0 }
  mode == "prov" { sub(/[<>=].*$/, "", $0); print $0 }
' | sort -u >"$WORK/available"

info "Checking $(printf '%s\n' "$OFFICIAL" | wc -l) official package name(s)"
while read -r name; do
  [[ -z "$name" ]] && continue
  if ! grep -qxF "$name" "$WORK/available"; then
    if printf '%s\n' "$AUR" | grep -qxF "$name"; then
      bad "$name: not in core/extra/multilib, and also listed in aur.txt — drop it from the pacman list"
    else
      bad "$name: not in core/extra/multilib (renamed, dropped, AUR-only, or [testing]-only)"
    fi
  fi
done <<<"$OFFICIAL"

########################################
# AUR
########################################
info "Checking $(printf '%s\n' "$AUR" | wc -l) AUR package name(s) against the AUR RPC"
# The RPC takes every name in one request.
aur_query=""
while read -r name; do
  [[ -n "$name" ]] && aur_query+="&arg[]=$name"
done <<<"$AUR"
curl -sfL --retry 3 -o "$WORK/aur.json" "https://aur.archlinux.org/rpc/v5/info?${aur_query#&}" \
  || { echo "Could not query the AUR RPC" >&2; exit 2; }

while read -r name; do
  [[ -z "$name" ]] && continue
  if ! jq -e --arg n "$name" '.results[] | select(.Name == $n)' "$WORK/aur.json" >/dev/null; then
    if grep -qxF "$name" "$WORK/available"; then
      bad "$name: no such AUR package, but it IS in the official repos — move it to packages/pacman.txt"
    else
      bad "$name: no such AUR package (renamed or deleted from the AUR)"
    fi
  fi
done <<<"$AUR"

########################################
# Conflicts between the two halves
########################################
info "Checking for AUR packages that conflict with declared official packages"
# `Conflicts` entries may carry a version constraint (foo>=1.2); strip it.
jq -r '.results[] | .Name as $n | (.Conflicts // [])[] | "\($n) \(.)"' "$WORK/aur.json" \
  | sed -E 's/[<>=].*$//' >"$WORK/conflicts"

while read -r aur_pkg conflicted; do
  [[ -z "${conflicted:-}" ]] && continue
  if printf '%s\n' "$OFFICIAL" | grep -qxF "$conflicted"; then
    bad "$aur_pkg (AUR) conflicts with '$conflicted', which a pacman list declares. pacman will not remove a conflicting package under --noconfirm, so install.sh's AUR half would abort — drop '$conflicted' from the pacman list ($aur_pkg provides it)."
  fi
done <"$WORK/conflicts"

########################################
# Summary
########################################
if [[ "${#PROBLEMS[@]}" -eq 0 ]]; then
  ok "All package names resolve; no AUR package conflicts with a declared official one."
  exit 0
fi
printf '\n\033[1;31m==> %s problem(s):\033[0m\n' "${#PROBLEMS[@]}"
printf '      %s\n' "${PROBLEMS[@]}"
exit 1
