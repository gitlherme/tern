import Foundation

/// Busca do seletor: cada palavra digitada precisa aparecer no nome do app ou no título
/// da janela. Começo do nome do app pesa mais que começo de palavra, que pesa mais que
/// trecho no meio, que pesa mais que letras em sequência ("vsc" acha "Visual Studio Code").
enum WindowFilter {
    static func apply(_ windows: [WindowInfo], query: String) -> [WindowInfo] {
        let tokens = normalize(query).split(separator: " ").map(String.init)
        guard !tokens.isEmpty else { return windows }

        let scored: [(index: Int, score: Int, window: WindowInfo)] = windows.enumerated().compactMap { index, window in
            guard let score = score(app: window.appName, title: window.title, tokens: tokens) else { return nil }
            return (index, score, window)
        }
        // Empate mantém a ordem de recência.
        return scored
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
            .map(\.window)
    }

    static func score(app: String, title: String, tokens: [String]) -> Int? {
        let app = normalize(app)
        let title = normalize(title)
        var total = 0
        for token in tokens {
            guard let best = [score(token, in: app, appBonus: 50), score(token, in: title, appBonus: 0)]
                .compactMap({ $0 }).max() else {
                return nil
            }
            total += best
        }
        return total
    }

    private static func score(_ token: String, in text: String, appBonus: Int) -> Int? {
        guard !text.isEmpty else { return nil }
        if text.hasPrefix(token) { return 400 + appBonus }
        if text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).contains(where: { $0.hasPrefix(token) }) {
            return 300 + appBonus
        }
        if text.contains(token) { return 200 + appBonus }
        if let gaps = subsequenceGaps(token, in: text) {
            return max(1, 100 - gaps) + appBonus / 2
        }
        return nil
    }

    /// Letras do token em ordem dentro do texto; devolve quantos caracteres ficaram entre elas.
    private static func subsequenceGaps(_ token: String, in text: String) -> Int? {
        var gaps = 0
        var started = false
        var remaining = token[...]
        for character in text {
            guard let next = remaining.first else { break }
            if character == next {
                remaining = remaining.dropFirst()
                started = true
            } else if started {
                gaps += 1
            }
        }
        return remaining.isEmpty ? gaps : nil
    }

    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
