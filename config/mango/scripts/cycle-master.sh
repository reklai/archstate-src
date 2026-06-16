#!/usr/bin/env bash
# Rotate a stack client into master.
set -euo pipefail

dir="${1:-next}"
case "$dir" in
  next|prev) ;;
  *) exit 2 ;;
esac

focused="$(mmsg get focusing-client)"
if jq -e '(.is_fullscreen // false) or (.is_fakefullscreen // false) or (.is_maximized // false)' <<<"$focused" >/dev/null; then
  exit 0
fi

monitor="$(jq -r '.monitor // empty' <<<"$focused")"
tag="$(jq -r '.tags[0] // empty' <<<"$focused")"
[ -n "$monitor" ] && [ -n "$tag" ] || exit 0

clients="$(mmsg get all-clients)"
filter='.clients | map(select(.monitor==$m and (.tags|index($t))
    and .is_floating==false and .is_minimized==false
    and .is_overlay==false and .is_scratchpad==false))'

master_id="$(jq -r --arg m "$monitor" --argjson t "$tag" \
  "$filter as \$wins
  | if (\$wins | length) < 2 then empty
    else ([\$wins[].x] | min) as \$master_x
    | \$wins | map(select(.x == \$master_x)) | sort_by(.y, .id) | .[0].id // empty
    end" <<<"$clients")"

mapfile -t stack_ids < <(jq -r --arg m "$monitor" --argjson t "$tag" \
  "$filter as \$wins
  | if (\$wins | length) < 2 then empty
    else ([\$wins[].x] | min) as \$master_x
    | \$wins | sort_by(.y, .x, .id) | .[]
    | select(.x != \$master_x) | .id
    end" <<<"$clients")

stack_count="${#stack_ids[@]}"
[ -n "$master_id" ] && [ "$stack_count" -ge 1 ] || exit 0

case "$dir" in
  next)
    target_id="${stack_ids[0]}"
    ;;
  prev)
    target_id="${stack_ids[$((stack_count - 1))]}"
    for _ in $(seq 1 $((stack_count - 1))); do
      mmsg dispatch "exchange_stack_client,prev" "client,${target_id}" >/dev/null
    done
    ;;
esac

mmsg dispatch zoom "client,${target_id}" >/dev/null

if [ "$dir" = "next" ]; then
  for _ in $(seq 1 $((stack_count - 1))); do
    mmsg dispatch "exchange_stack_client,next" "client,${master_id}" >/dev/null
  done
fi

# Land both focus AND the cursor on the new master. The exchange loop warps the
# cursor to the demoted old master, so focus a stack window (the old master), then
# glide left onto the new master: focusdir focuses and warps in one move (same
# left/right hop focus-toggle.sh relies on). Assumes a master-on-left tile layout.
mmsg dispatch focusid "client,${master_id}" >/dev/null
mmsg dispatch focusdir,left >/dev/null
