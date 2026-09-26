/// A capture format offered by a UVC device, reduced to what selection needs.
public struct CaptureFormatCandidate: Sendable, Hashable {
    /// Position in the device's format list.
    public var index: Int
    public var size: PixelSize
    public var minFrameRate: Double
    public var maxFrameRate: Double
    /// FourCC media subtype ('420v', '420f', 'yuvs', '2vuy', 'dmb1' for MJPEG, …).
    public var pixelFormat: UInt32

    public init(index: Int, size: PixelSize, minFrameRate: Double, maxFrameRate: Double, pixelFormat: UInt32) {
        self.index = index
        self.size = size
        self.minFrameRate = minFrameRate
        self.maxFrameRate = maxFrameRate
        self.pixelFormat = pixelFormat
    }
}

public struct CaptureFormatSelection: Sendable, Hashable {
    public var candidate: CaptureFormatCandidate
    /// Frame rate to request (clamped into the candidate's supported range).
    public var frameRate: Double
    public var meetsTarget: Bool
}

/// Chooses the capture format closest to the target (default 1920×1080 @ 60 FPS), independent of any
/// specific capture device. Priorities, in order:
/// 1. reaches the target frame rate;
/// 2. exact target resolution, else the closest resolution (smaller preferred over larger than target);
/// 3. uncompressed 4:2:0 bi-planar (what the display layer and Vision consume without conversion);
/// 4. higher maximum frame rate.
public struct CaptureFormatSelector: Sendable {
    public var targetSize: PixelSize
    public var targetFrameRate: Double
    /// Frame rates within this tolerance count as meeting the target (59.94 ≈ 60).
    public var frameRateTolerance: Double = 0.5

    public init(targetSize: PixelSize = PixelSize(width: 1920, height: 1080), targetFrameRate: Double = 60) {
        self.targetSize = targetSize
        self.targetFrameRate = targetFrameRate
    }

    public static func fourCC(_ string: String) -> UInt32 {
        string.utf8.prefix(4).reduce(0) { ($0 << 8) | UInt32($1) }
    }

    static let pixelFormatRank: [UInt32: Int] = [
        fourCC("420v"): 0, fourCC("420f"): 0,
        fourCC("x420"): 1, fourCC("xf20"): 1,
        fourCC("yuvs"): 2, fourCC("2vuy"): 2,
        fourCC("BGRA"): 3,
        fourCC("dmb1"): 5, fourCC("jpeg"): 5,
    ]

    public func select(from candidates: [CaptureFormatCandidate]) -> CaptureFormatSelection? {
        guard !candidates.isEmpty else { return nil }
        let targetArea = Double(targetSize.width * targetSize.height)
        func key(_ c: CaptureFormatCandidate) -> (Int, Int, Double, Int, Double) {
            let meets = c.maxFrameRate + frameRateTolerance >= targetFrameRate ? 0 : 1
            let exact = c.size == targetSize ? 0 : 1
            let area = Double(c.size.width * c.size.height)
            // Larger-than-target costs double: more bandwidth and scaling for no OCR benefit at 1080p.
            let distance = area >= targetArea ? (area - targetArea) / targetArea * 2 : (targetArea - area) / targetArea
            let format = Self.pixelFormatRank[c.pixelFormat] ?? 4
            return (meets, exact, distance, format, -c.maxFrameRate)
        }
        let best = candidates.min { key($0) < key($1) }!
        let rate = min(max(targetFrameRate, best.minFrameRate), best.maxFrameRate)
        return CaptureFormatSelection(candidate: best, frameRate: rate,
                                      meetsTarget: best.size == targetSize
                                          && best.maxFrameRate + frameRateTolerance >= targetFrameRate)
    }
}
