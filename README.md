# uncringe-kde-plasma

Fixes for the papercuts that make KDE Plasma feel cringe to a Windows refugee.

First module: **Windows-style middle-click autoscroll** — the one where you hold
the middle button, the cursor moves freely, and the page scrolls continuously,
faster the further you move from where you pressed. System-wide, any mouse, on
Wayland.

## Why this exists

Linux has *a* middle-button scroll: libinput's `ScrollMethod=4` ("on-button-down").
It is not the Windows feature. It's **delta-based** — motion becomes scroll, so it
stops the instant your hand stops, and the cursor freezes while held. Windows
autoscroll is **displacement-proportional** — the anchor stays put, the cursor
moves freely, and scrolling continues at a speed set by how far the cursor sits
from the anchor. No libinput option, toolkit setting, or general-purpose remapper
expresses that, because it needs a timer integrating displacement, not an event
mapping.

One more inconvenient truth: **Windows itself has no OS-level autoscroll.** Each
app implements it (browsers, Office), which is why the gesture there can hit-test
links and capture scroll to the pane it started in. Anything injecting at the
input layer — KatMouse on Windows, this daemon on Linux — cannot. So this project
uses a hybrid:

| Where | Mechanism | Fidelity |
|---|---|---|
| Chromium/Electron/Firefox apps | their **native** autoscroll (flag/pref below) | exact: anchor icon, origin capture, link hit-testing |
| Everything else (Qt, GTK, terminals, PDF viewers) | the daemon | free cursor + proportional continuous scroll |

The daemon knows when to stand down: a KWin script reports the focused window's
class over D-Bus to a tiny user service, and the daemon checks it at every
middle-press. Focused app has native support → the button passes through
untouched.

## Architecture

```
any mouse ──evdev grab──▶ autoscroll-daemon (root) ──uinput──▶ clone + wheel ──▶ compositor
                                   ▲
                                   │ read at each middle-press
KWin script ──D-Bus──▶ helper.py (user) ──▶ $XDG_RUNTIME_DIR/autoscroll-active-class
```

- **Any mouse**: every device with REL_X/REL_Y + BTN_MIDDLE is managed, with
  hotplug (2s rescan). Per-device gesture state.
- Hold middle + move → continuous scroll. Quick click without motion → replayed
  as a real middle click, so paste-primary and open-in-new-tab still work.

## Install

```bash
sudo ./install.sh      # installs daemon (system service), helper (user service),
                       # KWin script; enables everything, survives reboot
sudo ./uninstall.sh    # removes all of it
```

Requires: KDE Plasma 6 on Wayland, `python3-evdev`, `kpackagetool6` (ships with
Plasma). Root is needed for `/dev/uinput` and evdev grabs.

## Native autoscroll in browsers (the exact-Windows part)

- **Chromium / Brave / Electron apps**: launch flag
  `--enable-blink-features=MiddleClickAutoscroll` — not available in
  `chrome://flags`, command line only. Persist it by copying the app's `.desktop`
  file to `~/.local/share/applications/` and appending the flag to every `Exec=`
  line. (Chromium's own wrapper scripts do not read a `*-flags.conf` on Debian/
  Ubuntu packaging.)
- **Firefox**: `general.autoScroll = true` (about:config, or `user.js`).

The daemon's `NATIVE_APPS` tuple lists the window classes it defers to — extend
it if you flag more Electron apps.

## Tuning

`notches/frame = MAX_RATE * clamp((|offset|-DEADZONE)/RANGE, 0..1) ^ CURVE` at 60 Hz.

| Flag | Default | Meaning |
|---|---|---|
| `--deadzone` | 8 | px of slack before scrolling starts |
| `--range` | 250 | px from deadzone to full speed |
| `--max-rate` | 1.2 | notches/frame at full deflection (~72/s) |
| `--curve` | 1.4 | 1 = linear; higher = finer control near the anchor |
| `--smooth` | 0.12 | easing when slowing/stopping (s). 0 = raw |
| `--smooth-up` | 0.05 | easing when speeding up - smaller = snappier acceleration |
| `--freeze` | off | pin the cursor during gestures (prevents wheel landing on other widgets, feels bad) |
| `--safe` | off | never grab; inject wheel only. Cannot affect input, but clicks aren't suppressed |
| `--seconds N` | 0 | auto-release after N seconds — use while experimenting |
| `--debug` | off | log every decision |

Edit `ExecStart=` in `/etc/systemd/system/autoscroll.service` to persist flags.

## Safety model (a.k.a. battle scars)

Grabbing your only pointing device is a loaded gun. Every one of these guards
exists because its absence shipped and hurt:

- **Kernel ground truth**: a 1000 Hz gaming mouse can overflow the kernel's event
  queue; the kernel silently drops events (including button *releases*) and emits
  `SYN_DROPPED`. Remembered button state is therefore a lie waiting to happen —
  the daemon reconciles against the `active_keys()` ioctl every frame and rebuilds
  state on every `SYN_DROPPED`. A stale "held" flag self-heals in 16 ms instead of
  swallowing motion forever (= frozen cursor).
- **Watchdog thread**: a plain OS thread checks a 60 Hz heartbeat; if the asyncio
  loop wedges while grabs are held, it force-ungrabs everything and hard-exits so
  systemd restarts clean. An asyncio timeout cannot guard a stuck loop.
- **Two uinput devices**: wheel injection is a separate node from the event
  mirror; injecting into the mirror can interleave into a half-forwarded packet
  and corrupt SYN framing.
- **Settle before grab**: libinput needs a beat to open new uinput nodes before
  the real device is grabbed, or early events vanish.
- **Examine every device path exactly once**: an earlier hotplug scanner reopened
  all unmanaged `/dev/input/event*` nodes every 2 s — including the daemon's own
  live uinput nodes, which the compositor was actively reading — and that caused
  **periodic whole-screen freezes** on KWin + NVIDIA. The rescan now caches
  examined paths and only ever opens genuinely new (hotplugged) ones.
- `SIGKILL` is always safe — the kernel drops grabs when the fd closes.

## Limitations

- A quick middle-click can't hit-test what's under the cursor (only apps can), so
  "click empty space to enter sticky autoscroll mode" is not implementable at
  this layer. Hold-to-scroll only.
- In non-native apps, parking the cursor over another scrollable widget (a tab
  bar) mid-gesture sends the wheel there — same quirk KatMouse has on Windows.
  Native apps don't have this because they capture the gesture.
- Wayland/KDE specific (the stand-down channel is a KWin script). The daemon
  itself would work on any compositor if you feed the state file another way.
