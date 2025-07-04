//
//  ShortcutSettingsView.swift
//  Transcriptly
//
//  Settings view for customizing keyboard shortcuts
//

import SwiftUI

struct ShortcutSettingsView: View {
    @ObservedObject private var shortcutManager = ShortcutManager.shared
    @ObservedObject private var conflictDetector = ConflictDetector()
    
    @State private var editingShortcut: String?
    @State private var showingConflicts: [ConflictInfo] = []
    @State private var showConflictAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
            Text("Keyboard Shortcuts")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: DesignSystem.spacingMedium) {
                ForEach(shortcutManager.currentShortcuts) { shortcut in
                    ShortcutRowView(
                        shortcut: shortcut,
                        isEditing: editingShortcut == shortcut.id,
                        onEdit: { 
                            editingShortcut = shortcut.id
                        },
                        onSave: { keyCode, modifiers in
                            Task {
                                let result = await shortcutManager.updateShortcut(
                                    shortcut.id, 
                                    keyCode: keyCode, 
                                    modifiers: modifiers
                                )
                                
                                await MainActor.run {
                                    switch result {
                                    case .success:
                                        editingShortcut = nil
                                    case .conflictDetected(let conflicts):
                                        showingConflicts = conflicts
                                        showConflictAlert = true
                                    case .notFound, .invalidKeyCode:
                                        // Handle error
                                        break
                                    }
                                }
                            }
                        },
                        onCancel: {
                            editingShortcut = nil
                        },
                        onTest: {
                            _ = shortcutManager.testShortcut(shortcut.id)
                            // Show test feedback
                        },
                        onReset: {
                            shortcutManager.resetShortcut(shortcut.id)
                        }
                    )
                }
            }
            
            HStack {
                Button("Reset All to Defaults") {
                    shortcutManager.resetToDefaults()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Import Shortcuts") {
                    // TODO: Implement import
                }
                .buttonStyle(.bordered)
                
                Button("Export Shortcuts") {
                    // TODO: Implement export
                }
                .buttonStyle(.bordered)
            }
        }
        .alert("Shortcut Conflicts Detected", isPresented: $showConflictAlert) {
            Button("Cancel", role: .cancel) {
                editingShortcut = nil
            }
            Button("Use Anyway", role: .destructive) {
                // Force update despite conflicts
                editingShortcut = nil
            }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text("This shortcut conflicts with:")
                ForEach(showingConflicts) { conflict in
                    HStack {
                        Image(systemName: conflict.severity.systemImage)
                            .foregroundColor(conflict.severity.color)
                        Text("\(conflict.appName): \(conflict.shortcutDescription)")
                    }
                }
            }
        }
    }
}

struct ShortcutRowView: View {
    let shortcut: ShortcutBinding
    let isEditing: Bool
    let onEdit: () -> Void
    let onSave: (Int, NSEvent.ModifierFlags) -> Void
    let onCancel: () -> Void
    let onTest: () -> Void
    let onReset: () -> Void
    
    @State private var tempKeyCode: Int = 0
    @State private var tempModifiers: NSEvent.ModifierFlags = []
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shortcut.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                if !shortcut.isCustomizable {
                    Text("Cannot be changed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isEditing {
                StableShortcutRecorder(
                    keyCode: $tempKeyCode,
                    modifiers: $tempModifiers,
                    onShortcutChange: { keyCode, modifiers in
                        tempKeyCode = keyCode
                        tempModifiers = modifiers
                    }
                )
                .frame(height: 30)
                
                Button("Save") {
                    onSave(tempKeyCode, tempModifiers)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
            } else {
                Text(shortcut.displayString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                
                if shortcut.isCustomizable {
                    Button("Edit") {
                        tempKeyCode = shortcut.keyCode
                        tempModifiers = shortcut.eventModifiers
                        onEdit()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Test") {
                        onTest()
                    }
                    .buttonStyle(.bordered)
                    
                    if !shortcut.isDefault {
                        Button("Reset") {
                            onReset()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(DesignSystem.spacingMedium)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}