import ApplicationServices
import AppKit

enum AXWindow {
    static func copy(_ element: AXUIElement, _ attribute: String) -> AnyObject? {
        var raw: AnyObject?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &raw)
        return error == .success ? raw : nil
    }

    static func stringValue(_ element: AXUIElement, _ attribute: String) -> String {
        copy(element, attribute) as? String ?? ""
    }

    static func boolValue(_ element: AXUIElement, _ attribute: String) -> Bool {
        if let flag = copy(element, attribute) as? Bool { return flag }
        if let number = copy(element, attribute) as? NSNumber { return number.boolValue }
        return false
    }

    static func windows(for pid: pid_t) -> [AXUIElement] {
        let app = AXUIElementCreateApplication(pid)
        return copy(app, kAXWindowsAttribute as String) as? [AXUIElement] ?? []
    }

    static func windowID(_ element: AXUIElement) -> CGWindowID? {
        let raw = copy(element, "AXWindowNumber")
        if let number = raw as? NSNumber {
            return CGWindowID(truncating: number)
        }
        if let value = raw as? Int {
            return CGWindowID(value)
        }
        return nil
    }

    static func title(_ element: AXUIElement) -> String {
        stringValue(element, kAXTitleAttribute as String)
    }

    static func isMinimized(_ element: AXUIElement) -> Bool {
        boolValue(element, kAXMinimizedAttribute as String)
    }

    static func isSwitcherWindow(_ element: AXUIElement) -> Bool {
        let role = stringValue(element, kAXRoleAttribute as String)
        guard role == "AXWindow" || role == "AXSheet" else { return false }
        switch stringValue(element, kAXSubroleAttribute as String) {
        case "AXStandardWindow", "AXDialog", "AXSystemDialog", "":
            return true
        default:
            return false
        }
    }
}
