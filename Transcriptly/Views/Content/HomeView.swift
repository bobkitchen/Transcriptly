//
//  HomeView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//  Updated by Claude Code on 6/28/25 for Phase 4 Liquid Glass UI
//  Updated by Claude Code on 1/3/25 for Phase 10 Visual Polish
//  Updated by Claude Code on 7/4/25 for Phase 11 Home UI Redesign Sprint
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
    @State private var isRecordButtonHovered = false
    @State private var isDropzoneHovered = false
    @State private var isProcessingFile = false
    @State private var processingFileName = ""
    @State private var processingFileType = ""
    @State private var showingFileError = false
    @State private var fileErrorTitle = ""
    @State private var fileErrorMessage = ""
    @State private var floatOffset: CGFloat = 0
    @State private var floatTimer: Timer?
    
    // Responsive layout properties
    @Environment(\.availableWidth) private var availableWidth
    @Environment(\.sidebarCollapsed) private var sidebarCollapsed
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Welcome section - 24pt padding top
                welcomeSection
                    .padding(.top, 24)
                
                // Main Action Area - 48pt margin top
                mainActionArea
                    .padding(.top, 48)
                
                // Productivity Section - 48pt margin from main content
                productivitySection
                    .padding(.top, 48)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 32) // Bottom padding: 32pt
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
        .overlay(
            // File Processing Overlay
            fileProcessingOverlay
        )
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
        .alert(fileErrorTitle, isPresented: $showingFileError) {
            Button("OK") { 
                isProcessingFile = false 
            }
        } message: {
            Text(fileErrorMessage)
        }
        .onAppear {
            userStats.loadTodayStats()
            startFloatAnimation()
        }
        .onDisappear {
            stopFloatAnimation()
        }
    }
    
    @ViewBuilder
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) { // Stats line: 12pt below welcome
            Text("Welcome back")
                .font(.system(size: 28, weight: .semibold)) // 28pt, semibold
                .foregroundColor(.primary)
            
            // Stats line (15pt, secondary)
            Text("\(userStats.todaySessions) transcriptions today • \(userStats.wordsFormatted) words • \(userStats.todayMinutesSaved) minutes saved")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var mainActionArea: some View {
        VStack(spacing: 32) {
            // Record Button
            recordButton
            
            // Universal Dropzone
            universalDropzone
        }
    }
    
    @ViewBuilder
    private var recordButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await handleRecordingAction()
                }
            }) {
                Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(.regularMaterial) // Liquid Glass styling
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        (viewModel.isRecording ? Color.red : Color.accentColor).opacity(isRecordButtonHovered ? 0.5 : 0.3),
                                        (viewModel.isRecording ? Color.red : Color.accentColor).opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(isRecordButtonHovered ? 0.15 : 0.1),
                        radius: isRecordButtonHovered ? 8 : 6,
                        x: 0,
                        y: isRecordButtonHovered ? 6 : 4
                    )
                    .scaleEffect(isRecordButtonHovered ? 1.05 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRecordButtonHovered)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isRecording)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isRecordButtonHovered = hovering
            }
            
            Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primaryText)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
        }
    }
    
    @ViewBuilder
    private var universalDropzone: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("Drop any file here")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Documents, audio, and video files supported")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200) // Min height: 200pt
        .padding(32) // Padding: 32pt
        .background(.ultraThinMaterial) // Background: ultra thin material
        .overlay(
            RoundedRectangle(cornerRadius: 16) // Corner radius: 16pt
                .strokeBorder(
                    Color.secondary.opacity(0.3), // Border color: secondary label color at 30% opacity
                    style: StrokeStyle(lineWidth: 2, dash: [8, 8]) // Dashed border (2pt, 8pt dash pattern)
                )
        )
        .cornerRadius(16)
        .scaleEffect(isDropzoneHovered ? 1.02 : 1.0)
        .offset(y: isDropzoneHovered ? 0 : floatOffset)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDropzoneHovered)
        .animation(.easeInOut(duration: 2.0), value: floatOffset)
        .onDrop(of: [.fileURL], isTargeted: $isDropzoneHovered) { providers in
            handleFileDrop(providers: providers)
        }
    }
    
    @ViewBuilder
    private var productivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            
            HStack(spacing: DesignSystem.spacingLarge) {
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
    
    @ViewBuilder
    private var fileProcessingOverlay: some View {
        if isProcessingFile {
            ZStack {
                // Semi-transparent backdrop
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                // Processing card
                VStack(spacing: 24) {
                    // File icon with scale animation
                    Image(systemName: fileTypeIcon(for: processingFileType))
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(1.2)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8).delay(0.1),
                            value: isProcessingFile
                        )
                    
                    // Progress indicator
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.accentColor)
                    
                    // Processing text
                    VStack(spacing: 8) {
                        Text("Processing \(processingFileName)...")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        Text("Redirecting to appropriate view")
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)
                    }
                }
                .padding(32)
                .frame(width: 320)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                .scaleEffect(isProcessingFile ? 1.0 : 0.8)
                .opacity(isProcessingFile ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isProcessingFile)
            }
        }
    }
    
    private func fileTypeIcon(for fileExtension: String) -> String {
        let ext = fileExtension.lowercased()
        let documentExtensions = ["txt", "rtf", "doc", "docx", "pdf", "md"]
        let audioExtensions = ["mp3", "wav", "m4a", "aac", "flac", "ogg"]
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm", "m4v"]
        
        if documentExtensions.contains(ext) {
            return "doc.text"
        } else if audioExtensions.contains(ext) {
            return "waveform"
        } else if videoExtensions.contains(ext) {
            return "video"
        } else {
            return "doc"
        }
    }
    
    // MARK: - File Handling Logic
    
    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            DispatchQueue.main.async {
                if let url = url {
                    print("📁 HomeView: Universal dropzone received file: \(url.lastPathComponent)")
                    self.processFileImport(url)
                } else if let error = error {
                    print("❌ HomeView: Error loading dropped file: \(error.localizedDescription)")
                }
            }
        }
        
        return true
    }
    
    private func processFileImport(_ url: URL) {
        print("📁 HomeView: File import requested for: \(url.lastPathComponent)")
        print("📁 HomeView: Full file path: \(url.path)")
        print("📁 HomeView: File extension: \(url.pathExtension.lowercased())")
        
        // Show processing overlay
        processingFileName = url.lastPathComponent
        processingFileType = url.pathExtension.lowercased()
        isProcessingFile = true
        
        // Check file size (50MB limit for safety)
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = fileAttributes[.size] as? Int {
                let maxSize = 50 * 1024 * 1024 // 50MB
                if fileSize > maxSize {
                    showFileError("File too large", "Maximum file size is 50MB. This file is \(ByteCountFormatter().string(fromByteCount: Int64(fileSize))).")
                    return
                }
            }
        } catch {
            showFileError("File Error", "Unable to read file information.")
            return
        }
        
        // File type detection as specified in documentation
        let fileExtension = url.pathExtension.lowercased()
        let documentExtensions = ["txt", "rtf", "doc", "docx", "pdf", "md"]
        let audioExtensions = ["mp3", "wav", "m4a", "aac", "flac", "ogg"]
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm", "m4v"]
        
        if documentExtensions.contains(fileExtension) {
            print("📁 HomeView: Document detected, navigating to Read Aloud")
            // Navigate to Read Aloud
            selectedSection = .readAloud
            
            // Post notification to trigger file import in ReadAloudView
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("📁 HomeView: Posting readAloudImportFile notification")
                NotificationCenter.default.post(
                    name: .readAloudImportFile,
                    object: nil,
                    userInfo: ["fileURL": url]
                )
                
                // Hide processing overlay after navigation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isProcessingFile = false
                }
            }
        } else if audioExtensions.contains(fileExtension) || videoExtensions.contains(fileExtension) {
            print("📁 HomeView: Audio/Video file detected, redirecting to file transcription")
            selectedSection = .fileTranscription
            
            // Post notification to trigger file import in FileTranscriptionView
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("📁 HomeView: Posting fileTranscriptionImportFile notification")
                NotificationCenter.default.post(
                    name: .fileTranscriptionImportFile,
                    object: nil,
                    userInfo: ["fileURL": url]
                )
                
                // Hide processing overlay after navigation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isProcessingFile = false
                }
            }
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
                
                // Hide processing overlay after navigation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isProcessingFile = false
                }
            }
        }
    }
    
    private func showFileError(_ title: String, _ message: String) {
        fileErrorTitle = title
        fileErrorMessage = message
        showingFileError = true
    }
    
    private func startFloatAnimation() {
        // Only animate if reduce motion is not enabled
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        
        floatTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 2.0)) {
                    floatOffset = floatOffset == 0 ? -3 : 0
                }
            }
        }
    }
    
    private func stopFloatAnimation() {
        floatTimer?.invalidate()
        floatTimer = nil
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
    HomeView(viewModel: AppViewModel(), selectedSection: .constant(.home), onFloat: {})
        .padding()
}