import SwiftUI

// MARK: - Pixel icons

/// A pixel-art icon from the asset catalog (`px.<name>`, 16×16), drawn crisp at integer multiples.
struct PixelIcon: View {
    let name: String
    var size: CGFloat = 24

    init(_ name: String, size: CGFloat = 24) {
        self.name = name
        self.size = size
    }

    var body: some View {
        Image("px." + name)
            .renderingMode(.template)
            .resizable()
            .interpolation(.none)
            .frame(width: size, height: size)
    }
}

// MARK: - Buttons

/// Blocky OSD button: hard offset shadow that the button presses into.
struct KButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, ghost }
    var kind: Kind = .secondary
    var compact = false
    @Environment(\.kSurface) private var surface
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shadow: CGFloat = kind == .ghost ? 0 : 3
        return configuration.label
            .font(K.osd(compact ? 14 : 16))
            .textCase(.uppercase)
            .lineLimit(1)
            .padding(.horizontal, compact ? 10 : 14)
            .padding(.vertical, compact ? 6 : 9)
            .foregroundStyle(foreground)
            .background(background(pressed: pressed))
            .overlay(Rectangle().stroke(border, lineWidth: kind == .ghost ? 0 : 2))
            .background(Rectangle().fill(shadowColor).offset(x: shadow, y: shadow))
            .offset(x: pressed ? shadow : 0, y: pressed ? shadow : 0)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.linear(duration: 0.05), value: pressed)
            .contentShape(Rectangle())
    }

    private var foreground: Color {
        switch kind {
        case .primary: K.paper
        case .secondary, .ghost: surface == .ink ? K.paper : K.ink
        }
    }

    private func background(pressed: Bool) -> Color {
        switch kind {
        case .primary: K.red
        case .secondary: surface.background
        case .ghost: pressed ? surface.hairline : .clear
        }
    }

    private var border: Color { kind == .primary ? K.red : surface.foreground }
    private var shadowColor: Color { kind == .primary ? (surface == .ink ? K.paper.opacity(0.25) : K.ink) : surface.foreground.opacity(0.35) }
}

extension ButtonStyle where Self == KButtonStyle {
    static var kPrimary: KButtonStyle { KButtonStyle(kind: .primary) }
    static var kSecondary: KButtonStyle { KButtonStyle(kind: .secondary) }
    static var kGhost: KButtonStyle { KButtonStyle(kind: .ghost) }
    static func k(_ kind: KButtonStyle.Kind, compact: Bool = true) -> KButtonStyle { KButtonStyle(kind: kind, compact: compact) }
}

/// Icon (and optional OSD label) button for bars: flat, red when active, pressed = inverted block.
struct KIconButtonStyle: ButtonStyle {
    var active = false
    @Environment(\.kSurface) private var surface

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(K.osd(15))
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .foregroundStyle(configuration.isPressed ? surface.background : (active ? K.red : surface.foreground))
            .background(configuration.isPressed ? surface.foreground : Color.clear)
            .contentShape(Rectangle())
            .animation(.linear(duration: 0.05), value: configuration.isPressed)
    }
}

/// Icon + optional label, for bars.
struct KIconLabel: View {
    let icon: String
    var title: String?
    var size: CGFloat = 24

    var body: some View {
        HStack(spacing: 6) {
            PixelIcon(icon, size: size)
            if let title { Text(title).lineLimit(1) }
        }
    }
}

// MARK: - Toggle

/// Pixel switch: a sliding block in a box, red when on, with an OSD ON/OFF readout.
struct KToggleStyle: ToggleStyle {
    @Environment(\.kSurface) private var surface

    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(K.snap) { configuration.isOn.toggle() }
        } label: {
            HStack(spacing: 12) {
                configuration.label
                    .font(K.osd(16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(configuration.isOn ? "ON" : "OFF")
                    .font(K.osd(14))
                    .foregroundStyle(configuration.isOn ? K.red : surface.secondary)
                    .frame(width: 34, alignment: .trailing)
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Rectangle().stroke(surface.foreground, lineWidth: 2)
                    Rectangle()
                        .fill(configuration.isOn ? K.red : surface.foreground)
                        .frame(width: 18, height: 18)
                        .padding(3)
                }
                .frame(width: 48, height: 24)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == KToggleStyle {
    static var k: KToggleStyle { KToggleStyle() }
}

// MARK: - Slider

/// Stepped slider: a tick ruler with a square thumb.
struct KSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0.1
    @Environment(\.kSurface) private var surface

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            ZStack(alignment: .leading) {
                Rectangle().fill(surface.foreground).frame(height: 2)
                Rectangle().fill(K.red).frame(width: max(0, width * fraction), height: 4)
                HStack(spacing: 0) {
                    let ticks = Int(((range.upperBound - range.lowerBound) / step).rounded())
                    ForEach(0...max(1, ticks), id: \.self) { i in
                        Rectangle().fill(surface.foreground).frame(width: 1, height: i % 5 == 0 ? 10 : 5)
                        if i < ticks { Spacer(minLength: 0) }
                    }
                }
                .offset(y: 10)
                Rectangle()
                    .fill(K.red)
                    .overlay(Rectangle().stroke(surface.foreground, lineWidth: 2))
                    .frame(width: 18, height: 18)
                    .offset(x: max(0, min(width - 18, width * fraction - 9)))
            }
            .frame(height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                let raw = range.lowerBound + (drag.location.x / max(width, 1)) * (range.upperBound - range.lowerBound)
                let stepped = (raw / step).rounded() * step
                value = min(range.upperBound, max(range.lowerBound, stepped))
            })
        }
        .frame(height: 36)
    }
}

