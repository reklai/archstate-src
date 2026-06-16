#!/usr/bin/env bash
set -uo pipefail

if pgrep -x fuzzel >/dev/null 2>&1; then
  pkill -x fuzzel
  exit 0
fi

if ! command -v powerprofilesctl >/dev/null 2>&1; then
  notify-send "Power profile" "powerprofilesctl not found"
  exit 1
fi

current="$(powerprofilesctl get 2>/dev/null || true)"
mapfile -t profiles < <(powerprofilesctl list 2>/dev/null | sed -n 's/^[* ] *\([a-z-][a-z-]*\):.*/\1/p')

if [ "${#profiles[@]}" -eq 0 ]; then
  notify-send "Power profile" "No profiles available"
  exit 1
fi

label_for() {
  case "$1" in
    performance) printf 'Performance' ;;
    balanced) printf 'Balanced' ;;
    power-saver) printf 'Power saver' ;;
    *) printf '%s' "$1" ;;
  esac
}

declare -A PROFILE_BY_LINE
menu=""
for profile in "${profiles[@]}"; do
  mark="  "
  [ "$profile" = "$current" ] && mark="* "
  line="${mark}$(label_for "$profile")"
  PROFILE_BY_LINE["$line"]="$profile"
  menu+="${line}"$'\n'
done

choice="$(printf '%s' "$menu" | fuzzel --dmenu -p 'power > ')"
[ -n "${choice:-}" ] || exit 0

target="${PROFILE_BY_LINE[$choice]:-}"
[ -n "$target" ] || exit 0

if powerprofilesctl set "$target"; then
  notify-send "Power profile" "$(label_for "$target")"
  pkill -RTMIN+9 waybar 2>/dev/null || true
else
  notify-send "Power profile" "Failed to set $(label_for "$target")"
  exit 1
fi
