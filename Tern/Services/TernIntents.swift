import AppIntents
import AppKit
import Foundation

// MARK: Modo como entidade (Filtro de Foco e Atalhos)

struct TernModeEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Modo do Tern")
    static var defaultQuery = TernModeQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(_ mode: ExclusionMode) {
        id = mode.id
        name = mode.name
    }
}

/// Lê os modos direto do que está salvo: funciona mesmo quando o sistema chama o
/// Tern só para montar a lista dos Ajustes de Foco.
struct TernModeQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [TernModeEntity] {
        ExclusionStore().load().modes.filter { identifiers.contains($0.id) }.map(TernModeEntity.init)
    }

    func suggestedEntities() async throws -> [TernModeEntity] {
        ExclusionStore().load().modes.map(TernModeEntity.init)
    }
}

// MARK: Filtro de Foco (#6)

/// Aparece em Ajustes do Sistema › Foco › Filtros de Foco. O macOS chama `perform()`
/// quando o Foco liga, com o modo escolhido, e quando desliga, com o modo vazio.
struct TernFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Modo do Tern"
    static var description: IntentDescription? = IntentDescription("Enquanto este Foco estiver ligado, o Tern esconde do seletor os apps do modo escolhido.")

    @Parameter(title: "Modo")
    var mode: TernModeEntity?

    var displayRepresentation: DisplayRepresentation {
        if let mode {
            return DisplayRepresentation(title: "\(mode.name)")
        }
        return DisplayRepresentation(title: "Nenhum modo")
    }

    func perform() async throws -> some IntentResult {
        let id = mode?.id
        await MainActor.run {
            AppModel.shared.setActiveMode(id)
        }
        return .result()
    }
}

// MARK: Atalhos (#16)

struct TernAppEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "App")
    static var defaultQuery = TernAppQuery()

    /// Bundle id, como com.spotify.client.
    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

/// Sugere os apps abertos e os já ocultos, para dar para mostrar de novo um app fechado.
struct TernAppQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TernAppEntity] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [TernAppEntity] {
        await MainActor.run {
            var seen = Set<String>()
            var result: [TernAppEntity] = []
            for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
                guard let id = app.bundleIdentifier, id != Bundle.main.bundleIdentifier, seen.insert(id).inserted else { continue }
                result.append(TernAppEntity(id: id, name: app.localizedName ?? id))
            }
            for app in AppModel.shared.exclusions.apps where seen.insert(app.bundleID).inserted {
                result.append(TernAppEntity(id: app.bundleID, name: app.displayName))
            }
            return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}

enum TernHideDuration: String, AppEnum {
    case always, oneHour, untilTomorrow

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Duração")
    static var caseDisplayRepresentations: [TernHideDuration: DisplayRepresentation] = [
        .always: DisplayRepresentation(title: "Sempre"),
        .oneHour: DisplayRepresentation(title: "1 hora"),
        .untilTomorrow: DisplayRepresentation(title: "Até amanhã"),
    ]

    var duration: HideDuration {
        HideDuration(rawValue: rawValue) ?? .always
    }
}

struct OpenSwitcherIntent: AppIntent {
    static var title: LocalizedStringResource = "Abrir o seletor do Tern"
    static var description: IntentDescription? = IntentDescription("Mostra o seletor de janelas, como o atalho de teclado.")

    func perform() async throws -> some IntentResult {
        await MainActor.run { AppModel.shared.openSwitcherFromMenu() }
        return .result()
    }
}

struct HideAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Esconder app no Tern"
    static var description: IntentDescription? = IntentDescription("Tira um app do seletor de janelas, para sempre ou por um tempo.")

    @Parameter(title: "App")
    var app: TernAppEntity

    @Parameter(title: "Por quanto tempo", default: .always)
    var duration: TernHideDuration

    static var parameterSummary: some ParameterSummary {
        Summary("Esconder \(\.$app) no Tern por \(\.$duration)")
    }

    func perform() async throws -> some IntentResult {
        let app = app
        let duration = duration.duration
        await MainActor.run { AppModel.shared.excludeApp(bundleID: app.id, name: app.name, duration: duration) }
        return .result()
    }
}

struct UnhideAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Mostrar app no Tern"
    static var description: IntentDescription? = IntentDescription("Devolve ao seletor um app que estava escondido.")

    @Parameter(title: "App")
    var app: TernAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Mostrar \(\.$app) no Tern")
    }

    func perform() async throws -> some IntentResult {
        let id = app.id
        await MainActor.run { AppModel.shared.removeAppExclusion(bundleID: id) }
        return .result()
    }
}

struct SetModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Mudar o modo do Tern"
    static var description: IntentDescription? = IntentDescription("Liga um modo do Tern, ou desliga se nenhum for escolhido.")

    @Parameter(title: "Modo")
    var mode: TernModeEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Mudar o modo do Tern para \(\.$mode)")
    }

    func perform() async throws -> some IntentResult {
        let id = mode?.id
        await MainActor.run { AppModel.shared.setActiveMode(id) }
        return .result()
    }
}
