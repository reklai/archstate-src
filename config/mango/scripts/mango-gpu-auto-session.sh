#!/usr/bin/env bash
set -euo pipefail

. "$HOME/.config/mango/scripts/gpu-profile-lib.sh"

profile="$(mango_desired_gpu_profile)"
drm_devices="$(mango_drm_devices_for_profile "$profile")"

export WLR_DRM_DEVICES="$drm_devices"
export MANGO_GPU_PROFILE="$profile"
printf '%s\n' "$profile" >"$(mango_gpu_started_profile_file)"

case "$profile" in
  nvidia-only)
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    export GBM_BACKEND=nvidia-drm
    unset __NV_PRIME_RENDER_OFFLOAD
    unset DRI_PRIME
    ;;
  amd-only)
    unset __GLX_VENDOR_LIBRARY_NAME
    unset __NV_PRIME_RENDER_OFFLOAD
    unset __VK_LAYER_NV_optimus
    unset GBM_BACKEND
    export DRI_PRIME=0
    ;;
esac

exec mango "$@"
