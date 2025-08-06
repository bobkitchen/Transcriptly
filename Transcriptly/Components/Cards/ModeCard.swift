//
//  ModeCard.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 UI Overhaul - Unified Mode Card Component
//

import SwiftUI

/// Unified mode card that combines mode selection and prompt editing
struct ModeCard: View {
    let mode: RefinementMode
    @Binding var selectedMode: RefinementMode
    let stats: ModeStatistics?
    let onEdit: () -> Void
    let onAppsConfig: (() -> Void)?
    
    @State private var isHovered = false
    
    private var isSelected: Bool {
        selectedMode == mode
    }
    
    var body: some View {
        modeCardContent
    }
    
    private var modeCardContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            modeCardHeader
            
            if isSelected, let stats = stats {
                modeCardStats(stats)
            }
        }
        .padding(DesignSystem.spacingLarge)
        .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onHover { hovering in
            withAnimation(DesignSystem.fadeAnimation) {
                isHovered = hovering
            }
        }
    }
    
    private var modeCardHeader: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            // Radio button
            Button(action: {
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
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                HStack {
                    Text(mode.displayName)
                        .font(DesignSystem.Typography.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                        .onTapGesture {
                            withAnimation(DesignSystem.springAnimation) {
                                selectedMode = mode
                            }
                        }
                    
                    Spacer()
                    
                    if isHovered || isSelected {
                        modeCardActions
                    }
                }
                
                Text(mode.description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondaryText)
            }
        }
    }
    
    private var modeCardActions: some View {
        HStack(spacing: DesignSystem.spacingSmall) {
            if mode != .raw {
                Button("Edit", action: onEdit)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.accentColor)
                    .buttonStyle(.plain)
            }
            
            if let appsConfig = onAppsConfig {
                Button("Apps", action: appsConfig)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.accentColor)
                    .buttonStyle(.plain)
            }
        }
    }
    
    private func modeCardStats(_ stats: ModeStatistics) -> some View {
        HStack(spacing: DesignSystem.spacingSmall) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 12))
                .foregroundColor(.tertiaryText)
            
            Text("Used \(stats.usageCount) times")
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(.tertiaryText)
            
            if let lastEdited = stats.lastEditedDisplay {
                Text("• Edited \(lastEdited)")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.tertiaryText)
            }
            
            Spacer()
        }
    }
}

// MARK: - Compact Button Style

struct CompactButtonStyle: SwiftUI.ButtonStyle {
    
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        CompactButtonView(configuration: configuration)
    }
    
    struct CompactButtonView: View {
        let configuration: ButtonStyleConfiguration
        @State private var isPressed = false
        
        var body: some View {
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
}

// MARK: - Supporting Types

struct ModeStatistics: Sendable {
    let usageCount: Int
    let lastEditedDisplay: String?
    let assignedApps: [AppInfo]
    
    nonisolated(unsafe) static let sampleData: [RefinementMode: ModeStatistics] = [
        .cleanup: ModeStatistics(
            usageCount: 127,
            lastEditedDisplay: "2 days ago",
            assignedApps: []
        ),
        .email: ModeStatistics(
            usageCount: 43,
            lastEditedDisplay: "1 week ago",
            assignedApps: [
                AppInfo(bundleIdentifier: "com.apple.mail", localizedName: "Mail", icon: nil),
                AppInfo(bundleIdentifier: "com.microsoft.outlook", localizedName: "Outlook", icon: nil)
            ]
        ),
        .messaging: ModeStatistics(
            usageCount: 89,
            lastEditedDisplay: "3 days ago",
            assignedApps: [
                AppInfo(bundleIdentifier: "com.apple.messages", localizedName: "Messages", icon: nil),
                AppInfo(bundleIdentifier: "com.tinyspeck.slackmacgap", localizedName: "Slack", icon: nil),
                AppInfo(bundleIdentifier: "com.hnc.Discord", localizedName: "Discord", icon: nil),
                AppInfo(bundleIdentifier: "com.microsoft.teams2", localizedName: "Teams", icon: nil)
            ]
        )
    ]
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