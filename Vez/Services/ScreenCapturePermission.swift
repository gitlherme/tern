import AppKit
import CoreGraphics
import ScreenCaptureKit

enum ScreenCapturePermission {
    static var isTrusted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Pedido vindo dos Ajustes: coloca o Vez na frente, dispara o diálogo do sistema
    /// e abre a lista de Gravação da tela se o macOS não mostrar nada.
    @MainActor
    static func request(completion: (() -> Void)? = nil) {
        presentPrompt(openSettingsIfDenied: true, completion: completion)
    }

    /// Primeiro uso do seletor: tenta o diálogo sem roubar a tela para os Ajustes.
    @MainActor
    static func nudgePrompt() {
        NSApp.activate(ignoringOtherApps: true)
        _ = CGRequestScreenCaptureAccess()
        triggerCaptureForTCC()
        Task { @MainActor in
            await requestShareableContent()
        }
    }

    @MainActor
    private static func presentPrompt(openSettingsIfDenied: Bool, completion: (() -> Void)?) {
        let previousPolicy = NSApp.activationPolicy()
        if previousPolicy != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)

        _ = CGRequestScreenCaptureAccess()
        triggerCaptureForTCC()

        Task { @MainActor in
            await requestShareableContent()
            if openSettingsIfDenied && !isTrusted {
                openSystemSettings()
            }
            if NSApp.activationPolicy() != previousPolicy {
                NSApp.setActivationPolicy(previousPolicy)
            }
            completion?()
        }
    }

    /// Uma captura real é o que cria a linha de TCC em versões recentes do macOS;
    /// `CGRequestScreenCaptureAccess` sozinho costuma não fazer nada em app accessory.
    private static func triggerCaptureForTCC() {
        _ = CGWindowListCreateImage(
            CGRect(x: 0, y: 0, width: 1, height: 1),
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
    }

    @MainActor
    private static func requestShareableContent() async {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            // Diálogo recusado, ou a permissão ainda não vale neste processo.
        }
    }

    static func openSystemSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenRecording",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"
        ]
        for string in candidates {
            if let url = URL(string: string), NSWorkspace.shared.open(url) {
                return
            }
        }
        AccessibilityPermission.openSystemSettings()
    }
}
