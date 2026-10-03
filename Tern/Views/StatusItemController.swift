import AppKit
import Sparkle
import Combine

@MainActor
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
        let image = NSImage(named: "MenuBarIcon")
        image?.isTemplate = true
        image?.accessibilityDescription = "Tern"
        button.image = image
        button.toolTip = String(localized: "Tern — seletor de janelas")
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let open = NSMenuItem(
            title: String(localized: "Abrir seletor (\(model.hotkey.displayString))"),
            action: #selector(openSwitcher),
            keyEquivalent: ""
        )
        open.target = self
        menu.addItem(open)

        let settings = NSMenuItem(title: String(localized: "Ajustes…"), action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        if !model.isTrusted {
            menu.addItem(.separator())
            let permission = NSMenuItem(
                title: String(localized: "Conceder Acessibilidade…"),
                action: #selector(openAccessibility),
                keyEquivalent: ""
            )
            permission.target = self
            menu.addItem(permission)
        }

        menu.addItem(.separator())
        let updates = NSMenuItem(
            title: String(localized: "Procurar atualizações…"),
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        updates.target = UpdateService.shared.controller
        menu.addItem(updates)
        let quit = NSMenuItem(title: String(localized: "Sair do Tern"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
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
        model.openWelcome()
    }
}
