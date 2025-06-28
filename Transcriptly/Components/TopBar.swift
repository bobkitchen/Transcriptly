//
//  TopBar.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 UI Overhaul - Persistent Top Bar Component
//

import SwiftUI
import Combine

/// Persistent top bar with app title, mode controls, and record button
struct TopBar: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var showCapsuleMode: Bool
    @State private var recordingTime: TimeInterval = 0
    @State private var recordingTimer: Timer?
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingLarge) {
            // App Title
            Text("Transcriptly")
                .font(DesignSystem.Typography.body)
                .fontWeight(.medium)
                .foregroundColor(.secondaryText)
            
            Spacer()
            
            // Capsule Button
            Button(action: {
                showCapsuleMode = true
            }) {
                Image(systemName: "capsule")
                    .font(.system(size: 16))
                    .foregroundColor(.primaryText)
            }
            .buttonStyle(.plain)
            .help("Enter Capsule Mode")
            .interactiveSurface(cornerRadius: DesignSystem.cornerRadiusSmall)
            .padding(DesignSystem.spacingSmall)
            
            // Mode Dropdown
            Picker("Mode", selection: $viewModel.refinementService.currentMode) {
                ForEach(RefinementMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)
            .help("Select refinement mode")
            
            // Record Button
            Button(action: {
                Task {
                    await handleRecordingAction()
                }
            }) {
                HStack(spacing: DesignSystem.spacingSmall) {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 18))
                        .symbolRenderingMode(.hierarchical)
                    
                    if viewModel.isRecording {
                        Text(timeString(from: recordingTime))
                            .font(DesignSystem.Typography.monospacedCaption)
                            .frame(width: 44)
                    } else {
                        Text("Record")
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.medium)
                    }
                }
            }
            .buttonStyle(RecordButtonStyle(isRecording: viewModel.isRecording, recordingTime: recordingTime))
            .help("Start/stop recording (⌘⇧V)")
            .disabled(!viewModel.canRecord && !viewModel.isRecording)
        }
        .padding(.horizontal, DesignSystem.marginStandard)
        .padding(.vertical, 12)
        .frame(height: DesignSystem.Layout.topBarHeight)
        .liquidGlassHeader()
        .overlay(
            // Bottom border
            Rectangle()
                .fill(Color.dividerColor)
                .frame(height: 0.5)
                .opacity(0.5),
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
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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

#Preview {
    TopBar(
        viewModel: AppViewModel(),
        showCapsuleMode: .constant(false)
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