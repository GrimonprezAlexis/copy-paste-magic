import Carbon.HIToolbox

final class HotkeyManager {
    var onHotkeyPressed: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    // Static reference for the C callback
    fileprivate static weak var shared: HotkeyManager?

    func register() {
        HotkeyManager.shared = self

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            carbonHotKeyHandler,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(
            signature: 0x4350_4D47, // "CPMG"
            id: 1
        )

        RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
    }

    deinit {
        unregister()
    }
}

// Free function compatible with C function pointer requirement
private func carbonHotKeyHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    let err = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    if err == noErr && hotKeyID.id == 1 {
        DispatchQueue.main.async {
            HotkeyManager.shared?.onHotkeyPressed?()
        }
        return noErr
    }

    return OSStatus(eventNotHandledErr)
}
