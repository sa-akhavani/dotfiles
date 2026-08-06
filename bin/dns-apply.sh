#!/usr/bin/env bash
#
# Apply the per-network DNS servers declared in network-dns.txt to this host's
# saved NetworkManager profiles.
#
# Why this exists: NetworkManager's profiles live in
# /etc/NetworkManager/system-connections and hold wifi PSKs, so they can never be
# tracked in this repo. The DNS *policy* can be, though — network-dns.txt is
# shared by all three hosts, and this script reconciles whatever profiles a given
# host happens to have against it. Reinstall a machine, rejoin its networks, run
# this, and the DNS choices are back.
#
# Wifi profiles are matched on the real 802-11-wireless.ssid rather than the
# profile name, because the name is only a default and can be renamed. Anything
# that is not wifi is matched on its connection name instead.
#
# Nothing is created or deleted. The only thing that changes is the ipv4/ipv6
# dns and ignore-auto-dns properties of profiles named in the list, and
# nm-connection-editor undoes any of it by hand.
#
# Usage:
#   ./bin/dns-apply.sh                    # preview only — the default
#   ./bin/dns-apply.sh --apply            # actually modify the profiles
#   ./bin/dns-apply.sh --file other.txt   # read a different list
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
if [[ "$EUID" -eq 0 ]]; then
  echo "Run this as your normal user, not root — it calls sudo itself." >&2
  exit 1
fi

REPO_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
HOSTNAME_SHORT="$(hostnamectl --static 2>/dev/null || cat /etc/hostname 2>/dev/null || echo unknown)"
LIST="${LIST:-$REPO_DIR/network-dns.txt}"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

[[ -f "$LIST" ]] || { echo "no such list: $LIST" >&2; exit 1; }
command -v nmcli >/dev/null 2>&1 || { echo "nmcli not found — is networkmanager installed?" >&2; exit 1; }
# Reading profiles needs the daemon, not just the files on disk.
nmcli -t general status >/dev/null 2>&1 || {
  echo "NetworkManager is not running; start it before reconciling DNS." >&2; exit 1; }

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# Strip comments only where a '#' starts the line or follows whitespace, so an
# SSID may legitimately contain one. Blank lines go too.
parse_list() { sed -e 's/^[[:space:]]*#.*//' -e 's/[[:space:]]#.*//' -e '/^[[:space:]]*$/d' "$1"; }

# nmcli's terse/get-values output escapes ':' as '\:', which matters the moment
# an IPv6 nameserver is read back for comparison.
unescape() { printf '%s' "${1//\\:/:}"; }

declare -A WANT=()
ORDER=()

