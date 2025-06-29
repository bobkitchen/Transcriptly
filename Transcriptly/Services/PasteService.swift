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
        print("📋 PasteService.copyTextToClipboard() called with: '\(text.prefix(50))...'")
        guard !text.isEmpty else { 
            print("   ❌ Text is empty, skipping")
            return 
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let success = pasteboard.setString(text, forType: .string)
        print("   📋 Clipboard set result: \(success)")
        
        DispatchQueue.main.async {
            if success {
                self.lastCopiedText = text
                self.clipboardError = nil
                print("   ✅ Text successfully copied to clipboard")
            } else {
                self.clipboardError = "Failed to copy text to clipboard"
                print("   ❌ Failed to copy text to clipboard")
            }
        }
    }
    
    func pasteAtCursorLocation() async -> Bool {
        print("📝 PasteService.pasteAtCursorLocation() called")
        
        // Small delay to ensure clipboard is set and app is ready
        print("   ⏱️ Waiting 0.1s for clipboard to be ready...")
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Get the current text from clipboard
        let pasteboard = NSPasteboard.general
        guard let clipboardText = pasteboard.string(forType: .string), !clipboardText.isEmpty else {
            print("   ❌ No text in clipboard or clipboard empty")
            DispatchQueue.main.async {
                self.clipboardError = "No text in clipboard to paste"
            }
            return false
        }
        
        print("   📋 Clipboard contains: '\(clipboardText.prefix(50))...'")
        
        // Simulate paste operation using accessibility APIs
        print("   ⌨️ Simulating keyboard paste...")
        return await simulateKeyboardPaste()
    }
    
    private func simulateKeyboardPaste() async -> Bool {
        print("   🎯 Creating keyboard events for Cmd+V...")
        
        // This approach simulates Cmd+V to paste at the current cursor location
        // It works with most applications that support standard paste operations
        
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true), // 'V' key
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false) else {
            print("   ❌ Failed to create keyboard events")
            await MainActor.run {
                self.clipboardError = "Failed to create paste keyboard events"
            }
            return false
        }
        
        // Add Cmd modifier
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        
        print("   ⌨️ Posting Cmd+V key down...")
        // Post the key events with a small delay between them
        keyDown.post(tap: .cghidEventTap)
        
        // Small delay between key down and key up
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        print("   ⌨️ Posting Cmd+V key up...")
        keyUp.post(tap: .cghidEventTap)
        
        print("   ✅ Keyboard paste simulation completed")
        
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