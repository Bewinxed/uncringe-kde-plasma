// Push the active window's resource class to the autoscroll helper on every
// activation. KWin scripts cannot write files; callDBus is the only side channel.
function report() {
    var w = workspace.activeWindow;
    var cls = w ? String(w.resourceClass) : "";
    callDBus("com.bewinxed.AutoscrollHelper", "/", "com.bewinxed.AutoscrollHelper",
             "SetActive", cls);
}
workspace.windowActivated.connect(report);
report();
