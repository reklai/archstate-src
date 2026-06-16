#!/usr/bin/env bash
# Watch display hotplug state and reapply the display profile.
set -euo pipefail

lock_dir="${XDG_RUNTIME_DIR:-/tmp}/mango-display-watch.lock"
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

while true; do
  current_signature="$(connector_signature)"
  if [ "$current_signature" != "$last_signature" ]; then
    "$HOME/.config/mango/scripts/display-profile.sh" || true
    last_signature="$current_signature"
  fi
  sleep 5
done
