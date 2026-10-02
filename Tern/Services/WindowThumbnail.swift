import AppKit
import CoreGraphics

enum WindowThumbnail {
    static func capture(windowID: CGWindowID) -> NSImage? {
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
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
