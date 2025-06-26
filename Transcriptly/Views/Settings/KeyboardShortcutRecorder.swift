//
//  KeyboardShortcutRecorder.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI
import AppKit

struct KeyboardShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: String
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    func makeNSView(context: Context) -> KeyboardRecorderView {
        let recorder = KeyboardRecorderView()
        recorder.delegate = context.coordinator
        return recorder
    }
    
    func updateNSView(_ nsView: KeyboardRecorderView, context: Context) {
        nsView.shortcutString = shortcut
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, KeyboardRecorderDelegate {
        let parent: KeyboardShortcutRecorder
        
        init(_ parent: KeyboardShortcutRecorder) {
            self.parent = parent
        }
        
        func recorderDidStartRecording() {
            parent.onStartRecording()
        }
        
        func recorderDidStopRecording() {
            parent.onStopRecording()
        }
        
        func recorder(didCaptureShortcut shortcut: String) {
            parent.shortcut = shortcut
        }
    }
}

protocol KeyboardRecorderDelegate: AnyObject {
    func recorderDidStartRecording()
    func recorderDidStopRecording()
    func recorder(didCaptureShortcut shortcut: String)
}

class KeyboardRecorderView: NSView {
    weak var delegate: KeyboardRecorderDelegate?
    var shortcutString: String = ""
    private var isRecording = false
    private var eventMonitor: Any?
    
    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }
    
    func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        delegate?.recorderDidStartRecording()
        
        // Make this view first responder to capture key events
        window?.makeFirstResponder(self)
        
        // Set up global event monitor for key events
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil // Consume the event
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        delegate?.recorderDidStopRecording()
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        window?.makeFirstResponder(nil)
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard isRecording else { return }
        
        // Ignore modifier-only events
        let keyCode = event.keyCode
        let modifierKeys: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62] // Various modifier keys
        if modifierKeys.contains(keyCode) {
            return
        }
        
        // Handle escape to cancel
        if keyCode == 53 { // Escape key
            stopRecording()
            return
        }
        
        // Build shortcut string
        let shortcut = buildShortcutString(from: event)
        
        // Validate shortcut (must have at least one modifier)
        if event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty {
            // Require at least one modifier key
            return
        }
        
        // Save the shortcut
        delegate?.recorder(didCaptureShortcut: shortcut)
        stopRecording()
    }
    
    private func buildShortcutString(from event: NSEvent) -> String {
        var parts: [String] = []
        
        // Add modifiers in standard order
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
        
        // Add the main key
        if let keyName = keyNameForKeyCode(event.keyCode) {
            parts.append(keyName)
        }
        
        return parts.joined()
    }
    
    private func keyNameForKeyCode(_ keyCode: UInt16) -> String? {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 50: return "`"
        case 53: return "⎋" // Escape
        case 36: return "↩" // Return
        case 48: return "⇥" // Tab
        case 49: return "Space"
        case 51: return "⌫" // Delete
        case 76: return "⌤" // Enter
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        default: return nil
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if isRecording {
            stopRecording()
        }
        super.mouseDown(with: event)
    }
}