import KoubutsuCore
import SwiftUI

/// The frozen frame with the recognized Japanese outlined. Tap selects a character; drag selects a region.
/// A magnifier follows the finger. All geometry goes through `CoordinateMapper`.
struct StudyView: View {
    let session: StudySession

    @State private var dragStart: CGPoint?
    @State private var dragLocation: CGPoint?

    /// Movement below this is a tap.
    private let tapTravel: CGFloat = 12
    private let loupeSize: CGFloat = 130
    private let loupeZoom: CGFloat = 2.5

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.black
                if let image = session.image, let size = session.frameSize {
                    let mapper = CoordinateMapper(sourceSize: size, viewWidth: geometry.size.width,
                                                  viewHeight: geometry.size.height, contentMode: .aspectFit)
                    frozenImage(image, size: geometry.size)
                    outlines(mapper)
                    highlights(mapper)
                    dragRectangle
                    loupe(image, size: geometry.size)
                    if session.phase == .recognizing { ScanSweep() }
                    FreezeFlash()
                    status
                        .frame(width: geometry.size.width, alignment: .leading)
                        .padding(.top, 10)
                }
            }
            .contentShape(Rectangle())
            .gesture(selectionGesture(size: geometry.size))
        }
    }

    private func frozenImage(_ image: CGImage, size: CGSize) -> some View {
        Image(decorative: image, scale: 1)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.width, height: size.height)
    }

    private func outlines(_ mapper: CoordinateMapper) -> some View {
        ForEach(session.japaneseObservations) { observation in
            let rect = mapper.viewRect(for: observation.boundingBox)
            CornerTicks(length: 6)
                .stroke(K.red.opacity(0.85), lineWidth: 1.5)
                .frame(width: rect.width + 6, height: rect.height + 6)
                .offset(x: rect.x - 3, y: rect.y - 3)
        }
        .allowsHitTesting(false)
    }

    private func highlights(_ mapper: CoordinateMapper) -> some View {
        ForEach(Array(session.selectionBoxes().enumerated()), id: \.offset) { _, box in
            let rect = mapper.viewRect(for: box)
            Rectangle()
                .fill(K.red.opacity(0.22))
                .overlay(CornerTicks(length: 8).stroke(K.red, lineWidth: 3))
                .frame(width: rect.width + 4, height: rect.height + 4)
                .offset(x: rect.x - 2, y: rect.y - 2)
                .transition(.scale(scale: 1.25).combined(with: .opacity))
        }
        .animation(K.snap, value: session.spans)
        .allowsHitTesting(false)
    }

    @ViewBuilder private var dragRectangle: some View {
        if let start = dragStart, let current = dragLocation, isDrag(start, current) {
            let rect = CGRect(x: min(start.x, current.x), y: min(start.y, current.y),
                              width: abs(current.x - start.x), height: abs(current.y - start.y))
            Rectangle()
                .stroke(K.red, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .frame(width: rect.width, height: rect.height)
                .offset(x: rect.minX, y: rect.minY)
                .allowsHitTesting(false)
        }
    }

    /// Zoomed view of the image under the finger, shown above it.
    @ViewBuilder private func loupe(_ image: CGImage, size: CGSize) -> some View {
        if let point = dragLocation {
            let center = CGPoint(x: min(max(point.x, loupeSize / 2), size.width - loupeSize / 2),
                                 y: max(point.y - loupeSize * 0.9, loupeSize / 2))
            ZStack {
                frozenImage(image, size: size)
                    .scaleEffect(loupeZoom, anchor: UnitPoint(x: point.x / max(size.width, 1),
                                                              y: point.y / max(size.height, 1)))
                    .offset(x: center.x - point.x, y: center.y - point.y)
            }
            .frame(width: size.width, height: size.height)
            .mask(Rectangle().frame(width: loupeSize, height: loupeSize).position(center))
            .overlay(Rectangle().stroke(K.paper, lineWidth: 2)
                .overlay(CornerTicks(length: 16).stroke(K.red, lineWidth: 3))
                .frame(width: loupeSize, height: loupeSize).position(center))
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder private var status: some View {
        HStack(spacing: 10) {
            Text("▮▮ PAUSE").foregroundStyle(K.paper)
            switch session.phase {
            case .recognizing:
                HStack(spacing: 4) {
                    Text("READING").foregroundStyle(K.red)
                    BlinkingCursor(width: 10, height: 18)
                }
            case .failed(let message):
                Text(message.uppercased()).foregroundStyle(K.red)
            case .ready:
                Text("\(session.japaneseObservations.count) LINES").foregroundStyle(K.paper.opacity(0.7))
            }
        }
        .font(K.osd(20))
        .shadow(color: .black, radius: 0, x: 2, y: 2)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }

    private func isDrag(_ a: CGPoint, _ b: CGPoint) -> Bool {
        abs(a.x - b.x) > tapTravel || abs(a.y - b.y) > tapTravel
    }

    private func selectionGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragStart == nil { dragStart = value.startLocation }
                dragLocation = value.location
            }
            .onEnded { value in
                defer {
                    dragStart = nil
                    dragLocation = nil
                }
                guard let frameSize = session.frameSize else { return }
                let mapper = CoordinateMapper(sourceSize: frameSize, viewWidth: size.width,
                                              viewHeight: size.height, contentMode: .aspectFit)
                if isDrag(value.startLocation, value.location) {
                    let a = value.startLocation, b = value.location
                    let rect = PlaneRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(b.x - a.x),
                                         height: abs(b.y - a.y))
                    session.select(rect: mapper.normalizedRect(fromView: rect))
                } else if let point = mapper.normalizedPoint(fromView: PlanePoint(x: value.location.x,
                                                                                 y: value.location.y)) {
                    session.tap(at: point)
                }
            }
    }
}
