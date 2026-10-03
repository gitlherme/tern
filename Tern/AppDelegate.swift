import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppModel.shared.start()
        _ = UpdateService.shared
        statusItem = StatusItemController(model: AppModel.shared)
        if AppModel.shared.shouldShowWelcome {
            AppModel.shared.openWelcome()
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            URLCommands.handle(url)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        AppModel.shared.openSettings()
        return false
    }
}
