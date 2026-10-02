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
        NSWorkspace.shared.activateFileViewerSelecting([appURLForSettingsList()])
    }

    /// Build do Xcode: o + dos Ajustes não navega até o DerivedData.
    static var isRunningFromBuildFolder: Bool {
        let path = appBundleURL.standardizedFileURL.path
        return path.contains("/DerivedData/") || path.contains("/Build/Products/")
    }

    /// O .app que a pessoa deve escolher no + dos Ajustes. Instalado, é o próprio
    /// bundle; rodando pelo Xcode, uma cópia em ~/Applications.
    static func appURLForSettingsList() -> URL {
        isRunningFromBuildFolder ? publishToUserApplications() : appBundleURL
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
        alert.messageText = String(localized: "O Tern não entra sozinho nessa lista")
        let steps = String(localized: """
        O macOS nem sempre adiciona o Tern sozinho à lista de Gravação da Tela.

        1. Clique no + embaixo da lista.
        2. Escolha o Tern, que já está selecionado no Finder — ou arraste-o para a lista.
        3. Ligue a chave.
        4. Saia do Tern pela barra de menus e abra de novo.

        Caminho:
        """)
        alert.informativeText = steps + "\n" + appURLForSettingsList().path
        alert.alertStyle = .informational
        alert.addButton(withTitle: String(localized: "Mostrar Tern.app"))
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
