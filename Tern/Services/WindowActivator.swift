import ApplicationServices
import AppKit

struct WindowActivator {
    func activate(_ window: WindowInfo) {
        let axApp = AXUIElementCreateApplication(window.ownerPID)
        AXUIElementSetMessagingTimeout(axApp, 1.0)
        let axWindow = findAXWindow(in: axApp, matching: window)

        restoreAndRaise(axApp: axApp, axWindow: axWindow)

        guard let app = NSRunningApplication(processIdentifier: window.ownerPID) else { return }
        if app.isHidden {
            app.unhide()
        }
        app.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])

        restoreAndRaise(axApp: axApp, axWindow: axWindow)
    }

    private func restoreAndRaise(axApp: AXUIElement, axWindow: AXUIElement?) {
        guard let axWindow else {
            AXUIElementSetAttributeValue(axApp, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
            return
        }

        AXUIElementSetAttributeValue(axWindow, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        AXUIElementSetAttributeValue(axWindow, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(axWindow, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
        AXUIElementSetAttributeValue(axApp, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
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
            let titled = axWindows.filter { AccessibilityWindows.title($0) == targetTitle }
            if window.isMinimized, let minimized = titled.first(where: { AccessibilityWindows.isMinimized($0) }) {
                return minimized
            }
            if let first = titled.first {
                return first
            }
        }

        if window.isMinimized {
            return axWindows.first(where: { AccessibilityWindows.isMinimized($0) }) ?? axWindows.first
        }
        return axWindows.first
    }
}
