#!/usr/bin/env python3
"""Receives active-window class from the KWin script (via DBus) and writes it to
$XDG_RUNTIME_DIR/autoscroll-active-class, where the root autoscroll daemon reads
it at each middle-press to decide whether to stand down (apps with native
autoscroll: Brave/Firefox/Claude) or run the gesture (everything else)."""
import os, dbus, dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

STATE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"),
                     "autoscroll-active-class")

class Helper(dbus.service.Object):
    @dbus.service.method("com.bewinxed.AutoscrollHelper",
                         in_signature="s", out_signature="")
    def SetActive(self, cls):
        tmp = STATE + ".tmp"
        with open(tmp, "w") as f:
            f.write(str(cls).lower())
        os.replace(tmp, STATE)          # atomic - daemon never sees a partial write

DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
name = dbus.service.BusName("com.bewinxed.AutoscrollHelper", bus)
Helper(bus, "/")
open(STATE, "w").write("")             # start clean
print(":: helper up, writing to", STATE, flush=True)
GLib.MainLoop().run()
