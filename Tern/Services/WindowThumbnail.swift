import AppKit
import CoreGraphics

enum WindowThumbnail {
    static func capture(windowID: CGWindowID) -> NSImage? {
        captureImage(windowID: windowID).map(image(from:))
    }

    /// Captura sem tocar no AppKit, para rodar fora da main thread.
    static func captureImage(windowID: CGWindowID) -> CGImage? {
        guard windowID != kCGNullWindowID else { return nil }
        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else {
            return nil
        }
        if cgImage.width < 16 || cgImage.height < 16 {
            return nil
        }
        return cgImage
    }

    static func image(from cgImage: CGImage) -> NSImage {
        NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
