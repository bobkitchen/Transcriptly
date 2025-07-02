//
//  KeyboardShortcutRecorder.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//
//  Rewritten with simpler, more reliable approach to avoid NSEventMonitor crashes
//

import SwiftUI
import AppKit
import Carbon

struct KeyboardShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: String
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    func makeNSView(context: Context) -> SimpleKeyRecorderView {
        let recorder = SimpleKeyRecorderView()
        recorder.onShortcutCaptured = { capturedShortcut in
            DispatchQueue.main.async {
                shortcut = capturedShortcut
                onStopRecording()
            }
        }
        recorder.onRecordingStateChanged = { isRecording in
            DispatchQueue.main.async {
                if isRecording {
                    onStartRecording()
                } else {
                    onStopRecording()
                }
            }
        }
        return recorder
    }
    
    func updateNSView(_ nsView: SimpleKeyRecorderView, context: Context) {
        // No updates needed
    }
}

// Simplified key recorder view that uses keyDown override instead of NSEventMonitor
class SimpleKeyRecorderView: NSView {
    var onShortcutCaptured: ((String) -> Void)?
    var onRecordingStateChanged: ((Bool) -> Void)?
    
    private var isRecording = false {
        didSet {
            if oldValue != isRecording {
                onRecordingStateChanged?(isRecording)
            }
        }
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Simple visual setup
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    func startRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
        needsDisplay = true
    }
    
    func stopRecording() {
        isRecording = false
        window?.makeFirstResponder(nil)
        needsDisplay = true
    }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        // Handle escape to cancel
        if event.keyCode == 53 { // Escape key
            stopRecording()
            return
        }
        
        // Check for modifier keys
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        
        // Require at least one modifier
        if modifiers.isEmpty {
            NSSound.beep()
            return
        }
        
        // Ignore modifier-only events
        if isModifierOnlyKeyCode(event.keyCode) {
            return
        }
        
        // Build and capture the shortcut
        if let shortcut = buildShortcutString(from: event) {
            onShortcutCaptured?(shortcut)
            stopRecording()
        }
    }
    
    private func isModifierOnlyKeyCode(_ keyCode: UInt16) -> Bool {
        let modifierKeyCodes: Set<UInt16> = [
            54, 55, 56, 57, 58, 59, 60, 61, 62, 63, // Various modifier keys
            UInt16(kVK_Command), UInt16(kVK_Shift), UInt16(kVK_CapsLock), UInt16(kVK_Option),
            UInt16(kVK_Control), UInt16(kVK_RightCommand), UInt16(kVK_RightShift),
            UInt16(kVK_RightOption), UInt16(kVK_RightControl), UInt16(kVK_Function)
        ]
        return modifierKeyCodes.contains(keyCode)
    }
    
    private func buildShortcutString(from event: NSEvent) -> String? {
        var parts: [String] = []
        
        // Add modifiers in standard macOS order
        if event.modifierFlags.contains(.control) {
            parts.append("⌃")
        }
        if event.modifierFlags.contains(.option) {
            parts.append("⌥")
        }
        if event.modifierFlags.contains(.shift) {
            parts.append("⇧")
        }
        if event.modifierFlags.contains(.command) {
            parts.append("⌘")
        }
        
        // Get the key name
        guard let keyName = keyNameForKeyCode(event.keyCode) else {
            return nil
        }
        
        parts.append(keyName)
        return parts.joined()
    }
    
    private func keyNameForKeyCode(_ keyCode: UInt16) -> String? {
        // Use a simplified mapping for common keys
        switch Int(keyCode) {
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
            
            // Special keys
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Space: return "Space"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_DownArrow: return "↓"
        case kVK_UpArrow: return "↑"
            
            // Punctuation
        case kVK_ANSI_Period: return "."
        case kVK_ANSI_Comma: return ","
        case kVK_ANSI_Slash: return "/"
        case kVK_ANSI_Semicolon: return ";"
        case kVK_ANSI_Quote: return "'"
        case kVK_ANSI_LeftBracket: return "["
        case kVK_ANSI_RightBracket: return "]"
        case kVK_ANSI_Backslash: return "\\"
        case kVK_ANSI_Minus: return "-"
        case kVK_ANSI_Equal: return "="
        case kVK_ANSI_Grave: return "`"
            
        default: 
            return nil
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if isRecording {
            stopRecording()
        } else {
            super.mouseDown(with: event)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Optional: Add visual feedback when recording
        if isRecording {
            NSColor.systemOrange.withAlphaComponent(0.1).setFill()
            dirtyRect.fill()
        }
    }
}