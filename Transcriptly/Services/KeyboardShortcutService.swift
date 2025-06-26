//
//  KeyboardShortcutService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import Foundation
import AppKit
import Combine

final class KeyboardShortcutService: ObservableObject {
    var onShortcutPressed: (() -> Void)?
    
    init() {
        setupKeyboardShortcut()
    }
    
    private func setupKeyboardShortcut() {
        // Set up a local keyboard monitor for the app
        // This will work when the app has focus
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.isRecordingShortcut(event) == true {
                self?.onShortcutPressed?()
                return nil // Consume the event
            }
            return event
        }
    }
    
    private func isRecordingShortcut(_ event: NSEvent) -> Bool {
        // Check for Cmd+Shift+V
        let hasCmd = event.modifierFlags.contains(.command)
        let hasShift = event.modifierFlags.contains(.shift)
        let isVKey = event.charactersIgnoringModifiers?.lowercased() == "v"
        
        return hasCmd && hasShift && isVKey
    }
}