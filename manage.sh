#!/usr/bin/env bash
set -u
umask 077

die() { printf '%s\n' "$1" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "$1 is required"; }
need nmcli

action=${1:-}
target=${2:-}
name=${3:-}
case "$action" in
  add)
    if [ -z "$target" ]; then
      need omarchy
      target=$(omarchy file select --title 'Import WireGuard configuration' --extensions 'conf')
      picker_status=$?
      [ "$picker_status" -eq 1 ] && exit 0
      [ "$picker_status" -eq 0 ] || die "Could not open the system file chooser"
    fi
    [ -f "$target" ] || die "Config file not found"
    nmcli connection import type wireguard file "$target"
    ;;
  rename)
    [ -n "$target" ] || die "A profile UUID is required"
    [ -n "$name" ] || die "A profile name is required"
    nmcli connection modify uuid "$target" connection.id "$name"
    ;;
  delete)
    [ -n "$target" ] || die "A profile UUID is required"
    nmcli connection delete uuid "$target"
    ;;
  on) nmcli connection up uuid "$target" ;;
  off) nmcli connection down uuid "$target" ;;
  autoOn) nmcli connection modify uuid "$target" connection.autoconnect yes ;;
  autoOff) nmcli connection modify uuid "$target" connection.autoconnect no ;;
  *) die "Usage: manage.sh add [file] | rename <uuid> <name> | delete|on|off|autoOn|autoOff <uuid>" ;;
esac
