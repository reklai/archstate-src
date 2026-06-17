#!/usr/bin/env bash
set -euo pipefail

if (( EUID != 0 )); then
  exec sudo "$0" "$@"
fi

base_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
state_dir="/var/lib/battery-charge-hysteresis"
state_file="$state_dir/state"

install -D -m 0755 "$base_dir/battery-charge-hysteresis" /usr/local/bin/battery-charge-hysteresis
install -D -m 0644 "$base_dir/battery-charge-hysteresis.service" /etc/systemd/system/battery-charge-hysteresis.service
install -D -m 0644 "$base_dir/battery-charge-hysteresis.timer" /etc/systemd/system/battery-charge-hysteresis.timer

install -d -m 0755 "$state_dir"
if [[ ! -s "$state_file" ]]; then
  printf 'charging\n' > "$state_file"
  chmod 0644 "$state_file"
fi

stamp="$(date +%Y%m%d%H%M%S)"
for path in \
  /etc/udev/rules.d/99-battery-charge-threshold.rules \
  /etc/tmpfiles.d/battery-charge-threshold.conf
do
  if [[ -e "$path" ]]; then
    mv -- "$path" "$path.disabled.$stamp"
  fi
done

systemctl daemon-reload
systemctl enable --now battery-charge-hysteresis.timer
systemctl start battery-charge-hysteresis.service

printf 'Installed battery-charge-hysteresis.\n'
systemctl --no-pager --full status battery-charge-hysteresis.timer battery-charge-hysteresis.service || true
printf 'Current charge threshold: '
cat /sys/class/power_supply/BAT0/charge_control_end_threshold
printf 'Current hysteresis state: '
cat "$state_file"
