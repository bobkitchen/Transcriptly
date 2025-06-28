//
//  ExpandedCapsuleView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Capsule Interface Overhaul - Expanded State View
//

import SwiftUI
import AppKit

/// Expanded 150×40px capsule interface with full functionality
struct ExpandedCapsuleView: View {
    @ObservedObject var viewModel: AppViewModel
    let onHover: (Bool) -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            // Record button (left)
            Button(action: { 
                Task {
                    await handleRecordingAction()
                }
            }) {
                Circle()
                    .fill(recordButtonColor)
                    .frame(width: 20, height: 20) // Smaller button
                    .overlay(
                        Image(systemName: recordButtonIcon)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(viewModel.isRecording ? 0.9 : 1.0)
                    .animation(CapsuleDesignSystem.quickFadeAnimation, value: viewModel.isRecording)
            }
            .buttonStyle(.plain)
            .help(viewModel.isRecording ? "Stop Recording (⌘⇧V)" : "Start Recording (⌘⇧V)")
            
            // Center content area (no spacers, let it take available space)
            VStack(spacing: 1) {
                // Waveform
                if viewModel.isRecording {
                    CapsuleWaveform()
                        .frame(height: 14) // Smaller waveform
                        .transition(.opacity.combined(with: .scale))
                } else {
                    CapsuleWaveformIdle()
                        .frame(height: 14) // Smaller waveform
                        .transition(.opacity.combined(with: .scale))
                }
                
                // App detection info (if available)
                if let app = viewModel.detectedApp {
                    HStack(spacing: 2) {
                        AsyncAppIcon(bundleId: app.bundleIdentifier)
                            .frame(width: 8, height: 8)
                        
                        Text(app.displayName)
                            .font(.system(size: 6, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("→")
                            .font(.system(size: 6))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(viewModel.refinementService.currentMode.displayName)
                            .font(.system(size: 6, weight: .medium))
                            .foregroundColor(.white.opacity(CapsuleDesignSystem.textOpacity))
                    }
                    .lineLimit(1)
                    .fixedSize()
                } else {
                    // Current mode name (fallback)
                    Text(viewModel.refinementService.currentMode.displayName)
                        .font(.system(size: 8, weight: .medium)) // Smaller font
                        .foregroundColor(.white.opacity(CapsuleDesignSystem.textOpacity))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .frame(maxWidth: .infinity)
            .animation(CapsuleDesignSystem.springAnimation, value: viewModel.isRecording)
            
            // Expand button (right)
            Button(action: onClose) {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 16, height: 16) // Smaller button
                    .overlay(
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 6))
                            .foregroundColor(.white.opacity(CapsuleDesignSystem.textOpacity))
                    )
            }
            .buttonStyle(.plain)
            .help("Return to Main Window")
        }
        .padding(.horizontal, 8) // Reduced padding
        .padding(.vertical, 6) // Reduced padding
        .frame(
            width: CapsuleDesignSystem.expandedSize.width,
            height: CapsuleDesignSystem.expandedSize.height
        )
        .background(
            RoundedRectangle(cornerRadius: CapsuleDesignSystem.expandedCornerRadius)
                .fill(CapsuleDesignSystem.primaryMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CapsuleDesignSystem.expandedCornerRadius)
                        .strokeBorder(
                            CapsuleDesignSystem.borderColor,
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .onHover { hovering in
            onHover(hovering)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Floating recording interface")
        .accessibilityHint("Click record button to start recording, click expand button to return to main window")
    }
    
    // MARK: - Computed Properties
    
    private var recordButtonColor: Color {
        if viewModel.isRecording {
            return .red
        } else {
            return Color.red.opacity(0.8)
        }
    }
    
    private var recordButtonIcon: String {
        viewModel.isRecording ? "stop.fill" : "mic.fill"
    }
    
    // MARK: - Actions
    
    private func handleRecordingAction() async {
        if viewModel.isRecording {
            // Stop recording
            let recordingURL = await viewModel.stopRecording()
            if recordingURL != nil {
                // Recording completed successfully
                print("CapsuleView: Recording completed")
            }
            return
        }
        
        // Check permissions before starting recording
        let hasPermission = await viewModel.checkPermissions()
        if !hasPermission {
            // Permission denied - status will be updated automatically
            print("CapsuleView: Recording permission denied")
            return
        }
        
        // Start recording
        let success = await viewModel.startRecording()
        if !success {
            // Recording failed - error will be shown in status
            print("CapsuleView: Recording failed to start")
        } else {
            print("CapsuleView: Recording started successfully")
        }
    }
}


#Preview {
    ZStack {
        Rectangle()
            .fill(.black.opacity(0.8))
            .ignoresSafeArea()
        
        ExpandedCapsuleView(
            viewModel: AppViewModel(),
            onHover: { hovering in
                print("Hover: \(hovering)")
            },
            onClose: {
                print("Close capsule")
            }
        )
    }
    .frame(width: 300, height: 200)
}