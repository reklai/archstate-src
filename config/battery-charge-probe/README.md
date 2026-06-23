# Battery Charge Probe

This emulates a battery start threshold on systems that only expose
`charge_control_end_threshold`.

- At or below `40%`, it writes `60` to `charge_control_end_threshold`.
- At or above `60%`, it writes `40` to `charge_control_end_threshold`.
- Between those values, it keeps the previous state.

Install:

```sh
./install.sh
```

Check status:

```sh
systemctl status battery-charge-probe.timer battery-charge-probe.service
journalctl -u battery-charge-probe.service
```
