# webapp — any URL as a real desktop app

**The papercut:** self-hosted services live in browser tabs. You want Home
Assistant, Frigate, Grafana, Immich, or a router page to be a *thing on the
taskbar* you click, with its own icon and its own window — not a tab you hunt
for among forty others.

**The fix:** a `.desktop` launcher that runs the browser in `--app` mode
(chromeless window, no tab strip, no omnibox) with an explicit `--class`, plus a
generated SVG icon.

**The trap this script saves you from:** Chromium invents a WM class for
`--app` windows from the URL — `chrome-localhost__8123-Default`. Nothing
declares that string, so Plasma cannot match the running window to the launcher
you pinned. You get **two icons**: your pinned one, and a second generic entry
for the live window. It also changes if the URL ever changes, so a hand-written
`StartupWMClass` silently rots. Passing `--class=webapp-<slug>` and declaring
the identical `StartupWMClass=` is the only thing that makes the pinned icon and
the live window the same object.

```
webapp add <name> <url> [icon-file|glyph]   # create launcher + icon
webapp list                                 # what's installed
webapp remove <name>                        # delete launcher + icon
```

```bash
webapp add "Home Assistant" http://localhost:8123 🏠
webapp add Frigate http://localhost:5001 ~/pics/frigate.svg
webapp add Grafana http://nas.lan:3000
```

Then: app launcher → find it → right-click → **Pin to Task Manager**. Pinning
is left to you on purpose; doing it programmatically means editing the live
panel config and restarting `plasmashell`, which is a rude thing to do to
someone's session.

## Icons

Give it a file (`.svg` or any raster the theme can load) and it's copied
verbatim. Give it one or two characters and they become the glyph — emoji work
if `Noto Color Emoji` is installed. Give it nothing and you get the first letter
on a colour derived from a hash of the name, so an app keeps its colour across
reinstalls.

## Browser support

Chromium-family only: Brave, Chrome, Chromium, Edge, Vivaldi — first one found
on `PATH` wins. **Firefox is not a fallback.** Its site-specific-browser mode
was removed in 2021, and `--kiosk` gives you a fullscreen window with no
separate taskbar identity, which defeats the point. If Firefox is your daily
driver, these launchers will still use whichever Chromium you have installed;
that is intentional, not a bug.
