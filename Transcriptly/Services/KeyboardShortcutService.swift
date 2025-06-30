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
    
    // Hotkey IDs for different shortcuts
    private enum HotKeyID: UInt32 {
        case recording = 1
        case rawMode = 2
        case cleanupMode = 3
        case emailMode = 4
        case messagingMode = 5
    }
    
    // Dynamic shortcuts from UserDefaults
    private var recordingShortcut: String {
        UserDefaults.standard.string(forKey: "recordingShortcut") ?? "⌘⇧V"
    }
    private var rawModeShortcut: String {
        UserDefaults.standard.string(forKey: "rawModeShortcut") ?? "⌘1"
    }
    private var cleanupModeShortcut: String {
        UserDefaults.standard.string(forKey: "cleanupModeShortcut") ?? "⌘2"
    }
    private var emailModeShortcut: String {
        UserDefaults.standard.string(forKey: "emailModeShortcut") ?? "⌘3"
    }
    private var messagingModeShortcut: String {
        UserDefaults.standard.string(forKey: "messagingModeShortcut") ?? "⌘4"
    }
    
    init() {
        setupKeyboardShortcuts()
        
        // Listen for shortcut changes and reload
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Restart keyboard monitoring with new shortcuts
            self?.cleanup()
            self?.setupKeyboardShortcuts()
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
        // Clean up any existing hotkeys first
        cleanupCarbonHotkeys()
        
        // Install event handler
        let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        var eventSpecArray = [eventSpec]
        
        InstallEventHandler(GetApplicationEventTarget(), { (handlerCallRef, event, userData) -> OSStatus in
            guard let userData = userData, let event = event else { return OSStatus(eventNotHandledErr) }
            let service = Unmanaged<KeyboardShortcutService>.fromOpaque(userData).takeUnretainedValue()
            return service.handleCarbonHotKeyEvent(event)
        }, 1, &eventSpecArray, Unmanaged.passUnretained(self).toOpaque(), &hotKeyEventHandler)
        
        // Register individual hotkeys
        registerHotkey(recordingShortcut, id: .recording)
        registerHotkey(rawModeShortcut, id: .rawMode)
        registerHotkey(cleanupModeShortcut, id: .cleanupMode)
        registerHotkey(emailModeShortcut, id: .emailMode)
        registerHotkey(messagingModeShortcut, id: .messagingMode)
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
        let carbonModifiers = nsFlagsToCarbonModifiers(parsed.modifiers)
        let carbonKeyCode = UInt32(parsed.keyCode)
        
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: fourCharCodeFrom("TRNS"), id: id.rawValue)
        
        let status = RegisterEventHotKey(carbonKeyCode, carbonModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr, let hotKey = hotKeyRef {
            hotKeyRefs.append(hotKey)
        } else {
            print("Failed to register hotkey: \(shortcutString), status: \(status)")
        }
    }
    
    private func handleCarbonHotKeyEvent(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
        
        guard status == noErr else { return OSStatus(eventNotHandledErr) }
        
        // Safely dispatch to main queue only if not already on main thread
        if Thread.isMainThread {
            switch HotKeyID(rawValue: hotKeyID.id) {
            case .recording:
                onShortcutPressed?()
            case .rawMode:
                onModeChangePressed?(.raw)
            case .cleanupMode:
                onModeChangePressed?(.cleanup)
            case .emailMode:
                onModeChangePressed?(.email)
            case .messagingMode:
                onModeChangePressed?(.messaging)
            case .none:
                break
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch HotKeyID(rawValue: hotKeyID.id) {
                case .recording:
                    self.onShortcutPressed?()
                case .rawMode:
                    self.onModeChangePressed?(.raw)
                case .cleanupMode:
                    self.onModeChangePressed?(.cleanup)
                case .emailMode:
                    self.onModeChangePressed?(.email)
                case .messagingMode:
                    self.onModeChangePressed?(.messaging)
                case .none:
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
}