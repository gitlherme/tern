import Foundation

struct ExclusionStore {
    static let key = "vez.exclusions"

    func load() -> PersistedExclusions {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let decoded = try? JSONDecoder().decode(PersistedExclusions.self, from: data) else {
            return .empty
        }
        return decoded
    }

    func save(_ state: PersistedExclusions) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
