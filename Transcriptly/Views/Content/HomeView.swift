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
    let onFloat: () -> Void
    @State private var showingHistory = false
    @State private var showExportDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Integrated header (replaces top bar)
            ContentHeader(
                viewModel: viewModel,
                title: "Welcome back",
                showModeControls: true,
                showFloatButton: true,
                onFloat: onFloat
            )
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                
                    // Stats cards
                    let stats = historyService.statistics
                    HStack(spacing: 16) {
                        StatCard(
                            icon: "chart.bar.fill",
                            title: "Today",
                            value: formatNumber(todayWordCount.components(separatedBy: " ").first.flatMap(Int.init) ?? 0),
                            subtitle: "words",
                            secondaryValue: "\(stats.todayCount) sessions"
                        )
                        
                        StatCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "This Week",
                            value: formatNumber(weekWordCount),
                            subtitle: "words",
                            secondaryValue: weekTimeSaved + " saved"
                        )
                        
                        StatCard(
                            icon: "target",
                            title: "Current Mode",
                            value: viewModel.refinementService.currentMode.displayName,
                            subtitle: "active",
                            secondaryValue: "⌘\(viewModel.refinementService.currentMode.rawValue)"
                        )
                    }
                
                    // Recent transcriptions section
                    if !recentTranscriptions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Transcriptions")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                Button("View All") {
                                    showingHistory = true
                                }
                                .foregroundColor(.accentColor)
                                .font(.system(size: 14))
                            }
                            
                            VStack(spacing: 8) {
                                ForEach(Array(recentTranscriptions.prefix(5))) { transcription in
                                    TranscriptionCard(transcription: transcription)
                                }
                            }
                        }
                    }
                
                    // Quick actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        HStack(spacing: 12) {
                            NewQuickActionButton(
                                title: "View All History",
                                icon: "clock.arrow.circlepath",
                                action: { showingHistory = true }
                            )
                            .disabled(recentTranscriptions.isEmpty)
                            
                            NewQuickActionButton(
                                title: "Export Data",
                                icon: "square.and.arrow.up",
                                action: { showExportDialog = true }
                            )
                            .disabled(recentTranscriptions.isEmpty)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .adjustForInsetSidebar()
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
    
    private var weekWordCount: Int {
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        let weekTranscriptions = historyService.transcriptions.filter { 
            $0.timestamp > weekAgo 
        }
        return weekTranscriptions.map { $0.wordCount }.reduce(0, +)
    }
    
    private var weekTimeSaved: String {
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        let weekTranscriptions = historyService.transcriptions.filter { 
            $0.timestamp > weekAgo 
        }
        let totalDuration = weekTranscriptions.compactMap { $0.duration }.reduce(0, +)
        
        let minutes = Int(totalDuration) / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number == 0 { return "0" }
        if number < 1000 { return "\(number)" }
        return String(format: "%.1fK", Double(number) / 1000.0)
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

struct NewQuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
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
    HomeView(viewModel: AppViewModel(), onFloat: {})
        .padding()
}