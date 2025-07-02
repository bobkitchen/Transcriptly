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
    @Binding var selectedSection: SidebarSection
    let onFloat: () -> Void
    @ObservedObject private var historyService = TranscriptionHistoryService.shared
    @State private var showingHistory = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                // Welcome message
                welcomeSection
                
                // Three main action cards
                threeCardLayout
                
                // Recent activity section
                recentActivitySection
            }
            .padding(.horizontal, DesignSystem.marginStandard)
            .padding(.vertical, DesignSystem.spacingLarge)
        }
        .adjustForFloatingSidebar()
        .background(Color.primaryBackground)
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
    }
    
    
    @ViewBuilder
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
            Text("Welcome back")
                .font(DesignSystem.Typography.titleMedium)
                .foregroundColor(.primaryText)
                .fontWeight(.medium)
            
            Text("Choose how you'd like to be productive with your voice today")
                .font(DesignSystem.Typography.body)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DesignSystem.spacingMedium)
    }
    
    @ViewBuilder
    private var threeCardLayout: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            
            // Card 1: Record Dictation
            ProductivityCard(
                icon: "mic.fill",
                title: "Record Dictation",
                subtitle: "Voice to text with AI refinement",
                action: "Start Recording",
                color: .blue,
                onTap: {
                    selectedSection = .dictation
                }
            )
            
            // Card 2: Read Documents (Dropzone)
            ProductivityCard(
                icon: "doc.text.fill",
                title: "Read Documents",
                subtitle: "Text to speech for any document",
                action: "Choose Document",
                color: .green,
                supportedTypes: [
                    .pdf,
                    .plainText,
                    .rtf,
                    .html,
                    UTType(filenameExtension: "docx") ?? .data,
                    UTType(filenameExtension: "doc") ?? .data
                ],
                onTap: {
                    selectedSection = .readAloud
                },
                onDrop: { url in
                    handleFileImport(url)
                }
            )
            
            // Card 3: Transcribe Media (Dropzone) 
            ProductivityCard(
                icon: "waveform",
                title: "Transcribe Media",
                subtitle: "Convert audio files to text",
                action: "Select Audio",
                color: .purple,
                supportedTypes: [
                    .audio,
                    .mp3,
                    .wav,
                    UTType(filenameExtension: "m4a") ?? .data,
                    UTType(filenameExtension: "aac") ?? .data
                ],
                onTap: {
                    // Future feature - for now show a helpful message
                    // Could implement a coming soon alert or redirect to dictation
                    selectedSection = .dictation
                },
                onDrop: { url in
                    handleFileImport(url)
                }
            )
        }
    }
    
    @ViewBuilder
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack {
                Text("Recent Activity")
                    .font(DesignSystem.Typography.titleMedium)
                    .foregroundColor(.primaryText)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("View All") {
                    showingHistory = true
                }
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(.accentColor)
            }
            
            if recentTranscriptions.isEmpty {
                // Empty state
                VStack(spacing: DesignSystem.spacingSmall) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 24))
                        .foregroundColor(.tertiaryText)
                    
                    Text("No recent activity")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.secondaryText)
                    
                    Text("Your recent dictations and documents will appear here")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.spacingLarge)
                .background(
                    LiquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusSmall)
                )
            } else {
                LazyVStack(spacing: DesignSystem.spacingSmall) {
                    ForEach(recentTranscriptions) { transcription in
                        TranscriptionCard(transcription: transcription)
                    }
                }
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