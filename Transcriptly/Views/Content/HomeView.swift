//
//  HomeView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//  Updated by Claude Code on 6/28/25 for Phase 4 Liquid Glass UI
//  Updated by Claude Code on 1/3/25 for Phase 10 Visual Polish
//

import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var selectedSection: SidebarSection
    let onFloat: () -> Void
    @ObservedObject private var historyService = TranscriptionHistoryService.shared
    @StateObject private var userStats = UserStats()
    @State private var showingHistory = false
    
    // Responsive layout properties
    @Environment(\.availableWidth) private var availableWidth
    @Environment(\.sidebarCollapsed) private var sidebarCollapsed
    
    // Calculate optimal layout based on available width
    private var maxContentWidth: CGFloat {
        .infinity // Use all available space
    }
    
    private var shouldCenterContent: Bool {
        false // Always align to leading for better space usage
    }
    
    private var cardSpacing: CGFloat {
        // Increase spacing when sidebar collapsed for better use of space
        sidebarCollapsed ? DesignSystem.spacingXLarge : DesignSystem.spacingLarge
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingXLarge) {
                // Simplified header
                welcomeSection
                
                // Enhanced Action Cards
                enhancedActionCards
                
                // Stats Dashboard
                statsDashboard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignSystem.marginStandard)
            .padding(.vertical, DesignSystem.spacingLarge)
            .animation(DesignSystem.gentleSpring, value: sidebarCollapsed)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
        .onAppear {
            userStats.loadTodayStats()
        }
    }
    
    
    @ViewBuilder
    private var welcomeSection: some View {
        VStack(alignment: shouldCenterContent ? .center : .leading, spacing: DesignSystem.spacingMedium) {
            Text("Welcome back")
                .font(DesignSystem.Typography.heroTitle)
                .foregroundColor(.primary)
            
            // Subtle status line
            Text("\(userStats.todaySessions) transcriptions today • \(userStats.wordsFormatted) words • \(userStats.todayMinutesSaved) minutes saved")
                .font(DesignSystem.Typography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: shouldCenterContent ? .center : .leading)
    }
    
    @ViewBuilder
    private var enhancedActionCards: some View {
        HStack(spacing: cardSpacing) {
            EnhancedActionCard(
                icon: "mic.circle.fill",
                title: "Record Dictation",
                subtitle: "Voice to text with AI refinement",
                buttonText: "Start Recording",
                buttonColor: .blue,
                action: {
                    selectedSection = .dictation
                }
            )
            
            EnhancedActionCard(
                icon: "doc.text.fill",
                title: "Read Documents",
                subtitle: "Text to speech for any document",
                buttonText: "Choose Document",
                buttonColor: .green,
                action: {
                    selectedSection = .readAloud
                }
            )
            
            EnhancedActionCard(
                icon: "waveform",
                title: "Transcribe Media",
                subtitle: "Convert audio files to text",
                buttonText: "Select Audio",
                buttonColor: .purple,
                action: {
                    // Future feature - for now redirect to dictation
                    selectedSection = .dictation
                }
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    @ViewBuilder
    private var statsDashboard: some View {
        VStack(alignment: shouldCenterContent ? .center : .leading, spacing: DesignSystem.spacingMedium) {
            HStack {
                Text("Today's Productivity")
                    .font(DesignSystem.Typography.sectionTitle)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View History") {
                    showingHistory = true
                }
                .font(DesignSystem.Typography.body)
                .foregroundColor(.accentColor)
            }
            .frame(maxWidth: .infinity)
            
            HStack(spacing: cardSpacing) {
                ProductivityStatCard(
                    title: "Words",
                    value: userStats.wordsFormatted,
                    subtitle: userStats.growthFormatted,
                    icon: "textformat.size",
                    color: Color.blue
                )
                
                ProductivityStatCard(
                    title: "Time Saved",
                    value: "\(userStats.todayMinutesSaved)m",
                    subtitle: "vs typing",
                    icon: "clock.arrow.circlepath",
                    color: Color.green
                )
                
                ProductivityStatCard(
                    title: "Streak",
                    value: "\(userStats.currentStreak)",
                    subtitle: userStats.currentStreak >= 3 ? "🔥 Keep it up!" : "days",
                    icon: "flame.fill",
                    color: Color.orange
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
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
    
    private func handleFileImport(_ url: URL) {
        print("📁 HomeView: File import requested for: \(url.lastPathComponent)")
        print("📁 HomeView: Full file path: \(url.path)")
        print("📁 HomeView: File extension: \(url.pathExtension.lowercased())")
        
        // Determine file type and navigate to appropriate section
        let fileExtension = url.pathExtension.lowercased()
        let documentExtensions = ["pdf", "docx", "doc", "txt", "rtf", "html", "htm"]
        let audioExtensions = ["mp3", "wav", "m4a", "aac", "audio"]
        
        if documentExtensions.contains(fileExtension) {
            print("📁 HomeView: Document detected, navigating to Read Aloud")
            // Navigate to Read Aloud and trigger import
            selectedSection = .readAloud
            
            // Post notification to trigger file import in ReadAloudView
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("📁 HomeView: Posting readAloudImportFile notification")
                NotificationCenter.default.post(
                    name: .readAloudImportFile,
                    object: nil,
                    userInfo: ["fileURL": url]
                )
            }
        } else if audioExtensions.contains(fileExtension) {
            print("📁 HomeView: Audio file detected, redirecting to dictation")
            // For now, redirect to dictation (future: media transcription)
            selectedSection = .dictation
            
            // Could post notification for future audio import feature
            print("📁 Audio import not yet implemented, redirected to dictation")
        } else {
            print("📁 HomeView: Unknown file type, trying as document")
            // Unknown file type - try documents first
            selectedSection = .readAloud
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("📁 HomeView: Posting readAloudImportFile notification for unknown type")
                NotificationCenter.default.post(
                    name: .readAloudImportFile,
                    object: nil,
                    userInfo: ["fileURL": url]
                )
            }
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
    HomeView(viewModel: AppViewModel(), selectedSection: .constant(.home), onFloat: {})
        .padding()
}