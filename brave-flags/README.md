# brave-flags — persistent command-line flags for Brave

**The papercut:** some Chromium features exist ONLY as command-line flags
(`--enable-blink-features=MiddleClickAutoscroll` is not in chrome://flags), and
Brave's Debian/Ubuntu launcher does not read a `brave-flags.conf` the way Arch's
chromium wrapper does. There is no supported place to put flags.

**The fix:** a `.desktop` override in `~/.local/share/applications/` with the
flags spliced into every `Exec=` line (main window, new-window action, incognito
action), before any `%U` field code.

**The trap this script saves you from:** Brave's background mode keeps the
process alive after the last window closes, and Chromium is single-instance —
so "quit and reopen" usually just signals the OLD flagless process and your flag
silently never applies. Verify with `brave-flags list`, which shows what the
RUNNING process actually has.

```
brave-flags apply    # write the override (edit FLAGS in the script)
brave-flags list     # configured vs actually-live flags
brave-flags revert   # back to packaged defaults
```
