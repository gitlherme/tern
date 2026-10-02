import AppKit
import Carbon
import CoreGraphics

/// Intercepta o atalho na origem (event tap) para o HUD sobrepor o app da frente
/// em vez de o ⌥⇥ (ou o atalho gravado) também disparar no browser.
final class KeyboardInterceptor {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private(set) var isEnabled = false

    func start() {
        stop()

        let mask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
            KeyboardInterceptor.handleTap(proxy: proxy, type: type, event: event, userInfo: userInfo)
        }

        for location in [CGEventTapLocation.cgSessionEventTap, .cghidEventTap] {
            guard let tap = CGEvent.tapCreate(
                tap: location,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(mask),
                callback: callback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            ) else {
                continue
            }
            self.tap = tap
            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            self.source = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            isEnabled = true
            return
        }

        isEnabled = false
        NSLog("Tern: não consegui interceptar o teclado; o atalho pode vazar para o app da frente.")
    }

    func stop() {
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            self.source = nil
        }
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            self.tap = nil
        }
        isEnabled = false
    }

    private static func handleTap(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent,
        userInfo: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }
        _ = proxy
        let interceptor = Unmanaged<KeyboardInterceptor>.fromOpaque(userInfo).takeUnretainedValue()

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = interceptor.tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if interceptor.shouldSwallow(type: type, event: event) {
            return nil
        }
        return Unmanaged.passUnretained(event)
    }

    private func shouldSwallow(type: CGEventType, event: CGEvent) -> Bool {
        let run = {
            MainActor.assumeIsolated {
                self.decide(type: type, event: event)
            }
        }
        if Thread.isMainThread {
            return run()
        }
        var result = false
        DispatchQueue.main.sync {
            result = run()
        }
        return result
    }

    @MainActor
    private func decide(type: CGEventType, event: CGEvent) -> Bool {
        let model = AppModel.shared
        guard let nsEvent = NSEvent(cgEvent: event) else { return false }

        if type == .keyDown || type == .keyUp {
            if model.hotkey.matchesKeyEvent(nsEvent) {
                if type == .keyDown {
                    let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
                    if !isRepeat || model.isSwitcherVisible {
                        model.handleHotkey(reverse: model.hotkey.isReverse(nsEvent))
                    }
                }
                return true
            }
            if model.isSwitcherVisible {
                if type == .keyDown {
                    return model.handleSwitcherEvent(nsEvent)
                }
                if type == .keyUp && Self.isConsumedWhileSwitcherOpen(nsEvent, chord: model.hotkey) {
                    return true
                }
            }
            return false
        }

        if type == .flagsChanged, model.isSwitcherVisible {
            return model.handleSwitcherEvent(nsEvent)
        }
        return false
    }

    private static func isConsumedWhileSwitcherOpen(_ event: NSEvent, chord: HotkeyChord) -> Bool {
        if chord.matchesKeyEvent(event) { return true }
        switch Int(event.keyCode) {
        case kVK_Escape, kVK_Return, kVK_ANSI_KeypadEnter,
             kVK_LeftArrow, kVK_RightArrow, kVK_UpArrow, kVK_DownArrow,
             kVK_Delete, kVK_ForwardDelete, kVK_Tab:
            return true
        default:
            return false
        }
    }
}
