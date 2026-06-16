#!/usr/bin/env bash
# Cycle deck stack windows, skip master, and keep Mango's cursor warp.
set -euo pipefail

dir="${1:-next}"
case "$dir" in
  next|prev) ;;
  *) exit 2 ;;
esac

focused="$(mmsg get focusing-client)"
monitor="$(jq -r '.monitor // empty' <<<"$focused")"
tag="$(jq -r '.tags[0] // empty' <<<"$focused")"
[ -n "$monitor" ] && [ -n "$tag" ] || exit 0

clients="$(mmsg get all-clients)"

filter='.clients | map(select(.monitor==$m and (.tags|index($t))
  and .is_floating==false and .is_minimized==false
  and .is_overlay==false and .is_scratchpad==false))'

master_id="$(jq -r --arg m "$monitor" --argjson t "$tag" \
  "$filter | sort_by(.x, .y) | .[0].id // empty" <<<"$clients")"
mapfile -t stack < <(jq -r --arg m "$monitor" --argjson t "$tag" --argjson master "${master_id:-0}" \
  "$filter | sort_by(.id) | .[] | select(.id != \$master) | .id" <<<"$clients")
n="${#stack[@]}"
[ "$n" -ge 1 ] || exit 0

is_stack_id() {
  local id="$1"
  local stack_id
  for stack_id in "${stack[@]}"; do
    [ "$stack_id" = "$id" ] && return 0
  done
  return 1
}

for _ in $(seq 1 $((n + 1))); do
  mmsg dispatch "focusstack,${dir}" >/dev/null
  focused="$(mmsg get focusing-client)"
  focused_id="$(jq -r '.id // empty' <<<"$focused")"
  [ "$focused_id" = "$master_id" ] && continue
  is_stack_id "$focused_id" && exit 0
done
