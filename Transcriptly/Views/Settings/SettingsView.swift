//
//  SettingsView.swift
//  Transcriptly
//
//  Created by Claude Code on 8/6/25.
//

import SwiftUI

@available(macOS 26.0, *)
struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    let onFloat: () -> Void
    
    @State private var selectedTab = 0
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("playSound") private var playSound = true
    @AppStorage("autoStartOnLaunch") private var autoStartOnLaunch = false
    
    @Environment(\.availableWidth) private var availableWidth
    @Environment(\.sidebarCollapsed) private var sidebarCollapsed
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacing.xl) {
                // Header
                headerSection
                
                // Settings sections
                generalSettings
                notificationSettings
                keyboardShortcuts
                aboutSection
            }
            .padding(DesignSystem.spacing.lg)
        }
    }
    
    private var headerSection: some View {
        LiquidGlassContainer {
            HStack {
                Image(systemName: "gear")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading) {
                    Text("Settings")
                        .font(DesignSystem.typography.titleLarge)
                    Text("Configure Transcriptly to your preferences")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(DesignSystem.spacing.xl)
        }
    }
    
    private var generalSettings: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: DesignSystem.spacing.md) {
                Text("General")
                    .font(.headline)
                
                Toggle("Launch at startup", isOn: $autoStartOnLaunch)
                
                HStack {
                    Text("Default refinement mode:")
                    Picker("", selection: $viewModel.refinementMode) {
                        ForEach(RefinementMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 150)
                }
                
                Button("Open History") {
                    // Open history view
                }
            }
            .padding(DesignSystem.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var notificationSettings: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: DesignSystem.spacing.md) {
                Text("Notifications")
                    .font(.headline)
                
                Toggle("Enable notifications", isOn: $enableNotifications)
                Toggle("Play sound on completion", isOn: $playSound)
                    .disabled(!enableNotifications)
            }
            .padding(DesignSystem.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var keyboardShortcuts: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: DesignSystem.spacing.md) {
                Text("Keyboard Shortcuts")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: DesignSystem.spacing.sm) {
                    shortcutRow("Record/Stop", "⌘⇧V")
                    shortcutRow("Raw Mode", "⌘1")
                    shortcutRow("Clean-up Mode", "⌘2")
                    shortcutRow("Email Mode", "⌘3")
                    shortcutRow("Messaging Mode", "⌘4")
                    shortcutRow("Cancel", "Escape")
                    shortcutRow("Capsule Mode", "⌘⇧C")
                }
            }
            .padding(DesignSystem.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var aboutSection: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: DesignSystem.spacing.md) {
                Text("About")
                    .font(.headline)
                
                HStack {
                    Text("Version:")
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build:")
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundColor(.secondary)
                }
                
                Text("© 2025 Transcriptly")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(DesignSystem.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func shortcutRow(_ action: String, _ shortcut: String) -> some View {
        HStack {
            Text(action)
                .font(.body)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, DesignSystem.spacing.xs)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadius.small)
                        .fill(Color.secondary.opacity(0.1))
                )
        }
    }
}