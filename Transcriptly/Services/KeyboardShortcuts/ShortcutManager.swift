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
        print("🚀 ShortcutManager: Initializing...")
        setupDefaultShortcuts()
        setupEventTap()
        print("✅ ShortcutManager: Initialization complete")
    }
    
    func setupDefaultShortcuts() {
        currentShortcuts = [
            ShortcutBinding(
                id: "primary_record",
                keyCode: kVK_ANSI_R,
                modifiers: NSEvent.ModifierFlags([.command, .shift]).rawValue,
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
        print("🔄 ShortcutManager: Updating shortcut \(shortcutId) to keyCode: \(keyCode), modifiers: \(modifiers.rawValue)")
        
        // Check for conflicts before updating
        let conflicts = await conflictDetector.detectConflicts(keyCode: keyCode, modifiers: modifiers)
        
        if !conflicts.isEmpty {
            print("⚠️ ShortcutManager: Conflicts detected: \(conflicts)")
            return .conflictDetected(conflicts)
        }
        
        // Update shortcut
        if let index = currentShortcuts.firstIndex(where: { $0.id == shortcutId }) {
            let oldShortcut = currentShortcuts[index]
            print("📝 ShortcutManager: Updating \(oldShortcut.name) from \(oldShortcut.displayString) to new combination")
            
            currentShortcuts[index].keyCode = keyCode
            currentShortcuts[index].eventModifiers = modifiers
            
            print("💾 ShortcutManager: Saving updated shortcuts")
            saveShortcuts()
            registerAllShortcuts()
            
            print("✅ ShortcutManager: Shortcut updated successfully")
            return .success
        }
        
        print("❌ ShortcutManager: Shortcut not found: \(shortcutId)")
        return .notFound
    }
    
    func testShortcut(_ shortcutId: String) -> Bool {
        print("🧪 ShortcutManager: Testing shortcut \(shortcutId)")
        
        guard let shortcut = currentShortcuts.first(where: { $0.id == shortcutId }) else {
            print("❌ ShortcutManager: Shortcut not found: \(shortcutId)")
            return false
        }
        
        print("🎯 ShortcutManager: Found shortcut: \(shortcut.name) - \(shortcut.displayString)")
        
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
    
    func retryEventTapSetup() {
        print("🔄 ShortcutManager: Retrying event tap setup...")
        
        // Clean up existing event tap
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        
        // Try setting up again
        setupEventTap()
    }
    
    var isEventTapActive: Bool {
        guard let eventTap = eventTap else {
            print("❌ ShortcutManager: No event tap exists")
            return false
        }
        
        let isEnabled = CGEvent.tapIsEnabled(tap: eventTap)
        print("🔍 ShortcutManager: Event tap enabled: \(isEnabled)")
        return isEnabled
    }
    
    // MARK: - Private Methods
    
    private func setupEventTap() {
        print("🔧 ShortcutManager: Setting up event tap...")
        
        // Check accessibility permissions first
        if !checkAccessibilityPermissions() {
            print("⚠️ ShortcutManager: Accessibility permissions not granted")
            requestAccessibilityPermissions()
            return
        }
        
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
            print("❌ ShortcutManager: Failed to create event tap - need accessibility permissions?")
            requestAccessibilityPermissions()
            return
        }
        
        print("✅ ShortcutManager: Event tap created successfully")
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("🎯 ShortcutManager: Event tap enabled and running")
        print("📋 ShortcutManager: Registered shortcuts:")
        for shortcut in currentShortcuts {
            print("   - \(shortcut.name): \(shortcut.displayString) (keyCode: \(shortcut.keyCode), modifiers: \(shortcut.modifiers))")
        }
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        let checkOptionPrompt = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
        let options = [checkOptionPrompt: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    private func requestAccessibilityPermissions() {
        print("🔐 ShortcutManager: Requesting accessibility permissions...")
        let checkOptionPrompt = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
        let options = [checkOptionPrompt: true] as CFDictionary
        
        if !AXIsProcessTrustedWithOptions(options) {
            print("📝 ShortcutManager: Please grant accessibility permissions in System Settings")
            
            // Show alert to user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "Transcriptly needs accessibility permissions to use global keyboard shortcuts.\n\nPlease grant permission in System Settings > Privacy & Security > Accessibility."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Later")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    // Open System Settings to Accessibility pane
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
    
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }
        
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue))
        
        // Debug: Log only keydown events with modifiers
        if !modifiers.isEmpty {
            print("⌨️ ShortcutManager: Key event - keyCode: \(keyCode), modifiers: \(modifiers.rawValue)")
            
            // Check if this matches any of our shortcuts
            for shortcut in currentShortcuts {
                if shortcut.keyCode == keyCode && shortcut.eventModifiers == modifiers {
                    print("✅ ShortcutManager: Matched shortcut: \(shortcut.name) (\(shortcut.displayString))")
                    executeShortcutAction(shortcut.action)
                    return nil // Consume the event
                }
            }
            
            print("❌ ShortcutManager: No matching shortcut found")
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func executeShortcutAction(_ action: ShortcutAction) {
        print("🎬 ShortcutManager: Executing action: \(action)")
        Task { @MainActor in
            switch action {
            case .toggleRecording:
                print("📢 ShortcutManager: Posting toggleRecording notification")
                NotificationCenter.default.post(name: .toggleRecording, object: nil)
            case .switchMode(let mode):
                print("📢 ShortcutManager: Posting switchRefinementMode notification for mode: \(mode)")
                NotificationCenter.default.post(name: .switchRefinementMode, object: mode)
            case .cancelRecording:
                print("📢 ShortcutManager: Posting cancelRecording notification")
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
        // Letters
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        
        // Numbers
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        
        // Special keys
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow, 124: return "→"
        case kVK_DownArrow: return "↓"
        case kVK_UpArrow: return "↑"
        
        // Function keys
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
        
        default: return "Key \(keyCode)"
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