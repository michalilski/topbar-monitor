#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
APP="build/TopbarMonitor.app"

swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/TopbarMonitor "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"
echo "Built $APP"
