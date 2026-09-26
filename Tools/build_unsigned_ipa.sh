#!/usr/bin/env bash
# Builds an unsigned Release device build and packages it as build/ipa/Koubutsu.ipa.
# Usage: Tools/build_unsigned_ipa.sh [build-number]
set -euo pipefail
BUILD_NUMBER=${1:-1}
rm -rf build/ipa build/ipa-dd
mkdir -p build/ipa
xcodebuild -project Koubutsu.xcodeproj -scheme Koubutsu -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath build/ipa-dd \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  CURRENT_PROJECT_VERSION="${BUILD_NUMBER}" build > build/ipa/xcodebuild.log 2>&1 \
  || { grep -n -B2 -A6 "error:" build/ipa/xcodebuild.log | head -100; exit 1; }
APP=build/ipa-dd/Build/Products/Release-iphoneos/Koubutsu.app
test -d "$APP"
mkdir -p build/ipa/Payload
cp -R "$APP" build/ipa/Payload/
(cd build/ipa && zip -qry Koubutsu.ipa Payload)
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Info.plist"
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP/Info.plist"
ls -la build/ipa/Koubutsu.ipa
