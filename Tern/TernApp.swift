import SwiftUI

/// Página de apoio, aberta pelo menu da barra e pela linha de versão nos ajustes.
enum SupportLink {
    static let url = URL(string: "https://ko-fi.com/gitlherme")!
}

@main
struct TernApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(AppModel.shared)
        }
    }
}
