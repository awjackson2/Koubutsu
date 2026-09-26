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

# Vision on the simulator runs on the CPU: the first Japanese request loads models for ~2 minutes and
# later requests take several seconds each. Each configuration therefore runs for a few minutes and is
# captured repeatedly; all captures are kept.
series() { # name, launch args...
  local name=$1; shift
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" "$@" > /dev/null
  # Warm up (first Vision request loads models), then sample densely across two 24 s clip loops.
  for t in 20 60 64 68 72 76 80 84 88 92 96 100 104 108; do
    sleep $(( t - ${last:-0} )); last=$t
    xcrun simctl io "$UDID" screenshot "build/screenshots/${name}_t${t}s.png" > /dev/null
    if xcrun simctl spawn "$UDID" launchctl list | grep -q "$BUNDLE"; then state=running; else state=NOT-RUNNING; fi
    echo "captured ${name} at ${t}s (app ${state})"
  done
  last=0
}

series panel_debug --reset-settings --demo-translator --display-mode=panel --show-boxes --show-debug
series overlay --reset-settings --demo-translator --display-mode=overlay --hide-debug
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
ls -la build/screenshots
echo "--- crash reports ---"
find ~/Library/Logs/DiagnosticReports -name "Koubutsu*" -newer build/screenshots-build.log 2>/dev/null | while read -r f; do
  cp "$f" build/screenshots/ ; echo "== $f"; head -80 "$f"
done
echo "--- app log (errors/faults) ---"
xcrun simctl spawn "$UDID" log show --last 15m --style compact --predicate \
  'process == "Koubutsu" AND (messageType == error OR messageType == fault)' 2>/dev/null | tail -60 || true
