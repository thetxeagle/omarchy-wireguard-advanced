#!/usr/bin/env bash
set -u

command -v nmcli >/dev/null 2>&1 || { echo "NetworkManager (nmcli) is required" >&2; exit 1; }

printf '#CONNS\n'
nmcli -t -f UUID,NAME,TYPE,ACTIVE,DEVICE,STATE connection show 2>/dev/null || exit 1

while IFS=: read -r uuid name type active device state; do
  [ "$type" = wireguard ] || continue
  printf '#AUTO %s\n' "$uuid"
  nmcli -t -f connection.autoconnect connection show uuid "$uuid" 2>/dev/null | sed 's/^connection.autoconnect://' || true
  printf '#PEER %s\n' "$uuid"
  nmcli -t -f wireguard.peer connection show uuid "$uuid" 2>/dev/null || true
  if [ -n "$device" ] && [ "$device" != "--" ]; then
    printf '#DEV %s\n' "$device"
    nmcli -t -f IP4.ADDRESS,IP6.ADDRESS,IP4.ROUTE,IP6.ROUTE device show "$device" 2>/dev/null || true
    printf '#STAT %s\n' "$device"
    cat "/sys/class/net/$device/statistics/rx_bytes" 2>/dev/null || printf -- '-1\n'
    cat "/sys/class/net/$device/statistics/tx_bytes" 2>/dev/null || printf -- '-1\n'
  fi
done < <(nmcli -t -f UUID,NAME,TYPE,ACTIVE,DEVICE,STATE connection show 2>/dev/null)
