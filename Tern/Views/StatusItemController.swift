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
        model.$exclusions
            .map { [$0.activeModeID?.uuidString ?? ""] + $0.modes.map { "\($0.id)\($0.name)" } }
            .removeDuplicates()
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

        if !model.exclusions.modes.isEmpty {
            let modeItem = NSMenuItem(title: String(localized: "Modo"), action: nil, keyEquivalent: "")
            let modeMenu = NSMenu()
            let none = NSMenuItem(title: String(localized: "Nenhum"), action: #selector(selectMode(_:)), keyEquivalent: "")
            none.target = self
            none.state = model.exclusions.activeModeID == nil ? .on : .off
            modeMenu.addItem(none)
            modeMenu.addItem(.separator())
            for mode in model.exclusions.modes {
                let item = NSMenuItem(title: mode.name, action: #selector(selectMode(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = mode.id
                item.state = model.exclusions.activeModeID == mode.id ? .on : .off
                modeMenu.addItem(item)
            }
            modeItem.submenu = modeMenu
            menu.addItem(modeItem)
        }

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

        menu.addItem(.separator())
        let support = NSMenuItem(
            title: String(localized: "Apoiar o Tern…"),
            action: #selector(openSupport),
            keyEquivalent: ""
        )
        support.target = self
        menu.addItem(support)

        let quit = NSMenuItem(title: String(localized: "Sair do Tern"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        item.menu = menu
    }

    @objc private func openSwitcher() {
        model.openSwitcherFromMenu()
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        model.setActiveMode(sender.representedObject as? UUID)
    }

    @objc private func openSettings() {
        model.openSettings()
    }

    @objc private func openAccessibility() {
        model.openWelcome()
    }

    @objc private func openSupport() {
        NSWorkspace.shared.open(SupportLink.url)
    }
}
