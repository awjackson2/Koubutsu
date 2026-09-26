#!/usr/bin/env bash
# Prints facts about the installed Xcode/iOS SDK relevant to Koubutsu's API choices.
# Used by CI because development containers have no Xcode. Output is Markdown.
set -uo pipefail
SDK=$(xcrun --sdk iphoneos --show-sdk-path)
FW="$SDK/System/Library/Frameworks"
section() { echo; echo "## $1"; echo '```'; }
endsection() { echo '```'; }
iface() { # framework -> first arm64 swiftinterface path
  ls "$FW/$1.framework/Modules/$1.swiftmodule/"arm64*-apple-ios.swiftinterface 2>/dev/null | head -1
}

echo "# SDK Report"
section "Toolchain"; xcodebuild -version; swift --version 2>&1; xcodebuild -showsdks; endsection
section "Simulator runtimes"; xcrun simctl list runtimes; endsection
section "Available iPad simulators"; xcrun simctl list devices available | grep -i ipad | head -20; endsection

section "Vision: VNRecognizeTextRequest (ObjC header)"
grep -n -E "Revision[0-9]|API_AVAILABLE|supportedRecognitionLanguages|recognitionLanguages|automaticallyDetectsLanguage" \
  "$FW/Vision.framework/Headers/VNRecognizeTextRequest.h" | head -40
endsection
VI=$(iface Vision)
section "Vision: Swift RecognizeTextRequest ($VI)"
grep -n -E "struct RecognizeTextRequest|RecognizedTextObservation|recognitionLanguages|supportedRecognitionLanguages|recognitionLevel|usesLanguageCorrection|func perform\(on: CoreVideo.CVPixelBuffer|func perform\(on: CoreMedia.CMSampleBuffer|Revision" "$VI" | head -60
endsection

TI=$(iface Translation)
section "Translation ($TI)"
grep -n -E "@available|class TranslationSession|init\(installedSource|public init|func translate|func translations|func prepareTranslation|struct Request|struct Response|LanguageAvailability|func status|translationTask|Configuration|func cancel|isReady|canRequestDownloads" "$TI" | head -120
endsection

section "AVFoundation: external capture devices"
grep -rn -E "AVCaptureDeviceTypeExternal|AVCaptureDeviceWasConnected|AVCaptureDeviceWasDisconnected|AVCaptureDeviceTypeMicrophone|AVCaptureDeviceTypeBuiltInMicrophone" "$FW/AVFoundation.framework/Headers/" | head -30
endsection
section "AVFoundation: sample buffer rendering"
grep -rn -E "sampleBufferRenderer|enqueueSampleBuffer|AVSampleBufferVideoRenderer" "$FW/AVFoundation.framework/Headers/AVSampleBufferDisplayLayer.h" | head -20
grep -rn -E "copyPixelBufferForItemTime|hasNewPixelBufferForItemTime|initWithOutputSettings|initWithPixelBufferAttributes" "$FW/AVFoundation.framework/Headers/AVPlayerItemOutput.h" | head -10
endsection
echo; echo "_Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)_"
