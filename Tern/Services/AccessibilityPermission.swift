import ApplicationServices
import AppKit
import Foundation

enum AccessibilityPermission {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func promptIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private static let didPromptKey = "TernDidPromptAccessibility"

    /// Uma coisa por vez: na primeira vez, só o diálogo do macOS (que também põe o Tern
    /// na lista e tem o botão para os Ajustes); depois, só o painel dos Ajustes.
    static func request() {
        if UserDefaults.standard.bool(forKey: didPromptKey) {
            openSystemSettings()
        } else {
            UserDefaults.standard.set(true, forKey: didPromptKey)
            promptIfNeeded()
        }
    }

    static func openSystemSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ]
        for string in candidates {
            if let url = URL(string: string), NSWorkspace.shared.open(url) {
                return
            }
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
    }

    static func openInputMonitoringSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        ]
        for string in candidates {
            if let url = URL(string: string), NSWorkspace.shared.open(url) {
                return
            }
        }
        openSystemSettings()
    }
}
