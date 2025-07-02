//
//  KeyboardShortcutService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import Foundation
import AppKit
import Combine
import Carbon

final class KeyboardShortcutService: ObservableObject {
    var onShortcutPressed: (() -> Void)?
    var onModeChangePressed: ((RefinementMode) -> Void)?
    var onCancelPressed: (() -> Void)?
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isRecording: Bool = false
    
    // Carbon hotkey registration
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var hotKeyEventHandler: EventHandlerRef?
    
    // Track which shortcuts have shown conflict notifications
    private var notifiedShortcuts = Set<String>()
    
    // Track if we're currently registering to prevent re-entrancy
    private var isRegistering = false
    
    // Track if we've shown the conflict dialog this session
    private var hasShownConflictDialog = false
    
    // Hotkey IDs for different shortcuts
    private enum HotKeyID: UInt32 {
        case recording = 1
        case rawMode = 2
        case cleanupMode = 3
        case emailMode = 4
        case messagingMode = 5
    }
    
    // Dynamic shortcuts from UserDefaults - Changed to ⌘⌥ to avoid conflicts
    private var recordingShortcut: String {
        let saved = UserDefaults.standard.string(forKey: "recordingShortcut") ?? "⌘⌥V"
        // Filter out invalid shortcuts
        if saved == "⌘→" || saved.contains("→") {
            // Reset to default if invalid
            UserDefaults.standard.set("⌘⌥V", forKey: "recordingShortcut")
            return "⌘⌥V"
        }
        return saved
    }
    private var rawModeShortcut: String {
        let saved = UserDefaults.standard.string(forKey: "rawModeShortcut") ?? "⌘⌥1"
        if saved.contains("→") || saved.contains("←") {
            UserDefaults.standard.set("⌘⌥1", forKey: "rawModeShortcut")
            return "⌘⌥1"
        }
        return saved
    }
    private var cleanupModeShortcut: String {
        let saved = UserDefaults.standard.string(forKey: "cleanupModeShortcut") ?? "⌘⌥2"
        if saved.contains("→") || saved.contains("←") {
            UserDefaults.standard.set("⌘⌥2", forKey: "cleanupModeShortcut")
            return "⌘⌥2"
        }
        return saved
    }
    private var emailModeShortcut: String {
        let saved = UserDefaults.standard.string(forKey: "emailModeShortcut") ?? "⌘⌥3"
        if saved.contains("→") || saved.contains("←") {
            UserDefaults.standard.set("⌘⌥3", forKey: "emailModeShortcut")
            return "⌘⌥3"
        }
        return saved
    }
    private var messagingModeShortcut: String {
        let saved = UserDefaults.standard.string(forKey: "messagingModeShortcut") ?? "⌘⌥4"
        if saved.contains("→") || saved.contains("←") {
            UserDefaults.standard.set("⌘⌥4", forKey: "messagingModeShortcut")
            return "⌘⌥4"
        }
        return saved
    }
    
