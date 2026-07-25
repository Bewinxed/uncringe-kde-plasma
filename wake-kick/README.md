# wake-kick — displays that come back from sleep

**The papercut:** a high-bandwidth DisplayPort link (Samsung G9 at
5120x1440@240Hz = DSC compressed) sometimes fails link retraining after display
sleep on NVIDIA — black screen until you replug the cable. Windows users in the
[NVIDIA forum thread](https://forums.developer.nvidia.com/t/black-screen-with-hdr-240-hz-when-switching-or-closing-game-fullscreens/289754)
work around the same interaction by dropping to 120Hz or disabling HDR/G-Sync.

**Check the canonical fixes first** — this module is the layer *after* them:
1. `/etc/modprobe.d/`: `options nvidia NVreg_PreserveVideoMemoryAllocations=1`
   and `NVreg_TemporaryFilePath=/var`
2. `systemctl enable nvidia-suspend nvidia-resume nvidia-hibernate`
3. Avoid the trigger combo from the thread: HDR + 240Hz + VRR all at once
   (KWin: `kscreen-doctor output.X.vrrpolicy.never|automatic`)

**What this adds:** a `systemd-sleep` hook that, on every resume, forces DPMS on
and re-asserts the current mode on every enabled output. Healthy wake: both are
no-ops. Stuck link: the explicit modeset forces a retrain. All state is derived
at runtime (seat-0 user from loginctl, outputs/modes from kscreen JSON) and it
logs to the journal as `wake-kick`, so a bad wake finally leaves evidence:

```
journalctl -t wake-kick -b   # what happened on the last resume
```

Install: `sudo install -m755 wake-kick /usr/lib/systemd/system-sleep/wake-kick`