// MARK: - Segmented

/// Row of boxed options; the selected one is a filled red block.
struct KSegmented<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, title: String)]
    @Environment(\.kSurface) private var surface

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button {
                    withAnimation(K.snap) { selection = option.value }
                } label: {
                    Text(option.title)
                        .font(K.osd(14))
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(selection == option.value ? K.paper : surface.foreground)
                        .background(selection == option.value ? K.red : Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if index < options.count - 1 { Rectangle().fill(surface.foreground).frame(width: 2) }
            }
        }
        .overlay(Rectangle().stroke(surface.foreground, lineWidth: 2))
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Menu

struct KMenuItem: Identifiable {
    let id = UUID()
    var title: String
    var icon: String?
    var isChecked = false
    var isDivider = false
    var action: () -> Void = {}

    static var divider: KMenuItem { KMenuItem(title: "", isDivider: true) }
}

/// Replacement for `Menu`: a button that opens an ink HUD popover list.
struct KMenu<Label: View>: View {
    let items: () -> [KMenuItem]
    @ViewBuilder let label: () -> Label
    @State private var open = false

    var body: some View {
        Button { open.toggle() } label: { label() }
            .buttonStyle(KIconButtonStyle(active: open))
            .popover(isPresented: $open, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(items()) { item in
                        if item.isDivider {
                            Rectangle().fill(K.paper.opacity(0.2)).frame(height: 1).padding(.vertical, 4)
                        } else {
                            Button {
                                open = false
                                item.action()
                            } label: {
                                HStack(spacing: 10) {
                                    Text(item.isChecked ? "■" : "□")
                                        .foregroundStyle(item.isChecked ? K.red : K.paper.opacity(0.4))
                                    if let icon = item.icon { PixelIcon(icon, size: 16) }
                                    Text(item.title).frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .font(K.osd(16))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(KIconButtonStyle())
                        }
                    }
                }
                .padding(.vertical, 8)
                .frame(minWidth: 280, alignment: .leading)
                .kSurface(.ink)
                .kFrame(K.red, tick: 12)
                .presentationCompactAdaptation(.popover)
                .presentationBackground(K.ink)
            }
    }
}

// MARK: - Panels and labels

/// Section header from the print references: "■ ■ ■  TITLE ───── 01".
struct KSectionHeader: View {
    let title: String
    var index: Int?
    @Environment(\.kSurface) private var surface

    var body: some View {
        HStack(spacing: 10) {
            BlockMarks()
            Text(title).font(K.osd(14)).textCase(.uppercase).foregroundStyle(K.red)
            Rectangle().fill(surface.hairline).frame(height: 1)
            if let index { Text(String(format: "%02d", index)).font(K.osd(14)).foregroundStyle(surface.secondary) }
        }
    }
}

/// Small boxed tag.
struct KTag: View {
    let text: String
    var color: Color = K.red
    var filled = false

    var body: some View {
        Text(text)
            .font(K.osd(12))
            .textCase(.uppercase)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(filled ? K.paper : color)
            .background(filled ? color : .clear)
            .overlay(Rectangle().stroke(color, lineWidth: 1))
    }
}

/// Sheet chrome replacing the navigation bar: title in OSD type, actions at the sides, a hard rule below.
struct KSheetHeader<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                leading()
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(K.osd(24)).textCase(.uppercase).lineLimit(1)
                    if let subtitle { Text(subtitle).font(K.osd(13)).foregroundStyle(K.red) }
                }
                Spacer(minLength: 8)
                trailing()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            Rectangle().frame(height: 3)
        }
    }
}

extension KSheetHeader where Leading == EmptyView {
    init(title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.init(title: title, subtitle: subtitle, leading: { EmptyView() }, trailing: trailing)
    }
}

extension View {
    /// Paper sheet: square corners, grain, ink text.
    func kSheet() -> some View {
        kSurface(.paper)
            .presentationBackground(K.paper)
            .presentationCornerRadius(0)
    }

    /// A boxed panel on the current surface with corner ticks.
    func kPanel(padding: CGFloat = 14) -> some View {
        modifier(KPanelModifier(padding: padding))
    }
}

private struct KPanelModifier: ViewModifier {
    let padding: CGFloat
    @Environment(\.kSurface) private var surface

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(surface == .paper ? K.paperShade.opacity(0.5) : K.inkRaised)
            .kFrame(K.red, tick: 8, hairline: surface.hairline)
    }
}

/// Search field in OSD style (replaces `.searchable`).
struct KSearchField: View {
    @Binding var text: String
    var prompt = "SEARCH"
    @Environment(\.kSurface) private var surface

    var body: some View {
        HStack(spacing: 8) {
            PixelIcon("search", size: 16).foregroundStyle(K.red)
            TextField("", text: $text, prompt: Text(prompt).foregroundStyle(surface.secondary))
                .font(K.osd(16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: { PixelIcon("close", size: 16) }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .overlay(Rectangle().stroke(surface.foreground, lineWidth: 2))
    }
}
