import AVFoundation
import SwiftUI
import UIKit

/// Hosts the renderer's display layer. The layer is owned by `SampleBufferRenderer`, not the view, so
/// view re-creation never interrupts the video path.
struct VideoDisplayView: UIViewRepresentable {
    let renderer: SampleBufferRenderer

    func makeUIView(context: Context) -> HostView {
        let view = HostView()
        view.backgroundColor = .black
        view.displayLayer = renderer.layer
        return view
    }

    func updateUIView(_ view: HostView, context: Context) {
        view.displayLayer = renderer.layer
    }

    final class HostView: UIView {
        var displayLayer: CALayer? {
            didSet {
                guard displayLayer !== oldValue else { return }
                oldValue?.removeFromSuperlayer()
                if let displayLayer { layer.addSublayer(displayLayer) }
                setNeedsLayout()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            displayLayer?.frame = bounds
            CATransaction.commit()
        }
    }
}
