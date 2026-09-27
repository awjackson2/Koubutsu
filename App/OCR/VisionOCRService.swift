import CoreMedia
import Foundation
import KoubutsuCore
import Vision

/// Apple Vision text recognition behind `OCRService`.
///
/// `Vision` and `KoubutsuCore` both declare `NormalizedRect`, `NormalizedPoint` and
/// `RecognizedTextObservation`; this file is the only place both are imported, so names are qualified.
struct VisionOCRService: OCRService {
    typealias Frame = VideoFrame

    let clock: any HostClock

    init(clock: any HostClock = AppleHostClock()) {
        self.clock = clock
    }

    func supportedLanguages(quality: OCRQuality) async -> [String] {
        var request = RecognizeTextRequest()
        request.recognitionLevel = quality == .fast ? .fast : .accurate
        return request.supportedRecognitionLanguages.map { $0.maximalIdentifier }
    }

    /// True when the recognizer supports every language in `configuration`.
    func supports(_ configuration: OCRConfiguration) async -> Bool {
        var request = RecognizeTextRequest()
        request.recognitionLevel = configuration.quality == .fast ? .fast : .accurate
        let supported = Set(request.supportedRecognitionLanguages.compactMap { $0.languageCode?.identifier })
        return configuration.languages.allSatisfy { lang in
            Locale.Language(identifier: lang).languageCode.map { supported.contains($0.identifier) } ?? false
        }
    }

    func recognize(_ frame: VideoFrame, configuration: OCRConfiguration) async throws(OCRError) -> OCRResult {
        guard let pixelBuffer = frame.pixelBuffer else {
            throw .recognitionFailed("frame has no image buffer")
        }
        var request = RecognizeTextRequest()
        request.recognitionLevel = configuration.quality == .fast ? .fast : .accurate
        request.recognitionLanguages = configuration.languages.map { Locale.Language(identifier: $0) }
        request.automaticallyDetectsLanguage = false
        request.usesLanguageCorrection = configuration.usesLanguageCorrection
        if configuration.minimumTextHeight > 0 {
            request.minimumTextHeightFraction = Float(configuration.minimumTextHeight)
        }
        let roi = configuration.regionOfInterest?.clamped
        if let roi {
            let bl = roi.bottomLeftOrigin
            request.regionOfInterest = Vision.NormalizedRect(x: bl.x, y: bl.y, width: bl.width, height: bl.height)
        }

        let started = clock.now()
        let visionObservations: [Vision.RecognizedTextObservation]
        do {
            visionObservations = try await request.perform(on: pixelBuffer)
        } catch is CancellationError {
            throw .cancelled
        } catch {
            throw .recognitionFailed(String(describing: error))
        }
        let finished = clock.now()

        let observations = visionObservations.compactMap { observation in
            Self.convert(observation, frame: frame.timing, regionOfInterest: roi, configuration: configuration)
        }
        return OCRResult(frame: frame.timing, frameSize: frame.size, observations: observations,
                         started: started, finished: finished, configuration: configuration)
    }

    static func convert(_ observation: Vision.RecognizedTextObservation, frame: FrameTiming,
                        regionOfInterest: KoubutsuCore.NormalizedRect?,
                        configuration: OCRConfiguration) -> KoubutsuCore.RecognizedTextObservation? {
        let candidates = observation.topCandidates(max(1, configuration.maximumCandidates))
        guard let best = candidates.first, observation.confidence >= configuration.minimumConfidence else {
            return nil
        }
        let text = best.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        func point(_ p: Vision.NormalizedPoint) -> KoubutsuCore.NormalizedPoint {
            KoubutsuCore.NormalizedPoint(bottomLeftOriginX: Double(p.x), y: Double(p.y))
        }
        var quad = KoubutsuCore.NormalizedQuad(topLeft: point(observation.topLeft),
                                               topRight: point(observation.topRight),
                                               bottomRight: point(observation.bottomRight),
                                               bottomLeft: point(observation.bottomLeft))
        if let regionOfInterest {
            quad = regionOfInterest.denormalizing(quad)
        }
        var characterBoxes: [KoubutsuCore.NormalizedRect]?
        if configuration.characterBoxes {
            characterBoxes = Self.characterBoxes(best, text: text, regionOfInterest: regionOfInterest)
        }
        return KoubutsuCore.RecognizedTextObservation(
            id: observation.uuid,
            text: text,
            confidence: observation.confidence,
            boundingBox: quad.boundingRect,
            quad: quad,
            candidates: candidates.map { .init(text: $0.string, confidence: $0.confidence) },
            frame: frame,
            characterBoxes: characterBoxes)
    }

    /// One box per character of `text` (the trimmed candidate string) via `RecognizedText.boundingBox(for:)`.
    /// Nil if any character has no box, so callers fall back to proportional layout.
    static func characterBoxes(_ candidate: Vision.RecognizedText, text: String,
                               regionOfInterest: KoubutsuCore.NormalizedRect?) -> [KoubutsuCore.NormalizedRect]? {
        let string = candidate.string
        guard let start = string.range(of: text)?.lowerBound else { return nil }
        var boxes: [KoubutsuCore.NormalizedRect] = []
        var index = start
        for _ in text {
            let next = string.index(after: index)
            guard let box = try? candidate.boundingBox(for: index..<next) else { return nil }
            func point(_ p: Vision.NormalizedPoint) -> KoubutsuCore.NormalizedPoint {
                KoubutsuCore.NormalizedPoint(bottomLeftOriginX: Double(p.x), y: Double(p.y))
            }
            var quad = KoubutsuCore.NormalizedQuad(topLeft: point(box.topLeft), topRight: point(box.topRight),
                                                   bottomRight: point(box.bottomRight),
                                                   bottomLeft: point(box.bottomLeft))
            if let regionOfInterest { quad = regionOfInterest.denormalizing(quad) }
            boxes.append(quad.boundingRect)
            index = next
        }
        return boxes
    }
}
