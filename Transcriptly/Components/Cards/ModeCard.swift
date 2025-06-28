//
//  ModeCard.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 UI Overhaul - Unified Mode Card Component
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Unified mode card that combines mode selection and prompt editing
struct ModeCard: View {
    let mode: RefinementMode
    @Binding var selectedMode: RefinementMode
    let stats: ModeStatistics?
    let onEdit: () -> Void
    let onAppsConfig: (() -> Void)?
    
    @State private var isHovered = false
    @State private var assignedApps: [AppAssignment] = []
    @ObservedObject private var assignmentManager = AppAssignmentManager.shared
    
    private var isSelected: Bool {
        selectedMode == mode
    }
    
    private var assignedAppNames: String {
        let names = assignedApps.map { $0.appName }
        print("DEBUG: Mode \(mode.displayName) has \(assignedApps.count) assigned apps: \(names)")
        if names.count <= 3 {
            return names.joined(separator: ", ")
        } else {
            let firstThree = names.prefix(3).joined(separator: ", ")
            return "\(firstThree), +\(names.count - 3) more"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            // Main content
            HStack(spacing: DesignSystem.spacingMedium) {
                // Radio button
                Button(action: {
                    print("DEBUG ModeCard: Radio button clicked for \(mode)")
                    withAnimation(DesignSystem.springAnimation) {
                        selectedMode = mode
                    }
                }) {
                    Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .accentColor : .secondaryText)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                
                // Content
                VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                    // Title and description
                    HStack {
                        Text(mode.displayName)
                            .font(DesignSystem.Typography.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryText)
                            .onTapGesture {
                                print("DEBUG ModeCard: Title tapped for \(mode)")
                                withAnimation(DesignSystem.springAnimation) {
                                    selectedMode = mode
                                }
                            }
                        
                        Spacer()
                        
                        // Action buttons (show on hover or selection)
                        if isHovered || isSelected {
                            HStack(spacing: DesignSystem.spacingSmall) {
                                if mode != .raw {
                                    Button(action: onEdit) {
                                        HStack(spacing: DesignSystem.spacingTiny) {
                                            Text("Edit")
                                            Image(systemName: "pencil")
                                                .font(.system(size: 10))
                                        }
                                    }
                                    .buttonStyle(CompactButtonStyle())
                                }
                                
                                Button(action: { 
                                    if let appsConfig = onAppsConfig {
                                        appsConfig()
                                    } else {
                                        openApplicationPicker()
                                    }
                                }) {
                                    HStack(spacing: DesignSystem.spacingTiny) {
                                        Text("Apps")
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10))
                                    }
                                }
                                .buttonStyle(CompactButtonStyle())
                            }
                        }
                    }
                    
                    Text(mode.description)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 0)
            }
            
            // Stats line (if available and selected)
            if isSelected, let stats = stats {
                HStack(spacing: DesignSystem.spacingSmall) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                    
                    Text("Used \(stats.usageCount) times")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.tertiaryText)
                    
                    if let lastEdited = stats.lastEditedDisplay {
                        Text("•")
                            .foregroundColor(.tertiaryText)
                        Text("Edited \(lastEdited)")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(.tertiaryText)
                    }
                    
                    if !stats.assignedApps.isEmpty {
                        Text("•")
                            .foregroundColor(.tertiaryText)
                        
                        HStack(spacing: DesignSystem.spacingTiny) {
                            ForEach(stats.assignedApps.prefix(3), id: \.name) { app in
                                Circle()
                                    .fill(Color.accentColor.opacity(0.3))
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Text(String(app.name.prefix(1)))
                                            .font(.system(size: 8, weight: .medium))
                                            .foregroundColor(.accentColor)
                                    )
                            }
                            if stats.assignedApps.count > 3 {
                                Text("+\(stats.assignedApps.count - 3)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.tertiaryText)
                            }
                        }
                    }
                    
                    // Real assigned apps (always show for debugging)
                    Text("•")
                        .foregroundColor(.tertiaryText)
                    
                    HStack(spacing: DesignSystem.spacingTiny) {
                        Text("Assigned:")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(.tertiaryText)
                        
                        Text(assignedApps.isEmpty ? "None" : assignedAppNames)
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(assignedApps.isEmpty ? .tertiaryText : .accentColor)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(DesignSystem.spacingLarge)
        .frame(minHeight: DesignSystem.Layout.cardHeight)
        .padding(8)
        .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(8)
        .border(isSelected ? Color.blue : Color.clear, width: 2)
        .onHover { hovering in
            print("DEBUG ModeCard: Hover state changed for \(mode): \(hovering)")
            withAnimation(DesignSystem.fadeAnimation) {
                isHovered = hovering
            }
        }
        .onAppear {
            loadAssignedApps()
        }
    }
    
    // MARK: - App Assignment Functions
    
    private func openApplicationPicker() {
        let panel = NSOpenPanel()
        panel.title = "Select Application for \(mode.displayName)"
        panel.message = "Choose an application to automatically switch to \(mode.displayName) mode when using it."
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        // Start in Applications folder
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                // Create AppInfo from selected app
                if let bundle = Bundle(url: url) {
                    let appInfo = AppInfo(
                        bundleIdentifier: bundle.bundleIdentifier ?? url.lastPathComponent,
                        localizedName: bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? 
                                     bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? 
                                     url.deletingPathExtension().lastPathComponent,
                        executablePath: url.path
                    )
                    
                    DispatchQueue.main.async {
                        Task {
                            await assignApp(appInfo)
                        }
                    }
                } else {
                    // Fallback for apps without bundles
                    let appInfo = AppInfo(
                        bundleIdentifier: url.lastPathComponent,
                        localizedName: url.deletingPathExtension().lastPathComponent,
                        executablePath: url.path
                    )
                    
                    DispatchQueue.main.async {
                        Task {
                            await assignApp(appInfo)
                        }
                    }
                }
            }
        }
    }
    
    private func assignApp(_ app: AppInfo) async {
        let assignment = AppAssignment(
            appInfo: app,
            mode: mode,
            isUserOverride: true
        )
        
        do {
            try await assignmentManager.saveAssignment(assignment)
            print("DEBUG: Successfully saved assignment: \(app.displayName) -> \(mode.displayName)")
            
            // Immediate UI update without async/await complications
            print("DEBUG: About to reload assigned apps for \(mode.displayName)")
            loadAssignedApps()
            print("DEBUG: Finished reloading assigned apps for \(mode.displayName)")
        } catch {
            print("DEBUG: Failed to assign app: \(error)")
        }
    }
    
    private func loadAssignedApps() {
        assignedApps = assignmentManager.getAssignedApps(for: mode)
        print("DEBUG: Loaded \(assignedApps.count) apps for \(mode.displayName): \(assignedApps.map { $0.appName })")
    }
}

