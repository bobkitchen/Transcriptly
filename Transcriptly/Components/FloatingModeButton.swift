//
//  FloatingModeButton.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 6 UI Polish - Clear Floating Mode Button
//

import SwiftUI

/// Clear, intuitive button for entering floating recording mode
struct FloatingModeButton: View {
    let action: () -> Void
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
            action()
        }) {
            HStack(spacing: 6) {
                // Clear "floating overlay" icon - Picture-in-Picture concept
                Image(systemName: "pip.enter")
                    .font(.system(size: 12))
                    .symbolRenderingMode(.hierarchical)
                
                // Text label for ultimate clarity
                Text("Float")
                    .font(DesignSystem.Typography.floatingButton)
            }
            .foregroundColor(.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundView)
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
            .animation(DesignSystem.quickFadeAnimation, value: isPressed)
            .animation(DesignSystem.springAnimation, value: isHovered)
        }
        .buttonStyle(.plain)
        .help("Enter floating recording mode - compact overlay interface")
        .onHover { hovering in
            isHovered = hovering
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isHovered ? DesignSystem.Colors.hoverOverlay : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        Color.white.opacity(isHovered ? 0.15 : 0.05), 
                        lineWidth: 0.5
                    )
            )
    }
}

/// Alternative icon-only version for testing
struct FloatingModeIconButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
            action()
        }) {
            Image(systemName: "pip.enter")
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(DesignSystem.springAnimation, value: isHovered)
        }
        .buttonStyle(.plain)
        .help("Enter floating recording mode")
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// Alternative with different icon for testing
struct FloatingModeWindowButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "macwindow.on.rectangle")
                    .font(.system(size: 12))
                
                Text("Float")
                    .font(DesignSystem.Typography.floatingButton)
            }
            .foregroundColor(.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? DesignSystem.Colors.hoverOverlay : Color.clear)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(DesignSystem.springAnimation, value: isHovered)
        }
        .buttonStyle(.plain)
        .help("Enter floating recording mode")
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Press Events Helper

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Floating Mode Button Options")
            .font(.headline)
        
        HStack(spacing: 20) {
            FloatingModeButton(action: { print("Float mode") })
            FloatingModeIconButton(action: { print("Float mode") })
            FloatingModeWindowButton(action: { print("Float mode") })
        }
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