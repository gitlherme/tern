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
        return trimmed.isEmpty ? String(localized: "Janela sem título") : trimmed
    }
}

/// Esconde janelas cujo título combina com um padrão (#9), num app ou em qualquer app.
/// Sem `*`, basta o título conter o texto; com `*`, o padrão precisa cobrir o título todo
/// ("Picture*" pega "Picture in Picture"). Maiúsculas e acentos não importam.
struct TitleRule: Codable, Identifiable, Hashable {
    var id = UUID()
    var pattern: String
    /// nil = vale para qualquer app.
    var bundleID: String?
    var appName: String?

    func matches(bundleID: String, title: String) -> Bool {
        if let scope = self.bundleID, scope != bundleID { return false }
        let needle = Self.normalize(pattern)
        guard !needle.isEmpty else { return false }
        let haystack = Self.normalize(title)
        if needle.contains("*") {
            let parts = needle.components(separatedBy: "*").map(NSRegularExpression.escapedPattern(for:))
            let regex = "^" + parts.joined(separator: ".*") + "$"
            return haystack.range(of: regex, options: .regularExpression) != nil
        }
        return haystack.contains(needle)
    }

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct PersistedExclusions: Codable, Equatable {
    var apps: [AppExclusion]
    var windows: [WindowExclusion]
    var titleRules: [TitleRule]

    static let empty = PersistedExclusions(apps: [], windows: [], titleRules: [])

    init(apps: [AppExclusion], windows: [WindowExclusion], titleRules: [TitleRule]) {
        self.apps = apps
        self.windows = windows
        self.titleRules = titleRules
    }

    /// Campos novos são opcionais na leitura: quem atualiza mantém as exclusões salvas.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        apps = try container.decodeIfPresent([AppExclusion].self, forKey: .apps) ?? []
        windows = try container.decodeIfPresent([WindowExclusion].self, forKey: .windows) ?? []
        titleRules = try container.decodeIfPresent([TitleRule].self, forKey: .titleRules) ?? []
    }

    func hides(bundleID: String, title: String) -> Bool {
        if apps.contains(where: { $0.bundleID == bundleID }) {
            return true
        }
        if windows.contains(where: { $0.bundleID == bundleID && $0.title == title }) {
            return true
        }
        return titleRules.contains { $0.matches(bundleID: bundleID, title: title) }
    }

    mutating func addTitleRule(_ rule: TitleRule) {
        guard !rule.pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        titleRules.append(rule)
    }

    mutating func removeTitleRule(_ rule: TitleRule) {
        titleRules.removeAll { $0.id == rule.id }
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
