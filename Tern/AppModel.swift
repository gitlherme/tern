import AppKit
import Carbon
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var exclusions: PersistedExclusions
    @Published var hotkey: HotkeyChord
    @Published var isTrusted = false
    @Published var canCaptureScreen = false
    @Published var isSwitcherVisible = false
    /// Janelas visíveis no seletor: todas, ou só as que combinam com a busca.
    @Published var windows: [WindowInfo] = []
    /// Texto digitado com o seletor aberto (#10).
    @Published var filterText = ""
    @Published var thumbnails: [CGWindowID: NSImage] = [:]
    @Published var selectedIndex = 0
    @Published var confirmOnModifierRelease = false
    @Published var runningApps: [RunningAppInfo] = []
    @Published var isInterceptingKeys = false
    @Published var launchAtLogin = LaunchAtLogin.isEnabled
    @Published var launchAtLoginNeedsApproval = LaunchAtLogin.needsApproval

    let store = ExclusionStore()
    let enumerator = WindowEnumerator()
    let activator = WindowActivator()
    let hotkeys = HotkeyManager()
    let panel = SwitcherPanelController()
    let keyboardInterceptor = KeyboardInterceptor()

    private var recency = WindowRecency()
    /// Todas as janelas em ordem de recência, antes da busca.
    private var allWindows: [WindowInfo] = []
    private var pollTimer: Timer?
    private var settingsWindow: NSWindow?
    private var welcomeWindow: NSWindow?
    private var welcomeCloseObserver: NSObjectProtocol?
    private static let welcomeDoneKey = "TernWelcomeCompleted"
    private var consumeOpeningKey = false
    private var workspaceObserver: NSObjectProtocol?

    private init() {
        exclusions = store.load()
        hotkey = HotkeyDefaults.load()
    }

    func start() {
        isTrusted = AccessibilityPermission.isTrusted
        canCaptureScreen = ScreenCapturePermission.isTrusted
        refreshRunningApps()
        hotkeys.onPressed = { [weak self] reverse in
            Task { @MainActor in
                self?.handleHotkey(reverse: reverse)
            }
        }
        panel.attach(model: self)
        startKeyboardInterceptor()
        syncHotkeyRegistration()
        recency.recordCurrentFront(ignoringBundleID: Bundle.main.bundleIdentifier)
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.isSwitcherVisible else { return }
                self.recency.recordCurrentFront(ignoringBundleID: Bundle.main.bundleIdentifier)
            }
        }

        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let trusted = AccessibilityPermission.isTrusted
                let capture = ScreenCapturePermission.isTrusted
                if trusted != self.isTrusted {
                    self.isTrusted = trusted
                    if trusted && self.isSwitcherVisible {
                        self.refreshWindows()
                    }
                }
                if trusted, !self.keyboardInterceptor.isEnabled {
                    self.startKeyboardInterceptor()
                    self.syncHotkeyRegistration()
                }
                if capture != self.canCaptureScreen {
                    self.canCaptureScreen = capture
                    if capture && self.isSwitcherVisible {
                        self.refreshThumbnails()
                    } else if !capture {
                        self.thumbnails = [:]
                    }
                }
                ScreenCapturePermission.restoreAccessoryIfTrusted()
                self.refreshLaunchAtLogin()
                if !self.isSwitcherVisible {
                    self.recency.recordCurrentFront(ignoringBundleID: Bundle.main.bundleIdentifier)
                }
            }
        }
        if let pollTimer {
            RunLoop.main.add(pollTimer, forMode: .common)
        }
    }

    func setHotkey(_ chord: HotkeyChord) {
        hotkey = chord
        HotkeyDefaults.save(chord)
        syncHotkeyRegistration()
    }

    func handleHotkey(reverse: Bool) {
        if !isTrusted {
            // O seletor mostra o aviso com os botões; sem diálogo do macOS a cada toque.
            confirmOnModifierRelease = false
            isSwitcherVisible = true
            panel.show()
            return
        }

        if isSwitcherVisible {
            if reverse {
                selectPrevious()
            } else {
                selectNext()
            }
            return
        }

        filterText = ""
        refreshWindows()
        if reverse, windows.count > 1 {
            selectedIndex = windows.lastIndex(where: { !$0.isMinimized }) ?? (windows.count - 1)
        } else if windows.count > 1 {
            selectedIndex = 1
        } else {
            selectedIndex = 0
        }
        consumeOpeningKey = true
        confirmOnModifierRelease = hotkey.hasModifiers
        isSwitcherVisible = true
        panel.show()
        DispatchQueue.main.async { [weak self] in
            self?.consumeOpeningKey = false
        }
    }

    func openSwitcherFromMenu() {
        if !isTrusted {
            isSwitcherVisible = true
            confirmOnModifierRelease = false
            panel.show()
            return
        }
        filterText = ""
        refreshWindows()
        selectedIndex = 0
        confirmOnModifierRelease = false
        isSwitcherVisible = true
        panel.show()
    }

    func refreshWindows() {
        let raw = enumerator.enumerate(
            exclusions: exclusions,
            ignoringBundleID: Bundle.main.bundleIdentifier
        )
        if !isSwitcherVisible {
            recency.recordFrontmost(from: raw)
        }
        allWindows = recency.ordered(raw)
        applyFilter()
        refreshThumbnails()
    }

    /// Recalcula `windows` a partir de `allWindows` e da busca, mantendo a seleção válida.
    private func applyFilter() {
        windows = WindowFilter.apply(allWindows, query: filterText)
        if windows.isEmpty {
            selectedIndex = 0
        } else if selectedIndex >= windows.count {
            selectedIndex = windows.count - 1
        }
        if isSwitcherVisible {
            panel.updateFrameIfVisible()
        }
    }

    /// Ao digitar, o seletor deixa de confirmar quando o modificador é solto: ninguém
    /// digita segurando ⌥. A partir daí, ⏎ abre e esc fecha.
    func appendToFilter(_ text: String) {
        filterText += text
        confirmOnModifierRelease = false
        selectedIndex = 0
        applyFilter()
    }

    func deleteFromFilter() {
        guard !filterText.isEmpty else { return }
        filterText.removeLast()
        selectedIndex = 0
        applyFilter()
    }

    func clearFilter() {
        filterText = ""
        selectedIndex = allWindows.count > 1 ? 1 : 0
        applyFilter()
    }

    func refreshThumbnails() {
        let ids = Set(windows.map(\.windowID))
        thumbnails = thumbnails.filter { ids.contains($0.key) }
        guard canCaptureScreen else { return }
        for window in windows where thumbnails[window.windowID] == nil {
            if let image = WindowThumbnail.capture(windowID: window.windowID) {
                thumbnails[window.windowID] = image
            }
        }
    }

    func refreshRunningApps() {
        runningApps = enumerator.runningRegularApps(ignoringBundleID: Bundle.main.bundleIdentifier)
    }

    func selectNext() {
        guard !windows.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % windows.count
    }

    func selectPrevious() {
        guard !windows.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + windows.count) % windows.count
    }

    func select(_ index: Int) {
        guard windows.indices.contains(index) else { return }
        selectedIndex = index
    }

    func confirm() {
        guard isSwitcherVisible else { return }
        let target = windows.indices.contains(selectedIndex) ? windows[selectedIndex] : nil
        dismissSwitcher()
        if let target {
            recency.record(target)
            activator.activate(target)
        }
    }

    // MARK: Ações na janela selecionada (#12)

    func closeSelectedWindow() {
        guard let window = selectedWindow else { return }
        activator.close(window)
        refreshAfterAction(delays: [0.15, 0.6])
    }

    func minimizeSelectedWindow() {
        guard let window = selectedWindow else { return }
        activator.minimize(window)
        refreshAfterAction(delays: [0.3])
    }

    func quitSelectedApp() {
        guard let window = selectedWindow else { return }
        activator.quitApp(of: window)
        refreshAfterAction(delays: [0.6, 1.5])
    }

    private var selectedWindow: WindowInfo? {
        windows.indices.contains(selectedIndex) ? windows[selectedIndex] : nil
    }

    /// O app leva um instante para fechar ou minimizar; se ele abrir um "salvar alterações?",
    /// a janela continua na lista e a pessoa pode ir até ela.
    private func refreshAfterAction(delays: [TimeInterval]) {
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.isSwitcherVisible else { return }
                self.refreshWindows()
            }
        }
    }

    func dismissSwitcher() {
        isSwitcherVisible = false
        filterText = ""
        confirmOnModifierRelease = false
        consumeOpeningKey = false
        panel.hide()
        syncHotkeyRegistration()
    }

    func excludeSelectedApp() {
        guard windows.indices.contains(selectedIndex) else { return }
        let window = windows[selectedIndex]
        exclusions.addApp(bundleID: window.bundleID, name: window.appName)
        persistExclusions()
        refreshWindows()
    }

    func excludeSelectedWindow() {
        guard windows.indices.contains(selectedIndex) else { return }
        let window = windows[selectedIndex]
        exclusions.addWindow(bundleID: window.bundleID, title: window.title, appName: window.appName)
        persistExclusions()
        refreshWindows()
    }

    func excludeApp(bundleID: String, name: String) {
        exclusions.addApp(bundleID: bundleID, name: name)
        persistExclusions()
        refreshWindows()
    }

    func excludeWindow(_ window: WindowInfo) {
        exclusions.addWindow(bundleID: window.bundleID, title: window.title, appName: window.appName)
        persistExclusions()
        refreshWindows()
    }

    func removeAppExclusion(bundleID: String) {
        exclusions.removeApp(bundleID: bundleID)
        persistExclusions()
        refreshWindows()
    }

    func removeWindowExclusion(_ item: WindowExclusion) {
        exclusions.removeWindow(item)
        persistExclusions()
        refreshWindows()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        LaunchAtLogin.set(enabled)
        refreshLaunchAtLogin()
    }

    /// O estado pode mudar por fora, em Ajustes do Sistema › Itens de Início.
    func refreshLaunchAtLogin() {
        let enabled = LaunchAtLogin.isEnabled
        let needsApproval = LaunchAtLogin.needsApproval
        if enabled != launchAtLogin { launchAtLogin = enabled }
        if needsApproval != launchAtLoginNeedsApproval { launchAtLoginNeedsApproval = needsApproval }
    }

    /// Mostra as boas-vindas na primeira vez e sempre que faltar Acessibilidade.
    var shouldShowWelcome: Bool {
        !UserDefaults.standard.bool(forKey: Self.welcomeDoneKey) || !AccessibilityPermission.isTrusted
    }

    func openWelcome() {
        dismissSwitcher()
        NSApp.activate(ignoringOtherApps: true)

        if welcomeWindow == nil {
            let hosting = NSHostingView(rootView: WelcomeView().environmentObject(self))
            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: hosting.fittingSize),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = String(localized: "Boas-vindas ao Tern")
            window.contentView = hosting
            window.isReleasedWhenClosed = false
            window.center()
            welcomeCloseObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { _ in
                UserDefaults.standard.set(true, forKey: Self.welcomeDoneKey)
            }
            welcomeWindow = window
        }

        welcomeWindow?.makeKeyAndOrderFront(nil)
    }

    func closeWelcome() {
        welcomeWindow?.close()
    }

    func openSettings() {
        dismissSwitcher()
        refreshRunningApps()
        NSApp.activate(ignoringOtherApps: true)

        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 580, height: 520),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = String(localized: "Ajustes do Tern")
            window.contentView = NSHostingView(rootView: SettingsView().environmentObject(self))
            window.setFrameAutosaveName("TernSettings")
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 520, height: 420)
            window.center()
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func handleSwitcherEvent(_ event: NSEvent) -> Bool {
        guard isSwitcherVisible else { return false }

        if event.type == .flagsChanged {
            if confirmOnModifierRelease {
                let needed = hotkey.modifierFlags.intersection([.command, .option, .control, .shift])
                let current = event.modifierFlags.intersection([.command, .option, .control, .shift])
                if !current.isSuperset(of: needed) {
                    confirm()
                    return true
                }
            }
            return false
        }

        guard event.type == .keyDown else { return false }

        if UInt32(event.keyCode) == hotkey.keyCode {
            if consumeOpeningKey {
                consumeOpeningKey = false
                return true
            }
            let shiftPressed = event.modifierFlags.contains(.shift)
            let chordHasShift = hotkey.modifierFlags.contains(.shift)
            if shiftPressed == chordHasShift {
                selectNext()
            } else {
                selectPrevious()
            }
            return true
        }

        switch Int(event.keyCode) {
        case kVK_Escape:
            if filterText.isEmpty {
                dismissSwitcher()
            } else {
                clearFilter()
            }
            return true
        case kVK_Return, kVK_ANSI_KeypadEnter:
            confirm()
            return true
        case kVK_LeftArrow, kVK_UpArrow:
            selectPrevious()
            return true
        case kVK_RightArrow, kVK_DownArrow:
            selectNext()
            return true
        case kVK_Delete, kVK_ForwardDelete:
            // Com busca ativa, ⌫ edita a busca; esconder app só com a busca vazia,
            // para ninguém esconder um app sem querer enquanto digita.
            if !filterText.isEmpty {
                deleteFromFilter()
            } else if event.modifierFlags.contains(.option) {
                excludeSelectedWindow()
            } else {
                excludeSelectedApp()
            }
            return true
        default:
            break
        }

        if event.modifierFlags.contains(.command), !event.modifierFlags.contains(.control) {
            switch Int(event.keyCode) {
            case kVK_ANSI_W:
                closeSelectedWindow()
                return true
            case kVK_ANSI_M:
                minimizeSelectedWindow()
                return true
            case kVK_ANSI_Q:
                quitSelectedApp()
                return true
            default:
                break
            }
        }

        if let typed = Self.filterCharacters(from: event) {
            appendToFilter(typed)
            return true
        }
        return false
    }

    /// Caracteres que entram na busca: letras, números, espaço e pontuação, sem ⌘ ou ⌃.
    /// Usa as teclas sem modificadores, porque o ⌥ do atalho pode estar pressionado.
    private static func filterCharacters(from event: NSEvent) -> String? {
        if !event.modifierFlags.intersection([.command, .control]).isEmpty { return nil }
        guard let characters = event.charactersIgnoringModifiers, !characters.isEmpty else { return nil }
        let allowed = CharacterSet.alphanumerics.union(.punctuationCharacters).union(.symbols).union(CharacterSet(charactersIn: " "))
        guard characters.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        return characters
    }

    private func persistExclusions() {
        store.save(exclusions)
    }

    private func startKeyboardInterceptor() {
        keyboardInterceptor.start()
        isInterceptingKeys = keyboardInterceptor.isEnabled
    }

    private func syncHotkeyRegistration() {
        if keyboardInterceptor.isEnabled {
            hotkeys.unregister()
        } else {
            hotkeys.register(hotkey)
        }
    }

    /// NSEvent monitors run as nonisolated callbacks; AppKit delivers them on the main thread.
    nonisolated static func handleSwitcherEventAssumingMain(_ event: NSEvent) -> Bool {
        MainActor.assumeIsolated {
            shared.handleSwitcherEvent(event)
        }
    }

    nonisolated static func dismissSwitcherAssumingMain() {
        MainActor.assumeIsolated {
            shared.dismissSwitcher()
        }
    }
}
