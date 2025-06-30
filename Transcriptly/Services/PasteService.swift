//
//  PasteService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import Foundation
import AppKit
import Combine

final class PasteService: ObservableObject {
    @Published var lastCopiedText: String = ""
    @Published var clipboardError: String?
    
    init() {
        // Initialize service
    }
    
    func copyTextToClipboard(_ text: String) {
        guard !text.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let success = pasteboard.setString(text, forType: .string)
        
        DispatchQueue.main.async {
            if success {
                self.lastCopiedText = text
                self.clipboardError = nil
            } else {
                self.clipboardError = "Failed to copy text to clipboard"
            }
        }
    }
    
    func pasteAtCursorLocation() async -> Bool {
        // Small delay to ensure clipboard is set and app is ready
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Get the current text from clipboard
        let pasteboard = NSPasteboard.general
        guard let clipboardText = pasteboard.string(forType: .string), !clipboardText.isEmpty else {
            DispatchQueue.main.async {
                self.clipboardError = "No text in clipboard to paste"
            }
            return false
        }
        
        // Simulate paste operation using accessibility APIs
        return await simulateKeyboardPaste()
    }
    
    private func simulateKeyboardPaste() async -> Bool {
        // Check if we have accessibility permissions
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessibilityEnabled {
            await MainActor.run {
                self.clipboardError = "Accessibility permissions required for auto-paste. Please grant permission in System Settings."
            }
            print("❌ Accessibility permissions not granted")
            return false
        }
        
        print("✅ Accessibility permissions granted, attempting paste...")
        
        // This approach simulates Cmd+V to paste at the current cursor location
        // It works with most applications that support standard paste operations
        
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true), // 'V' key
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false) else {
            await MainActor.run {
                self.clipboardError = "Failed to create paste keyboard events"
            }
            print("❌ Failed to create CGEvent objects")
            return false
        }
        
        // Add Cmd modifier
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        
        print("🎹 Posting keyboard events...")
        
        // Post the key events with a small delay between them
        keyDown.post(tap: .cghidEventTap)
        
        // Small delay between key down and key up
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        keyUp.post(tap: .cghidEventTap)
        
        print("✅ Keyboard events posted successfully")
        
        await MainActor.run {
            clipboardError = nil
        }
        
        return true
    }
    
    func clearClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        DispatchQueue.main.async {
            self.lastCopiedText = ""
            self.clipboardError = nil
        }
    }
    
    var hasClipboardText: Bool {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string) != nil
    }
    
    var clipboardText: String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
}