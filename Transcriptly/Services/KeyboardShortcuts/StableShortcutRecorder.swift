//
//  StableShortcutRecorder.swift
//  Transcriptly
//
//  A stable implementation of keyboard shortcut recording that avoids common crashes
//

import SwiftUI
import AppKit
import Carbon

struct StableShortcutRecorder: View {
    @Binding var keyCode: Int
    @Binding var modifiers: NSEvent.ModifierFlags
    let onShortcutChange: (Int, NSEvent.ModifierFlags) -> Void
    
    @State private var isRecording = false
    @State private var displayText = ""
    @State private var monitor: Any?
    
    var body: some View {
        HStack(spacing: 8) {
            // Display current shortcut or recording state
            Text(displayText.isEmpty ? formatShortcut() : displayText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(isRecording ? .orange : .primaryText)
                .frame(minWidth: 150, alignment: .center)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRecording ? Color.orange.opacity(0.1) : Color.secondary.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.orange : Color.clear, lineWidth: 2)
                )
            
            // Record button
            Button(action: toggleRecording) {
                Text(isRecording ? "Stop" : "Record")
                    .foregroundColor(isRecording ? .orange : .accentColor)
            }
            .buttonStyle(.plain)
            
            // Clear button
            if keyCode > 0 && !isRecording {
                Button(action: clearShortcut) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        displayText = "Press shortcut keys..."
        
        // Use local monitor for in-app recording
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            return self.handleKeyEvent(event) ? nil : event
        }
    }
    
    private func stopRecording() {
        isRecording = false
        displayText = ""
        
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard isRecording else { return false }
        
        // Handle escape to cancel
        if event.keyCode == 53 { // Escape
            stopRecording()
            return true
        }
        
        // Only process keyDown events with modifiers
        if event.type == .keyDown {
            let mods = event.modifierFlags.intersection([.command, .option, .shift, .control])
            
            // Require at least one modifier
            if !mods.isEmpty {
                // Update the binding
                keyCode = Int(event.keyCode)
                modifiers = mods
                onShortcutChange(keyCode, modifiers)
                
                // Stop recording
                stopRecording()
                return true
            } else {
                // Beep if no modifiers
                NSSound.beep()
                return true
            }
        }
        
        return false
    }
    
    private func clearShortcut() {
        keyCode = 0
        modifiers = []
        onShortcutChange(0, [])
    }
    
    private func formatShortcut() -> String {
        guard keyCode > 0 else {
            return "Click to set"
        }
        
        var parts: [String] = []
        
        // Add modifiers in standard order
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        
        // Add key
        parts.append(keyCodeToString(keyCode))
        
        return parts.joined()
    }
    
    private func keyCodeToString(_ code: Int) -> String {
        switch code {
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
        case kVK_RightArrow: return "→"
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
        
        default: return "Key \(code)"
        }
    }
}

// Alternative pure SwiftUI implementation for testing
struct SimpleShortcutField: View {
    @Binding var shortcutString: String
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            if isEditing {
                TextField("Press shortcut...", text: $shortcutString)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                    .onSubmit {
                        isEditing = false
                    }
            } else {
                Text(shortcutString.isEmpty ? "Not Set" : shortcutString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primaryText)
                    .frame(minWidth: 150)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                    .onTapGesture {
                        isEditing = true
                    }
            }
            
            Button(isEditing ? "Done" : "Edit") {
                isEditing.toggle()
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
        }
    }
}