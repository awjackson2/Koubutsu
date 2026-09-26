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
STATUS=0
xcodebuild -project Koubutsu.xcodeproj -scheme Koubutsu \
  -destination "id=${UDID}" \
  -resultBundlePath "build/Koubutsu-${ACTION}.xcresult" \
  CODE_SIGNING_ALLOWED=NO \
  "${ACTION}" > build/xcodebuild.log 2>&1 || STATUS=$?
grep -E "error:|warning: |\*\* |Test (Case|Suite|run)|✔|✘|passed after|failed after" build/xcodebuild.log || true
tail -5 build/xcodebuild.log
exit "${STATUS}"
