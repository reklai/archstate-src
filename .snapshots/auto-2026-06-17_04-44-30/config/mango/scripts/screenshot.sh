#!/usr/bin/env bash
# Select a region, save it, and copy it to the clipboard.
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

FILE="$DIR/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"

grim -g "$(slurp)" - | tee "$FILE" | wl-copy

notify-send "Screenshot Captured" "Saved to $FILE" -i $HOME/.config/mango/scripts/screenshot.png
