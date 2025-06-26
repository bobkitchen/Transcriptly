//
//  SettingsView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("playCompletionSound") private var playCompletionSound = true
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("recordingShortcut") private var recordingShortcut = "⌘⇧V"
    @AppStorage("rawModeShortcut") private var rawModeShortcut = "⌘1"
    @AppStorage("cleanupModeShortcut") private var cleanupModeShortcut = "⌘2"
    @AppStorage("emailModeShortcut") private var emailModeShortcut = "⌘3"
    @AppStorage("messagingModeShortcut") private var messagingModeShortcut = "⌘4"
    @State private var showingHistory = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Account Section (Placeholder)
            GroupBox("Account") {
                HStack {
                    Text("Sign in to sync your preferences")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Sign In") {
                        // TODO: Implement in Phase 3
                    }
                    .disabled(true)
                }
                .padding(.vertical, 4)
            }
            
            // Notifications
            GroupBox("Notifications") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Play sound on completion", isOn: $playCompletionSound)
                    Toggle("Show notifications", isOn: $showNotifications)
                }
                .padding(.vertical, 4)
            }
            
            // History
            GroupBox("History") {
                HStack {
                    Text("View transcription history")
                    Spacer()
                    Button("View History") {
                        showingHistory = true
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Keyboard Shortcuts
            GroupBox("Keyboard Shortcuts") {
                VStack(alignment: .leading, spacing: 12) {
                    ShortcutRow(
                        title: "Start/Stop Recording",
                        shortcut: $recordingShortcut,
                        isEditable: true
                    )
                    
                    ShortcutRow(
                        title: "Raw Transcription",
                        shortcut: $rawModeShortcut,
                        isEditable: true
                    )
                    
                    ShortcutRow(
                        title: "Clean-up Mode",
                        shortcut: $cleanupModeShortcut,
                        isEditable: true
                    )
                    
                    ShortcutRow(
                        title: "Email Mode",
                        shortcut: $emailModeShortcut,
                        isEditable: true
                    )
                    
                    ShortcutRow(
                        title: "Messaging Mode",
                        shortcut: $messagingModeShortcut,
                        isEditable: true
                    )
                }
                .padding(.vertical, 4)
            }
            
            // About
            GroupBox("About") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcriptly")
                        .font(.headline)
                    Text("Version 0.6.0")
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Button("Help") {
                            if let url = URL(string: "https://transcriptly.app/help") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                        
                        Button("Privacy Policy") {
                            if let url = URL(string: "https://transcriptly.app/privacy") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
    }
}

struct ShortcutRow: View {
    let title: String
    @Binding var shortcut: String
    let isEditable: Bool
    @State private var isWaitingForKeypress = false
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            
            if isWaitingForKeypress {
                ZStack {
                    Text("Press keys... (ESC to cancel)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    KeyboardShortcutRecorder(
                        shortcut: $shortcut,
                        onStartRecording: {
                            // Already in recording state
                        },
                        onStopRecording: {
                            isWaitingForKeypress = false
                        }
                    )
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .onAppear {
                        // Start recording when the recorder appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let recorderView = findRecorderView() {
                                recorderView.startRecording()
                            }
                        }
                    }
                }
            } else {
                Text(shortcut)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            if isEditable {
                Button(isWaitingForKeypress ? "Cancel" : "Set") {
                    if isWaitingForKeypress {
                        if let recorderView = findRecorderView() {
                            recorderView.stopRecording()
                        }
                        isWaitingForKeypress = false
                    } else {
                        isWaitingForKeypress = true
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    private func findRecorderView() -> KeyboardRecorderView? {
        // Helper function to find the recorder view in the view hierarchy
        guard let window = NSApplication.shared.keyWindow else { return nil }
        return findRecorderInView(window.contentView)
    }
    
    private func findRecorderInView(_ view: NSView?) -> KeyboardRecorderView? {
        guard let view = view else { return nil }
        
        if let recorder = view as? KeyboardRecorderView {
            return recorder
        }
        
        for subview in view.subviews {
            if let recorder = findRecorderInView(subview) {
                return recorder
            }
        }
        
        return nil
    }
}

#Preview {
    SettingsView()
        .padding()
}