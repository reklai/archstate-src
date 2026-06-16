#!/usr/bin/env bash
# Static wallpaper via swaybg. Persists the chosen image across logins.
#   wallpaper.sh restore   -> apply saved image (or default); used at login
#   wallpaper.sh pick      -> choose an image from the folder, apply, save
#   wallpaper.sh random    -> pick a random image from the folder, apply, save
#   wallpaper.sh <path>    -> apply a specific image, save
set -euo pipefail

dir="$HOME/Pictures/Wallpapers"
state="$HOME/.cache/waybar-wallpaper.path"
default="$HOME/Pictures/Wallpapers/Anime Girl Student Sunset 4k Wallpaper iPhone HD Phone 3171m.jpg"

case "${1:-restore}" in
  pick|picker|select)
    if pgrep -x fuzzel >/dev/null 2>&1; then pkill -x fuzzel; exit 0; fi
    declare -A WALLPAPERS
    menu=""
    while IFS= read -r -d '' file; do
      label="$(basename "$file")"
      WALLPAPERS["$label"]="$file"
      menu+="${label}"$'\n'
    done < <(find "$dir" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 | sort -z)
    [[ -n "$menu" ]] || { notify-send "Wallpaper" "No images found in $dir"; exit 0; }
    choice="$(printf '%s' "$menu" | fuzzel --dmenu -p 'wallpaper > ')"
    [[ -n "${choice:-}" ]] || exit 0
    img="${WALLPAPERS[$choice]:-}"
    ;;
  random)
    img="$(find "$dir" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n1)"
    ;;
  restore|"")
    if [[ -f "$state" ]]; then img="$(cat "$state")"; else img="$default"; fi
    [[ -f "$img" ]] || img="$default"
    ;;
  *)
    img="$1"
    ;;
esac

[[ -n "${img:-}" && -f "$img" ]] || exit 0
printf '%s' "$img" > "$state"

unit="mango-wallpaper.service"

if command -v systemd-run >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user stop "$unit" >/dev/null 2>&1 || true

  env_args=()
  for name in WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS; do
    if [[ -n "${!name:-}" ]]; then
      env_args+=(--setenv="${name}=${!name}")
    fi
  done

  systemd-run \
    --user \
    --quiet \
    --collect \
    --unit="$unit" \
    --property=Description="Mango wallpaper" \
    --property=PartOf=mango-session.target \
    "${env_args[@]}" \
    swaybg -i "$img" -m fill
else
  pkill -x swaybg 2>/dev/null || true
  swaybg -i "$img" -m fill >/dev/null 2>&1 &
  disown
fi
