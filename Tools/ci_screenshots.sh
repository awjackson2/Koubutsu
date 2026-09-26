#!/usr/bin/env bash
# Builds the app, runs it on an iPad simulator in several configurations and saves screenshots to
# build/screenshots/. Uses the demo translator because simulators have no translation models.
set -uo pipefail
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)["devices"]
for runtime in sorted(data, reverse=True):
    for d in data[runtime]:
        if d.get("isAvailable") and d["name"].startswith("iPad Pro 13-inch"):
            print(d["udid"]); sys.exit()
')
echo "Simulator: ${UDID}"
mkdir -p build/screenshots
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 || true
xcodebuild -project Koubutsu.xcodeproj -scheme Koubutsu -destination "id=${UDID}" \
  -derivedDataPath build/dd CODE_SIGNING_ALLOWED=NO build > build/screenshots-build.log 2>&1 \
  || { tail -50 build/screenshots-build.log; exit 1; }
APP=$(find build/dd/Build/Products -name "Koubutsu.app" -maxdepth 3 | head -1)
xcrun simctl install "$UDID" "$APP"
BUNDLE=com.awjackson2.Koubutsu

shot() { # name, seconds after launch, launch args...
  local name=$1 delay=$2; shift 2
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" "$@" > /dev/null
  sleep "$delay"
  xcrun simctl io "$UDID" screenshot "build/screenshots/${name}.png" > /dev/null
  echo "captured ${name}"
}

# Clip timeline: 0-6 s title menu, 6-14 s dialogue (typewriter), 14-18 s saving, 18-24 s katakana menu.
shot panel_dialogue 13 --demo-translator --display-mode=panel --show-debug
shot overlay_dialogue 13 --demo-translator --display-mode=overlay --hide-debug
shot overlay_boxes_menu 21 --demo-translator --display-mode=panelAndOverlay --show-boxes --hide-debug
shot title_debug 4 --demo-translator --display-mode=panelAndOverlay --show-boxes --show-debug
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
ls -la build/screenshots
