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
        case kVK_ANSI_R: return "R"
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