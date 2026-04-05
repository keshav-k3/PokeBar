//
//  SleepSheetFrameDecoder.swift
//  PokeBar
//
//  Slices horizontal sleep sprite sheets into frames (square strip or two half-width frames).
//

import AppKit

enum SleepSheetFrameDecoder {
    /// Base pacing for sleep strips (PNG has no embedded timing). ~0.5s+ per frame reads closer to
    /// web/canvas previews than the old 0.1s “flipbook” default.
    private static let sleepHoldShort: TimeInterval = 0.48
    private static let sleepHoldLong: TimeInterval = 0.62

    /// Per-frame display time before advancing (seconds). Two-frame sheets get a slightly asymmetric
    /// pattern so the loop feels like a slow breathe instead of a metronome.
    private static func delays(forFrameCount count: Int) -> [TimeInterval] {
        switch count {
        case 2:
            return [sleepHoldLong, sleepHoldShort]
        case 1:
            return [sleepHoldLong]
        default:
            return Array(repeating: (sleepHoldLong + sleepHoldShort) / 2, count: count)
        }
    }

    /// Returns cropped frame images left-to-right and a delay per frame.
    static func decode(url: URL) -> (frames: [NSImage], delays: [TimeInterval])? {
        guard let image = NSImage(contentsOf: url),
              let rep = bitmapRepresentation(from: image) else { return nil }

        let w = rep.pixelsWide
        let h = rep.pixelsHigh
        guard w > 0, h > 0, let fullCG = rep.cgImage else { return nil }

        let layout = inferLayout(width: w, height: h)
        guard layout.frameCount >= 1, layout.tileW > 0, layout.tileH > 0 else { return nil }

        var frames: [NSImage] = []
        frames.reserveCapacity(layout.frameCount)

        for i in 0..<layout.frameCount {
            let ox = CGFloat(i * layout.tileW)
            let rect = CGRect(x: ox, y: 0, width: CGFloat(layout.tileW), height: CGFloat(layout.tileH))
            guard let cropped = fullCG.cropping(to: rect) else { continue }
            let frame = NSImage(cgImage: cropped, size: NSSize(width: layout.tileW, height: layout.tileH))
            frames.append(frame)
        }

        guard !frames.isEmpty else { return nil }
        let delays = Self.delays(forFrameCount: frames.count)
        return (frames, delays)
    }

    /// Square strip: W = N×H → N frames of H×H. Else: two frames of (W/2)×H.
    private static func inferLayout(width w: Int, height h: Int) -> (tileW: Int, tileH: Int, frameCount: Int) {
        if h > 0, w % h == 0, w / h >= 2 {
            let n = w / h
            return (h, h, n)
        }
        if w % 2 == 0 {
            return (w / 2, h, 2)
        }
        return (0, 0, 0)
    }

    private static func bitmapRepresentation(from image: NSImage) -> NSBitmapImageRep? {
        if let bmp = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first {
            return bmp
        }
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let w = cg.width
        let h = cg.height
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: w,
            pixelsHigh: h,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSImage(cgImage: cg, size: NSSize(width: w, height: h)).draw(
            in: NSRect(x: 0, y: 0, width: w, height: h),
            from: NSRect(x: 0, y: 0, width: w, height: h),
            operation: .copy,
            fraction: 1.0
        )
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }
}
