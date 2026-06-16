#!/usr/bin/env bash
set -uo pipefail
# Toggle: if the picker (fuzzel) is already open, clicking the icon again closes it.
if pgrep -x fuzzel >/dev/null 2>&1; then pkill -x fuzzel; exit 0; fi
powered="$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}')"
menu=""
[ "$powered" = "yes" ] && menu+="Power off"$'\n' || menu+="Power on"$'\n'
menu+="Scan (10s)"$'\n'
declare -A MAC
while read -r _ mac name; do
  [ -n "${mac:-}" ] || continue
  state="  "; bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes" && state="* "
  line="${state}${name}"; menu+="${line}"$'\n'; MAC["$line"]="$mac"
done < <(bluetoothctl devices 2>/dev/null)
choice="$(printf '%s' "$menu" | fuzzel --dmenu -p 'bluetooth > ')"
[ -n "${choice:-}" ] || exit 0
case "$choice" in
  "Power on")  bluetoothctl power on  >/dev/null 2>&1 ;;
  "Power off") bluetoothctl power off >/dev/null 2>&1 ;;
  "Scan (10s)") notify-send "Bluetooth" "Scanning 10s..."; bluetoothctl --timeout 10 scan on >/dev/null 2>&1 || true ;;
  *) mac="${MAC[$choice]:-}"; [ -n "$mac" ] || exit 0
     if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
       bluetoothctl disconnect "$mac" >/dev/null 2>&1; notify-send "Bluetooth" "Disconnected"
     else
       bluetoothctl connect "$mac" >/dev/null 2>&1 && notify-send "Bluetooth" "Connected" || notify-send "Bluetooth" "Connect failed"
     fi ;;
esac
