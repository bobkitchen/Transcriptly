//
//  ConflictDetector.swift
//  Transcriptly
//
//  Created by Claude Code on 8/6/25.
//

import Foundation
import AppKit
import Combine
import SwiftUI

struct ConflictInfo: Identifiable {
    let id = UUID()
    let shortcut: String
    let applicationName: String
    let conflictType: ConflictType
    
    enum ConflictType {
        case system
        case application
    }
    
    var severity: ConflictSeverity {
        switch conflictType {
        case .system:
            return .high
        case .application:
            return .medium
        }
    }
}

enum ConflictSeverity {
    case low
    case medium
    case high
    
    var color: Color {
        switch self {
        case .low:
            return .yellow
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

class ConflictDetector: ObservableObject {
    @Published var conflicts: [ConflictInfo] = []
    
    func detectConflicts(_ shortcut: String) -> [ConflictInfo] {
        return Self.checkForConflicts(shortcut)
    }
    
    func detectConflicts(keyCode: Int, modifiers: NSEvent.ModifierFlags) async -> [ConflictInfo] {
        // Convert keyCode and modifiers to string representation
        let shortcut = keyComboToString(keyCode: keyCode, modifiers: modifiers)
        return Self.checkForConflicts(shortcut)
    }
    
    private func keyComboToString(keyCode: Int, modifiers: NSEvent.ModifierFlags) -> String {
        var result = ""
        if modifiers.contains(.command) { result += "⌘" }
        if modifiers.contains(.shift) { result += "⇧" }
        if modifiers.contains(.option) { result += "⌥" }
        if modifiers.contains(.control) { result += "⌃" }
        
        // Simple keyCode to character mapping
        let keyChar: String
        switch keyCode {
        case 0: keyChar = "A"
        case 1: keyChar = "S"
        case 2: keyChar = "D"
        case 3: keyChar = "F"
        case 4: keyChar = "H"
        case 5: keyChar = "G"
        case 6: keyChar = "Z"
        case 7: keyChar = "X"
        case 8: keyChar = "C"
        case 9: keyChar = "V"
        case 11: keyChar = "B"
        case 12: keyChar = "Q"
        case 13: keyChar = "W"
        case 14: keyChar = "E"
        case 15: keyChar = "R"
        case 17: keyChar = "T"
        case 31: keyChar = "O"
        case 32: keyChar = "U"
        case 34: keyChar = "I"
        case 35: keyChar = "P"
        case 37: keyChar = "L"
        case 38: keyChar = "J"
        case 40: keyChar = "K"
        case 45: keyChar = "N"
        case 46: keyChar = "M"
        default: keyChar = String(keyCode)
        }
        
        return result + keyChar
    }
    
    static func checkForConflicts(_ shortcut: String) -> [ConflictInfo] {
        // Placeholder implementation
        // In a real implementation, this would check system shortcuts and other apps
        var conflicts: [ConflictInfo] = []
        
        // Check common system shortcuts
        let systemShortcuts = ["⌘Q", "⌘W", "⌘A", "⌘S", "⌘D", "⌘F", "⌘Z", "⌘X", "⌘C", "⌘V"]
        if systemShortcuts.contains(shortcut) {
            conflicts.append(ConflictInfo(
                shortcut: shortcut,
                applicationName: "System",
                conflictType: .system
            ))
        }
        
        return conflicts
    }
}