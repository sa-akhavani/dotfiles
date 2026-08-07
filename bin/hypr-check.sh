#!/usr/bin/env bash
#
# Validate the Hyprland Lua config without touching the running session.
#
# Hyprland's config is Lua as of 0.55 (hyprlang is deprecated and on its way
# out). `Hyprland --verify-config` loads a config, reports what is wrong with
# it, and exits without starting a compositor — so this is safe to run from
# inside your own session, and needs no sudo.
#
# Two reasons this is a script and not a one-liner:
#
#   * the config is chezmoi-templated, so what is in home/ is not what Hyprland
#     reads. Each GPU value is rendered to a throwaway directory and checked
#     there, which is the only way a laptop can catch a config it just broke for
#     the NVIDIA desktop.
#   * --verify-config does exit nonzero on a bad config, but only if you keep
#     the status: `Hyprland --verify-config -c f | tail -1` reports tail's 0 and
#     looks like a pass. Hence no pipe on the command itself here.
#
# What it catches: syntax errors, unknown hl.* functions, unknown config keys,
# wrong value types, bad modifier names in binds, unknown event names, and
# invalid window-rule fields.
#
# What it does NOT catch: dispatcher option typos (an unknown key in
# hl.dsp.window.move({...}) is silently ignored) and mistyped final keysyms
# ("leftt"). Those still need a real session to shake out.
#
# Usage:
#   ./bin/hypr-check.sh          # check every GPU variant
#   ./bin/hypr-check.sh --gpu nvidia
#
# Exit status: 0 = every variant is fine, 1 = at least one is not.
#

set -euo pipefail

GPUS=(intel amd nvidia)

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --gpu)     GPUS=("$2"); shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown argument: $1 (try --help)" >&2; exit 1 ;;
  esac
done

REPO_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }
bad()  { printf '\033[1;31m[x]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

command -v chezmoi   >/dev/null 2>&1 || { echo "chezmoi is not installed"   >&2; exit 1; }
command -v Hyprland  >/dev/null 2>&1 || { echo "Hyprland is not installed"  >&2; exit 1; }

FAILED=0

# Cheap first pass: a syntax error is worth catching before spinning up
# Hyprland three times, and it names the file directly. Templates are skipped —
# they are not valid Lua until chezmoi has rendered them.
if command -v luac >/dev/null 2>&1; then
  bold "Lua syntax (luac -p)"
  while IFS= read -r -d '' f; do
    if luac -p "$f" 2>/dev/null; then
      ok "${f#"$REPO_DIR"/}"
    else
      bad "${f#"$REPO_DIR"/}"
      luac -p "$f" 2>&1 | sed 's/^/      /'
      FAILED=1
    fi
  done < <(find "$REPO_DIR/home/dot_config/hypr" -name '*.lua' -print0 | sort -z)
fi

bold "Hyprland --verify-config, per GPU"

for gpu in "${GPUS[@]}"; do
  cfg=$(mktemp --suffix=.toml)      # .toml suffix required: chezmoi picks its
  dest=$(mktemp -d)                 # config parser from the file extension
  printf 'sourceDir = "%s"\ndestDir = "%s"\n\n[data]\n    gpu = "%s"\n' \
    "$REPO_DIR" "$dest" "$gpu" >"$cfg"

  if ! chezmoi --config "$cfg" --source "$REPO_DIR" --destination "$dest" \
       apply >/dev/null 2>&1; then
    bad "$gpu: chezmoi failed to render the templates"
    FAILED=1
    rm -rf "$cfg" "$dest"
    continue
  fi

  entry="$dest/.config/hypr/hyprland.lua"
  if [[ ! -f "$entry" ]]; then
    bad "$gpu: no hyprland.lua was rendered (is it in .chezmoiignore?)"
    FAILED=1
    rm -rf "$cfg" "$dest"
    continue
  fi

  # Unpiped and inside `if`, so the real status survives and `set -e` does not
  # abort the run before the errors can be printed.
  #
  # HOME points at the rendered tree, not the real one. workspaces.lua finds
  # split-monitor-workspaces through $HOME (Hyprland resolves require() against
  # the config directory only, so the library has to be on package.path by
  # absolute path), and chezmoi has just cloned that external into $dest. Left
  # alone, this would either check the copy in the real $HOME — the wrong one —
  # or fail outright on a host where it has not been applied yet.
  if out=$(HOME="$dest" Hyprland --verify-config -c "$entry" 2>&1); then
    ok "$gpu"
  else
    bad "$gpu"
    sed -n '/Config parsing result:/,$p' <<<"$out" \
      | grep -vE '^\s*$|Config parsing result:|^=+$' \
      | sed 's/^/      /'
    FAILED=1
  fi

  rm -rf "$cfg" "$dest"
done

if [[ "$FAILED" -ne 0 ]]; then
  bold "Config is broken — do NOT reload."
  dim "  the running session keeps its current config until you apply"
  exit 1
fi

bold "All variants parse."
dim "  binds and dispatcher arguments are still only proven by using them"
exit 0
