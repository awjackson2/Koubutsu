#!/usr/bin/env bash
# Prints facts about the installed Xcode/iOS SDK relevant to Koubutsu's API choices.
# Used by CI because development containers have no Xcode. Output is Markdown.
set -uo pipefail
SDK=$(xcrun --sdk iphoneos --show-sdk-path)
FW="$SDK/System/Library/Frameworks"
section() { echo; echo "## $1"; echo '```'; }
endsection() { echo '```'; }
iface() { ls "$FW/$1.framework/Modules/$1.swiftmodule/"arm64*-apple-ios.swiftinterface 2>/dev/null | head -1; }
# Prints a declaration block starting at the first line matching $2 through its closing brace at column 0/2.
block() { awk -v pat="$2" 'found==0 && $0 ~ pat {found=1} found {print; if ($0 ~ /^}/) exit}' "$1" | cut -c1-240 | head -${3:-120}; }

echo "# SDK Report"
section "Toolchain"; xcodebuild -version; swift --version 2>&1 | head -1; xcodebuild -showsdks | grep -E "iOS|Simulator - iOS"; endsection
section "Simulator runtimes"; xcrun simctl list runtimes | grep iOS; endsection

VI=$(iface Vision)
section "Vision: RecognizeTextRequest"; block "$VI" "^public struct RecognizeTextRequest" 80; endsection
section "Vision: RecognizedTextObservation"; block "$VI" "^public struct RecognizedTextObservation" 80; endsection
section "Vision: RecognizedText"; block "$VI" "^public struct RecognizedText " 60; endsection
section "Vision: ImageRequestHandler / perform"
grep -n -E "public (init|func perform)\(.*(CVPixelBuffer|CMSampleBuffer)" "$VI" | cut -c1-240 | head -20
block "$VI" "^public struct ImageRequestHandler" 40
endsection
section "Vision: NormalizedRect"; block "$VI" "^public struct NormalizedRect " 60; endsection
section "Vision: NormalizedPoint"; block "$VI" "^public struct NormalizedPoint " 40; endsection

TI=$(iface Translation)
section "Translation (full, availability-filtered)"
grep -v -E "@available\((tvOS|watchOS|visionOS), unavailable" "$TI" | grep -v -E "^\s*$|^//|^import|^@_exported" | cut -c1-240 | head -260
endsection

H="$FW/AVFoundation.framework/Headers"
section "AVCaptureDevice external type"; sed -n '466,500p' "$H/AVCaptureDevice.h"; endsection
section "AVCaptureDevice: every mention of external devices (iPhone support, 10.1.0)"
grep -n -i -E "external|UVC" "$H/AVCaptureDevice.h" | cut -c1-240 | head -40
endsection
section "AVCaptureDevice connect/disconnect notifications"; sed -n '20,45p' "$H/AVCaptureDevice.h"; endsection
section "AVSampleBufferDisplayLayer.sampleBufferRenderer"; sed -n '290,310p' "$H/AVSampleBufferDisplayLayer.h"; endsection
section "AVSampleBufferVideoRenderer"
grep -n -E "API_AVAILABLE|enqueue|flush|requiresFlush|status|copyDisplayedPixelBuffer|expectMinimum|presentationTimeExpectation" "$H/AVSampleBufferVideoRenderer.h" | cut -c1-200 | head -40
grep -n -E "enqueueSampleBuffer|flush|isReadyForMoreMediaData|API_AVAILABLE" "$H/AVQueuedSampleBufferRendering.h" | cut -c1-200 | head -20
endsection
echo; echo "_Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)_"
