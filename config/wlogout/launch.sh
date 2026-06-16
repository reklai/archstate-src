#!/bin/sh
set -eu

buttons=5
gap=12
button_w=112
button_h=124

size="$(
    mmsg get all-monitors 2>/dev/null |
        jq -r '[.monitors[] | select(.active == true and .width > 0 and .height > 0)][0] | "\(.width) \(.height)"' 2>/dev/null ||
        true
)"

set -- ${size:-1920 1080}
width=${1:-1920}
height=${2:-1080}

case "$width:$height" in
    *[!0-9:]* | 0:* | *:0)
        width=1920
        height=1080
        ;;
esac

target_w=$((buttons * button_w + (buttons - 1) * gap))
target_h=$button_h
margin_x=$(((width - target_w) / 2))
margin_y=$(((height - target_h) / 2))

[ "$margin_x" -lt 24 ] && margin_x=24
[ "$margin_y" -lt 24 ] && margin_y=24

exec wlogout \
    -p layer-shell \
    -n \
    -b "$buttons" \
    -c "$gap" \
    -r "$gap" \
    -L "$margin_x" \
    -R "$margin_x" \
    -T "$margin_y" \
    -B "$margin_y" \
    "$@"
