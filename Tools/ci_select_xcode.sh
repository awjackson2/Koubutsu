#!/usr/bin/env bash
# Selects the newest stable Xcode installed on a GitHub macOS runner.
set -euo pipefail
ls -d /Applications/Xcode*.app || true
CANDIDATE=$(ls -d /Applications/Xcode_[0-9]*.app 2>/dev/null | grep -v -i beta | sort -V | tail -1 || true)
if [[ -z "${CANDIDATE}" ]]; then CANDIDATE=/Applications/Xcode.app; fi
echo "Selecting ${CANDIDATE}"
sudo xcode-select -s "${CANDIDATE}/Contents/Developer"
xcodebuild -version