// MARK: - Compact Button Style

struct CompactButtonStyle: ButtonStyle {
    @State private var isPressed = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodySmall)
            .fontWeight(.medium)
            .foregroundColor(.secondaryText)
            .padding(.horizontal, DesignSystem.spacingSmall)
            .padding(.vertical, DesignSystem.spacingTiny)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusTiny)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusTiny)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.quickFadeAnimation, value: isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
                if pressed {
                    NSHapticFeedbackManager.defaultPerformer.perform(
                        .levelChange,
                        performanceTime: .now
                    )
                }
            }
    }
}

// MARK: - Supporting Views

struct AsyncAppIcon: View {
    let bundleId: String
    @State private var icon: NSImage?
    
    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
            } else {
                Image(systemName: "app.fill")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadIcon()
        }
    }
    
    private func loadIcon() {
        DispatchQueue.global(qos: .userInitiated).async {
            let workspace = NSWorkspace.shared
            let appURL = workspace.urlForApplication(withBundleIdentifier: bundleId)
            
            let appIcon = appURL.map { workspace.icon(forFile: $0.path) }
            
            DispatchQueue.main.async {
                icon = appIcon
            }
        }
    }
}

// MARK: - Supporting Types

struct ModeStatistics {
    let usageCount: Int
    let lastEditedDisplay: String?
    let assignedApps: [PreviewAppInfo]
    
    static let sampleData: [RefinementMode: ModeStatistics] = [
        .cleanup: ModeStatistics(
            usageCount: 127,
            lastEditedDisplay: "2 days ago",
            assignedApps: []
        ),
        .email: ModeStatistics(
            usageCount: 43,
            lastEditedDisplay: "1 week ago",
            assignedApps: [
                PreviewAppInfo(name: "Mail"),
                PreviewAppInfo(name: "Outlook")
            ]
        ),
        .messaging: ModeStatistics(
            usageCount: 89,
            lastEditedDisplay: "3 days ago",
            assignedApps: [
                PreviewAppInfo(name: "Messages"),
                PreviewAppInfo(name: "Slack"),
                PreviewAppInfo(name: "Discord"),
                PreviewAppInfo(name: "Teams")
            ]
        )
    ]
}

struct PreviewAppInfo {
    let name: String
}

#Preview {
    VStack(spacing: 12) {
        ModeCard(
            mode: .raw,
            selectedMode: .constant(.cleanup),
            stats: nil,
            onEdit: { print("Edit raw") },
            onAppsConfig: nil
        )
        
        ModeCard(
            mode: .cleanup,
            selectedMode: .constant(.cleanup),
            stats: ModeStatistics.sampleData[.cleanup],
            onEdit: { print("Edit cleanup") },
            onAppsConfig: { print("Apps cleanup") }
        )
        
        ModeCard(
            mode: .email,
            selectedMode: .constant(.cleanup),
            stats: ModeStatistics.sampleData[.email],
            onEdit: { print("Edit email") },
            onAppsConfig: { print("Apps email") }
        )
    }
    .padding(40)
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}