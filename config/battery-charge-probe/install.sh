#!/usr/bin/env bash
set -euo pipefail

if (( EUID != 0 )); then
  exec sudo "$0" "$@"
fi

base_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
state_dir="/var/lib/battery-charge-probe"

install -D -m 0755 "$base_dir/battery-charge-probe" /usr/local/bin/battery-charge-probe
install -D -m 0644 "$base_dir/battery-charge-probe.service" /etc/systemd/system/battery-charge-probe.service
install -D -m 0644 "$base_dir/battery-charge-probe.timer" /etc/systemd/system/battery-charge-probe.timer
install -d -m 0755 "$state_dir"

systemctl daemon-reload
systemctl enable --now battery-charge-probe.timer
systemctl start battery-charge-probe.service

printf 'Installed battery-charge-probe.\n'
systemctl --no-pager --full status battery-charge-probe.timer battery-charge-probe.service || true
