//
//  SafeShortcutRecorder.swift
//  Transcriptly
//
//  A safer implementation of shortcut recording that avoids NSView drawing crashes
//

import SwiftUI
import AppKit
import Carbon

struct SafeShortcutRecorder: View {
    @Binding var shortcut: String
    @State private var isRecording = false
    @State private var recordedShortcut = ""
    
    var body: some View {
        HStack {
            if isRecording {
                Text("Press shortcut keys...")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.orange)
                    .frame(minWidth: 150)
                    .padding(.horizontal, DesignSystem.spacingMedium)
                    .padding(.vertical, DesignSystem.spacingSmall)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(DesignSystem.cornerRadiusSmall)
                    .onAppear {
                        startRecording()
                    }
                    .onDisappear {
                        stopRecording()
                    }
            } else {
                Text(shortcut)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primaryText)
                    .frame(minWidth: 150)
                    .padding(.horizontal, DesignSystem.spacingMedium)
                    .padding(.vertical, DesignSystem.spacingSmall)
                    .liquidGlassBackground(
                        material: .ultraThinMaterial,
                        cornerRadius: DesignSystem.cornerRadiusSmall
                    )
            }
            
            Button(isRecording ? "Cancel" : "Edit") {
                if isRecording {
                    stopRecording()
                    isRecording = false
                } else {
                    isRecording = true
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
        }
    }
    
    private func startRecording() {
        SafeShortcutMonitor.shared.startRecording { capturedShortcut in
            DispatchQueue.main.async {
                if !capturedShortcut.isEmpty {
                    self.shortcut = capturedShortcut
                    self.recordedShortcut = capturedShortcut
                }
                self.isRecording = false
            }
        }
    }
    
    private func stopRecording() {
        SafeShortcutMonitor.shared.stopRecording()
    }
}

// Singleton monitor to handle shortcut recording safely
class SafeShortcutMonitor {
    static let shared = SafeShortcutMonitor()
    
    private var eventMonitor: Any?
    private var completion: ((String) -> Void)?
    
    private init() {}
    
    func startRecording(completion: @escaping (String) -> Void) {
        self.completion = completion
        
        // Stop any existing monitor
        stopRecording()
        
        // Create a local event monitor
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self else { return event }
            
            // Handle escape to cancel
            if event.keyCode == 53 { // Escape key
                self.stopRecording()
                self.completion?("")
                return nil
            }
            
            // Check for modifier keys
            let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
            
            // Require at least one modifier
            if modifiers.isEmpty {
                NSSound.beep()
                return nil
            }
            
            // Build shortcut string
            if let shortcutString = self.buildShortcutString(keyCode: Int(event.keyCode), modifiers: modifiers) {
                self.stopRecording()
                self.completion?(shortcutString)
                return nil
            }
            
            return event
        }
    }
    
    func stopRecording() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        completion = nil
    }
    
    private func buildShortcutString(keyCode: Int, modifiers: NSEvent.ModifierFlags) -> String? {
        var parts: [String] = []
        
        // Add modifiers in standard macOS order
        if modifiers.contains(.control) {
            parts.append("⌃")
        }
        if modifiers.contains(.option) {
            parts.append("⌥")
        }
        if modifiers.contains(.shift) {
            parts.append("⇧")
        }
        if modifiers.contains(.command) {
            parts.append("⌘")
        }
        
        // Get the key name
        guard let keyName = keyNameForKeyCode(keyCode) else {
            return nil
        }
        
        parts.append(keyName)
        return parts.joined()
    }
    
    private func keyNameForKeyCode(_ keyCode: Int) -> String? {
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
}