import Carbon
import SwiftUI

enum HotKeyAction: String, CaseIterable, Codable, Identifiable {
    case startStop, pauseResume, reset, togglePopover, quit

    var id: String { rawValue }

    var titleKey: String { "shortcut.\(rawValue)" }

    var defaultHotKey: HotKey {
        let mods = UInt32(controlKey | optionKey)
        switch self {
        case .startStop: return HotKey(keyCode: UInt32(kVK_ANSI_S), modifiers: mods)
        case .pauseResume: return HotKey(keyCode: UInt32(kVK_ANSI_P), modifiers: mods)
        case .reset: return HotKey(keyCode: UInt32(kVK_ANSI_R), modifiers: mods)
        case .togglePopover: return HotKey(keyCode: UInt32(kVK_ANSI_T), modifiers: mods)
        case .quit: return HotKey.commandQ
        }
    }
}

struct HotKey: Codable, Equatable {
    static let commandQ = HotKey(keyCode: UInt32(kVK_ANSI_Q), modifiers: UInt32(cmdKey))

    var keyCode: UInt32
    /// Carbon modifier mask (cmdKey, optionKey, controlKey, shiftKey)
    var modifiers: UInt32

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// Whether the event is this exact key combination
    func matches(_ event: NSEvent) -> Bool {
        HotKey(event: event) == self
    }

    init?(event: NSEvent) {
        var mods: UInt32 = 0
        let flags = event.modifierFlags
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        let code = UInt32(event.keyCode)
        // Plain keys would hijack normal typing; only function keys may go without modifiers
        let needsModifier = !functionKeyCodes.contains(code)
        let hasModifier = mods & UInt32(cmdKey | optionKey | controlKey) != 0
        if needsModifier, !hasModifier { return nil }
        keyCode = code
        modifiers = mods
    }

