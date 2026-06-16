#!/usr/bin/env bash
set -uo pipefail
# Toggle: if the picker (fuzzel) is already open, clicking the icon again closes it.
if pgrep -x fuzzel >/dev/null 2>&1; then pkill -x fuzzel; exit 0; fi
notify-send -t 2500 "Wi-Fi" "Scanning networks..."
nmcli dev wifi rescan >/dev/null 2>&1 || true
mapfile -t rows < <(nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list 2>/dev/null | awk -F: 'NF>=3 && $3!=""')
declare -A SSID; menu=""
for r in "${rows[@]}"; do
  active="${r%%:*}"; rest="${r#*:}"; sig="${rest%%:*}"; ssid="${rest#*:}"
  mark="  "; [ "$active" = "yes" ] && mark="* "
  line="${mark}${ssid} (${sig}%)"; menu+="${line}"$'\n'; SSID["$line"]="$ssid"
done
[ -n "$menu" ] || { notify-send "Wi-Fi" "No networks found"; exit 0; }
choice="$(printf '%s' "$menu" | fuzzel --dmenu -p 'wifi > ')"
[ -n "${choice:-}" ] || exit 0
target="${SSID[$choice]:-}"; [ -n "$target" ] || exit 0
if nmcli dev wifi connect "$target" >/dev/null 2>&1; then
  notify-send "Wi-Fi" "Connected to $target"
else
  pass="$(printf '' | fuzzel --dmenu --password -p "$target password > ")"
  [ -n "${pass:-}" ] || exit 0
  nmcli dev wifi connect "$target" password "$pass" >/dev/null 2>&1 \
    && notify-send "Wi-Fi" "Connected to $target" || notify-send "Wi-Fi" "Failed: $target"
fi
