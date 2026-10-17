#!/bin/bash
# Baut die App mit Swift Package Manager und erzeugt ein .app-Bundle
# inkl. Info.plist mit LSUIElement = true (kein Dock-Icon).
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP=".build/PhysioNudge.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/release/PhysioNudge "$APP/Contents/MacOS/PhysioNudge"
cp -R Resources/Exercises "$APP/Contents/Resources/Exercises"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>PhysioNudge</string>
    <key>CFBundleIdentifier</key>
    <string>de.hochhaus.PhysioNudge</string>
    <key>CFBundleName</key>
    <string>PhysioNudge</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

echo "Fertig: $APP"
open "$APP"
