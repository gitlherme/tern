import AppKit
import CoreGraphics
import ScreenCaptureKit

enum ScreenCapturePermission {
    static var isTrusted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    static var appBundleURL: URL {
        Bundle.main.bundleURL
    }

    static var userApplicationsCopyURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
            .appendingPathComponent("Tern.app")
    }

    /// Pedido vindo dos Ajustes: o macOS 15+ quase nunca cria a linha sozinho
    /// para app accessory assinado localmente. Mantém o Tern no Dock, registra
    /// no Launch Services, abre a lista e o Finder no .app certo para o +.
    @MainActor
    static func request(completion: (() -> Void)? = nil) {
        presentAsRegularApp()
        registerWithLaunchServices()
        _ = CGRequestScreenCaptureAccess()
        triggerCaptureForTCC()

        Task { @MainActor in
            await requestShareableContent()
            if !isTrusted {
                openSystemSettings()
                revealInFinder()
                showAddAppAlert()
            }
            completion?()
        }
    }

    /// Primeiro uso do seletor: tenta o diálogo sem abrir o Finder.
    @MainActor
    static func nudgePrompt() {
        presentAsRegularApp()
        registerWithLaunchServices()
        _ = CGRequestScreenCaptureAccess()
        triggerCaptureForTCC()
        Task { @MainActor in
            await requestShareableContent()
        }
    }

    @MainActor
    static func revealInFinder() {
        registerWithLaunchServices()
        let url = publishToUserApplications()
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    /// Cópia em ~/Applications para o + dos Ajustes achar um .app fora do DerivedData.
    /// O cdhash é o mesmo do processo que está rodando, então a permissão vale nos dois.
    @discardableResult
    static func publishToUserApplications() -> URL {
        let dest = userApplicationsCopyURL
        let source = appBundleURL.standardizedFileURL
        if source == dest.standardizedFileURL {
            return dest
        }
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: source, to: dest)
            registerURL(dest)
            return dest
        } catch {
            return source
        }
    }

    @MainActor
    private static func presentAsRegularApp() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Restaura o modo só-barra depois que a permissão existir (ou no próximo launch).
    @MainActor
    static func restoreAccessoryIfTrusted() {
        guard isTrusted else { return }
        if NSApp.activationPolicy() != .accessory {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    static func registerWithLaunchServices() {
        registerURL(appBundleURL)
    }

    private static func registerURL(_ url: URL) {
        let lsregister = URL(fileURLWithPath: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister")
        guard FileManager.default.isExecutableFile(atPath: lsregister.path) else { return }
        let proc = Process()
        proc.executableURL = lsregister
        proc.arguments = ["-f", url.path]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
        } catch {
            return
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

    @MainActor
    private static func showAddAppAlert() {
        let alert = NSAlert()
        alert.messageText = "O Tern não entra sozinho nessa lista"
        alert.informativeText = """
        Neste macOS a lista Screen & System Audio Recording só mostra apps que já pediram a permissão — e o Tern rodando pelo Xcode (assinado localmente) quase nunca aparece sozinho.

        1. Clique no + embaixo da lista.
        2. Escolha o Tern.app que está selecionado no Finder (cópia em Aplicativos da sua pasta de usuário) — ou arraste-o para a lista.
        3. Ligue o interruptor.
        4. No Tern, barra de menus → Sair, depois ⌘R no Xcode.

        Caminho:
        \(publishToUserApplications().path)
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Mostrar Tern.app")
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            revealInFinder()
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
