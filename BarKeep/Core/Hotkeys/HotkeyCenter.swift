import Carbon.HIToolbox
import Foundation

/// Глобальные горячие клавиши через Carbon — работают без Accessibility и Input Monitoring.
final class HotkeyCenter {
    static let shared = HotkeyCenter()

    private var handlers: [UInt32: @MainActor () -> Void] = [:]
    private var references: [UInt32: EventHotKeyRef] = [:]
    private var nextID: UInt32 = 1
    private var installed = false

    private init() {}

    @discardableResult
    func register(
        keyCode: UInt32,
        modifiers: UInt32,
        handler: @escaping @MainActor () -> Void
    ) -> UInt32? {
        installHandlerIfNeeded()

        let id = nextID
        nextID += 1

        var reference: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &reference
        )

        guard status == noErr, let reference else {
            NSLog("BarKeep: не удалось зарегистрировать хоткей keyCode=\(keyCode), status=\(status)")
            return nil
        }

        handlers[id] = handler
        references[id] = reference
        return id
    }

    fileprivate func fire(id: UInt32) {
        MainActor.assumeIsolated {
            handlers[id]?()
        }
    }

    private func installHandlerIfNeeded() {
        guard !installed else { return }
        installed = true

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                guard let event else { return OSStatus(eventNotHandledErr) }
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
                guard status == noErr, hotKeyID.signature == HotkeyCenter.signature else {
                    return OSStatus(eventNotHandledErr)
                }
                HotkeyCenter.shared.fire(id: hotKeyID.id)
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
    }

    private static let signature: OSType = 0x424B4550 // 'BKEP'
}
