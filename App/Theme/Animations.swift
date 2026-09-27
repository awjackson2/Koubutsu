import SwiftUI
import UIKit

/// Blinking block cursor ("▮") for waiting states and hints.
struct BlinkingCursor: View {
    var color: Color = K.red
    var width: CGFloat = 9
    var height: CGFloat = 16
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let on = reduceMotion || Int(context.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
            Rectangle().fill(color).frame(width: width, height: height).opacity(on ? 1 : 0)
        }
    }
}

/// An image that resolves from coarse pixels to full detail (4 → 8 → 16 → 32 px), in steps.
struct PixelResolve: View {
    let image: String
    let size: CGFloat
    let progress: Double

    private static let steps = [4, 8, 16, 32]

    var body: some View {
        let px = Self.steps[min(Self.steps.count - 1, max(0, Int(progress * Double(Self.steps.count))))]
        Group {
            if let mosaic = Self.mosaic(image, px) {
                Image(uiImage: mosaic).resizable().interpolation(.none)
            } else {
                Image(image).resizable().interpolation(.none)
            }
        }
        .frame(width: size, height: size)
    }

    /// The image averaged down to `px`×`px` (a mosaic), shown with nearest-neighbour scaling.
    private static func mosaic(_ name: String, _ px: Int) -> UIImage? {
        guard let source = UIImage(named: name)?.cgImage,
              let context = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: px, height: px))
        return context.makeImage().map { UIImage(cgImage: $0) }
    }
}

/// VCR power-on: the logo resolves, the wordmark types out, a status line, then a scanline wipe.
struct BootSequenceView: View {
    let onFinish: () -> Void
    @State private var phase = 0.0
    @State private var typed = 0
    @State private var wipe: CGFloat = 0
    @State private var finished = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let word = "KOUBUTSU"

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                K.ink
                VStack(spacing: 22) {
                    PixelResolve(image: "LogoMark", size: 160, progress: phase)
                        .kFrame(K.red, tick: 18)
                    HStack(spacing: 0) {
                        Text(String(word.prefix(typed))).font(K.osd(44)).foregroundStyle(K.paper)
                        BlinkingCursor(width: 20, height: 40)
                    }
                    HStack(spacing: 10) {
                        BlockMarks()
                        Text(typed >= word.count ? "SIGNAL OK · よむ・わかる・おぼえる" : "SIGNAL…")
                            .font(K.osd(16))
                            .foregroundStyle(K.paper.opacity(0.7))
                    }
                }
                Scanlines(spacing: 3, opacity: 0.25)
            }
            .mask(alignment: .top) {
                Rectangle().frame(height: geometry.size.height * (1 - wipe))
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(K.red)
                    .frame(height: 3)
                    .offset(y: geometry.size.height * (1 - wipe))
                    .opacity(wipe > 0 && wipe < 1 ? 1 : 0)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .task { await run() }
    }

    private func run() async {
        if reduceMotion {
            phase = 1
            typed = word.count
            try? await Task.sleep(for: .milliseconds(450))
            finish()
            return
        }
        for step in 1...4 {
            phase = Double(step) / 4
            try? await Task.sleep(for: .milliseconds(110))
        }
        for i in 1...word.count {
            typed = i
            try? await Task.sleep(for: .milliseconds(55))
        }
        try? await Task.sleep(for: .milliseconds(420))
        withAnimation(.easeIn(duration: 0.35)) { wipe = 1 }
        try? await Task.sleep(for: .milliseconds(360))
        finish()
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinish()
    }
}

/// A red scan line sweeping top to bottom, repeatedly (study mode reading the frozen frame).
struct ScanSweep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            EmptyView()
        } else {
            TimelineView(.animation) { context in
                GeometryReader { geometry in
                    let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.1) / 1.1
                    let y = geometry.size.height * t
                    ZStack(alignment: .top) {
                        LinearGradient(colors: [K.red.opacity(0), K.red.opacity(0.18)], startPoint: .top, endPoint: .bottom)
                            .frame(height: 60)
                            .offset(y: y - 60)
                        Rectangle().fill(K.red).frame(height: 2).offset(y: y)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                }
            }
            .allowsHitTesting(false)
        }
    }
}

/// One-shot paper flash (freeze-frame shutter).
struct FreezeFlash: View {
    @State private var visible = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        K.paper
            .opacity(visible && !reduceMotion ? 0.55 : 0)
            .allowsHitTesting(false)
            .onAppear { withAnimation(.easeOut(duration: 0.22)) { visible = false } }
    }
}

extension View {
    /// Pulses once whenever `value` changes (badges).
    func kPulse<V: Equatable>(on value: V) -> some View {
        modifier(PulseModifier(value: value))
    }
}

private struct PulseModifier<V: Equatable>: ViewModifier {
    let value: V
    @State private var scale: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: value) { _, _ in
                guard !reduceMotion else { return }
                scale = 1.35
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { scale = 1 }
            }
    }
}
