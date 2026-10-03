import Foundation

struct AppExclusion: Codable, Identifiable, Hashable {
    var id: String { bundleID }
    var bundleID: String
    var displayName: String
    /// Soneca (#7): oculto só até esta data. nil = até a pessoa remover.
    var until: Date? = nil

    func isActive(at now: Date) -> Bool {
        until.map { $0 > now } ?? true
    }
}

/// Por quanto tempo esconder um app.
enum HideDuration: String, CaseIterable, Identifiable {
    case always, oneHour, untilTomorrow

    var id: String { rawValue }

    /// "Até amanhã" = amanhã às 6h, para o app voltar antes do dia começar.
    func until(from now: Date = Date(), calendar: Calendar = .current) -> Date? {
        switch self {
        case .always:
            return nil
        case .oneHour:
            return now.addingTimeInterval(60 * 60)
        case .untilTomorrow:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
            return calendar.date(bySettingHour: 6, minute: 0, second: 0, of: tomorrow)
        }
    }
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

    func hides(bundleID: String, title: String, now: Date = Date()) -> Bool {
        if apps.contains(where: { $0.bundleID == bundleID && $0.isActive(at: now) }) {
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

    mutating func addApp(bundleID: String, name: String, until: Date? = nil) {
        windows.removeAll { $0.bundleID == bundleID }
        if let index = apps.firstIndex(where: { $0.bundleID == bundleID }) {
            // Já oculto para sempre continua para sempre; uma soneca nova substitui a anterior.
            if apps[index].until != nil {
                apps[index].until = until
            }
            return
        }
        apps.append(AppExclusion(bundleID: bundleID, displayName: name, until: until))
        apps.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    /// Tira as sonecas vencidas. Devolve true se algo mudou.
    mutating func removeExpired(now: Date = Date()) -> Bool {
        let before = apps.count
        apps.removeAll { !$0.isActive(at: now) }
        return apps.count != before
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
