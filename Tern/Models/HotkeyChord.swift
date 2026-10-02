import AppKit
import Carbon
import Foundation

struct HotkeyChord: Codable, Equatable {
    var keyCode: UInt32
    var carbonModifiers: UInt32

    static let `default` = HotkeyChord(keyCode: UInt32(kVK_Tab), carbonModifiers: UInt32(optionKey))

    var modifierFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if carbonModifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        if carbonModifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if carbonModifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        if carbonModifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        return flags
    }

    var hasModifiers: Bool {
        carbonModifiers != 0
    }

    var reverseCarbonModifiers: UInt32? {
        let shift = UInt32(shiftKey)
        let reversed: UInt32
        if carbonModifiers & shift != 0 {
            reversed = carbonModifiers & ~shift
        } else {
            reversed = carbonModifiers | shift
        }
        if reversed == 0 {
            return nil
        }
        if reversed == carbonModifiers {
            return nil
        }
        return reversed
    }

    var isReservedSystemSwitcher: Bool {
        keyCode == UInt32(kVK_Tab) && carbonModifiers == UInt32(cmdKey)
    }

    func matchesKeyEvent(_ event: NSEvent) -> Bool {
        guard UInt32(event.keyCode) == keyCode else { return false }
        let current = event.modifierFlags.intersection([.command, .option, .control, .shift])
        let needed = modifierFlags.intersection([.command, .option, .control, .shift])
        return current.subtracting(.shift) == needed.subtracting(.shift) && !needed.subtracting(.shift).isEmpty
    }

    func isReverse(_ event: NSEvent) -> Bool {
        event.modifierFlags.contains(.shift) != modifierFlags.contains(.shift)
    }

    var displayString: String {
        var parts: [String] = []
        if carbonModifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if carbonModifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if carbonModifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if carbonModifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        parts.append(Self.glyph(for: keyCode))
        return parts.joined()
    }

    static func from(event: NSEvent) -> HotkeyChord? {
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        guard carbon != 0 else { return nil }
        return HotkeyChord(keyCode: UInt32(event.keyCode), carbonModifiers: carbon)
    }

    static func glyph(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_Tab: return "⇥"
        case kVK_Space: return "Espaço"
        case kVK_Return: return "↩"
        case kVK_ANSI_KeypadEnter: return "⌅"
        case kVK_Escape: return "⎋"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_ANSI_Grave: return "`"
        case kVK_ANSI_Minus: return "−"
        case kVK_ANSI_Equal: return "="
        case kVK_ANSI_LeftBracket: return "["
        case kVK_ANSI_RightBracket: return "]"
        case kVK_ANSI_Backslash: return "\\"
        case kVK_ANSI_Semicolon: return ";"
        case kVK_ANSI_Quote: return "'"
        case kVK_ANSI_Comma: return ","
        case kVK_ANSI_Period: return "."
        case kVK_ANSI_Slash: return "/"
        default:
            let keyMap: [Int: String] = [
                kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
                kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
                kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
                kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
                kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
                kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
                kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z",
                kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
                kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
                kVK_ANSI_8: "8", kVK_ANSI_9: "9"
            ]
            return keyMap[Int(keyCode)] ?? "Tecla \(keyCode)"
        }
    }
}

enum HotkeyDefaults {
    static let key = "vez.hotkey"

    static func load() -> HotkeyChord {
        guard let data = UserDefaults.standard.data(forKey: key),
              let chord = try? JSONDecoder().decode(HotkeyChord.self, from: data) else {
            return .default
        }
        return chord
    }

    static func save(_ chord: HotkeyChord) {
        if let data = try? JSONEncoder().encode(chord) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
