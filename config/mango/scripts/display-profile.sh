#!/usr/bin/env bash
# Display profile:
#   * External plugged in -> drive the external at the same refresh rate as the
#     internal panel when it can, then switch the internal panel off.
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

outputs_json="$(wlr-randr --json 2>/dev/null || true)"
[ -n "$outputs_json" ] || exit 0

# The internal panel's top refresh -- the fps the laptop natively runs at. The
# external is matched to this rate when possible (null if there is no panel).
target_refresh="$(
  printf '%s\n' "$outputs_json" |
    jq -c '[ .[] | select(.name | startswith("eDP-")) | .modes[]?
             | select(.refresh > 0) | .refresh ]
           | if length > 0 then max else null end'
)"

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

# Candidate modes for one output, best first. Prefer modes whose refresh matches
# the internal panel ($target_refresh); then nearest refresh, then highest
# refresh, then resolution. With no panel ($target == null) this degrades to
# plain highest-refresh-first.
candidates='
  .modes
  | map(select(.width > 0 and .height > 0 and .refresh > 0))
  | sort_by([
      (if $target != null and (((.refresh - $target) | if . < 0 then -. else . end) < 1)
         then 0 else 1 end),
      (if $target != null
         then ((.refresh - $target) | if . < 0 then -. else . end) else 0 end),
      (0 - .refresh),
      (0 - (.width * .height))
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

# Bring $1 up at the most-preferred refresh that genuinely applies (matching the
# internal panel first). Returns non-zero if no advertised mode could be driven.
enable_best() {
  local out="$1" w h r
  while read -r w h r; do
    [ -n "$r" ] || continue
    wlr-randr --output "$out" --on --mode "${w}x${h}@${r}Hz" --pos 0,0 >/dev/null 2>&1 || true
    mode_active "$out" "$w" "$h" "$r" && return 0
  done < <(printf '%s\n' "$outputs_json" |
             jq -r --arg o "$out" --argjson target "$target_refresh" \
                '.[] | select(.name == $o) | '"$candidates")
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
  printf 'nvidia-external\n' >"$profile_file"
  exit 0
fi

# No usable external -> keep the internal panel on so we never go dark.
internal="$(select_output '(.name | startswith("eDP-"))')"
if [ -n "$internal" ]; then
  enable_best "$internal" ||
    wlr-randr --output "$internal" --on --preferred --pos 0,0 >/dev/null 2>&1 || true
  printf 'amd-internal\n' >"$profile_file"
fi
