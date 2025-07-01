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
        VStack(spacing: 0) {
            // Header
            homeHeader
            
            // Main three-card layout
            ScrollView {
                VStack(spacing: DesignSystem.spacingLarge) {
                    // Welcome message
                    welcomeSection
                    
                    // Three main action cards
                    threeCardLayout
                    
                    // Recent activity section
                    recentActivitySection
                    
                    // Universal dropzone section
                    dropzoneSection
                }
                .padding(.horizontal, DesignSystem.marginStandard)
                .padding(.bottom, DesignSystem.spacingLarge)
            }
        }
        .adjustForFloatingSidebar()
        .background(Color.primaryBackground)
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
    }
    
    @ViewBuilder
    private var homeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Transcriptly")
                    .font(DesignSystem.Typography.titleLarge)
                    .foregroundColor(.primaryText)
                    .fontWeight(.semibold)
                
                Text("Your voice productivity suite")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Button(action: onFloat) {
                Image(systemName: "pip.enter")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("Float Window")
        }
        .padding(.horizontal, DesignSystem.marginStandard)
        .padding(.vertical, 16)
        .background(.regularMaterial.opacity(0.3))
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
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: DesignSystem.spacingMedium),
            GridItem(.flexible(), spacing: DesignSystem.spacingMedium),
            GridItem(.flexible(), spacing: DesignSystem.spacingMedium)
        ], spacing: DesignSystem.spacingMedium) {
            
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
            
            // Card 2: Read Documents  
            ProductivityCard(
                icon: "doc.text.fill",
                title: "Read Documents",
                subtitle: "Text to speech for any document",
                action: "Choose Document",
                color: .green,
                onTap: {
                    selectedSection = .readAloud
                }
            )
            
            // Card 3: Transcribe Media
            ProductivityCard(
                icon: "waveform",
                title: "Transcribe Media",
                subtitle: "Convert audio files to text",
                action: "Select Audio",
                color: .purple,
                onTap: {
                    // Future feature - for now show a helpful message
                    // Could implement a coming soon alert or redirect to dictation
                    selectedSection = .dictation
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
    
    @ViewBuilder
    private var dropzoneSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            Text("Quick Import")
                .font(DesignSystem.Typography.titleMedium)
                .foregroundColor(.primaryText)
                .fontWeight(.medium)
            
            UniversalDropzone.forAnyFile(
                title: "Drop Files Here",
                subtitle: "Import documents for reading or audio for transcription"
            ) { url in
                handleFileImport(url)
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
        
        // Determine file type and navigate to appropriate section
        let fileExtension = url.pathExtension.lowercased()
        let documentExtensions = ["pdf", "docx", "doc", "txt", "rtf", "html", "htm"]
        let audioExtensions = ["mp3", "wav", "m4a", "aac", "audio"]
        
        if documentExtensions.contains(fileExtension) {
            // Navigate to Read Aloud and trigger import
            selectedSection = .readAloud
            
            // Post notification to trigger file import in ReadAloudView
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ImportDocumentFile"),
                    object: url
                )
            }
        } else if audioExtensions.contains(fileExtension) {
            // For now, redirect to dictation (future: media transcription)
            selectedSection = .dictation
            
            // Could post notification for future audio import feature
            print("📁 Audio import not yet implemented, redirected to dictation")
        } else {
            // Unknown file type - try documents first
            selectedSection = .readAloud
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ImportDocumentFile"),
                    object: url
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