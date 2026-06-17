#!/usr/bin/env bash
# Waybar custom/keyd on-click: toggle keyd, notify, refresh the module.
# State is read from systemd (is-active), NOT the socket file: keyd leaves a stale
# /run/keyd.socket when it exits, so the old socket check always saw "running" and
# the toggle could only ever stop the service, never start it.
set -u

if systemctl is-active --quiet keyd.service; then
  action=stop;  title="Keyd -> Stop"
else
  action=start; title="Keyd -> Start"
fi

# Block until the job settles (no --no-block) so the refresh below reflects the real
# state and the icon flips immediately. --no-ask-password avoids hanging on a polkit
# prompt if the session ever lacks authorization (it fails fast instead).
systemctl --no-ask-password "$action" keyd.service
rc=$?

command -v notify-send >/dev/null 2>&1 && notify-send "$title" >/dev/null 2>&1 || true
# nudge waybar to re-run the status module (matches "signal": 8)
pkill -RTMIN+8 waybar 2>/dev/null || true

exit "$rc"
