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
        // This approach simulates Cmd+V to paste at the current cursor location
        // It works with most applications that support standard paste operations
        
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true) // 'V' key
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false)
        
        // Add Cmd modifier
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        // Post the key events
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        
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