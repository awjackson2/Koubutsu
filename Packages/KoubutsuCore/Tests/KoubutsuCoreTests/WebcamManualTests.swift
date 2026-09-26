import Testing
@testable import KoubutsuCore

/// Geometry and readings measured from a live C920 webcam recording of a Japanese instruction manual
/// (numbered list 1–8; Thai on the facing page misread as Latin/digits; 「ク」 wrapped from item 1 and read at
/// 0.30 in some results). Before 7.6.2 the list regrouped into 1–4 blocks per result and the junk got boxes.
struct WebcamManualTests {
    static let frameA: [RecognizedTextObservation] = [
        line("700705imau", x: 0.0, y: 0.229, w: 0.172, h: 0.167, confidence: 0.5),
        line("231570820447", x: 0.0, y: 0.331, w: 0.166, h: 0.114, confidence: 0.5),
        line("6", x: 0.478, y: 0.026, w: 0.015, h: 0.031, confidence: 1),
        line("1.電源ボタン：電源オン／オフ、画面点灯／消灯、画面ロッ", x: 0.049, y: 0.234, w: 0.631, h: 0.058, confidence: 0.5),
        line("ク", x: 0.068, y: 0.287, w: 0.022, h: 0.041, confidence: 0.3),
        line("2.ボリュームノブ：音量調整", x: 0.045, y: 0.325, w: 0.307, h: 0.053, confidence: 0.5),
        line("3.再生／一時停止ボタン：再生／一時停止、操作決定", x: 0.043, y: 0.370, w: 0.579, h: 0.063, confidence: 1),
        line("4.上／下曲ボタン：曲の切り替えとメニューの切り替え", x: 0.041, y: 0.419, w: 0.606, h: 0.054, confidence: 0.5),
        line("5.TFカードスロット：TFカード挿入用スロット", x: 0.039, y: 0.466, w: 0.494, h: 0.053, confidence: 0.5),
        line("6.Type-C USBポート：充電／データ転送", x: 0.036, y: 0.516, w: 0.454, h: 0.055, confidence: 1),
        line("7.ディスプレイ", x: 0.035, y: 0.564, w: 0.163, h: 0.053, confidence: 1),
        line("8.3.5mmシングルエンドヘッドホン出力端子", x: 0.032, y: 0.612, w: 0.509, h: 0.056, confidence: 1),
    ]

    /// Next result: 「ク」 missed, junk read differently, item 2 slightly shifted.
    static let frameB: [RecognizedTextObservation] = frameA.compactMap { observation in
        var o = observation
        switch o.text {
        case "ク": return nil
        case "700705imau": o.text = "200702mau"
        case "231570820447": o.text = "2M1570820747"
        case "2.ボリュームノブ：音量調整": o.boundingBox.y += 0.003
        default: break
        }
        return o
    }

    private func ocr(_ observations: [RecognizedTextObservation], at t: Double) -> OCRResult {
        let frame = FakeFrame(sequence: UInt64(t * 10), host: t).timing
        return OCRResult(frame: frame, frameSize: .init(width: 1920, height: 1080),
                         observations: observations.map { var o = $0; o.frame = frame; return o },
                         started: frame.hostTime, finished: frame.hostTime.adding(0.5), configuration: .japanese)
    }

    @Test func eachListItemIsOneBlockAndJunkIsDropped() {
        var s = TextStabilizer()
        let texts = s.process(ocr(Self.frameA, at: 0)).compactMap { event -> String? in
            if case .stabilized(let t) = event { t.text } else { nil }
        }
        #expect(texts.count == 8)
        #expect(texts.contains("1.電源ボタン:電源オン/オフ、画面点灯/消灯、画面ロック"))
        #expect(texts.contains("8.3.5mmシングルエンドヘッドホン出力端子"))
        #expect(!texts.contains { !TextNormalizer.containsJapaneseText($0) })
    }

    @Test func alternatingReadingsCauseNoFurtherEvents() {
        var s = TextStabilizer()
        _ = s.process(ocr(Self.frameA, at: 0))
        var later: [TextEvent] = []
        for i in 1...20 {
            later += s.process(ocr(i.isMultiple(of: 2) ? Self.frameA : Self.frameB, at: Double(i) * 0.5))
        }
        #expect(later.isEmpty)
        #expect(s.tracks.count == 8)
    }
}
