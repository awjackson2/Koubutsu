import SwiftUI

/// Layout helpers shared by the sheets (settings, word bank, review, recent lines, word card).
///
/// A sheet has its own width: on an iPad it is narrower than the window, on an iPhone it is the whole screen. So
/// compact decisions inside a sheet come from the sheet's measured width (and Dynamic Type), not from the
/// window's layout class or the size class.
enum SheetLayout {
    /// Below this width a sheet stacks its rows. iPad sheets are wider; iPhone portrait (375–440 pt) is narrower.
    static let narrowWidth: CGFloat = 500

    static func isNarrow(width: CGFloat) -> Bool { width > 0 && width < narrowWidth }
}

extension View {
    /// Keeps `narrow` in step with this view's width (see `SheetLayout.narrowWidth`).
    func trackingNarrowWidth(_ narrow: Binding<Bool>) -> some View {
        onGeometryChange(for: Bool.self) { proxy in
            SheetLayout.isNarrow(width: proxy.size.width)
        } action: { value in
            narrow.wrappedValue = value
        }
    }

    /// Grows the label of a `KButtonStyle` button so the whole button is at least 44×44 pt. The style pads a
    /// compact label by 10×6 pt and a regular one by 14×9 pt. The frame sits inside the label because a frame or
    /// content shape outside a `Button` does not enlarge its hit area.
    func kButtonTarget(compact: Bool = true) -> some View {
        frame(minWidth: compact ? 24 : 16, minHeight: compact ? 32 : 26)
    }

    /// A `KSectionHeader` read by VoiceOver as one heading ("Meanings, 02").
    func kHeading() -> some View {
        accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
    }

    /// Makes a `KSlider` usable with VoiceOver: one adjustable element (swipe up/down) with a label and value.
    func kAdjustable(_ label: String, value: String, binding: Binding<Double>, range: ClosedRange<Double>,
                     step: Double) -> some View {
        accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityAdjustableAction { direction in
                let current = binding.wrappedValue
                let next: Double
                switch direction {
                case .increment: next = current + step
                case .decrement: next = current - step
                default: return
                }
                let stepped = (next / step).rounded() * step
                binding.wrappedValue = min(range.upperBound, max(range.lowerBound, stepped))
            }
    }
}

/// `KSegmented`'s boxed options with 44 pt segments. Falls back to a vertical list when the options do not fit the
/// width or at the accessibility text sizes, so long titles never truncate.
struct KChoicePicker<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, title: String)]
    @Environment(\.kSurface) private var surface
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                column
            } else {
                ViewThatFits(in: .horizontal) {
                    row
                    column
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var row: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                segment(option, stacked: false)
                if index < options.count - 1 { Rectangle().fill(surface.foreground).frame(width: 2) }
            }
        }
        .overlay(Rectangle().stroke(surface.foreground, lineWidth: 2))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var column: some View {
        VStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                segment(option, stacked: true)
                if index < options.count - 1 { Rectangle().fill(surface.foreground).frame(height: 2) }
            }
        }
        .overlay(Rectangle().stroke(surface.foreground, lineWidth: 2))
        .fixedSize(horizontal: false, vertical: true)
    }

    private func segment(_ option: (value: Value, title: String), stacked: Bool) -> some View {
        let selected = selection == option.value
        return Button {
            withAnimation(K.snap) { selection = option.value }
        } label: {
            Text(option.title)
                .font(K.osd(14))
                .textCase(.uppercase)
                .lineLimit(stacked ? nil : 1)
                .multilineTextAlignment(stacked ? .leading : .center)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: stacked ? .leading : .center)
                .foregroundStyle(selected ? K.paper : surface.foreground)
                .background(selected ? K.red : Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
