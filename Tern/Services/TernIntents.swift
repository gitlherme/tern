import AppIntents
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
