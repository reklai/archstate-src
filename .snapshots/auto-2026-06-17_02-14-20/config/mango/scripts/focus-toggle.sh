#!/usr/bin/env bash
# Toggle between the master window and the visible stack.
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
master_id="$(jq -r --arg m "$monitor" --argjson t "$tag" \
  "$filter | sort_by(.x, .y) | .[0].id" <<<"$clients")"

if [ "$focused_id" = "$master_id" ]; then
  mmsg dispatch focusdir,right >/dev/null
else
  mmsg dispatch focusdir,left  >/dev/null
fi
