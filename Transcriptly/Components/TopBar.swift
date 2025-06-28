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
    let showCapsuleMode: () -> Void
    @State private var recordingTime: TimeInterval = 0
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            // App Title - smaller and more subtle
            Text("Transcriptly")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.tertiaryText)
            
            Spacer()
            
            // App detection indicator
            if viewModel.showModeDetectionIndicator,
               let app = viewModel.detectedApp,
               let mode = viewModel.autoSelectedMode {
                AppDetectionIndicator(app: app, mode: mode)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Mode dropdown
            Picker("Mode", selection: $viewModel.refinementService.currentMode) {
                ForEach(RefinementMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)
            .font(.system(size: 12))
            .foregroundColor(.secondaryText)
            .onChange(of: viewModel.refinementService.currentMode) { _, newMode in
                // User override - hide auto-detection indicator if it was shown
                if newMode != viewModel.autoSelectedMode {
                    viewModel.showModeDetectionIndicator = false
                }
            }
            
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
            Button(action: showCapsuleMode) {
                Image(systemName: "capsule")
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
            }
            .buttonStyle(.plain)
            .help("Enter Floating Capsule Mode")
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
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showModeDetectionIndicator)
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

struct AppDetectionIndicator: View {
    let app: AppInfo
    let mode: RefinementMode
    @State private var appIcon: NSImage?
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingSmall) {
            // App icon
            Group {
                if let icon = appIcon {
                    Image(nsImage: icon)
                        .resizable()
                } else {
                    Image(systemName: "app.fill")
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 16, height: 16)
            
            Text("\(app.displayName) → \(mode.displayName)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal, DesignSystem.spacingSmall)
        .padding(.vertical, DesignSystem.spacingTiny)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(DesignSystem.cornerRadiusSmall)
        .onAppear {
            loadAppIcon()
        }
    }
    
    private func loadAppIcon() {
        guard let executablePath = app.executablePath else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let icon = NSWorkspace.shared.icon(forFile: executablePath)
            
            DispatchQueue.main.async {
                appIcon = icon
            }
        }
    }
}

#Preview {
    TopBar(
        viewModel: AppViewModel(),
        showCapsuleMode: { print("Show capsule mode") }
    )
    .padding(40)
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}