import SwiftUI

/// Printed-paper grain: a tiled noise texture over a surface.
struct GrainOverlay: View {
    var opacity: Double = 1

    var body: some View {
        Image("Grain")
            .resizable(resizingMode: .tile)
            .interpolation(.none)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

/// CRT scanlines.
struct Scanlines: View {
    var spacing: CGFloat = 3
    var opacity: Double = 0.07

    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black.opacity(opacity)))
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

/// HUD corner brackets (detection-box ticks) around a rectangle.
struct CornerTicks: Shape {
    var length: CGFloat = 10
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.insetBy(dx: inset, dy: inset)
        let l = min(length, r.width / 2, r.height / 2)
        for (corner, dx, dy) in [(CGPoint(x: r.minX, y: r.minY), 1.0, 1.0), (CGPoint(x: r.maxX, y: r.minY), -1.0, 1.0),
                                 (CGPoint(x: r.minX, y: r.maxY), 1.0, -1.0), (CGPoint(x: r.maxX, y: r.maxY), -1.0, -1.0)] {
            p.move(to: CGPoint(x: corner.x + dx * l, y: corner.y))
            p.addLine(to: corner)
            p.addLine(to: CGPoint(x: corner.x, y: corner.y + dy * l))
        }
        return p
    }
}

/// "■ ■ ■" dotted marker from the print references.
struct BlockMarks: View {
    var count = 3
    var size: CGFloat = 5
    var color: Color = K.red

    var body: some View {
        HStack(spacing: size) {
            ForEach(0..<count, id: \.self) { _ in Rectangle().fill(color).frame(width: size, height: size) }
        }
    }
}

extension View {
    /// Grain + scanlines on top of a surface.
    func kTexture(grain: Double = 1, scanlines: Double = 0.05) -> some View {
        overlay { GrainOverlay(opacity: grain) }
            .overlay { if scanlines > 0 { Scanlines(opacity: scanlines) } }
    }

    /// Hairline frame with red HUD corner ticks.
    func kFrame(_ color: Color = K.red, tick: CGFloat = 10, hairline: Color? = nil) -> some View {
        overlay {
            ZStack {
                if let hairline { Rectangle().stroke(hairline, lineWidth: 1) }
                CornerTicks(length: tick).stroke(color, lineWidth: 2)
            }
            .allowsHitTesting(false)
        }
    }
}
