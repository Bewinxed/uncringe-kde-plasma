# midscroll — libinput button-scrolling, correctly labelled

**The papercut:** you want Windows middle-click autoscroll, find libinput's
"button scrolling" (`ScrollMethod=4`), enable it, and hate it: the cursor
freezes, and scrolling stops the instant your hand stops.

**The truth this module encodes:** that is not a broken version of the Windows
feature - it is a DIFFERENT feature. libinput button scrolling is delta-based
(motion becomes scroll). Windows autoscroll is displacement-proportional
(continuous scroll at a speed set by distance from the anchor). libinput cannot
express the latter; see the `autoscroll` module for the real thing. The two are
also mutually exclusive - libinput consumes the middle-drag below the toolkit,
so apps' own autoscroll can never fire while it is on.

**The Wayland part:** `xinput set-prop` does NOT work on a Wayland session
(reaches XWayland clients only). KWin owns libinput and exposes the same
switches over D-Bus at `/org/kde/KWin/InputDevice/eventN` - property names
`scrollOnButtonDown` / `scrollButton`. KWin persists changes to
`~/.config/kcminputrc` itself. Adjust DEV/VID/PID/NAME at the top for your mouse.

```
midscroll on       # libinput button scrolling (cursor freezes, works everywhere)
midscroll off      # hand the button back to apps (needed by the autoscroll module)
midscroll factor 2 # scroll speed multiplier
midscroll status
```
