//
//  RecordButton.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 UI Overhaul - Advanced Record Button Component
//

import SwiftUI

/// Advanced record button with three states: Default, Recording, Processing
struct RecordButton: View {
    let isRecording: Bool
    let isProcessing: Bool
    let recordingTime: TimeInterval
    let action: () -> Void
    
    @State private var pulseAnimation = false
    @State private var processingRotation: Double = 0
    
    var currentState: RecordButtonState {
        if isProcessing {
            return .processing
        } else if isRecording {
            return .recording
        } else {
            return .default
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.spacingSmall) {
                // Icon with state-specific styling
                Group {
                    switch currentState {
                    case .default:
                        Image(systemName: "mic.circle.fill")
                    case .recording:
                        Image(systemName: "stop.circle.fill")
                    case .processing:
                        Image(systemName: "waveform.circle.fill")
                            .rotationEffect(.degrees(processingRotation))
                    }
                }
                .font(.system(size: 18))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.white)
                
                // Text content based on state
                Group {
                    switch currentState {
                    case .default:
                        Text("Record")
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.medium)
                    case .recording:
                        Text(timeString(from: recordingTime))
                            .font(DesignSystem.Typography.monospacedCaption)
                            .frame(width: 44)
                    case .processing:
                        Text("Processing...")
                            .font(DesignSystem.Typography.bodySmall)
                    }
                }
                .foregroundColor(.white)
            }
            .padding(.horizontal, DesignSystem.spacingLarge)
            .padding(.vertical, DesignSystem.spacingMedium)
            .background(backgroundGradient)
            .cornerRadius(20)
            .shadow(color: shadowColor, radius: 8, y: 2)
            .scaleEffect(scaleEffect)
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .animation(DesignSystem.springAnimation, value: currentState)
        .onAppear {
            startAnimations()
        }
        .onChange(of: currentState) { _, newState in
            updateAnimations(for: newState)
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundGradient: LinearGradient {
        switch currentState {
        case .default:
            return LinearGradient(
                colors: [.accentColor, .accentColor.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .recording:
            return LinearGradient(
                colors: [.red, .red.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .processing:
            return LinearGradient(
                colors: [.orange, .orange.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var shadowColor: Color {
        switch currentState {
        case .default:
            return .accentColor.opacity(0.3)
        case .recording:
            return .red.opacity(0.3)
        case .processing:
            return .orange.opacity(0.3)
        }
    }
    
    private var scaleEffect: CGFloat {
        switch currentState {
        case .default:
            return 1.0
        case .recording:
            return pulseAnimation ? 1.05 : 1.0
        case .processing:
            return 1.0
        }
    }
    
    // MARK: - Helper Methods
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startAnimations() {
        pulseAnimation = true
    }
    
    private func updateAnimations(for state: RecordButtonState) {
        switch state {
        case .default:
            // Stop all animations
            withAnimation(.easeOut(duration: 0.3)) {
                pulseAnimation = false
                processingRotation = 0
            }
            
        case .recording:
            // Start pulse animation
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                pulseAnimation = true
            }
            
        case .processing:
            // Start rotation animation
            withAnimation(
                Animation.linear(duration: 2.0)
                    .repeatForever(autoreverses: false)
            ) {
                processingRotation = 360
            }
            pulseAnimation = false
        }
    }
}

// MARK: - Supporting Types

enum RecordButtonState {
    case `default`
    case recording
    case processing
}

// MARK: - Convenience Initializers

extension RecordButton {
    /// Simplified initializer for basic recording state
    init(
        isRecording: Bool,
        recordingTime: TimeInterval = 0,
        action: @escaping () -> Void
    ) {
        self.isRecording = isRecording
        self.isProcessing = false
        self.recordingTime = recordingTime
        self.action = action
    }
}

#Preview {
    VStack(spacing: 20) {
        // Default state
        RecordButton(
            isRecording: false,
            isProcessing: false,
            recordingTime: 0,
            action: { print("Record tapped") }
        )
        
        // Recording state
        RecordButton(
            isRecording: true,
            isProcessing: false,
            recordingTime: 45,
            action: { print("Stop tapped") }
        )
        
        // Processing state
        RecordButton(
            isRecording: false,
            isProcessing: true,
            recordingTime: 0,
            action: { print("Processing...") }
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