while IFS= read -r line; do
  if [[ "$line" != *=* ]]; then
    warn "ignoring malformed line (no '='): $line"
    continue
  fi
  key="$(trim "${line%%=*}")"
  val="$(trim "${line#*=}")"
  if [[ -z "$key" || -z "$val" ]]; then
    warn "ignoring malformed line (empty side): $line"
    continue
  fi
  [[ -v "WANT[$key]" ]] || ORDER+=("$key")
  WANT["$key"]="$val"
done < <(parse_list "$LIST")

printf 'Host: %s   list: %s\n' "$HOSTNAME_SHORT" "$LIST"

if [[ ${#WANT[@]} -eq 0 ]]; then
  bold "No entries in $(basename "$LIST") — nothing to do."
  dim "  Add lines of the form:  MySSID = 1.1.1.1 1.0.0.1"
  exit 0
fi

PLAN_NAMES=()   # human-readable description, one per planned change
PLAN_ARGS=()    # newline-joined nmcli args, index-aligned with PLAN_NAMES
PLAN_UUIDS=()
MATCHED=()      # which list keys matched at least one profile
declare -A SEEN=()

while IFS= read -r uuid; do
  [[ -n "$uuid" ]] || continue
  ctype="$(nmcli -g connection.type connection show uuid "$uuid" 2>/dev/null || true)"
  cname="$(nmcli -g connection.id   connection show uuid "$uuid" 2>/dev/null || true)"
  if [[ "$ctype" == "802-11-wireless" ]]; then
    key="$(unescape "$(nmcli -g 802-11-wireless.ssid connection show uuid "$uuid" 2>/dev/null || true)")"
    label="wifi SSID '$key'"
    [[ "$key" == "$cname" ]] || label="$label (profile '$cname')"
  else
    key="$cname"
    label="$ctype connection '$cname'"
  fi
  [[ -n "$key" ]] || continue
  [[ -v "WANT[$key]" ]] || continue

  SEEN["$key"]=1

  # Split the declared servers by family. Commas are just separators, and
  # anything with a ':' in it can only be IPv6.
  v4=(); v6=()
  for srv in ${WANT[$key]//,/ }; do
    if [[ "$srv" == *:* ]]; then v6+=("$srv"); else v4+=("$srv"); fi
  done

  args=(); changes=()
  for fam in ipv4 ipv6; do
    if [[ "$fam" == ipv4 ]]; then want_list=("${v4[@]+"${v4[@]}"}"); else want_list=("${v6[@]+"${v6[@]}"}"); fi
    [[ ${#want_list[@]} -gt 0 ]] || continue
    want_str="$(IFS=,; printf '%s' "${want_list[*]}")"
    have_str="$(unescape "$(nmcli -g "$fam.dns" connection show uuid "$uuid" 2>/dev/null || true)")"
    have_ign="$(nmcli -g "$fam.ignore-auto-dns" connection show uuid "$uuid" 2>/dev/null || true)"
    if [[ "$have_str" != "$want_str" ]]; then
      args+=("$fam.dns" "$want_str")
      changes+=("$fam.dns: ${have_str:-<none>} -> $want_str")
    fi
    # Without this the DHCP/RA servers stay in front of ours and the override
    # silently does nothing.
    if [[ "$have_ign" != "yes" ]]; then
      args+=("$fam.ignore-auto-dns" "yes")
      changes+=("$fam.ignore-auto-dns: ${have_ign:-<unset>} -> yes")
    fi
  done

  if [[ ${#args[@]} -eq 0 ]]; then
    MATCHED+=("$label — already correct")
    continue
  fi
  MATCHED+=("$label")
  PLAN_NAMES+=("$label"$'\n'"$(printf '        %s\n' "${changes[@]}")")
  PLAN_UUIDS+=("$uuid")
  PLAN_ARGS+=("$(printf '%s\n' "${args[@]}")")
done < <(nmcli -g UUID connection show)

UNMATCHED=()
for key in "${ORDER[@]}"; do
  [[ -v "SEEN[$key]" ]] || UNMATCHED+=("$key")
done

if [[ ${#MATCHED[@]} -gt 0 ]]; then
  bold "Profiles on this host matching the list (${#MATCHED[@]})"
  printf '      %s\n' "${MATCHED[@]}"
fi

if [[ ${#UNMATCHED[@]} -gt 0 ]]; then
  bold "Declared but not saved on this host (${#UNMATCHED[@]}) — skipped"
  printf '      %s\n' "${UNMATCHED[@]}"
  dim "  This list is shared across hosts, so this is normal and not an error."
  dim "  Join the network once (the PSK cannot live in this repo), then re-run."
fi

if [[ ${#PLAN_UUIDS[@]} -eq 0 ]]; then
  bold "Nothing to change."
  exit 0
fi

bold "Will modify ${#PLAN_UUIDS[@]} profile(s)"
printf '      %s\n' "${PLAN_NAMES[@]}"

if [[ "$APPLY" -eq 0 ]]; then
  dim "  preview only — re-run with --apply to make the change"
  exit 0
fi

for i in "${!PLAN_UUIDS[@]}"; do
  mapfile -t args < <(printf '%s' "${PLAN_ARGS[$i]}")
  sudo nmcli connection modify uuid "${PLAN_UUIDS[$i]}" "${args[@]}"
done

ok "Updated ${#PLAN_UUIDS[@]} profile(s)."
dim "  A profile that is currently active keeps its old DNS until it is"
dim "  reactivated:  nmcli connection up <name>   (or just reconnect)."
