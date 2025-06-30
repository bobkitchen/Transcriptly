//
//  ModeIndicator.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 6 UI Polish - Custom Mode Indicator Component
//

import SwiftUI

/// Elegant custom mode indicator replacing generic system dropdown
struct ModeIndicator: View {
    @Binding var currentMode: RefinementMode
    @State private var showModeMenu = false
    @State private var isHovered = false
    
    var body: some View {
        Menu {
            ForEach(RefinementMode.allCases, id: \.self) { mode in
                Button(action: { 
                    currentMode = mode
                    HapticFeedback.selection()
                }) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.displayName)
                                .font(.system(size: 14, weight: .medium))
                            Text(mode.description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: mode.icon)
                            .foregroundColor(mode.accentColor)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                // Mode icon with accent color
                Image(systemName: currentMode.icon)
                    .font(.system(size: 14))
                    .foregroundColor(currentMode.accentColor)
                    .symbolRenderingMode(.hierarchical)
                
                // Full mode name (no truncation)
                Text(currentMode.displayName)
                    .font(DesignSystem.Typography.modeIndicator)
                    .foregroundColor(.primaryText)
                
                // Subtle dropdown indicator
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.tertiaryText)
            }
            .padding(.horizontal, DesignSystem.spacingMedium)
            .padding(.vertical, 6)
            .background(backgroundMaterial)
            .cornerRadius(DesignSystem.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(DesignSystem.springAnimation, value: isHovered)
        }
        .menuStyle(.borderlessButton)
        .help("Switch refinement mode (⌘1-4)")
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    @ViewBuilder
    private var backgroundMaterial: some View {
        if isHovered {
            Rectangle()
                .fill(.regularMaterial)
        } else {
            Rectangle()
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - RefinementMode Extensions

extension RefinementMode {
    /// Accent color for each mode - visual distinction
    var accentColor: Color {
        switch self {
        case .raw: 
            return .gray
        case .cleanup: 
            return .blue
        case .email: 
            return .green
        case .messaging: 
            return .purple
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ModeIndicator(currentMode: .constant(.cleanup))
        ModeIndicator(currentMode: .constant(.email))
        ModeIndicator(currentMode: .constant(.messaging))
        ModeIndicator(currentMode: .constant(.raw))
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