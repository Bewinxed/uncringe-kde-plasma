#!/usr/bin/env bash
# Install the autoscroll stack. Run from the repo root:  sudo ./install.sh
set -euo pipefail
cd "$(dirname "$0")"

[[ $EUID -eq 0 ]] || { echo "run me with sudo"; exit 1; }
USER_NAME=${SUDO_USER:?must be run via sudo from your desktop user, not a root shell}
USER_UID=$(id -u "$USER_NAME")
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
# systemctl --user and qdbus6 need the user's session bus, which runuser
# alone does not provide.
run_user() {
  runuser -u "$USER_NAME" -- env \
    XDG_RUNTIME_DIR="/run/user/$USER_UID" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_UID/bus" "$@"
}

echo ":: dependency: python3-evdev"
python3 -c "import evdev" 2>/dev/null || apt-get install -y python3-evdev

echo ":: daemon -> /usr/local/bin/autoscroll-daemon"
install -m755 autoscroll/autoscroll-daemon /usr/local/bin/autoscroll-daemon

echo ":: helper -> $USER_HOME/.local/lib/autoscroll/"
install -m755 -D autoscroll/helper.py "$USER_HOME/.local/lib/autoscroll/helper.py"
install -m644 -D autoscroll/autoscroll-helper.service \
  "$USER_HOME/.config/systemd/user/autoscroll-helper.service"
chown -R "$USER_NAME": "$USER_HOME/.local/lib/autoscroll" \
  "$USER_HOME/.config/systemd/user/autoscroll-helper.service"

echo ":: KWin active-window reporter"
run_user kpackagetool6 --type=KWin/Script -i autoscroll/kwin/autoscroll-activewindow 2>/dev/null \
  || run_user kpackagetool6 --type=KWin/Script -u autoscroll/kwin/autoscroll-activewindow
run_user kwriteconfig6 --file kwinrc --group Plugins --key autoscroll-activewindowEnabled true
run_user qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure || true

echo ":: user service (active-window helper)"
run_user systemctl --user daemon-reload
run_user systemctl --user enable --now autoscroll-helper.service

echo ":: system service (daemon)"
sed "s/@UID@/$USER_UID/" autoscroll/autoscroll.service > /etc/systemd/system/autoscroll.service
systemctl daemon-reload
systemctl enable --now autoscroll.service
sleep 2
systemctl --no-pager --lines=4 status autoscroll.service || true

echo
echo "done. Hold the middle button and move - any app, any mouse."
echo "For the exact-Windows experience in browsers, see README: 'Native autoscroll'."
