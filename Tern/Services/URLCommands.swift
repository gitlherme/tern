import AppKit
import Foundation

/// tern://open, tern://hide?app=<bundle id>[&for=1h|tomorrow], tern://unhide?app=<bundle id>,
/// tern://mode?name=<modo> (sem name desliga). Qualquer página pode abrir um link tern://,
/// então só há ações inofensivas: nada fecha janelas nem encerra apps.
enum URLCommands {
    @MainActor
    static func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "tern",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let query = Dictionary(
            (components.queryItems ?? []).compactMap { item in item.value.map { (item.name.lowercased(), $0) } },
            uniquingKeysWith: { first, _ in first }
        )
        let model = AppModel.shared

        switch (components.host ?? "").lowercased() {
        case "open":
            model.openSwitcherFromMenu()
        case "hide":
            guard let bundleID = validBundleID(query["app"]) else { return }
            let name = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first?.localizedName ?? bundleID
            model.excludeApp(bundleID: bundleID, name: name, duration: duration(query["for"]))
        case "unhide":
            guard let bundleID = validBundleID(query["app"]) else { return }
            model.removeAppExclusion(bundleID: bundleID)
        case "mode":
            let name = query["name"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let mode = model.exclusions.modes.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
            model.setActiveMode(mode?.id)
        default:
            NSLog("Tern: URL desconhecida %@", url.absoluteString)
        }
    }

    private static func validBundleID(_ raw: String?) -> String? {
        guard let raw, (1...255).contains(raw.count),
              raw.range(of: "^[A-Za-z0-9.-]+$", options: .regularExpression) != nil else { return nil }
        return raw
    }

    private static func duration(_ raw: String?) -> HideDuration {
        switch raw?.lowercased() {
        case "1h", "hour", "1hour": return .oneHour
        case "tomorrow": return .untilTomorrow
        default: return .always
        }
    }
}
