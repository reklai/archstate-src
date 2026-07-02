#!/usr/bin/env bash
# Helpers for selecting exactly one DRM GPU for the Mango session.
# NVIDIA is used when a NVIDIA-wired external output is connected; otherwise
# AMD is used for the internal panel and as the conservative fallback.

MANGO_NVIDIA_PCI="${MANGO_NVIDIA_PCI:-0000:01:00.0}"
MANGO_AMD_PCI="${MANGO_AMD_PCI:-0000:69:00.0}"

mango_card_for_pci() {
  local pci="$1" card_path dev

  for card_path in /sys/class/drm/card[0-9]; do
    [ -e "$card_path/device" ] || continue
    dev="$(basename "$(readlink -f "$card_path/device")")"
    if [ "$dev" = "$pci" ]; then
      printf '/dev/dri/%s\n' "${card_path##*/}"
      return 0
    fi
  done

  return 1
}

mango_has_connected_external_on_pci() {
  local pci="$1" card_path card connector status

  for card_path in /sys/class/drm/card[0-9]; do
    [ -e "$card_path/device" ] || continue
    [ "$(basename "$(readlink -f "$card_path/device")")" = "$pci" ] || continue
    card="${card_path##*/}"

    for status in "/sys/class/drm/${card}-"*/status; do
      [ -e "$status" ] || continue
      connector="${status#/sys/class/drm/${card}-}"
      connector="${connector%/status}"
      case "$connector" in
        eDP-*|Writeback-*) continue ;;
      esac
      [ "$(cat "$status" 2>/dev/null)" = connected ] && return 0
    done
  done

  return 1
}

mango_has_connected_internal_on_pci() {
  local pci="$1" card_path card status

  for card_path in /sys/class/drm/card[0-9]; do
    [ -e "$card_path/device" ] || continue
    [ "$(basename "$(readlink -f "$card_path/device")")" = "$pci" ] || continue
    card="${card_path##*/}"

    for status in "/sys/class/drm/${card}-"eDP-*/status; do
      [ -e "$status" ] || continue
      [ "$(cat "$status" 2>/dev/null)" = connected ] && return 0
    done
  done

  return 1
}

mango_desired_gpu_profile() {
  if mango_has_connected_external_on_pci "$MANGO_NVIDIA_PCI"; then
    printf 'nvidia-only\n'
    return 0
  fi

  printf 'amd-only\n'
}

mango_drm_devices_for_profile() {
  local profile="$1" card

  case "$profile" in
    nvidia-only)
      card="$(mango_card_for_pci "$MANGO_NVIDIA_PCI")" || return 1
      ;;
    amd-only)
      card="$(mango_card_for_pci "$MANGO_AMD_PCI")" || return 1
      ;;
    *)
      return 1
      ;;
  esac

  printf '%s\n' "$card"
}

mango_gpu_started_profile_file() {
  printf '%s/mango-gpu-started-profile\n' "${XDG_RUNTIME_DIR:-/tmp}"
}

mango_gpu_current_profile_file() {
  printf '%s/mango-gpu-current-profile\n' "${XDG_RUNTIME_DIR:-/tmp}"
}
