import Foundation
import ServiceManagement

/// Item de início via `SMAppService` (macOS 13+). O estado mora no macOS, não em
/// UserDefaults: a pessoa pode desligar em Ajustes do Sistema e o Tern precisa refletir.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// O macOS registrou o item, mas espera aprovação em Itens de Início.
    static var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    static func set(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Tern: falha ao mudar o item de início (%@)", error.localizedDescription)
        }
    }

    static func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