    init() {
        // One-time migration to new shortcuts if still using old ones
        migrateOldShortcutsIfNeeded()
        
        setupKeyboardShortcuts()
        
        // Track if we're currently updating to prevent loops
        var isUpdating = false
        
        // Listen for shortcut changes and reload
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, !isUpdating else { return }
            
            // Check if any keyboard shortcut keys changed
            guard let userInfo = notification.userInfo,
                  let changedKeys = userInfo["NSUserDefaultsChangedKeys"] as? [String],
                  changedKeys.contains(where: { $0.contains("Shortcut") }) else {
                return
            }
            
            // Prevent re-entrancy
            isUpdating = true
            
            // Restart keyboard monitoring with new shortcuts
            self.cleanup()
            self.setupKeyboardShortcuts()
            
            isUpdating = false
        }
    }
    
    private func migrateOldShortcutsIfNeeded() {
        // Check if we need to migrate from old ⌘⇧ shortcuts to new ⌘⌥ shortcuts
        let needsMigration = UserDefaults.standard.string(forKey: "recordingShortcut") == "⌘⇧V" ||
                           UserDefaults.standard.string(forKey: "recordingShortcut") == nil
        
        if needsMigration {
            print("Migrating to new keyboard shortcuts to avoid conflicts...")
            UserDefaults.standard.set("⌘⌥V", forKey: "recordingShortcut")
            UserDefaults.standard.set("⌘⌥1", forKey: "rawModeShortcut")
            UserDefaults.standard.set("⌘⌥2", forKey: "cleanupModeShortcut")
            UserDefaults.standard.set("⌘⌥3", forKey: "emailModeShortcut")
            UserDefaults.standard.set("⌘⌥4", forKey: "messagingModeShortcut")
            UserDefaults.standard.synchronize()
        }
    }
    
    deinit {
        cleanup()
        NotificationCenter.default.removeObserver(self)
    }
    
    func setRecordingState(_ recording: Bool) {
        isRecording = recording
    }
    
    private func setupKeyboardShortcuts() {
        // Register Carbon hotkeys for system-wide functionality
        setupCarbonHotkeys()
        
        // Keep local monitor for escape key during recording
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            // Handle escape key for cancel (only during recording)
            if self.isRecording && self.isEscapeKey(event) {
                self.onCancelPressed?()
                return nil // Consume the event
            }
            
            return event
        }
    }
    
    private func cleanup() {
        // Unregister Carbon hotkeys
        cleanupCarbonHotkeys()
        
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }
    
    private func isRecordingShortcut(_ event: NSEvent) -> Bool {
        return isShortcutMatch(event, shortcutString: recordingShortcut)
    }
    
    private func getModeFromShortcut(_ event: NSEvent) -> RefinementMode? {
        if isShortcutMatch(event, shortcutString: rawModeShortcut) {
            return .raw
        } else if isShortcutMatch(event, shortcutString: cleanupModeShortcut) {
            return .cleanup
        } else if isShortcutMatch(event, shortcutString: emailModeShortcut) {
            return .email
        } else if isShortcutMatch(event, shortcutString: messagingModeShortcut) {
            return .messaging
        }
        return nil
    }
    
    private func isEscapeKey(_ event: NSEvent) -> Bool {
        return event.keyCode == 53 // Escape key code
    }
    
    private func isShortcutMatch(_ event: NSEvent, shortcutString: String) -> Bool {
        let parsedShortcut = parseShortcutString(shortcutString)
        
        // Check modifiers
        let eventModifiers = event.modifierFlags.intersection([.command, .option, .shift, .control])
        if eventModifiers != parsedShortcut.modifiers {
            return false
        }
        
        // Check key
        return event.keyCode == parsedShortcut.keyCode
    }
    
    private func parseShortcutString(_ shortcutString: String) -> (modifiers: NSEvent.ModifierFlags, keyCode: UInt16) {
        var modifiers: NSEvent.ModifierFlags = []
        var keyChar: String = ""
        
        // Parse modifiers and extract the key
        for char in shortcutString {
            switch char {
            case "⌘":
                modifiers.insert(.command)
            case "⇧":
                modifiers.insert(.shift)
            case "⌥":
                modifiers.insert(.option)
            case "⌃":
                modifiers.insert(.control)
            default:
                keyChar += String(char)
            }
        }
        
        // Convert key character to key code
        let keyCode = keyCodeForCharacter(keyChar)
        
        return (modifiers, keyCode)
    }
    
    private func keyCodeForCharacter(_ char: String) -> UInt16 {
        switch char.uppercased() {
        case "A": return 0
        case "S": return 1
        case "D": return 2
        case "F": return 3
        case "H": return 4
        case "G": return 5
        case "Z": return 6
        case "X": return 7
        case "C": return 8
        case "V": return 9
        case "B": return 11
        case "Q": return 12
        case "W": return 13
        case "E": return 14
        case "R": return 15
        case "Y": return 16
        case "T": return 17
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "6": return 22
        case "5": return 23
        case "=": return 24
        case "9": return 25
        case "7": return 26
        case "-": return 27
        case "8": return 28
        case "0": return 29
        case "]": return 30
        case "O": return 31
        case "U": return 32
        case "[": return 33
        case "I": return 34
        case "P": return 35
        case "L": return 37
        case "J": return 38
        case "'": return 39
        case "K": return 40
        case ";": return 41
        case "\\": return 42
        case ",": return 43
        case "/": return 44
        case "N": return 45
        case "M": return 46
        case ".": return 47
        case "`": return 50
        case "SPACE": return 49
        case "⎋": return 53 // Escape
        case "↩": return 36 // Return
        case "⇥": return 48 // Tab
        case "⌫": return 51 // Delete
        case "⌤": return 76 // Enter
        case "←": return 123
        case "→": return 124
        case "↓": return 125
        case "↑": return 126
        case "F1": return 122
        case "F2": return 120
        case "F3": return 99
        case "F4": return 118
        case "F5": return 96
        case "F6": return 97
        case "F7": return 98
        case "F8": return 100
        case "F9": return 101
        case "F10": return 109
        case "F11": return 103
        case "F12": return 111
        default: return 0 // Unknown key
        }
    }
    
    // MARK: - Carbon Hotkey Management
    
    private func setupCarbonHotkeys() {
        // Prevent re-entrancy
        guard !isRegistering else { 
            print("Already registering hotkeys, skipping...")
            return 
        }
        
        isRegistering = true
        defer { isRegistering = false }
        
        // Clean up any existing hotkeys first
        cleanupCarbonHotkeys()
        
        // Clear the notified shortcuts for fresh registration attempt
        notifiedShortcuts.removeAll()
        
        // Install event handler only if not already installed
        if hotKeyEventHandler == nil {
            let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
            var eventSpecArray = [eventSpec]
            
            InstallEventHandler(GetApplicationEventTarget(), { (handlerCallRef, event, userData) -> OSStatus in
                guard let userData = userData, let event = event else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<KeyboardShortcutService>.fromOpaque(userData).takeUnretainedValue()
                return service.handleCarbonHotKeyEvent(event)
            }, 1, &eventSpecArray, Unmanaged.passUnretained(self).toOpaque(), &hotKeyEventHandler)
        }
        
        // Register individual hotkeys
        print("Registering hotkeys:")
        print("  Recording: \(recordingShortcut)")
        print("  Raw mode: \(rawModeShortcut)")
        print("  Cleanup mode: \(cleanupModeShortcut)")
        print("  Email mode: \(emailModeShortcut)")
        print("  Messaging mode: \(messagingModeShortcut)")
        
        registerHotkey(recordingShortcut, id: .recording)
        registerHotkey(rawModeShortcut, id: .rawMode)
        registerHotkey(cleanupModeShortcut, id: .cleanupMode)
        registerHotkey(emailModeShortcut, id: .emailMode)
        registerHotkey(messagingModeShortcut, id: .messagingMode)
        
        // Show a single notification if any shortcuts failed (only once per app launch)
        if !notifiedShortcuts.isEmpty && !hasShownConflictDialog {
            hasShownConflictDialog = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showKeyboardShortcutConflictNotification(shortcut: self.notifiedShortcuts.first ?? "")
            }
        }
    }
    
    private func cleanupCarbonHotkeys() {
        // Unregister all hotkeys
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()
        
        // Remove event handler
        if let handler = hotKeyEventHandler {
            RemoveEventHandler(handler)
            hotKeyEventHandler = nil
        }
    }
    
    private func registerHotkey(_ shortcutString: String, id: HotKeyID) {
        let parsed = parseShortcutString(shortcutString)
        
        // Skip registration if key code is 0 (unknown key)
        if parsed.keyCode == 0 {
            print("Skipping registration of unknown hotkey: \(shortcutString)")
            return
        }
        
        let carbonModifiers = nsFlagsToCarbonModifiers(parsed.modifiers)
        let carbonKeyCode = UInt32(parsed.keyCode)
        
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: fourCharCodeFrom("TRNS"), id: id.rawValue)
        
        let status = RegisterEventHotKey(carbonKeyCode, carbonModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr, let hotKey = hotKeyRef {
            hotKeyRefs.append(hotKey)
            print("Successfully registered hotkey: \(shortcutString)")
        } else {
            let errorMessage = getHotkeyErrorMessage(status)
            print("Failed to register hotkey: \(shortcutString), status: \(status) - \(errorMessage)")
            
            // If it's a duplicate error, track it for later notification
            if status == -9878 {
                print("  ⚠️  This keyboard shortcut is already in use by macOS or another app.")
                print("  ⚠️  Please check System Settings → Keyboard → Keyboard Shortcuts")
                print("  ⚠️  Or try using a different combination like ⌘⌥ instead of ⌘⇧")
                
                // Track this shortcut as failed
                notifiedShortcuts.insert(shortcutString)
            }
        }
    }
    
    private func getHotkeyErrorMessage(_ status: OSStatus) -> String {
        switch status {
        case -9878:
            return "Hotkey already registered (duplicate)"
        case -9860:
            return "Invalid hotkey combination"
        case -9870:
            return "Hotkey disabled by user"
        default:
            return "Unknown error"
        }
    }
    
    private func handleCarbonHotKeyEvent(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
        
        guard status == noErr else { 
            print("Failed to get hotkey parameter from event")
            return OSStatus(eventNotHandledErr) 
        }
        
        print("Received hotkey event with ID: \(hotKeyID.id)")
        
        // Safely dispatch to main queue only if not already on main thread
        if Thread.isMainThread {
            switch HotKeyID(rawValue: hotKeyID.id) {
            case .recording:
                print("Recording hotkey triggered")
                onShortcutPressed?()
            case .rawMode:
                print("Raw mode hotkey triggered")
                onModeChangePressed?(.raw)
            case .cleanupMode:
                print("Cleanup mode hotkey triggered")
                onModeChangePressed?(.cleanup)
            case .emailMode:
                print("Email mode hotkey triggered")
                onModeChangePressed?(.email)
            case .messagingMode:
                print("Messaging mode hotkey triggered")
                onModeChangePressed?(.messaging)
            case .none:
                print("Unknown hotkey ID: \(hotKeyID.id)")
                break
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch HotKeyID(rawValue: hotKeyID.id) {
                case .recording:
                    print("Recording hotkey triggered (async)")
                    self.onShortcutPressed?()
                case .rawMode:
                    print("Raw mode hotkey triggered (async)")
                    self.onModeChangePressed?(.raw)
                case .cleanupMode:
                    print("Cleanup mode hotkey triggered (async)")
                    self.onModeChangePressed?(.cleanup)
                case .emailMode:
                    print("Email mode hotkey triggered (async)")
                    self.onModeChangePressed?(.email)
                case .messagingMode:
                    print("Messaging mode hotkey triggered (async)")
                    self.onModeChangePressed?(.messaging)
                case .none:
                    print("Unknown hotkey ID: \(hotKeyID.id)")
                    break
                }
            }
        }
        
        return OSStatus(noErr)
    }
    
    private func nsFlagsToCarbonModifiers(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonModifiers: UInt32 = 0
        
        if flags.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if flags.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        if flags.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if flags.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        
        return carbonModifiers
    }
    
    private func fourCharCodeFrom(_ string: String) -> FourCharCode {
        let utf8 = string.utf8
        var code: FourCharCode = 0
        for (i, byte) in utf8.enumerated() {
            if i >= 4 { break }
            code = (code << 8) + FourCharCode(byte)
        }
        return code
    }
    
    private func showKeyboardShortcutConflictNotification(shortcut: String) {
        let alert = NSAlert()
        alert.messageText = "Keyboard Shortcuts Need Configuration"
        alert.informativeText = "Some keyboard shortcuts couldn't be registered. This usually happens when:\n\n• Another app is using the same shortcuts\n• macOS system shortcuts are conflicting\n• The app was previously opened\n\nThe app will still work with the available shortcuts. You can change them in Settings if needed."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open Settings")
        
        if alert.runModal() == .alertSecondButtonReturn {
            // Open settings
            NotificationCenter.default.post(name: Notification.Name("OpenSettings"), object: nil)
        }
    }
    
}