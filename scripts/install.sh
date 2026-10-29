#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="TopbarMonitor.app"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"
LABEL="com.michalilski.topbar-monitor"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"

build_app() {
    "$ROOT/scripts/build-app.sh"
}

copy_app() {
    pkill -x TopbarMonitor 2>/dev/null || true
    rm -rf "$INSTALL_DIR/$APP_NAME"
    cp -R "$ROOT/build/$APP_NAME" "$INSTALL_DIR/"
}

write_launch_agent() {
    mkdir -p "$(dirname "$AGENT")"
    cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/$APP_NAME/Contents/MacOS/TopbarMonitor</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
PLIST
}

load_launch_agent() {
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$AGENT"
}

main() {
    build_app
    copy_app
    write_launch_agent
    load_launch_agent
    echo "Installed $INSTALL_DIR/$APP_NAME (starts at login via $AGENT)"
}

main "$@"
