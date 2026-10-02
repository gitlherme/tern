import AppKit
import CoreGraphics

enum ScreenCapturePermission {
    static var isTrusted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    @discardableResult
    static func request() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    static func openSystemSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ]
        for string in candidates {
            if let url = URL(string: string), NSWorkspace.shared.open(url) {
                return
            }
        }
        AccessibilityPermission.openSystemSettings()
    }
}
