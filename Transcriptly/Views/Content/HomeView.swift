//
//  HomeView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//  Updated by Claude Code on 6/28/25 for Phase 4 Liquid Glass UI
//

import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject private var historyService = TranscriptionHistoryService.shared
    @State private var showCapsuleMode = false
    @State private var showingHistory = false
    @State private var showExportDialog = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                // Welcome Header
                Text("Welcome back")
                    .font(UIPolishDesignSystem.Typography.title)
                    .foregroundColor(.primaryText)
                    .padding(.top, DesignSystem.marginStandard)
                
                // Stats Cards
                let stats = historyService.statistics
                HStack(spacing: DesignSystem.spacingLarge) {
                    StatCard(
                        icon: "chart.bar.fill",
                        title: "Today",
                        value: "\(stats.todayCount)",
                        subtitle: stats.todayCount == 1 ? "session" : "sessions",
                        secondaryValue: todayWordCount
                    )
                    
                    StatCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "This Week", 
                        value: "\(stats.weekCount)",
                        subtitle: stats.weekCount == 1 ? "session" : "sessions",
                        secondaryValue: weekTimeSaved
                    )
                    
                    StatCard(
                        icon: "target",
                        title: "Most Used",
                        value: stats.mostUsedMode?.displayName ?? "None",
                        subtitle: "mode",
                        secondaryValue: "\(stats.totalCount) total"
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
                            showingHistory = true
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .font(DesignSystem.Typography.body)
                    }
                    
                    if recentTranscriptions.isEmpty {
                        VStack(spacing: DesignSystem.spacingMedium) {
                            Image(systemName: "mic.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.tertiaryText)
                                .symbolRenderingMode(.hierarchical)
                            
                            Text("No transcriptions yet")
                                .font(DesignSystem.Typography.bodyLarge)
                                .foregroundColor(.secondaryText)
                            
                            Text("Start recording to see your transcription history here")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(.tertiaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.spacingLarge * 2)
                        .background(Color.secondaryBackground.opacity(0.3))
                        .cornerRadius(DesignSystem.cornerRadiusMedium)
                    } else {
                        VStack(spacing: DesignSystem.spacingSmall) {
                            ForEach(recentTranscriptions) { transcription in
                                TranscriptionCard(transcription: transcription)
                            }
                        }
                    }
                }
                
                // Quick Actions Section
                VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                    Text("Quick Actions")
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(.primaryText)
                    
                    HStack(spacing: 12) {
                        QuickActionButton(
                            title: viewModel.capsuleController.isCapsuleModeActive ? "Exit Float Mode" : "Enter Float Mode",
                            icon: "pip.enter",
                            action: { viewModel.capsuleController.toggleCapsuleMode() },
                            isProminent: true
                        )
                        
                        QuickActionButton(
                            title: "View All History",
                            icon: "clock.arrow.circlepath",
                            action: { showingHistory = true }
                        )
                        
                        QuickActionButton(
                            title: "Export Today's Work",
                            icon: "square.and.arrow.up",
                            action: { showExportDialog = true }
                        )
                    }
                }
            }
            .adjustForInsetSidebar()
            .padding(DesignSystem.marginStandard)
        }
        .background(Color.primaryBackground)
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
        .fileExporter(
            isPresented: $showExportDialog,
            document: TranscriptionExportDocument(transcriptions: todayTranscriptions),
            contentType: .json,
            defaultFilename: "today-transcriptions"
        ) { result in
            switch result {
            case .success(let url):
                print("Exported today's transcriptions to: \(url)")
            case .failure(let error):
                print("Export failed: \(error)")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var recentTranscriptions: [TranscriptionRecord] {
        return historyService.getTranscriptions(limit: 3)
    }
    
    private var todayTranscriptions: [TranscriptionRecord] {
        return historyService.transcriptions.filter { 
            Calendar.current.isDateInToday($0.timestamp) 
        }
    }
    
    private var todayWordCount: String {
        let todayTranscriptions = historyService.transcriptions.filter { 
            Calendar.current.isDateInToday($0.timestamp) 
        }
        let totalWords = todayTranscriptions.map { $0.wordCount }.reduce(0, +)
        return "\(totalWords) words"
    }
    
    private var weekTimeSaved: String {
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        let weekTranscriptions = historyService.transcriptions.filter { 
            $0.timestamp > weekAgo 
        }
        let totalDuration = weekTranscriptions.compactMap { $0.duration }.reduce(0, +)
        
        let minutes = Int(totalDuration) / 60
        if minutes < 60 {
            return "\(minutes) min total"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m total"
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

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    let isProminent: Bool
    
    init(title: String, icon: String, action: @escaping () -> Void, isProminent: Bool = false) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isProminent = isProminent
    }
    
    var body: some View {
        if isProminent {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(PrimaryButtonStyle())
        } else {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(SecondaryButtonStyle())
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