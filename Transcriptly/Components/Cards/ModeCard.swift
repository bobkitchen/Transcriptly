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
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            // Main content
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
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                
                // Content
                VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                    // Title and description
                    HStack {
                        Text(mode.displayName)
                            .font(DesignSystem.Typography.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                        
                        // Action buttons (show on hover or selection)
                        if isHovered || isSelected {
                            HStack(spacing: DesignSystem.spacingSmall) {
                                if mode != .raw {
                                    Button("Edit") {
                                        onEdit()
                                    }
                                    .buttonStyle(CompactButtonStyle())
                                }
                                
                                if let appsConfig = onAppsConfig {
                                    Button(action: appsConfig) {
                                        HStack(spacing: DesignSystem.spacingTiny) {
                                            Text("Apps")
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 10))
                                        }
                                    }
                                    .buttonStyle(CompactButtonStyle())
                                }
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
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
                    
                    Spacer()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(DesignSystem.spacingLarge)
        .frame(minHeight: DesignSystem.Layout.cardHeight)
        .selectableCard(isSelected: isSelected, cornerRadius: DesignSystem.cornerRadiusMedium)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(DesignSystem.springAnimation) {
                selectedMode = mode
            }
        }
        .onHover { hovering in
            withAnimation(DesignSystem.fadeAnimation) {
                isHovered = hovering
            }
        }
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

// MARK: - Supporting Types

extension RefinementMode {
    var displayName: String {
        switch self {
        case .raw:
            return "Raw Transcription"
        case .cleanup:
            return "Clean-up Mode"
        case .email:
            return "Email Mode"
        case .messaging:
            return "Messaging Mode"
        }
    }
    
    var description: String {
        switch self {
        case .raw:
            return "No AI processing - exactly what you said"
        case .cleanup:
            return "Removes filler words and fixes grammar"
        case .email:
            return "Professional formatting with greetings and signatures"
        case .messaging:
            return "Concise and casual for quick messages"
        }
    }
}

struct ModeStatistics {
    let usageCount: Int
    let lastEditedDisplay: String?
    let assignedApps: [AppInfo]
    
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
                AppInfo(name: "Mail"),
                AppInfo(name: "Outlook")
            ]
        ),
        .messaging: ModeStatistics(
            usageCount: 89,
            lastEditedDisplay: "3 days ago",
            assignedApps: [
                AppInfo(name: "Messages"),
                AppInfo(name: "Slack"),
                AppInfo(name: "Discord"),
                AppInfo(name: "Teams")
            ]
        )
    ]
}

struct AppInfo {
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