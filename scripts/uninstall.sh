#!/usr/bin/env bash
set -euo pipefail

APP_NAME="TopbarMonitor.app"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"
LABEL="com.michalilski.topbar-monitor"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"

remove_launch_agent() {
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
    rm -f "$AGENT"
}

remove_app() {
    pkill -x TopbarMonitor 2>/dev/null || true
    rm -rf "$INSTALL_DIR/$APP_NAME"
}

remove_data() {
    rm -rf "$HOME/Library/Application Support/TopbarMonitor"
    defaults delete "$LABEL" 2>/dev/null || true
}

main() {
    remove_launch_agent
    remove_app
    if [[ "${1:-}" == "--purge" ]]; then
        remove_data
    fi
    echo "Uninstalled $APP_NAME"
}

main "$@"
