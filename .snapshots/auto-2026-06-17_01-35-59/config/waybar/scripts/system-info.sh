#!/usr/bin/env bash
# Waybar JSON modules for compact system status with useful hover details.
set -u
shopt -s nullglob

mode="${1:-}"

json_escape() {
  local s="${1-}"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/}
  s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

emit() {
  local text="$1" tooltip="$2" class="${3:-normal}"
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(json_escape "$text")" "$(json_escape "$tooltip")" "$(json_escape "$class")" 2>/dev/null || exit 0
}

markup_label() {
  local icon="$1" value="$2"
  printf '<span font_family="Symbols Nerd Font" size="16000" foreground="#9aa3af">%s</span>  <span font_family="FiraCode Nerd Font Mono" foreground="#d8dee9">%s</span>' "$icon" "$value"
}

class_high() {
  local pct="${1:-0}" warning="${2:-80}" critical="${3:-90}"
  if (( pct >= critical )); then
    printf 'critical'
  elif (( pct >= warning )); then
    printf 'warning'
  else
    printf 'normal'
  fi
}

gib() {
  awk -v kib="${1:-0}" 'BEGIN { printf "%.1f GiB", kib / 1048576 }'
}

read_file() {
  local path="$1" fallback="${2:-}"
  if [[ -r "$path" ]]; then
    cat "$path"
  else
    printf '%s' "$fallback"
  fi
}

cpu_module() {
  local icon cache user nice system idle iowait irq softirq steal
  icon=$(printf '\uf4bc')
  read -r user nice system idle iowait irq softirq steal < <(
    awk '/^cpu / { print $2, $3, $4, $5, $6, $7, $8, $9 }' /proc/stat
  )

  local idle_all=$((idle + iowait))
  local nonidle=$((user + nice + system + irq + softirq + steal))
  local total=$((idle_all + nonidle))
  local tmpdir="${TMPDIR:-/tmp}"
  [[ -d "$tmpdir" && -w "$tmpdir" ]] || tmpdir="/tmp"
  cache="${tmpdir}/waybar-system-cpu-${UID}.stat"

  local usage=0 prev_total prev_idle total_delta idle_delta
  if read -r prev_total prev_idle < "$cache" 2>/dev/null; then
    total_delta=$((total - prev_total))
    idle_delta=$((idle_all - prev_idle))
    if (( total_delta > 0 )); then
      usage=$((((total_delta - idle_delta) * 100) / total_delta))
    fi
  fi
  printf '%s %s\n' "$total" "$idle_all" > "$cache"

  local load run_threads cores
  load=$(awk '{ print $1 " / " $2 " / " $3 }' /proc/loadavg)
  run_threads=$(awk '{ print $4 }' /proc/loadavg)
  cores=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || printf '?')

  local count=0 sum=0 max=0 f freq avg_ghz max_ghz
  for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
    freq=$(read_file "$f" 0)
    [[ "$freq" =~ ^[0-9]+$ ]] || continue
    (( count++ ))
    (( sum += freq ))
    (( freq > max )) && max="$freq"
  done
  if (( count > 0 )); then
    avg_ghz=$(awk -v sum="$sum" -v count="$count" 'BEGIN { printf "%.2f", sum / count / 1000000 }')
    max_ghz=$(awk -v max="$max" 'BEGIN { printf "%.2f", max / 1000000 }')
  else
    avg_ghz="n/a"
    max_ghz="n/a"
  fi

  local tooltip
  tooltip=$(
    printf 'CPU\nUsage: %s%%\nLoad avg: %s\nThreads: %s\nCores: %s\nFrequency: avg %s GHz / max %s GHz' \
      "$usage" "$load" "$run_threads" "$cores" "$avg_ghz" "$max_ghz"
  )

  emit "$(markup_label "$icon" "${usage}%")" "$tooltip" "$(class_high "$usage" 70 90)"
}

memory_module() {
  local icon total avail swap_total swap_free cached sreclaim buffers
  icon=$(printf '\uefc5')
  total=$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)
  avail=$(awk '/^MemAvailable:/ { print $2 }' /proc/meminfo)
  swap_total=$(awk '/^SwapTotal:/ { print $2 }' /proc/meminfo)
  swap_free=$(awk '/^SwapFree:/ { print $2 }' /proc/meminfo)
  cached=$(awk '/^Cached:/ { print $2 }' /proc/meminfo)
  sreclaim=$(awk '/^SReclaimable:/ { print $2 }' /proc/meminfo)
  buffers=$(awk '/^Buffers:/ { print $2 }' /proc/meminfo)

  local used=$((total - avail))
  local pct=$((used * 100 / total))
  local swap_used=$((swap_total - swap_free))
  local swap_pct=0
  if (( swap_total > 0 )); then
    swap_pct=$((swap_used * 100 / swap_total))
  fi
  local cache_total=$((cached + sreclaim + buffers))

  local tooltip
  tooltip=$(
    printf 'RAM\nUsed: %s / %s (%s%%)\nAvailable: %s\nCache + buffers: %s\nSwap: %s / %s (%s%%)' \
      "$(gib "$used")" "$(gib "$total")" "$pct" \
      "$(gib "$avail")" "$(gib "$cache_total")" \
      "$(gib "$swap_used")" "$(gib "$swap_total")" "$swap_pct"
  )

  emit "$(markup_label "$icon" "${pct}%")" "$tooltip" "$(class_high "$pct" 80 92)"
}

disk_module() {
  local icon fs size used avail pct mount pct_num
  icon=$(printf '\uf0a0')
  read -r fs size used avail pct mount < <(df -h / | awk 'NR == 2 { print $1, $2, $3, $4, $5, $6 }')
  pct_num="${pct%\%}"

  local tooltip
  tooltip=$(printf 'Storage\nMount: %s\nDevice: %s\nUsed: %s / %s (%s)\nFree: %s' "$mount" "$fs" "$used" "$size" "$pct" "$avail")

  emit "$(markup_label "$icon" "$pct")" "$tooltip" "$(class_high "$pct_num" 80 92)"
}

