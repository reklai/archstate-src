#!/usr/bin/env bash
# Prefer the best external display; fall back to the internal display.
set -euo pipefail

if ! command -v wlr-randr >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

outputs_json="$(wlr-randr --json 2>/dev/null || true)"
if [ -z "$outputs_json" ]; then
  exit 0
fi

best_mode_filter='
  .modes
  | map(select(.width > 0 and .height > 0 and .refresh > 0))
  | max_by(.refresh)
  | "\(.width)x\(.height)@\(.refresh)Hz"
'

selected_external="$(
  printf '%s\n' "$outputs_json" |
    jq -r 'map(select((.name | startswith("eDP-") | not) and (.modes | length > 0)))
           | sort_by((.modes | map(.refresh) | max) // 0)
           | reverse
           | .[0].name // empty'
)"

if [ -n "$selected_external" ]; then
  selected_mode="$(
    printf '%s\n' "$outputs_json" |
      jq -r --arg output "$selected_external" '.[] | select(.name == $output) | '"$best_mode_filter"
  )"

  wlr-randr --output "$selected_external" --on --mode "$selected_mode" --pos 0,0 || true

  while IFS= read -r output; do
    [ "$output" = "$selected_external" ] && continue
    wlr-randr --output "$output" --off || true
  done < <(printf '%s\n' "$outputs_json" | jq -r '.[].name')

  exit 0
fi

internal="$(
  printf '%s\n' "$outputs_json" |
    jq -r 'map(select((.name | startswith("eDP-")) and (.modes | length > 0)))
           | sort_by((.modes | map(.refresh) | max) // 0)
           | reverse
           | .[0].name // empty'
)"

if [ -n "$internal" ]; then
  internal_mode="$(
    printf '%s\n' "$outputs_json" |
      jq -r --arg output "$internal" '.[] | select(.name == $output) | '"$best_mode_filter"
  )"
  wlr-randr --output "$internal" --on --mode "$internal_mode" --pos 0,0 || true
fi
