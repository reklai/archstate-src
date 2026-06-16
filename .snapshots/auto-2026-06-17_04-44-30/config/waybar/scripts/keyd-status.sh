#!/usr/bin/env bash
# Waybar custom/keyd: report keyd state as JSON.
# State comes from systemd (is-active), NOT the socket file: keyd leaves a stale
# /run/keyd.socket behind when it exits, so a socket check always reported "running".
set -u
kb=$(printf '\uf11c')   # nf-fa-keyboard_o

if systemctl is-active --quiet keyd.service; then
  printf '{"text":"<span font_family=\\"Symbols Nerd Font\\" size=\\"16000\\">%s</span>","tooltip":"keyd active — click to stop","class":"on"}\n' "$kb" 2>/dev/null || exit 0
else
  printf '{"text":"<span font_family=\\"Symbols Nerd Font\\" size=\\"16000\\">%s</span>","tooltip":"keyd stopped — click to start","class":"off"}\n' "$kb" 2>/dev/null || exit 0
fi
