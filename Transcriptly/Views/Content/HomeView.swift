//
//  HomeView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//  Updated by Claude Code on 6/28/25 for Phase 4 Liquid Glass UI
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showCapsuleMode = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                // Welcome Header
                Text("Welcome back")
                    .font(DesignSystem.Typography.titleLarge)
                    .foregroundColor(.primaryText)
                    .padding(.top, DesignSystem.marginStandard)
                
                // Stats Cards
                HStack(spacing: DesignSystem.spacingLarge) {
                    StatCard(
                        icon: "chart.bar.fill",
                        title: "Today",
                        value: "1,234",
                        subtitle: "words",
                        secondaryValue: "12 sessions"
                    )
                    
                    StatCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "This Week", 
                        value: "8,456",
                        subtitle: "words",
                        secondaryValue: "45 min saved"
                    )
                    
                    StatCard(
                        icon: "target",
                        title: "Efficiency",
                        value: "87%",
                        subtitle: "refined",
                        secondaryValue: "23 patterns"
                    )
                }
                
                // Recent Transcriptions Section
                VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                    HStack {
                        Text("Recent Transcriptions")
                            .font(DesignSystem.Typography.titleMedium)
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                        
                        Button("View All") {
                            // Navigate to full history
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .font(DesignSystem.Typography.body)
                    }
                    
                    VStack(spacing: DesignSystem.spacingSmall) {
                        ForEach(recentTranscriptions) { transcription in
                            TranscriptionCard(transcription: transcription)
                        }
                    }
                }
                
                // Quick Actions Section
                VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                    Text("Quick Actions")
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(.primaryText)
                    
                    HStack(spacing: DesignSystem.spacingMedium) {
                        Button(action: {
                            viewModel.capsuleController.toggleCapsuleMode()
                        }) {
                            HStack(spacing: DesignSystem.spacingSmall) {
                                Image(systemName: "capsule")
                                    .font(.system(size: 16))
                                Text(viewModel.capsuleController.isCapsuleModeActive ? "Exit Capsule Mode" : "Enter Capsule Mode")
                                    .font(DesignSystem.Typography.body)
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("View All History") {
                            // Navigate to history
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Export Today's Work") {
                            // Export action
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
            .padding(DesignSystem.marginStandard)
        }
        .background(Color.primaryBackground)
    }
    
    // MARK: - Computed Properties
    
    private var recentTranscriptions: [TranscriptionRecord] {
        // TODO: Get actual recent transcriptions from viewModel
        // For now, return sample data
        Array(TranscriptionRecord.sampleData.prefix(3))
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