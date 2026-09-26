#!/usr/bin/env bash
# Builds and tests the app on the newest available iPad simulator.
set -euo pipefail
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys, re
data = json.load(sys.stdin)["devices"]
best = None
for runtime, devices in data.items():
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not m:
        continue
    ver = (int(m.group(1)), int(m.group(2)))
    for d in devices:
        if d.get("isAvailable") and "iPad" in d["name"]:
            key = (ver, "Pro" in d["name"], d["name"])
            if best is None or key > best[0]:
                best = (key, d["udid"])
if best is None:
    sys.exit("no iPad simulator available")
print(best[1], file=sys.stdout)
print("Selected", best[0], file=sys.stderr)
')
echo "Simulator: ${UDID}"
ACTION=${1:-test}
shift || true
EXTRA=("$@")
STATUS=0
LIMIT=${XCODEBUILD_TIME_LIMIT:-2700}
xcodebuild -project Koubutsu.xcodeproj -scheme Koubutsu \
  -destination "id=${UDID}" \
  -resultBundlePath "build/Koubutsu-${ACTION}.xcresult" \
  CODE_SIGNING_ALLOWED=NO \
  "${ACTION}" ${EXTRA[@]+"${EXTRA[@]}"} > build/xcodebuild.log 2>&1 &
PID=$!
START=$(date +%s)
while kill -0 "$PID" 2>/dev/null; do
  sleep 10
  if (( $(date +%s) - START > LIMIT )); then
    echo "::error::xcodebuild exceeded ${LIMIT}s; last log lines:"
    tail -150 build/xcodebuild.log
    echo "--- simulator app log (last 2 min) ---"
    xcrun simctl spawn "${UDID}" log show --last 2m --style compact \
      --predicate 'process == "Koubutsu" OR subsystem == "com.awjackson2.Koubutsu"' 2>/dev/null | tail -80 || true
    kill "$PID" 2>/dev/null; sleep 5; kill -9 "$PID" 2>/dev/null
    STATUS=124
    break
  fi
done
if [[ $STATUS -eq 0 ]]; then wait "$PID" || STATUS=$?; fi
grep -E "error:|warning: |\*\* |Test (Case|Suite|run)|✔|✘|passed after|failed after|recorded an issue" build/xcodebuild.log | grep -v "^\s*$" | tail -250 || true
tail -5 build/xcodebuild.log
exit "${STATUS}"
