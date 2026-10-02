import AppKit
import ApplicationServices
import Foundation

struct WindowMRUKey: Codable, Equatable {
    var bundleID: String
    var windowID: UInt32
    var title: String

    func matches(_ window: WindowInfo) -> Bool {
        if window.bundleID != bundleID { return false }
        if windowID != 0, window.windowID == windowID { return true }
        let expected = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let actual = window.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !expected.isEmpty && expected == actual
    }

    func isSameEntry(as other: WindowMRUKey) -> Bool {
        if bundleID != other.bundleID { return false }
        if windowID != 0, other.windowID != 0, windowID == other.windowID { return true }
        let a = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = other.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !a.isEmpty && a == b
    }
}

/// Recência das janelas: a atual no 0, a anterior no 1 — ping-pong no atalho.
struct WindowRecency {
    private static let defaultsKey = "vez.windowMRU"
    private static let limit = 40

    private var keys: [WindowMRUKey]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([WindowMRUKey].self, from: data) {
            keys = decoded
        } else {
            keys = []
        }
    }

    mutating func record(_ window: WindowInfo) {
        record(
            WindowMRUKey(
                bundleID: window.bundleID,
                windowID: window.windowID,
                title: window.title
            )
        )
    }

    mutating func recordFrontmost(from windows: [WindowInfo]) {
        guard let front = windows.first(where: { !$0.isMinimized }) ?? windows.first else { return }
        record(front)
    }

    mutating func recordCurrentFront(ignoringBundleID: String?) {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.activationPolicy == .regular,
              let bundleID = app.bundleIdentifier else { return }
        if let ignoringBundleID, bundleID == ignoringBundleID { return }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        let focused = AccessibilityWindows.child(axApp, kAXFocusedWindowAttribute as String)
            ?? AccessibilityWindows.child(axApp, kAXMainWindowAttribute as String)
        let windowID = focused.flatMap { AccessibilityWindows.windowID($0) } ?? 0
        let title = focused.map { AccessibilityWindows.title($0) } ?? (app.localizedName ?? "")
        record(WindowMRUKey(bundleID: bundleID, windowID: windowID, title: title))
    }

    func ordered(_ windows: [WindowInfo]) -> [WindowInfo] {
        guard !windows.isEmpty else { return [] }

        let originalIndex = Dictionary(
            uniqueKeysWithValues: windows.enumerated().map { ($0.element.windowID, $0.offset) }
        )
        let front = windows.first(where: { !$0.isMinimized }) ?? windows[0]
        let visible = windows.filter { !$0.isMinimized && $0.windowID != front.windowID }
        let minimized = windows.filter(\.isMinimized)

        func recencyThenZ(_ lhs: WindowInfo, _ rhs: WindowInfo) -> Bool {
            let leftRank = rank(lhs)
            let rightRank = rank(rhs)
            if leftRank != rightRank {
                return leftRank < rightRank
            }
            return (originalIndex[lhs.windowID] ?? Int.max) < (originalIndex[rhs.windowID] ?? Int.max)
        }

        return [front] + visible.sorted(by: recencyThenZ) + minimized.sorted(by: recencyThenZ)
    }

    private func rank(_ window: WindowInfo) -> Int {
        keys.firstIndex { $0.matches(window) } ?? Int.max
    }

    private mutating func record(_ key: WindowMRUKey) {
        keys.removeAll { $0.isSameEntry(as: key) }
        keys.insert(key, at: 0)
        if keys.count > Self.limit {
            keys = Array(keys.prefix(Self.limit))
        }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(keys) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
