//
//  RecordingView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import SwiftUI
import Combine

struct RecordingView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var recordingTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var recordingDuration: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Status and transcription result display
            VStack(spacing: 8) {
                // Error message display
                if let errorMessage = appViewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if appViewModel.isTranscribing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Transcribing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if !appViewModel.transcribedText.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last transcription:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(appViewModel.transcribedText)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(minHeight: 60)
            
            // Large record button with SF Symbol
            Button(action: {
                Task {
                    await handleRecordingAction()
                }
            }) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: appViewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title)
                        Text(appViewModel.isRecording ? "Stop Recording" : "Start Recording")
                            .font(.headline)
                    }
                    
                    // Recording duration display
                    if appViewModel.isRecording {
                        Text(formatDuration(recordingDuration))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(appViewModel.isRecording ? Color.red : Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .help("Click to start recording or use ⌘⇧V")
            .disabled(!appViewModel.canRecord && !appViewModel.isRecording)
            .onReceive(recordingTimer) { _ in
                if appViewModel.isRecording {
                    recordingDuration += 1
                }
            }
            .onChange(of: appViewModel.isRecording) { _, isRecording in
                if isRecording {
                    recordingDuration = 0
                } else {
                    recordingTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                }
            }
            
            // Keyboard shortcut display using SF Mono
            HStack(spacing: 4) {
                Text("Keyboard shortcut:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("⌘⇧V")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func handleRecordingAction() async {
        if appViewModel.isRecording {
            // Stop recording and get the file URL
            let recordingURL = await appViewModel.stopRecording()
            if recordingURL != nil {
                // Recording completed successfully
                // TODO: Process the recording (Task 2.3 will handle this)
            }
            return
        }
        
        // Check permissions before starting recording
        let hasPermission = await appViewModel.checkPermissions()
        if !hasPermission {
            // Permission denied - status will be updated automatically
            return
        }
        
        // Start recording
        let success = await appViewModel.startRecording()
        if !success {
            // Recording failed - error will be shown in status
        }
    }
}

#Preview {
    RecordingView()
        .padding()
}