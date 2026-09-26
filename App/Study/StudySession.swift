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
    /// Dictionary matches for a tapped word, best first.
    private(set) var words: [LookupResult] = []
    /// Words of a dragged phrase.
    private(set) var tokens: [LookupToken] = []

    /// Open the word card as soon as the tapped word is looked up (automation screenshots).
    var autoOpenCard = false

    @ObservationIgnored private var lookup: DictionaryLookup?
    @ObservationIgnored private var lookupTask: Task<Void, Never>?

    @ObservationIgnored private var translator: TranslationController?
    @ObservationIgnored private var translateTask: Task<Void, Never>?
    @ObservationIgnored private let context = CIContext()

    var selectedText: String { StudySelection.joinedText(spans) }
    var japaneseObservations: [RecognizedTextObservation] {
        observations.filter { TextNormalizer.containsJapaneseText($0.text) }
    }

    /// Freezes `frame` and reads it.
    func begin(frame: VideoFrame, ocr: VisionOCRService, translator: TranslationController,
               lookup: DictionaryLookup?) async {
        self.translator = translator
        self.lookup = lookup
        words = []
        tokens = []
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
        lookupTask?.cancel()
        words = []
        tokens = []
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
        lookUpWord(at: span)
    }

    func select(rect: NormalizedRect) {
        let selected = StudySelection(observations: japaneseObservations).spans(in: rect)
        guard !selected.isEmpty else {
            clearSelection()
            return
        }
        spans = selected
        translate(StudySelection.joinedText(selected))
        segment(StudySelection.joinedText(selected))
    }

    func clearSelection() {
        spans = []
        words = []
        tokens = []
        lookupTask?.cancel()
        translation = nil
        translatedSource = nil
        translateTask?.cancel()
    }

    /// The selected line (with some margin) cut out of the frozen frame, for the word bank.
    func lineCrop() -> CGImage? {
        guard let image, let span = spans.first,
              let line = observations.first(where: { $0.id == span.observationID }) else { return nil }
        let box = line.boundingBox
        let rect = NormalizedRect(x: box.x - box.height * 0.8, y: box.y - box.height * 0.6,
                                  width: box.width + box.height * 1.6, height: box.height * 2.2).clamped
        let width = Double(image.width), height = Double(image.height)
        return image.cropping(to: CGRect(x: rect.x * width, y: rect.y * height, width: rect.width * width,
                                         height: rect.height * height).integral)
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

    /// Looks up the word starting at the tapped character and widens the highlight to the whole word.
    private func lookUpWord(at span: SelectedSpan) {
        lookupTask?.cancel()
        words = []
        tokens = []
        guard let lookup else { return }
        let characters = Array(span.lineText)
        let start = span.range.lowerBound
        let rest = String(characters[start...])
        lookupTask = Task {
            let results = await Task.detached(priority: .userInitiated) { lookup.word(at: rest) }.value
            guard !Task.isCancelled, spans.first?.observationID == span.observationID,
                  spans.first?.range.lowerBound == start else { return }
            words = results
            if let first = results.first {
                let end = min(characters.count, start + first.matched.count)
                spans = [SelectedSpan(observationID: span.observationID, range: start..<end,
                                      text: String(characters[start..<end]), lineText: span.lineText)]
            }
        }
    }

    private func segment(_ text: String) {
        lookupTask?.cancel()
        words = []
        tokens = []
        guard let lookup else { return }
        lookupTask = Task {
            let result = await Task.detached(priority: .userInitiated) { lookup.segment(text) }.value
            guard !Task.isCancelled, selectedText == text else { return }
            tokens = result
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
