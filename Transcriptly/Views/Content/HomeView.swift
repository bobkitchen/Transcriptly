//
//  HomeView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showCapsuleMode = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Title
            Text("Transcriptly")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            // Main Record Button
            Button(action: {
                Task {
                    await handleRecordingAction()
                }
            }) {
                VStack(spacing: 16) {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(viewModel.isRecording ? .red : .accentColor)
                    
                    Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                        .font(.title2)
                    
                    Text("⌘⇧V")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Capsule Mode Button
            Button(viewModel.capsuleController.isCapsuleModeActive ? "Exit Capsule Mode" : "Enter Capsule Mode") {
                viewModel.capsuleController.toggleCapsuleMode()
            }
            .buttonStyle(.bordered)
            
            // Statistics
            VStack(spacing: 8) {
                HStack(spacing: 40) {
                    StatisticView(title: "Words Today", value: "1,234")
                    StatisticView(title: "Time Saved", value: "45 min")
                }
            }
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
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

struct StatisticView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HomeView(viewModel: AppViewModel())
        .padding()
}