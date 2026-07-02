#!/usr/bin/env bash
# Display profile:
#   * External plugged in -> drive the external at its highest-refresh mode,
#     choosing the highest resolution available at that refresh, then switch the
#     internal panel off.
#   * No usable external     -> fall back to the internal panel.
#
# Each candidate mode is applied and then verified actually current, so a mode
# the output/GPU link can't drive is skipped instead of leaving you dark.
set -euo pipefail

command -v wlr-randr >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

profile_file="${XDG_RUNTIME_DIR:-/tmp}/mango-gpu-current-profile"
if [ -r "$HOME/.config/mango/scripts/gpu-profile-lib.sh" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.config/mango/scripts/gpu-profile-lib.sh"
  profile_file="$(mango_gpu_current_profile_file)"
fi

current_gpu_profile() {
  if declare -F mango_desired_gpu_profile >/dev/null; then
    mango_desired_gpu_profile 2>/dev/null && return 0
  fi
  printf 'amd-only\n'
}

outputs_json=""
for _ in 1 2 3 4 5; do
  outputs_json="$(wlr-randr --json 2>/dev/null || true)"
  [ -n "$outputs_json" ] && break
  sleep 0.2
done
[ -n "$outputs_json" ] || exit 0

# Rank an output by its best mode: [refresh, area, preferred], highest wins.
score='
  (.modes | map(select(.width > 0 and .height > 0 and .refresh > 0))) as $m
  | if ($m | length) == 0 then [0, 0, 0]
    else ($m | max_by(.refresh).refresh) as $r
      | ($m | map(select(.refresh == $r))
           | max_by([(.width * .height), (.preferred // false | if . then 1 else 0 end)]))
      | [.refresh, (.width * .height), (.preferred // false | if . then 1 else 0 end)]
    end
'

# Candidate modes for one output, best first. Prefer highest refresh, then the
# highest resolution available at that refresh.
candidates='
  .modes
  | map(select(.width > 0 and .height > 0 and .refresh > 0))
  | sort_by([
      (0 - .refresh),
      (0 - (.width * .height)),
      (0 - (.preferred // false | if . then 1 else 0 end))
    ])
  | .[] | "\(.width) \(.height) \(.refresh)"
'

# Highest-scoring connected output matching the given jq predicate.
select_output() {
  printf '%s\n' "$outputs_json" |
    jq -r 'map(select(('"$1"') and (.modes | length > 0)))
           | sort_by('"$score"') | reverse | .[0].name // empty'
}

# True once $1 is enabled with the requested mode actually current (modeset stuck).
mode_active() {
  wlr-randr --json 2>/dev/null |
    jq -e --arg o "$1" --argjson w "$2" --argjson h "$3" --argjson r "$4" '
      any(.[]; .name == $o and .enabled == true
        and (.modes | any(.current == true and .width == $w and .height == $h
              and ((.refresh - $r) | if . < 0 then -. else . end) < 1)))' >/dev/null 2>&1
}

# Bring $1 up at the best advertised mode that genuinely applies. Returns
# non-zero if no advertised mode could be driven.
enable_best() {
  local out="$1" w h r
  while read -r w h r; do
    [ -n "$r" ] || continue
    wlr-randr --output "$out" --on --mode "${w}x${h}@${r}Hz" --pos 0,0 >/dev/null 2>&1 || true
    mode_active "$out" "$w" "$h" "$r" && return 0
  done < <(printf '%s\n' "$outputs_json" |
             jq -r --arg o "$out" '.[] | select(.name == $o) | '"$candidates")
  return 1
}

external="$(select_output '(.name | startswith("eDP-") | not)')"

if [ -n "$external" ] && enable_best "$external"; then
  # External is confirmed live -> switch every other output (internal panel and
  # any secondary output) off so only the chosen external drives the desktop.
  while IFS= read -r other; do
    [ "$other" = "$external" ] && continue
    wlr-randr --output "$other" --off >/dev/null 2>&1 || true
  done < <(printf '%s\n' "$outputs_json" | jq -r '.[].name')
  current_gpu_profile >"$profile_file"
  exit 0
fi

# No usable external -> keep the internal panel on so we never go dark.
internal="$(select_output '(.name | startswith("eDP-"))')"
if [ -n "$internal" ]; then
  enable_best "$internal" ||
    wlr-randr --output "$internal" --on --preferred --pos 0,0 >/dev/null 2>&1 || true
  current_gpu_profile >"$profile_file"
fi