temperature_module() {
  local icon file raw milli label dir base idx name max_milli=-1 max_label="sensor"
  icon=$(printf '\uf2c7')
  local entries=()

  for file in /sys/class/hwmon/hwmon*/temp*_input; do
    raw=$(read_file "$file" "")
    [[ "$raw" =~ ^-?[0-9]+$ ]] || continue
    if (( raw > 1000 || raw < -1000 )); then
      milli="$raw"
    else
      milli=$((raw * 1000))
    fi

    dir=$(dirname "$file")
    base=$(basename "$file")
    idx="${base#temp}"
    idx="${idx%_input}"
    name=$(read_file "$dir/name" "hwmon")
    label=$(read_file "$dir/temp${idx}_label" "${name} temp${idx}")

    entries+=("${milli}|${label}")
    if (( milli > max_milli )); then
      max_milli="$milli"
      max_label="$label"
    fi
  done

  for file in /sys/class/thermal/thermal_zone*/temp; do
    raw=$(read_file "$file" "")
    [[ "$raw" =~ ^-?[0-9]+$ ]] || continue
    if (( raw > 1000 || raw < -1000 )); then
      milli="$raw"
    else
      milli=$((raw * 1000))
    fi

    dir=$(dirname "$file")
    label=$(read_file "$dir/type" "$(basename "$dir")")
    entries+=("${milli}|${label}")
    if (( milli > max_milli )); then
      max_milli="$milli"
      max_label="$label"
    fi
  done

  if (( max_milli < 0 )); then
    emit "${icon}  n/a" "Temperature sensors not found" "warning"
    return
  fi

  local max_c=$(((max_milli + 500) / 1000))
  local top
  top=$(
    printf '%s\n' "${entries[@]}" |
      sort -t'|' -nr -k1,1 |
      awk -F'|' 'NR <= 5 { printf "Sensor %d: %s %.1f°C\n", NR, $2, $1 / 1000 }'
  )

  local tooltip
  tooltip=$(printf 'Temperature\nCurrent: %s°C\nHottest: %s\nCritical: 85°C\n%s' "$max_c" "$max_label" "$top")

  local class
  class="$(class_high "$max_c" 75 85)"

  emit "$(markup_label "$icon" "${max_c}°")" "$tooltip" "$class"
}

battery_module() {
  local icon bat="/sys/class/power_supply/BAT0" adapter="/sys/class/power_supply/ADP0"
  local capacity status threshold energy_now energy_full energy_design power_now ac_online

  capacity=$(read_file "$bat/capacity" 0)
  status=$(read_file "$bat/status" "Unknown")
  threshold=$(read_file "$bat/charge_control_end_threshold" "n/a")
  energy_now=$(read_file "$bat/energy_now" 0)
  energy_full=$(read_file "$bat/energy_full" 0)
  energy_design=$(read_file "$bat/energy_full_design" 0)
  power_now=$(read_file "$bat/power_now" 0)
  ac_online=$(read_file "$adapter/online" 0)

  if (( capacity <= 10 )); then
    icon=$(printf '\uf244')
  elif (( capacity <= 35 )); then
    icon=$(printf '\uf243')
  elif (( capacity <= 60 )); then
    icon=$(printf '\uf242')
  elif (( capacity <= 85 )); then
    icon=$(printf '\uf241')
  else
    icon=$(printf '\uf240')
  fi

  local health power_w ac_state note class profile
  health=$(awk -v full="$energy_full" -v design="$energy_design" 'BEGIN { if (design > 0) printf "%.0f%%", full * 100 / design; else printf "n/a" }')
  power_w=$(awk -v p="$power_now" 'BEGIN { printf "%.1f W", p / 1000000 }')
  profile=$(powerprofilesctl get 2>/dev/null || printf 'n/a')
  if [[ "$ac_online" == "1" ]]; then
    ac_state="online"
  else
    ac_state="offline"
  fi

  note=""
  if [[ "$threshold" =~ ^[0-9]+$ ]] && (( capacity > threshold )); then
    note="Note: above charge cap; firmware is holding charge"
  fi

  if (( capacity <= 10 )); then
    class="critical"
  elif (( capacity <= 20 )); then
    class="warning"
  elif [[ "$status" == "Charging" ]]; then
    class="charging"
  else
    class="normal"
  fi

  local energy_now_wh energy_full_wh tooltip
  energy_now_wh=$(awk -v v="$energy_now" 'BEGIN { printf "%.1f Wh", v / 1000000 }')
  energy_full_wh=$(awk -v v="$energy_full" 'BEGIN { printf "%.1f Wh", v / 1000000 }')
  tooltip=$(
    printf 'Battery\nCharge: %s%%\nStatus: %s\nPower profile: %s\nCharge limit: %s%%\nEnergy: %s / %s\nHealth: %s of design\nAC: %s\nPower: %s' \
      "$capacity" "$status" "$profile" "$threshold" "$energy_now_wh" "$energy_full_wh" "$health" "$ac_state" "$power_w"
  )
  if [[ -n "$note" ]]; then
    tooltip=$(printf '%s\n%s' "$tooltip" "$note")
  fi

  emit "$(markup_label "$icon" "${capacity}%")" "$tooltip" "$class"
}

case "$mode" in
  cpu) cpu_module ;;
  memory) memory_module ;;
  disk) disk_module ;;
  temperature) temperature_module ;;
  battery) battery_module ;;
  *) emit "?" "Unknown system-info mode: ${mode}" "critical" ;;
esac
