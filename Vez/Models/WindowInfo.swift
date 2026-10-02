import AppKit
import CoreGraphics
import UniformTypeIdentifiers

struct WindowInfo: Identifiable {
    var id: CGWindowID { windowID }

    let windowID: CGWindowID
    let ownerPID: pid_t
    let bundleID: String
    let appName: String
    let title: String
    let bounds: CGRect
    let isOnscreen: Bool
    let isMinimized: Bool

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Janela sem título" : trimmed
    }

    var icon: NSImage {
        AppIcon.image(bundleID: bundleID, pid: ownerPID)
    }
}

enum AppIcon {
    static func image(bundleID: String, pid: pid_t) -> NSImage {
        if let icon = NSRunningApplication(processIdentifier: pid)?.icon {
            return icon
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: .application)
    }
}

struct RunningAppInfo: Identifiable {
    var id: String { bundleID }
    let bundleID: String
    let name: String
    let icon: NSImage
}
