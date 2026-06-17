#!/usr/bin/env bash
# Waybar wireplumber on-click: toggle the audio mixer window.
# Click once to open pavucontrol; click again (on the speaker icon) to close it.
# Handy under Mango/dwl where the window has no titlebar/X and Esc doesn't close it.
set -u

if pgrep -x pavucontrol >/dev/null 2>&1; then
  pkill -x pavucontrol
else
  GTK_THEME=Adwaita:dark setsid -f pavucontrol >/dev/null 2>&1
fi
