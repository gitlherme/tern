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
    @Published var windows: [WindowInfo] = []
    @Published var thumbnails: [CGWindowID: NSImage] = [:]
    @Published var selectedIndex = 0
    @Published var confirmOnModifierRelease = false
    @Published var runningApps: [RunningAppInfo] = []

    let store = ExclusionStore()
    let enumerator = WindowEnumerator()
    let activator = WindowActivator()
    let hotkeys = HotkeyManager()
    let panel = SwitcherPanelController()

    private var pollTimer: Timer?
    private var settingsWindow: NSWindow?
    private var didAskScreenCapture = false

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
        hotkeys.register(hotkey)
        panel.attach(model: self)

        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let trusted = AccessibilityPermission.isTrusted
                let capture = ScreenCapturePermission.isTrusted
                if trusted != self.isTrusted {
                    self.isTrusted = trusted
                    if trusted && self.isSwitcherVisible {
                        self.refreshWindows()
                        self.selectedIndex = self.windows.count > 1 ? 1 : 0
                    }
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
            }
        }
        if let pollTimer {
            RunLoop.main.add(pollTimer, forMode: .common)
        }
    }

    func setHotkey(_ chord: HotkeyChord) {
        hotkey = chord
        HotkeyDefaults.save(chord)
        hotkeys.register(chord)
    }

    func handleHotkey(reverse: Bool) {
        if !isTrusted {
            confirmOnModifierRelease = false
            hotkeys.unregister()
            isSwitcherVisible = true
            panel.show()
            AccessibilityPermission.promptIfNeeded()
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

        refreshWindows()
        if windows.count > 1 {
            selectedIndex = reverse ? windows.count - 1 : 1
        } else {
            selectedIndex = 0
        }
        confirmOnModifierRelease = hotkey.hasModifiers
        hotkeys.unregister()
        isSwitcherVisible = true
        panel.show()
        askScreenCaptureIfNeeded()
    }

    func openSwitcherFromMenu() {
        if !isTrusted {
            isSwitcherVisible = true
            confirmOnModifierRelease = false
            hotkeys.unregister()
            panel.show()
            AccessibilityPermission.promptIfNeeded()
            return
        }
        refreshWindows()
        selectedIndex = 0
        confirmOnModifierRelease = false
        hotkeys.unregister()
        isSwitcherVisible = true
        panel.show()
        askScreenCaptureIfNeeded()
    }

    func refreshWindows() {
        windows = enumerator.enumerate(
            exclusions: exclusions,
            ignoringBundleID: Bundle.main.bundleIdentifier
        )
        if windows.isEmpty {
            selectedIndex = 0
        } else if selectedIndex >= windows.count {
            selectedIndex = windows.count - 1
        }
        if isSwitcherVisible {
            panel.updateFrameIfVisible()
        }
        refreshThumbnails()
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
            activator.activate(target)
        }
    }

    func dismissSwitcher() {
        isSwitcherVisible = false
        confirmOnModifierRelease = false
        panel.hide()
        hotkeys.register(hotkey)
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
            window.title = "Ajustes do Vez"
            window.contentView = NSHostingView(rootView: SettingsView().environmentObject(self))
            window.setFrameAutosaveName("VezSettings")
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
            dismissSwitcher()
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
            if event.modifierFlags.contains(.option) {
                excludeSelectedWindow()
            } else {
                excludeSelectedApp()
            }
            return true
        default:
            return false
        }
    }

    private func persistExclusions() {
        store.save(exclusions)
    }

    private func askScreenCaptureIfNeeded() {
        guard !canCaptureScreen, !didAskScreenCapture else { return }
        didAskScreenCapture = true
        ScreenCapturePermission.nudgePrompt()
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
