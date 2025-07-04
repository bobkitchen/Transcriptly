//
//  ConflictDetector.swift
//  Transcriptly
//
//  Detects keyboard shortcut conflicts with system and app shortcuts
//

import Cocoa
import ApplicationServices
import SwiftUI
import Carbon
import Combine

@MainActor
class ConflictDetector: ObservableObject {
    
    func detectConflicts(keyCode: Int, modifiers: NSEvent.ModifierFlags) async -> [ConflictInfo] {
        var conflicts: [ConflictInfo] = []
        
        // Check system shortcuts
        let systemConflicts = checkSystemShortcuts(keyCode: keyCode, modifiers: modifiers)
        conflicts.append(contentsOf: systemConflicts)
        
        // Check running applications
        let appConflicts = await checkRunningApplications(keyCode: keyCode, modifiers: modifiers)
        conflicts.append(contentsOf: appConflicts)
        
        return conflicts
    }
    
    private func checkSystemShortcuts(keyCode: Int, modifiers: NSEvent.ModifierFlags) -> [ConflictInfo] {
        var conflicts: [ConflictInfo] = []
        
        // Known system shortcuts that commonly conflict
        let systemShortcuts: [(Int, NSEvent.ModifierFlags, String, String)] = [
            (kVK_Space, [.command], "Spotlight", "Show Spotlight search"),
            (kVK_Tab, [.command], "System", "Switch between applications"),
            (kVK_ANSI_W, [.command], "System", "Close window"),
            (kVK_ANSI_Q, [.command], "System", "Quit application"),
            (kVK_ANSI_N, [.command], "System", "New window/document"),
            (kVK_ANSI_S, [.command], "System", "Save"),
            (kVK_ANSI_A, [.command], "System", "Select all"),
            (kVK_ANSI_C, [.command], "System", "Copy"),
            (kVK_ANSI_V, [.command], "System", "Paste"),
            (kVK_ANSI_Z, [.command], "System", "Undo"),
            (kVK_ANSI_3, [.command, .shift], "System", "Screenshot selected area"),
            (kVK_ANSI_4, [.command, .shift], "System", "Screenshot to clipboard"),
            (kVK_ANSI_5, [.command, .shift], "System", "Screenshot or recording options")
        ]
        
        for (sysKeyCode, sysModifiers, app, description) in systemShortcuts {
            if sysKeyCode == keyCode && sysModifiers == modifiers {
                conflicts.append(ConflictInfo(
                    appName: app,
                    shortcutDescription: description,
                    severity: .high,
                    canBeDisabled: app != "System"
                ))
            }
        }
        
        return conflicts
    }
    
    private func checkRunningApplications(keyCode: Int, modifiers: NSEvent.ModifierFlags) async -> [ConflictInfo] {
        var conflicts: [ConflictInfo] = []
        
        // Get running applications
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            guard let bundleId = app.bundleIdentifier,
                  bundleId != Bundle.main.bundleIdentifier else { continue }
            
            // Check known shortcuts for popular applications
            let appConflicts = checkKnownAppShortcuts(bundleId: bundleId, keyCode: keyCode, modifiers: modifiers)
            conflicts.append(contentsOf: appConflicts)
        }
        
        return conflicts
    }
    
    private func checkKnownAppShortcuts(bundleId: String, keyCode: Int, modifiers: NSEvent.ModifierFlags) -> [ConflictInfo] {
        let knownShortcuts: [String: [(Int, NSEvent.ModifierFlags, String)]] = [
            "com.apple.Safari": [
                (kVK_ANSI_R, [.command], "Reload page"),
                (kVK_ANSI_D, [.command], "Add bookmark"),
                (kVK_ANSI_L, [.command], "Focus address bar"),
                (kVK_ANSI_T, [.command], "New tab"),
                (kVK_ANSI_W, [.command], "Close tab")
            ],
            "com.google.Chrome": [
                (kVK_ANSI_R, [.command], "Reload page"),
                (kVK_ANSI_D, [.command], "Bookmark page"),
                (kVK_ANSI_L, [.command], "Focus address bar"),
                (kVK_ANSI_T, [.command], "New tab")
            ],
            "com.microsoft.VSCode": [
                (kVK_ANSI_P, [.command, .shift], "Command palette"),
                (kVK_ANSI_F, [.command, .shift], "Find in files"),
                (kVK_ANSI_N, [.command], "New file")
            ],
            "com.apple.dt.Xcode": [
                (kVK_ANSI_B, [.command], "Build"),
                (kVK_ANSI_R, [.command], "Run"),
                (kVK_ANSI_U, [.command], "Test")
            ]
        ]
        
        guard let appShortcuts = knownShortcuts[bundleId] else { return [] }
        
        var conflicts: [ConflictInfo] = []
        
        for (shortcutKeyCode, shortcutModifiers, description) in appShortcuts {
            if shortcutKeyCode == keyCode && shortcutModifiers == modifiers {
                let appName = getAppName(from: bundleId)
                conflicts.append(ConflictInfo(
                    appName: appName,
                    shortcutDescription: description,
                    severity: .medium,
                    canBeDisabled: true
                ))
            }
        }
        
        return conflicts
    }
    
    private func getAppName(from bundleId: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId),
           let bundle = Bundle(url: url),
           let name = bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String ??
                     bundle.infoDictionary?["CFBundleDisplayName"] as? String {
            return name
        }
        
        // Fallback to extracting from bundle ID
        return bundleId.components(separatedBy: ".").last?.capitalized ?? bundleId
    }
}

struct ConflictInfo: Identifiable {
    let id = UUID()
    let appName: String
    let shortcutDescription: String
    let severity: ConflictSeverity
    let canBeDisabled: Bool
}

enum ConflictSeverity {
    case low, medium, high
    
    var color: Color {
        switch self {
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var systemImage: String {
        switch self {
        case .low: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        }
    }
}