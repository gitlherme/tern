import AppKit
import Combine

final class StatusItemController: NSObject {
    private let model: AppModel
    private let item: NSStatusItem
    private var cancellables = Set<AnyCancellable>()

    init(model: AppModel) {
        self.model = model
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureButton()
        rebuildMenu()
        model.$isTrusted
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
        model.$hotkey
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
    }

    private func configureButton() {
        guard let button = item.button else { return }
        let image = NSImage(systemSymbolName: "rectangle.on.rectangle", accessibilityDescription: "Vez")?.copy() as? NSImage
        image?.isTemplate = true
        button.image = image
        button.toolTip = "Vez — seletor de janelas"
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let open = NSMenuItem(
            title: "Abrir seletor (\(model.hotkey.displayString))",
            action: #selector(openSwitcher),
            keyEquivalent: ""
        )
        open.target = self
        menu.addItem(open)

        let settings = NSMenuItem(title: "Ajustes…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        if !model.isTrusted {
            menu.addItem(.separator())
            let permission = NSMenuItem(
                title: "Conceder Acessibilidade…",
                action: #selector(openAccessibility),
                keyEquivalent: ""
            )
            permission.target = self
            menu.addItem(permission)
        }

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Sair do Vez", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        item.menu = menu
    }

    @objc private func openSwitcher() {
        model.openSwitcherFromMenu()
    }

    @objc private func openSettings() {
        model.openSettings()
    }

    @objc private func openAccessibility() {
        AccessibilityPermission.promptIfNeeded()
        AccessibilityPermission.openSystemSettings()
    }
}
