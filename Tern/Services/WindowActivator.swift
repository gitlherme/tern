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

    /// Aperta o botão de fechar da janela, como um clique no vermelho: se houver
    /// alterações não salvas, o próprio app pergunta.
    func close(_ window: WindowInfo) {
        guard let axWindow = axWindow(for: window),
              let button = AccessibilityWindows.child(axWindow, kAXCloseButtonAttribute as String) else { return }
        AXUIElementPerformAction(button, kAXPressAction as CFString)
    }

    func minimize(_ window: WindowInfo) {
        guard let axWindow = axWindow(for: window) else { return }
        AXUIElementSetAttributeValue(axWindow, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
    }

    /// Pede para o app encerrar normalmente; documentos não salvos ficam a cargo dele.
    func quitApp(of window: WindowInfo) {
        NSRunningApplication(processIdentifier: window.ownerPID)?.terminate()
    }

    /// Só a janela exata: pelo id, ou por um título que só ela tem. O `findAXWindow` cai
    /// para a primeira janela do app quando não acha, o que serve para trazer à frente,
    /// mas fecharia a janela errada.
    private func axWindow(for window: WindowInfo) -> AXUIElement? {
        let axApp = AXUIElementCreateApplication(window.ownerPID)
        AXUIElementSetMessagingTimeout(axApp, 1.0)
        let axWindows = AccessibilityWindows.copy(axApp, kAXWindowsAttribute as String) as? [AXUIElement] ?? []
        if let exact = axWindows.first(where: { AccessibilityWindows.windowID($0) == window.windowID }) {
            return exact
        }
        let title = window.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        let titled = axWindows.filter { AccessibilityWindows.title($0) == title }
        return titled.count == 1 ? titled[0] : nil
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
