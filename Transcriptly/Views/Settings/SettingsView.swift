//
//  SettingsView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//  Updated by Claude Code on 6/28/25 for Phase 4 Fixes - Liquid Glass Design
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
        VStack(spacing: 0) {
            // Simple header (no controls)
            HStack {
                Text("Settings")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.regularMaterial.opacity(0.3))
            
            // Existing content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                
                // Account Section
                SettingsCard(
                    title: "Account",
                    icon: "person.circle",
                    accentColor: .blue
                ) {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        HStack {
                            Text("Sign in to sync your preferences")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(.secondaryText)
                            
                            Spacer()
                            
                            Button("Sign In") {
                                // TODO: Implement in future phase
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(true)
                        }
                        
                        Text("Account features coming soon")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(.tertiaryText)
                            .padding(.vertical, DesignSystem.spacingTiny)
                            .padding(.horizontal, DesignSystem.spacingSmall)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(DesignSystem.cornerRadiusTiny)
                    }
                }
                
                // Notifications Section
                SettingsCard(
                    title: "Notifications",
                    icon: "bell",
                    accentColor: .green
                ) {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        Toggle("Play sound on completion", isOn: $playCompletionSound)
                            .toggleStyle(SwitchToggleStyle())
                            .tint(.accentColor)
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        Toggle("Show notifications", isOn: $showNotifications)
                            .toggleStyle(SwitchToggleStyle())
                            .tint(.accentColor)
                    }
                }
                
                // History Section
                SettingsCard(
                    title: "History",
                    icon: "clock.arrow.circlepath",
                    accentColor: .purple
                ) {
                    HStack {
                        Text("View transcription history")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.secondaryText)
                        
                        Spacer()
                        
                        Button("View History") {
                            showingHistory = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                
                // Keyboard Shortcuts Section
                SettingsCard(
                    title: "Keyboard Shortcuts",
                    icon: "keyboard",
                    accentColor: .orange
                ) {
                    VStack(spacing: DesignSystem.spacingSmall) {
                        ShortcutRow(
                            title: "Start/Stop Recording",
                            shortcut: $recordingShortcut,
                            isEditable: true
                        )
                        
                        Divider().background(Color.white.opacity(0.1))
                        
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
                }
                
                // About Section
                SettingsCard(
                    title: "About",
                    icon: "info.circle",
                    accentColor: .gray
                ) {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        HStack {
                            Text("Transcriptly")
                                .font(DesignSystem.Typography.bodyLarge)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            Text("Version 1.0.0")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(.secondaryText)
                        }
                        
                        HStack(spacing: DesignSystem.spacingLarge) {
                            Link("Help", destination: URL(string: "https://transcriptly.app/help")!)
                                .foregroundColor(.accentColor)
                                .font(DesignSystem.Typography.body)
                            
                            Link("Privacy Policy", destination: URL(string: "https://transcriptly.app/privacy")!)
                                .foregroundColor(.accentColor)
                                .font(DesignSystem.Typography.body)
                        }
                    }
                }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .adjustForInsetSidebar()
        .background(Color.primaryBackground)
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
    }
}

// MARK: - Supporting Views

/// Reusable settings card component with Liquid Glass design
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack(spacing: DesignSystem.spacingMedium) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(accentColor)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 24)
                
                Text(title)
                    .font(DesignSystem.Typography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
            }
            
            content
        }
        .padding(DesignSystem.spacingLarge)
        .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
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
                .font(DesignSystem.Typography.body)
                .foregroundColor(.primaryText)
            
            Spacer()
            
            if isWaitingForKeypress {
                ZStack {
                    Text("Press keys... (ESC to cancel)")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.orange)
                        .padding(.horizontal, DesignSystem.spacingSmall)
                        .padding(.vertical, DesignSystem.spacingTiny)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(DesignSystem.cornerRadiusTiny)
                    
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
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .padding(.horizontal, DesignSystem.spacingSmall)
                    .padding(.vertical, DesignSystem.spacingTiny)
                    .background(Color.tertiaryBackground)
                    .cornerRadius(DesignSystem.cornerRadiusTiny)
            }
            
            if isEditable {
                Button(isWaitingForKeypress ? "Cancel" : "Edit") {
                    if isWaitingForKeypress {
                        if let recorderView = findRecorderView() {
                            recorderView.stopRecording()
                        }
                        isWaitingForKeypress = false
                    } else {
                        isWaitingForKeypress = true
                    }
                }
                .buttonStyle(CompactButtonStyle())
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
}