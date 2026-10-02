import Foundation
import Sparkle

/// Atualizações pelo Sparkle. O feed (SUFeedURL) e a chave pública (SUPublicEDKey)
/// ficam no Info.plist; as versões são assinadas com a chave EdDSA da conta `tern`.
@MainActor
final class UpdateService: ObservableObject {
    static let shared = UpdateService()

    let controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    @Published var automaticallyChecks: Bool {
        didSet { controller.updater.automaticallyChecksForUpdates = automaticallyChecks }
    }

    private init() {
        automaticallyChecks = controller.updater.automaticallyChecksForUpdates
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
