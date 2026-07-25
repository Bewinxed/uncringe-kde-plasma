#!/usr/bin/env bash
# Remove everything install.sh added.  sudo ./uninstall.sh
set -uo pipefail
[[ $EUID -eq 0 ]] || { echo "run me with sudo"; exit 1; }
USER_NAME=${SUDO_USER:?run via sudo from your desktop user}
run_user() { runuser -u "$USER_NAME" -- "$@"; }

systemctl disable --now autoscroll.service 2>/dev/null
rm -f /etc/systemd/system/autoscroll.service /usr/local/bin/autoscroll-daemon
systemctl daemon-reload

run_user systemctl --user disable --now autoscroll-helper.service 2>/dev/null
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
rm -rf "$USER_HOME/.local/lib/autoscroll" \
       "$USER_HOME/.config/systemd/user/autoscroll-helper.service"
run_user systemctl --user daemon-reload

run_user kpackagetool6 --type=KWin/Script -r autoscroll-activewindow 2>/dev/null
run_user kwriteconfig6 --file kwinrc --group Plugins --key autoscroll-activewindowEnabled --delete
run_user qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null

echo "removed. Mouse input is untouched the moment the service stops."
