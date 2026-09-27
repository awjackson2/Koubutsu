import SwiftUI

/// Surveillance-monitor housing drawn around the video stage outside full screen (9.4.0): a header strip with a
/// channel tag, the source name and a running clock, tick rails along the sides and bottom, a recessed bezel and
/// red HUD corner ticks. Purely decorative: no hit testing and no per-frame work (the clock ticks once a second).
struct MonitorFrame: View {
    /// The video stage in this view's coordinate space (from `VideoStageLayout.framed`).
    let stage: CGRect
    let sourceLabel: String?
    let isRunning: Bool
    var bottomInset: CGFloat = 16

    private let bezel: CGFloat = 5
    private let tickInset: CGFloat = 10

    var body: some View {
        let housingBottom = stage.maxY + bottomInset
        ZStack(alignment: .topLeading) {
            // Housing: fills the window so the space the chrome does not cover (portrait) is part of the console.
            K.inkRaised
                .kTexture(grain: 0.25, scanlines: 0.35)
            Rectangle().fill(K.paper.opacity(0.18))
                .frame(height: 1)
                .offset(y: housingBottom)
            // Recessed bezel
            Rectangle()
                .fill(K.ink)
                .overlay(Rectangle().stroke(K.paper.opacity(0.22), lineWidth: 1))
                .frame(width: stage.width + bezel * 2, height: stage.height + bezel * 2)
                .offset(x: stage.minX - bezel, y: stage.minY - bezel)
            rails(housingBottom: housingBottom)
            CornerTicks(length: 22)
                .stroke(K.red, lineWidth: 3)
                .frame(width: stage.width + tickInset * 2, height: stage.height + tickInset * 2)
                .offset(x: stage.minX - tickInset, y: stage.minY - tickInset)
            header
                .frame(width: stage.width, height: 18)
                .offset(x: stage.minX, y: stage.minY - 34)
            caption
                .frame(width: stage.width, height: 16)
                .offset(x: stage.minX, y: housingBottom + 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var header: some View {
        HStack(spacing: 10) {
            KTag(text: "CH-01", filled: true)
            Text((sourceLabel ?? "NO SOURCE").uppercased())
                .font(K.osdFixed(14))
                .foregroundStyle(K.paper.opacity(0.8))
                .lineLimit(1)
            BlockMarks(count: 3, size: 4)
            Spacer(minLength: 8)
            Text("映像入力 · VIDEO IN")
                .font(K.dotFixed(12))
                .foregroundStyle(K.paper.opacity(0.4))
                .lineLimit(1)
            Spacer(minLength: 8)
            MonitorClock(isRunning: isRunning)
        }
    }

    /// Maker's plate under the housing (visible where the chrome leaves space, e.g. portrait).
    private var caption: some View {
        HStack(spacing: 10) {
            BlockMarks(count: 3, size: 4, color: K.paper.opacity(0.3))
            Text("KOUBUTSU MONITOR SYSTEM · MODEL KB-09")
                .font(K.osdFixed(12))
            Spacer(minLength: 8)
            Text("よむ・わかる・おぼえる")
                .font(K.dotFixed(12))
        }
        .foregroundStyle(K.paper.opacity(0.3))
        .lineLimit(1)
    }

    /// Ruler ticks: along both sides (every 1/32 of the stage height, longer every 1/4 and 1/8) and along the
    /// bottom edge of the housing.
    private func rails(housingBottom: CGFloat) -> some View {
        Canvas { context, _ in
            let color = GraphicsContext.Shading.color(K.paper.opacity(0.35))
            let divisions = 32
            for i in 1..<divisions {
                let y = stage.minY + stage.height * CGFloat(i) / CGFloat(divisions)
                let length: CGFloat = i % 8 == 0 ? 8 : (i % 4 == 0 ? 5 : 3)
                context.fill(Path(CGRect(x: stage.minX - tickInset - 3 - length, y: y, width: length, height: 1)),
                             with: i % 8 == 0 ? .color(K.red) : color)
                context.fill(Path(CGRect(x: stage.maxX + tickInset + 3, y: y, width: length, height: 1)),
                             with: i % 8 == 0 ? .color(K.red) : color)
            }
            let columns = 64
            for i in 2..<(columns - 1) {
                let x = stage.minX + stage.width * CGFloat(i) / CGFloat(columns)
                let length: CGFloat = i % 8 == 0 ? 4 : 2
                context.fill(Path(CGRect(x: x, y: housingBottom - 2 - length, width: 1, height: length)), with: color)
            }
        }
    }
}

/// "● REC 21:47:03" — the record dot blinks while a source runs; the host clock ticks once a second.
private struct MonitorClock: View {
    let isRunning: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let blink = !reduceMotion && Int(context.date.timeIntervalSinceReferenceDate) % 2 == 0
            HStack(spacing: 6) {
                Rectangle()
                    .fill(isRunning ? K.red : K.grey)
                    .frame(width: 8, height: 8)
                    .opacity(isRunning && blink ? 0.25 : 1)
                Text(isRunning ? "REC" : "STBY")
                Text(Self.clock(context.date))
            }
            .font(K.osdFixed(14))
            .foregroundStyle(K.paper.opacity(0.8))
        }
    }

    /// 24-hour HH:MM:SS regardless of the locale's clock style.
    private static func clock(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return String(format: "%02d:%02d:%02d", c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }
}