    var displayString: String {
        var str = ""
        if modifiers & UInt32(controlKey) != 0 { str += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { str += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { str += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { str += "⌘" }
        return str + keyName(for: keyCode)
    }
}

private let functionKeyCodes: Set<UInt32> = Set([
    kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8,
    kVK_F9, kVK_F10, kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15,
    kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20,
].map { UInt32($0) })

private let keyNames: [Int: String] = [
    kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
    kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
    kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
    kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
    kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
    kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
    kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z",
    kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
    kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
    kVK_ANSI_8: "8", kVK_ANSI_9: "9",
    kVK_ANSI_Minus: "-", kVK_ANSI_Equal: "=", kVK_ANSI_LeftBracket: "[",
    kVK_ANSI_RightBracket: "]", kVK_ANSI_Semicolon: ";", kVK_ANSI_Quote: "'",
    kVK_ANSI_Comma: ",", kVK_ANSI_Period: ".", kVK_ANSI_Slash: "/",
    kVK_ANSI_Backslash: "\\", kVK_ANSI_Grave: "`",
    kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥",
    kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
    kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
    kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
    kVK_ANSI_Keypad0: "0", kVK_ANSI_Keypad1: "1", kVK_ANSI_Keypad2: "2",
    kVK_ANSI_Keypad3: "3", kVK_ANSI_Keypad4: "4", kVK_ANSI_Keypad5: "5",
    kVK_ANSI_Keypad6: "6", kVK_ANSI_Keypad7: "7", kVK_ANSI_Keypad8: "8",
    kVK_ANSI_Keypad9: "9", kVK_ANSI_KeypadDecimal: ".", kVK_ANSI_KeypadMultiply: "*",
    kVK_ANSI_KeypadPlus: "+", kVK_ANSI_KeypadDivide: "/", kVK_ANSI_KeypadMinus: "-",
    kVK_ANSI_KeypadEquals: "=", kVK_ANSI_KeypadEnter: "⌤",
    kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5",
    kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10",
    kVK_F11: "F11", kVK_F12: "F12", kVK_F13: "F13", kVK_F14: "F14",
    kVK_F15: "F15", kVK_F16: "F16", kVK_F17: "F17", kVK_F18: "F18",
    kVK_F19: "F19", kVK_F20: "F20",
]

private func keyName(for keyCode: UInt32) -> String {
    keyNames[Int(keyCode)] ?? "#\(keyCode)"
}

private let hotKeySignature: OSType = 0x574C_4231 // "WLB1"
private let storageKey = "hotKeys"
private let knownActionsKey = "hotKeysKnownActions"
/// Actions that existed in 1.0, before known actions were tracked
private let initialActions: [HotKeyAction] = [
    .startStop, .pauseResume, .reset, .togglePopover,
]

/// Reads saved shortcuts one by one, skipping actions removed in newer versions
private func decodeSavedHotKeys(_ data: Data) -> [HotKeyAction: HotKey]? {
    // Stored as a flat [action, hotKey, action, hotKey, ...] array
    guard let items = try? JSONSerialization.jsonObject(with: data) as? [Any],
          items.count % 2 == 0 else { return nil }
    var keys: [HotKeyAction: HotKey] = [:]
    for index in stride(from: 0, to: items.count, by: 2) {
        guard let name = items[index] as? String,
              let action = HotKeyAction(rawValue: name),
              let value = items[index + 1] as? [String: Any],
              let keyCode = (value["keyCode"] as? UInt32) ?? (value["keyCode"] as? NSNumber)?.uint32Value,
              let modifiers = (value["modifiers"] as? UInt32) ?? (value["modifiers"] as? NSNumber)?.uint32Value else { continue }
        keys[action] = HotKey(keyCode: keyCode, modifiers: modifiers)
    }
    return keys
}

class HotKeyCenter: ObservableObject {
    static let shared = HotKeyCenter()

    @Published private(set) var hotKeys: [HotKeyAction: HotKey] = [:]
    @Published private(set) var recordingAction: HotKeyAction?
    private var handlers: [HotKeyAction: () -> Void] = [:]
    private var refs: [HotKeyAction: EventHotKeyRef] = [:]
    private var recordingMonitor: Any?

    var suspended: Bool { recordingAction != nil }

    private init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: storageKey),
           let saved = decodeSavedHotKeys(data) {
            /*
             Keep the user's shortcuts across updates. Actions added in newer
             versions get their default shortcut, unless it is already taken.
             */
            var keys = saved
            let known = defaults.stringArray(forKey: knownActionsKey)?
                .compactMap(HotKeyAction.init(rawValue:)) ?? initialActions
            for action in HotKeyAction.allCases where !known.contains(action) {
                let key = action.defaultHotKey
                if !keys.values.contains(key) {
                    keys[action] = key
                }
            }
            hotKeys = keys
            save()
        } else {
            restoreDefaults()
        }

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hkID = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID), nil,
                                           MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            guard status == noErr, hkID.signature == hotKeySignature else {
                return OSStatus(eventNotHandledErr)
            }
            let index = Int(hkID.id)
            guard index >= 0, index < HotKeyAction.allCases.count else {
                return OSStatus(eventNotHandledErr)
            }
            let action = HotKeyAction.allCases[index]
            DispatchQueue.main.async {
                HotKeyCenter.shared.handlers[action]?()
            }
            return noErr
        }, 1, &spec, nil, nil)
    }

    func onPress(_ action: HotKeyAction, handler: @escaping () -> Void) {
        handlers[action] = handler
        registerAll()
    }

    /// Handles shortcuts inside the app's own windows when not registered globally (e.g. ⌘Q)
    func handleLocalKeyDown(_ event: NSEvent) -> Bool {
        guard !suspended, let pressed = HotKey(event: event) else { return false }
        for action in HotKeyAction.allCases where hotKeys[action] == pressed {
            if refs[action] == nil, let handler = handlers[action] {
                handler()
                return true
            }
        }
        return false
    }

    func set(_ hotKey: HotKey?, for action: HotKeyAction) {
        hotKeys[action] = hotKey
        // A combination can only trigger one action
        if let hotKey = hotKey {
            for (other, key) in hotKeys where other != action && key == hotKey {
                hotKeys[other] = nil
            }
        }
        save()
        registerAll()
    }

    func restoreDefaults() {
        stopRecording()
        var keys: [HotKeyAction: HotKey] = [:]
        for action in HotKeyAction.allCases {
            keys[action] = action.defaultHotKey
        }
        hotKeys = keys
        save()
        registerAll()
    }

    /// Records a shortcut for a single action at a time, temporarily disabling global hotkeys
    func startRecording(_ action: HotKeyAction) {
        stopRecording()
        recordingAction = action
        unregisterAll()
        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, let current = self.recordingAction else { return event }
            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
            switch Int(event.keyCode) {
            case kVK_Escape where mods.isEmpty:
                self.stopRecording()
            case kVK_Delete where mods.isEmpty, kVK_ForwardDelete where mods.isEmpty:
                self.set(nil, for: current)
                self.stopRecording()
            default:
                if let hotKey = HotKey(event: event) {
                    self.set(hotKey, for: current)
                    self.stopRecording()
                } else {
                    NSSound.beep()
                }
            }
            return nil
        }
    }

    func stopRecording() {
        if let monitor = recordingMonitor {
            NSEvent.removeMonitor(monitor)
            recordingMonitor = nil
        }
        if recordingAction != nil {
            recordingAction = nil
            registerAll()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(hotKeys) {
            UserDefaults.standard.set(data, forKey: storageKey)
            UserDefaults.standard.set(HotKeyAction.allCases.map(\.rawValue),
                                      forKey: knownActionsKey)
        }
    }

    private func unregisterAll() {
        for ref in refs.values {
            UnregisterEventHotKey(ref)
        }
        refs.removeAll()
    }

    private func registerAll() {
        unregisterAll()
        guard !suspended else { return }
        for (index, action) in HotKeyAction.allCases.enumerated() {
            guard let key = hotKeys[action], handlers[action] != nil else { continue }
            // A global ⌘Q would quit this app instead of the frontmost one;
            // it is handled inside the app's own windows instead
            if key == HotKey.commandQ { continue }
            var ref: EventHotKeyRef?
            let hkID = EventHotKeyID(signature: hotKeySignature, id: UInt32(index))
            let status = RegisterEventHotKey(key.keyCode, key.modifiers, hkID,
                                             GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref = ref {
                refs[action] = ref
            } else {
                print("cannot register hotkey \(key.displayString): \(status)")
            }
        }
    }
}

struct HotKeyRecorder: View {
    let action: HotKeyAction
    @ObservedObject private var center = HotKeyCenter.shared
    @ObservedObject private var l10n = L10n.shared

    private var isRecording: Bool { center.recordingAction == action }

    var body: some View {
        HStack(spacing: 4) {
            Button {
                isRecording ? center.stopRecording() : center.startRecording(action)
            } label: {
                Text(label)
                    .font(.system(.body).monospacedDigit())
                    .foregroundColor(isRecording ? .accentColor : .primary)
                    .frame(width: 92)
            }
            if center.hotKeys[action] != nil, !isRecording {
                Button {
                    center.set(nil, for: action)
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .onDisappear {
            if isRecording { center.stopRecording() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tbPopoverDidClose)) { _ in
            if isRecording { center.stopRecording() }
        }
    }

    private var label: String {
        if isRecording { return l10n.t("shortcut.recording") }
        return center.hotKeys[action]?.displayString ?? l10n.t("shortcut.none")
    }
}
