import AppKit
import Carbon

final class HotkeyManager {
    static let signature: OSType = 0x56455A48 // 'VEZH'

    var onPressed: ((Bool) -> Void)?

    private var forwardRef: EventHotKeyRef?
    private var reverseRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var handlerInstalled = false

    deinit {
        unregister()
        if let handlerRef {
            RemoveEventHandler(handlerRef)
        }
    }

    func register(_ chord: HotkeyChord) {
        unregister()
        installHandlerIfNeeded()

        var forwardID = EventHotKeyID(signature: Self.signature, id: 1)
        let forwardStatus = RegisterEventHotKey(
            chord.keyCode,
            chord.carbonModifiers,
            forwardID,
            GetApplicationEventTarget(),
            0,
            &forwardRef
        )
        if forwardStatus != noErr {
            NSLog("Vez: falha ao registrar atalho (%d)", forwardStatus)
        }

        if let reverseMods = chord.reverseCarbonModifiers {
            var reverseID = EventHotKeyID(signature: Self.signature, id: 2)
            _ = RegisterEventHotKey(
                chord.keyCode,
                reverseMods,
                reverseID,
                GetApplicationEventTarget(),
                0,
                &reverseRef
            )
        }
    }

    func unregister() {
        if let forwardRef {
            UnregisterEventHotKey(forwardRef)
            self.forwardRef = nil
        }
        if let reverseRef {
            UnregisterEventHotKey(reverseRef)
            self.reverseRef = nil
        }
    }

    fileprivate func handleCarbon(id: UInt32) {
        let reverse = id == 2
        DispatchQueue.main.async { [weak self] in
            self?.onPressed?(reverse)
        }
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            vezCarbonHotkeyHandler,
            1,
            &spec,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &handlerRef
        )
        if status != noErr {
            NSLog("Vez: falha ao instalar handler de atalho (%d)", status)
        }
    }
}

private let vezCarbonHotkeyHandler: EventHandlerUPP = { _, event, userData in
    guard let event, let userData else {
        return OSStatus(eventNotHandledErr)
    }
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr, hotKeyID.signature == HotkeyManager.signature else {
        return OSStatus(eventNotHandledErr)
    }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    manager.handleCarbon(id: hotKeyID.id)
    return noErr
}
