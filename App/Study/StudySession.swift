import CoreImage
import KoubutsuCore
import Observation

/// Study mode state: a frozen frame, its text (re-read with accurate OCR and per-character boxes), the
/// learner's selection and its translation. The live pipeline keeps running underneath; only the view changes.
@MainActor
@Observable
final class StudySession {
    enum Phase: Equatable {
        case recognizing
        case ready
        case failed(String)
    }

    private(set) var isActive = false
    private(set) var image: CGImage?
    private(set) var frameSize: PixelSize?
    private(set) var observations: [RecognizedTextObservation] = []
    private(set) var phase: Phase = .recognizing
    private(set) var spans: [SelectedSpan] = []
    /// Text sent for translation: the whole line for a tap, the selection for a drag.
    private(set) var translatedSource: String?
    private(set) var translation: String?
    private(set) var isTranslating = false
    /// The frozen source's media time, if any (for context when saving).
    private(set) var frameTiming: FrameTiming?

    @ObservationIgnored private var translator: TranslationController?
    @ObservationIgnored private var translateTask: Task<Void, Never>?
    @ObservationIgnored private let context = CIContext()

    var selectedText: String { StudySelection.joinedText(spans) }
    var japaneseObservations: [RecognizedTextObservation] {
        observations.filter { TextNormalizer.containsJapaneseText($0.text) }
    }

    /// Freezes `frame` and reads it.
    func begin(frame: VideoFrame, ocr: VisionOCRService, translator: TranslationController) async {
        self.translator = translator
        isActive = true
        phase = .recognizing
        observations = []
        spans = []
        translation = nil
        translatedSource = nil
        frameTiming = frame.timing
        frameSize = frame.size
        if let pixelBuffer = frame.pixelBuffer {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            image = context.createCGImage(ciImage, from: ciImage.extent)
        }
        do {
            let result = try await ocr.recognize(frame, configuration: .study)
            guard isActive else { return }
            observations = result.observations
            phase = .ready
        } catch {
            guard isActive else { return }
            phase = .failed(error.description)
        }
    }

    func end() {
        isActive = false
        translateTask?.cancel()
        image = nil
        observations = []
        spans = []
        translation = nil
        translatedSource = nil
    }

    func tap(at point: NormalizedPoint) {
        guard let span = StudySelection(observations: japaneseObservations).character(at: point) else {
            clearSelection()
            return
        }
        spans = [span]
        translate(span.lineText)
    }

    func select(rect: NormalizedRect) {
        let selected = StudySelection(observations: japaneseObservations).spans(in: rect)
        guard !selected.isEmpty else {
            clearSelection()
            return
        }
        spans = selected
        translate(StudySelection.joinedText(selected))
    }

    func clearSelection() {
        spans = []
        translation = nil
        translatedSource = nil
        translateTask?.cancel()
    }

    /// Character boxes of the current selection, per line.
    func selectionBoxes() -> [NormalizedRect] {
        spans.compactMap { span in
            guard let observation = observations.first(where: { $0.id == span.observationID }) else { return nil }
            let boxes = CharacterLayout.boxes(for: observation)
            guard span.range.upperBound <= boxes.count else { return nil }
            return boxes[span.range].dropFirst().reduce(boxes[span.range.lowerBound]) { $0.union($1) }
        }
    }

    private func translate(_ text: String) {
        guard text != translatedSource else { return }
        translateTask?.cancel()
        translatedSource = text
        translation = nil
        isTranslating = true
        translateTask = Task { [translator] in
            let result = await translator?.translate(text: text)
            guard !Task.isCancelled, translatedSource == text else { return }
            translation = result
            isTranslating = false
        }
    }
}
