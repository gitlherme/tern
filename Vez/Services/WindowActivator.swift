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
        var rawWindows: AnyObject?
        let error = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &rawWindows)
        guard error == .success, let axWindows = rawWindows as? [AXUIElement] else {
            return nil
        }

        for axWindow in axWindows {
            if windowNumber(of: axWindow) == window.windowID {
                return axWindow
            }
        }

        let targetTitle = window.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !targetTitle.isEmpty {
            for axWindow in axWindows where title(of: axWindow) == targetTitle {
                return axWindow
            }
        }

        return axWindows.first
    }

    private func windowNumber(of element: AXUIElement) -> CGWindowID? {
        var raw: AnyObject?
        let error = AXUIElementCopyAttributeValue(element, "AXWindowNumber" as CFString, &raw)
        guard error == .success else { return nil }
        if let number = raw as? NSNumber {
            return CGWindowID(truncating: number)
        }
        if let value = raw as? Int {
            return CGWindowID(value)
        }
        return nil
    }

    private func title(of element: AXUIElement) -> String {
        var raw: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &raw) == .success else {
            return ""
        }
        return (raw as? String) ?? ""
    }
}
