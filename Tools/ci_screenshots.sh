#!/usr/bin/env bash
# Builds the app, runs it on an iPad or iPhone simulator in several configurations and saves screenshots to
# build/screenshots/. Uses the demo translator because simulators have no translation models.
set -uo pipefail
# DEVICE=iPad (default: iPad Pro 13-inch) or iPhone (newest iPhone Pro, not Max; each series in portrait and
# landscape via --orientation, 10.1.0).
DEVICE=${DEVICE:-iPad}
UDID=$(xcrun simctl list devices available -j | DEVICE="$DEVICE" python3 -c '
import json, os, re, sys
family = os.environ["DEVICE"]
data = json.load(sys.stdin)["devices"]
def wanted(name):
    if family == "iPhone":
        return name.startswith("iPhone") and "Pro" in name and "Max" not in name
    return name.startswith("iPad Pro 13-inch")
for runtime in sorted(data, key=lambda r: [int(x) for x in re.findall(r"\d+", r)], reverse=True):
    for d in sorted(data[runtime], key=lambda d: d["name"], reverse=True):
        if d.get("isAvailable") and wanted(d["name"]):
            print(d["udid"]); sys.exit()
sys.exit("no %s simulator available" % family)
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
# SERIES (comma-separated names, optional) limits which configurations run; empty runs all of them.
SERIES=$(echo "${SERIES:-}" | tr -d ' ')
# iPhone runs every series twice (portrait, landscape), so it samples fewer frames per run.
if [ "$DEVICE" = iPhone ]; then ORIENTATIONS="portrait landscape"; TIMES="20 60 76 92 108"
else ORIENTATIONS=""; TIMES="20 60 64 68 72 76 80 84 88 92 96 100 104 108"; fi
series() { # name, launch args...
  local name=$1; shift
  if [ -n "$SERIES" ] && [[ ",${SERIES}," != *",${name},"* ]]; then echo "skipping ${name}"; return; fi
  if [ -z "$ORIENTATIONS" ]; then capture "$name" "$@"; return; fi
  for o in $ORIENTATIONS; do capture "iphone_${o}_${name}" "$@" "--orientation=${o}"; done
}
capture() { # file prefix, launch args...
  local name=$1; shift
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" "$@" > /dev/null
  # Warm up (first Vision request loads models), then sample densely across two 24 s clip loops.
  for t in $TIMES; do
    sleep $(( t - ${last:-0} )); last=$t
    xcrun simctl io "$UDID" screenshot "build/screenshots/${name}_t${t}s.png" > /dev/null
    if xcrun simctl spawn "$UDID" launchctl list | grep -q "$BUNDLE"; then state=running; else state=NOT-RUNNING; fi
    echo "captured ${name} at ${t}s (app ${state})"
  done
  last=0
}

series panel_debug --reset-settings --demo-translator --display-mode=panel --show-boxes --show-debug
series overlay --reset-settings --demo-translator --display-mode=overlay --hide-debug
series fullscreen --reset-settings --demo-translator --display-mode=overlay --full-screen
series study --reset-settings --demo-translator --display-mode=overlay --start-at=12 --pause-after=1 --study-after=40 --study-select=0.1,0.72,0.45,0.18
series card --reset-settings --demo-translator --display-mode=overlay --start-at=12 --pause-after=1 --study-after=40 --study-tap=0.303,0.761 --open-card
series furigana --reset-settings --demo-translator --display-mode=overlay --furigana
series settings --reset-settings --demo-translator --open=settings
series words --reset-settings --demo-translator --seed-words --open=words
series review --reset-settings --demo-translator --seed-words --open=review
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
ls -la build/screenshots
echo "--- crash reports ---"
find ~/Library/Logs/DiagnosticReports -name "Koubutsu*" -newer build/screenshots-build.log 2>/dev/null | while read -r f; do
  cp "$f" build/screenshots/ ; echo "== $f"; head -80 "$f"
done
echo "--- app log (errors/faults) ---"
xcrun simctl spawn "$UDID" log show --last 15m --style compact --predicate \
  'process == "Koubutsu" AND (messageType == error OR messageType == fault)' 2>/dev/null | tail -60 || true
