//
//  TopBar.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 UI Overhaul - Persistent Top Bar Component
//  Updated by Claude Code on 6/28/25 for Phase 4 Fixes - Subtle Header Design
//

import SwiftUI
import Combine

/// Subtle top bar with essential controls - redesigned to be visually secondary to sidebar
struct TopBar: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var recordingTime: TimeInterval = 0
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            // App Title - smaller and more subtle
            Text("Transcriptly")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.tertiaryText)
            
            Spacer()
            
            // Quick mode indicator (read-only)
            Text(viewModel.refinementService.currentMode.displayName)
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            
            // Compact Record button
            CompactRecordButton(
                isRecording: viewModel.isRecording,
                recordingTime: recordingTime,
                action: {
                    Task {
                        await handleRecordingAction()
                    }
                }
            )
            
            // Capsule mode button
            Button(action: {
                viewModel.capsuleController.toggleCapsuleMode()
            }) {
                Image(systemName: "capsule")
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.capsuleController.isCapsuleModeActive ? .accentColor : .secondaryText)
            }
            .buttonStyle(.plain)
            .help(viewModel.capsuleController.isCapsuleModeActive ? "Exit Capsule Mode" : "Enter Capsule Mode")
        }
        .padding(.horizontal, DesignSystem.marginStandard)
        .padding(.vertical, 8) // Reduced from 12
        .frame(height: DesignSystem.Layout.topBarHeight)
        .background(.regularMaterial) // More subtle than liquidGlassHeader
        .overlay(
            // Subtle bottom border
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5),
            alignment: .bottom
        )
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if viewModel.isRecording {
                recordingTime += 1
            }
        }
        .onChange(of: viewModel.isRecording) { _, isRecording in
            if isRecording {
                recordingTime = 0
            }
        }
    }
    
    private func handleRecordingAction() async {
        if viewModel.isRecording {
            // Stop recording
            let recordingURL = await viewModel.stopRecording()
            if recordingURL != nil {
                // Recording completed successfully
            }
            return
        }
        
        // Check permissions before starting recording
        let hasPermission = await viewModel.checkPermissions()
        if !hasPermission {
            // Permission denied - status will be updated automatically
            return
        }
        
        // Start recording
        let success = await viewModel.startRecording()
        if !success {
            // Recording failed - error will be shown in status
        }
    }
}

// MARK: - Compact Record Button

struct CompactRecordButton: View {
    let isRecording: Bool
    let recordingTime: TimeInterval
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 16))
                    .symbolRenderingMode(.hierarchical)
                
                if isRecording {
                    Text(timeString(from: recordingTime))
                        .font(.system(.caption2, design: .monospaced))
                        .frame(width: 36)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: isRecording ? [.red, .red.opacity(0.8)] : [.accentColor, .accentColor.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .help("Start/stop recording (⌘⇧V)")
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    TopBar(viewModel: AppViewModel())
        .padding(40)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}