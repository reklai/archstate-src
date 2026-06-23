#!/usr/bin/env bash
# Cycle focus across tiled windows in visual order.
set -euo pipefail

focused="$(mmsg get focusing-client)"
monitor="$(jq -r '.monitor // empty' <<<"$focused")"
tag="$(jq -r '.tags[0] // empty' <<<"$focused")"
focused_id="$(jq -r '.id // empty' <<<"$focused")"
[ -n "$monitor" ] && [ -n "$tag" ] || exit 0

clients="$(mmsg get all-clients)"
filter='.clients | map(select(.monitor==$m and (.tags|index($t))
  and .is_floating==false and .is_minimized==false
  and .is_overlay==false and .is_scratchpad==false))'

visible_ids=()
visible_x=()
visible_y=()
while IFS=$'\t' read -r id x y; do
  visible_ids+=("$id")
  visible_x+=("$x")
  visible_y+=("$y")
done < <(jq -r --arg m "$monitor" --argjson t "$tag" \
  "$filter | sort_by(.x, .y, .id) | .[] | [.id, .x, .y] | @tsv" <<<"$clients")

n="${#visible_ids[@]}"
[ "$n" -ge 2 ] || exit 0

current_index=-1
target_index=0
for i in "${!visible_ids[@]}"; do
  if [ "${visible_ids[$i]}" = "$focused_id" ]; then
    current_index="$i"
    target_index="$(((i + 1) % n))"
    break
  fi
done

target_id="${visible_ids[$target_index]}"

if [ "$current_index" -ge 0 ]; then
  current_x="${visible_x[$current_index]}"
  current_y="${visible_y[$current_index]}"
  target_x="${visible_x[$target_index]}"
  target_y="${visible_y[$target_index]}"

  if [ "$target_x" -gt "$current_x" ]; then
    mmsg dispatch focusdir,right >/dev/null
  elif [ "$target_x" -lt "$current_x" ]; then
    mmsg dispatch focusdir,left >/dev/null
  elif [ "$target_y" -gt "$current_y" ]; then
    mmsg dispatch focusdir,down >/dev/null
  elif [ "$target_y" -lt "$current_y" ]; then
    mmsg dispatch focusdir,up >/dev/null
  fi
fi

focused_id="$(mmsg get focusing-client | jq -r '.id // empty')"
[ "$focused_id" = "$target_id" ] || mmsg dispatch focusid "client,${target_id}" >/dev/null
