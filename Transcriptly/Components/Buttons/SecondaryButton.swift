//
//  SecondaryButton.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 UI Overhaul - Secondary Button Component
//

import SwiftUI

/// Secondary button style with Liquid Glass design
struct SecondaryButtonStyle: ButtonStyle {
    @State private var isHovered = false
    @State private var isPressed = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body)
            .fontWeight(.medium)
            .foregroundColor(.primaryText)
            .padding(.horizontal, DesignSystem.spacingLarge)
            .padding(.vertical, DesignSystem.spacingMedium)
            .frame(minHeight: DesignSystem.Layout.buttonMinHeight)
            .liquidGlassBackground(
                material: .ultraThinMaterial,
                cornerRadius: DesignSystem.cornerRadiusSmall,
                strokeOpacity: isHovered ? 0.2 : 0.1
            )
            .hoverOverlay(isHovered: isHovered, cornerRadius: DesignSystem.cornerRadiusSmall)
            .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.01 : 1.0))
            .standardShadow(isHovered: isHovered)
            .animation(DesignSystem.fastSpringAnimation, value: isHovered)
            .animation(DesignSystem.quickFadeAnimation, value: isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
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

/// Primary button style with Liquid Glass design
struct PrimaryButtonStyle: ButtonStyle {
    @State private var isHovered = false
    @State private var isPressed = false
    let accentColor: Color
    
    init(accentColor: Color = .accentColor) {
        self.accentColor = accentColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.spacingLarge)
            .padding(.vertical, DesignSystem.spacingMedium)
            .frame(minHeight: DesignSystem.Layout.buttonMinHeight)
            .background(
                LinearGradient(
                    colors: [accentColor, accentColor.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(DesignSystem.cornerRadiusSmall)
            .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
            .shadow(
                color: accentColor.opacity(isHovered ? 0.4 : 0.3),
                radius: isHovered ? 12 : 8,
                y: isHovered ? 6 : 4
            )
            .animation(DesignSystem.fastSpringAnimation, value: isHovered)
            .animation(DesignSystem.quickFadeAnimation, value: isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
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

/// Record button style with special animations
struct RecordButtonStyle: ButtonStyle {
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var pulseAnimation = false
    let isRecording: Bool
    let recordingTime: TimeInterval?
    
    init(isRecording: Bool, recordingTime: TimeInterval? = nil) {
        self.isRecording = isRecording
        self.recordingTime = recordingTime
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: DesignSystem.spacingSmall) {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .font(.system(size: 18))
                .symbolRenderingMode(.hierarchical)
            
            if isRecording, let time = recordingTime {
                Text(timeString(from: time))
                    .font(DesignSystem.Typography.monospacedCaption)
                    .frame(width: 44)
            } else {
                Text("Record")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, DesignSystem.spacingLarge)
        .padding(.vertical, DesignSystem.spacingMedium)
        .background(
            LinearGradient(
                colors: isRecording ? [.red, .red.opacity(0.8)] : [.accentColor, .accentColor.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .shadow(
            color: isRecording ? Color.red.opacity(0.3) : Color.accentColor.opacity(0.3),
            radius: 8,
            y: 2
        )
        .scaleEffect(
            isPressed ? 0.95 : 
            (pulseAnimation && isRecording ? 1.05 : 
             (isHovered ? 1.02 : 1.0))
        )
        .animation(
            isRecording ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : DesignSystem.fastSpringAnimation,
            value: pulseAnimation
        )
        .animation(DesignSystem.fastSpringAnimation, value: isHovered)
        .animation(DesignSystem.quickFadeAnimation, value: isPressed)
        .onHover { hovering in
            isHovered = hovering
        }
        .onChange(of: configuration.isPressed) { _, pressed in
            isPressed = pressed
        }
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    VStack(spacing: 20) {
        Button("Secondary Button") {
            // Action
        }
        .buttonStyle(SecondaryButtonStyle())
        
        Button("Primary Button") {
            // Action
        }
        .buttonStyle(PrimaryButtonStyle())
        
        Button("Record") {
            // Action
        }
        .buttonStyle(RecordButtonStyle(isRecording: false))
        
        Button("Recording") {
            // Action
        }
        .buttonStyle(RecordButtonStyle(isRecording: true, recordingTime: 45))
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