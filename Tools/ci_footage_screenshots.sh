#!/usr/bin/env bash
# Captures Video mode screenshots on external footage. The footage is copied into the simulator app's
# Documents folder (as a user import would) and never leaves the runner.
# Usage: Tools/ci_footage_screenshots.sh <footage.mov> <name> "<t1> <t2> ..."
set -uo pipefail
FOOTAGE=$1; NAME=$2; TIMES=$3
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)["devices"]
for runtime in sorted(data, reverse=True):
    for d in data[runtime]:
        if d.get("isAvailable") and d["name"].startswith("iPad Pro 13-inch"):
            print(d["udid"]); sys.exit()
')
mkdir -p build/footage-screenshots
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 || true
xcodebuild -project Koubutsu.xcodeproj -scheme Koubutsu -destination "id=${UDID}" \
  -derivedDataPath build/dd CODE_SIGNING_ALLOWED=NO build > build/footage-screenshots-build.log 2>&1 \
  || { tail -50 build/footage-screenshots-build.log; exit 1; }
APP=$(find build/dd/Build/Products -name "Koubutsu.app" -maxdepth 3 | head -1)
BUNDLE=com.awjackson2.Koubutsu
xcrun simctl install "$UDID" "$APP"
DATA=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)
mkdir -p "$DATA/Documents"
cp "$FOOTAGE" "$DATA/Documents/${NAME}.mov"

for t in $TIMES; do
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  # Play 6 s from t then pause; the paused frame keeps being read (still-frame re-delivery). Vision's
  # first request on the simulator loads models for up to ~2 minutes, so capture late.
  xcrun simctl launch "$UDID" "$BUNDLE" --reset-settings --select-video="$NAME" --start-at="$t" \
    --pause-after=6 --display-mode=panelAndOverlay --show-boxes --show-debug > /dev/null
  sleep 150
  xcrun simctl io "$UDID" screenshot "build/footage-screenshots/${NAME}_at${t}s.png" > /dev/null
  echo "captured ${NAME} at ${t}s"
done
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
rm -f "$DATA/Documents/${NAME}.mov"
