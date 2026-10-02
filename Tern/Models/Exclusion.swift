import Foundation

struct AppExclusion: Codable, Identifiable, Hashable {
    var id: String { bundleID }
    var bundleID: String
    var displayName: String
}

struct WindowExclusion: Codable, Identifiable, Hashable {
    var id: String { bundleID + "\u{1e}" + title }
    var bundleID: String
    var title: String
    var appName: String

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Janela sem título" : trimmed
    }
}

struct PersistedExclusions: Codable, Equatable {
    var apps: [AppExclusion]
    var windows: [WindowExclusion]

    static let empty = PersistedExclusions(apps: [], windows: [])

    func hides(bundleID: String, title: String) -> Bool {
        if apps.contains(where: { $0.bundleID == bundleID }) {
            return true
        }
        return windows.contains { $0.bundleID == bundleID && $0.title == title }
    }

    mutating func addApp(bundleID: String, name: String) {
        windows.removeAll { $0.bundleID == bundleID }
        guard !apps.contains(where: { $0.bundleID == bundleID }) else { return }
        apps.append(AppExclusion(bundleID: bundleID, displayName: name))
        apps.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    mutating func addWindow(bundleID: String, title: String, appName: String) {
        guard !apps.contains(where: { $0.bundleID == bundleID }) else { return }
        let item = WindowExclusion(bundleID: bundleID, title: title, appName: appName)
        guard !windows.contains(item) else { return }
        windows.append(item)
        windows.sort {
            if $0.appName != $1.appName {
                return $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending
            }
            return $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
        }
    }

    mutating func removeApp(bundleID: String) {
        apps.removeAll { $0.bundleID == bundleID }
    }

    mutating func removeWindow(_ item: WindowExclusion) {
        windows.removeAll { $0 == item }
    }
}
