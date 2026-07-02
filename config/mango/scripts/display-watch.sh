#!/usr/bin/env bash
# Watch display hotplug state and reapply the display profile.
set -euo pipefail

lock_key="${MANGO_INSTANCE_SIGNATURE:-${XDG_SESSION_ID:-default}}"
lock_key="${lock_key##*/}"
lock_dir="${XDG_RUNTIME_DIR:-/tmp}/mango-display-watch-${lock_key}.lock"
if ! mkdir "$lock_dir" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$lock_dir"' EXIT

connector_signature() {
  for status_file in /sys/class/drm/card*-*/status; do
    [ -e "$status_file" ] || continue
    printf '%s=' "${status_file%/status}"
    cat "$status_file"
  done | sort
}

last_signature=""

notify_gpu_profile_mismatch() {
  [ -r "$HOME/.config/mango/scripts/gpu-profile-lib.sh" ] || return 0
  # shellcheck source=/dev/null
  . "$HOME/.config/mango/scripts/gpu-profile-lib.sh"

  local desired started
  desired="$(mango_desired_gpu_profile 2>/dev/null || true)"
  started="$(cat "$(mango_gpu_started_profile_file)" 2>/dev/null || true)"

  [ -n "$desired" ] || return 0
  [ -n "$started" ] || return 0
  [ "$desired" != "$started" ] || return 0

  if command -v notify-send >/dev/null 2>&1; then
    notify-send \
      "GPU profile changed" \
      "Restart Mango to switch from $started to $desired and fully release the unused GPU."
  fi
}

while true; do
  current_signature="$(connector_signature)"
  if [ "$current_signature" != "$last_signature" ]; then
    "$HOME/.config/mango/scripts/display-profile.sh" || true
    notify_gpu_profile_mismatch
    last_signature="$current_signature"
  fi
  sleep 5
done
