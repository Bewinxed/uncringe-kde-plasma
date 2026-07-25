# audit — find unused/misconfigured devices without chasing ghosts

**The papercut:** hardware audits on Linux drown you in false positives, and
half the "fixes" online target things that only look broken.

**What it checks (findings vs ok, colour-coded):** VM guest agents enabled on
bare metal (`--fix` disables), genuinely unclaimed PCI devices, missing
firmware, wired NICs sitting dark while traffic rides Wi-Fi, Bluetooth
consumers with no BT hardware, NVIDIA sleep/persistence sanity, libvirt running
with zero VMs (`--fix` disables), RGB hardware without controller software, and
the top repeated journal errors.

**The ghosts it refuses to chase (each verified the hard way):**
- "UNCLAIMED" AMD host bridges / data fabric / dummy functions are normal Zen 4
  platform topology — nothing binds to them by design.
- GPUs at PCIe gen1 / 20 W at idle is ASPM, not a stuck link.
- `Persistence: Disabled` per-GPU while `nvidia-persistenced` is active is
  correct — the daemon supersedes the legacy flag.
- A "TI serial device" with `bDeviceClass 9` is a TUSB80xx USB **hub**, not a
  Zigbee radio. Check the class before assuming radios from vendor IDs.

```
./audit          # report
sudo ./audit --fix   # also disable VM guest agents / idle libvirt
```
