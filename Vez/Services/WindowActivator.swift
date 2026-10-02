import ApplicationServices
import AppKit

struct WindowActivator {
    func activate(_ window: WindowInfo) {
        let axApp = AXUIElementCreateApplication(window.ownerPID)
        if let axWindow = findAXWindow(in: axApp, matching: window) {
            AXUIElementSetAttributeValue(axWindow, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            AXUIElementSetAttributeValue(axWindow, kAXMainAttribute as CFString, kCFBooleanTrue)
            AXUIElementSetAttributeValue(axWindow, kAXFocusedAttribute as CFString, kCFBooleanTrue)
            AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
            AXUIElementSetAttributeValue(axApp, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
        }

        guard let app = NSRunningApplication(processIdentifier: window.ownerPID) else { return }
        if #available(macOS 14.0, *) {
            app.activate()
        } else {
            app.activate(options: [.activateIgnoringOtherApps])
        }
    }

    private func findAXWindow(in axApp: AXUIElement, matching window: WindowInfo) -> AXUIElement? {
        let axWindows = AccessibilityWindows.copy(axApp, kAXWindowsAttribute as String) as? [AXUIElement] ?? []

        for axWindow in axWindows {
            if AccessibilityWindows.windowID(axWindow) == window.windowID {
                return axWindow
            }
        }

        let targetTitle = window.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !targetTitle.isEmpty {
            for axWindow in axWindows where AccessibilityWindows.title(axWindow) == targetTitle {
                return axWindow
            }
        }

        return axWindows.first
    }
}
