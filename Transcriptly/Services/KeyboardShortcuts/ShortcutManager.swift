//
//  ShortcutManager.swift
//  Transcriptly
//
//  Manages keyboard shortcuts with conflict detection and customization
//

import Cocoa
import Carbon
import Combine

@MainActor
class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()
    
    @Published var currentShortcuts: [ShortcutBinding] = []
    @Published var hasConflicts: Bool = false
    
    private let conflictDetector = ConflictDetector()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private init() {
        setupDefaultShortcuts()
        setupEventTap()
    }
    
    func setupDefaultShortcuts() {
        currentShortcuts = [
            ShortcutBinding(
                id: "primary_record",
                keyCode: kVK_ANSI_M,
                modifiers: NSEvent.ModifierFlags.command.rawValue,
                action: .toggleRecording,
                name: "Start/Stop Recording",
                isCustomizable: true,
                isDefault: true
            ),
            ShortcutBinding(
                id: "mode_raw",
                keyCode: kVK_ANSI_1,
                modifiers: NSEvent.ModifierFlags.command.rawValue,
                action: .switchMode(.raw),
                name: "Raw Transcription Mode",
                isCustomizable: true
            ),
            ShortcutBinding(
                id: "mode_cleanup",
                keyCode: kVK_ANSI_2,
                modifiers: NSEvent.ModifierFlags.command.rawValue,
                action: .switchMode(.cleanup),
                name: "Clean-up Mode",
                isCustomizable: true
            ),
            ShortcutBinding(
                id: "mode_email",
                keyCode: kVK_ANSI_3,
                modifiers: NSEvent.ModifierFlags.command.rawValue,
                action: .switchMode(.email),
                name: "Email Mode",
                isCustomizable: true
            ),
            ShortcutBinding(
                id: "mode_messaging",
                keyCode: kVK_ANSI_4,
                modifiers: NSEvent.ModifierFlags.command.rawValue,
                action: .switchMode(.messaging),
                name: "Messaging Mode",
                isCustomizable: true
            ),
            ShortcutBinding(
                id: "cancel_recording",
                keyCode: kVK_Escape,
                modifiers: 0,
                action: .cancelRecording,
                name: "Cancel Recording",
                isCustomizable: false
            )
        ]
        
        registerAllShortcuts()
    }
    
    func updateShortcut(_ shortcutId: String, keyCode: Int, modifiers: NSEvent.ModifierFlags) async -> ShortcutUpdateResult {
        // Check for conflicts before updating
        let conflicts = await conflictDetector.detectConflicts(keyCode: keyCode, modifiers: modifiers)
        
        if !conflicts.isEmpty {
            return .conflictDetected(conflicts)
        }
        
        // Update shortcut
        if let index = currentShortcuts.firstIndex(where: { $0.id == shortcutId }) {
            currentShortcuts[index].keyCode = keyCode
            currentShortcuts[index].eventModifiers = modifiers
            
            saveShortcuts()
            registerAllShortcuts()
            
            return .success
        }
        
        return .notFound
    }
    
    func testShortcut(_ shortcutId: String) -> Bool {
        guard let shortcut = currentShortcuts.first(where: { $0.id == shortcutId }) else {
            return false
        }
        
        // Simulate shortcut execution for testing
        executeShortcutAction(shortcut.action)
        return true
    }
    
    func resetToDefaults() {
        setupDefaultShortcuts()
        saveShortcuts()
    }
    
    func resetShortcut(_ shortcutId: String) {
        setupDefaultShortcuts()
        if let defaultShortcut = currentShortcuts.first(where: { $0.id == shortcutId }) {
            _ = Task {
                await updateShortcut(shortcutId, keyCode: defaultShortcut.keyCode, modifiers: defaultShortcut.eventModifiers)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let manager = Unmanaged<ShortcutManager>.fromOpaque(refcon!).takeUnretainedValue()
                return manager.handleKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("Failed to create event tap")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }
        
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue))
        
        // Check if this matches any of our shortcuts
        for shortcut in currentShortcuts {
            if shortcut.keyCode == keyCode && shortcut.eventModifiers == modifiers {
                executeShortcutAction(shortcut.action)
                return nil // Consume the event
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func executeShortcutAction(_ action: ShortcutAction) {
        Task { @MainActor in
            switch action {
            case .toggleRecording:
                NotificationCenter.default.post(name: .toggleRecording, object: nil)
            case .switchMode(let mode):
                NotificationCenter.default.post(name: .switchRefinementMode, object: mode)
            case .cancelRecording:
                NotificationCenter.default.post(name: .cancelRecording, object: nil)
            }
        }
    }
    
    private func registerAllShortcuts() {
        // Implementation for registering shortcuts with system
    }
    
    private func saveShortcuts() {
        do {
            let data = try JSONEncoder().encode(currentShortcuts)
            UserDefaults.standard.set(data, forKey: "customShortcuts")
        } catch {
            print("Failed to save shortcuts: \(error)")
        }
    }
    
    deinit {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }
}

// MARK: - Supporting Types

struct ShortcutBinding: Codable, Identifiable {
    let id: String
    var keyCode: Int
    var modifiers: UInt
    let action: ShortcutAction
    let name: String
    let isCustomizable: Bool
    var isDefault: Bool = false
    
    // Computed property for NSEvent.ModifierFlags
    var eventModifiers: NSEvent.ModifierFlags {
        get { NSEvent.ModifierFlags(rawValue: modifiers) }
        set { modifiers = newValue.rawValue }
    }
    
    var displayString: String {
        var result = ""
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        
        if flags.contains(.command) { result += "⌘" }
        if flags.contains(.option) { result += "⌥" }
        if flags.contains(.shift) { result += "⇧" }
        if flags.contains(.control) { result += "⌃" }
        
        result += keyCodeToString(keyCode)
        return result
    }
    
    private func keyCodeToString(_ keyCode: Int) -> String {
        switch keyCode {
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_Escape: return "⎋"
        default: return String(UnicodeScalar(keyCode + 65) ?? "?")
        }
    }
}

enum ShortcutAction: Codable {
    case toggleRecording
    case switchMode(RefinementMode)
    case cancelRecording
    
    private enum CodingKeys: String, CodingKey {
        case type
        case mode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "toggleRecording":
            self = .toggleRecording
        case "switchMode":
            let mode = try container.decode(RefinementMode.self, forKey: .mode)
            self = .switchMode(mode)
        case "cancelRecording":
            self = .cancelRecording
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown action type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .toggleRecording:
            try container.encode("toggleRecording", forKey: .type)
        case .switchMode(let mode):
            try container.encode("switchMode", forKey: .type)
            try container.encode(mode, forKey: .mode)
        case .cancelRecording:
            try container.encode("cancelRecording", forKey: .type)
        }
    }
}

enum ShortcutUpdateResult {
    case success
    case conflictDetected([ConflictInfo])
    case notFound
    case invalidKeyCode
}

// Notification extensions
extension Notification.Name {
    static let toggleRecording = Notification.Name("toggleRecording")
    static let switchRefinementMode = Notification.Name("switchRefinementMode")
    static let cancelRecording = Notification.Name("cancelRecording")
}