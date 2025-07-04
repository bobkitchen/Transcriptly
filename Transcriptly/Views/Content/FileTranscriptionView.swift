//
//  FileTranscriptionView.swift
//  Transcriptly
//
//  View for transcribing audio and video files
//

import SwiftUI
import UniformTypeIdentifiers

struct FileTranscriptionView: View {
    @StateObject private var transcriptionService = FileTranscriptionService.shared
    @State private var selectedFileURL: URL?
    @State private var isFileImporterPresented = false
    @State private var showingSaveDialog = false
    @State private var editedTranscription = ""
    
    // Responsive layout
    @Environment(\.availableWidth) private var availableWidth
    @Environment(\.sidebarCollapsed) private var sidebarCollapsed
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Main content
            ScrollView {
                VStack(spacing: DesignSystem.spacingLarge) {
                    if selectedFileURL == nil && !transcriptionService.isTranscribing {
                        // File selection (button only - dropzone is on home page)
                        fileSelectionSection
                    } else if transcriptionService.isTranscribing {
                        // Transcription in progress
                        transcriptionProgressSection
                    } else if let result = transcriptionService.transcriptionResult {
                        // Transcription result
                        transcriptionResultSection(result)
                    }
                    
                    // Error display
                    if let error = transcriptionService.error {
                        errorSection(error)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignSystem.marginStandard)
                .padding(.vertical, DesignSystem.spacingLarge)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: supportedContentTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .onReceive(NotificationCenter.default.publisher(for: .fileTranscriptionImportFile)) { notification in
            print("📡 FileTranscriptionView: Received file import notification")
            if let userInfo = notification.userInfo,
               let url = userInfo["fileURL"] as? URL {
                print("📁 FileTranscriptionView: Received file import notification for: \(url.lastPathComponent)")
                selectedFileURL = url
                startTranscription()
            } else {
                print("❌ FileTranscriptionView: Invalid notification data")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                Text("File Transcription")
                    .font(DesignSystem.Typography.pageTitle)
                    .foregroundColor(.primaryText)
                
                Text("Convert audio and video files to text")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            // Provider info (read-only, configured in Settings > AI Providers)
            HStack(spacing: DesignSystem.spacingSmall) {
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 14))
                Text("Apple Speech")
                    .font(DesignSystem.Typography.body)
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, DesignSystem.spacingMedium)
            .padding(.vertical, DesignSystem.spacingSmall)
            .background(Color.secondaryBackground)
            .cornerRadius(DesignSystem.cornerRadiusSmall)
            .help("Configure transcription provider in Settings > AI Providers")
        }
        .padding(.horizontal, DesignSystem.marginStandard)
        .padding(.vertical, DesignSystem.spacingLarge)
        .background(.regularMaterial.opacity(0.3))
    }
    
    // MARK: - File Selection Section
    
    private var fileSelectionSection: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // File selection prompt (dropzone is on home page)
            VStack(spacing: DesignSystem.spacingMedium) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Select audio or video file")
                    .font(DesignSystem.Typography.titleMedium)
                    .foregroundColor(.primaryText)
                
                Text("Browse for a file to transcribe, or use the universal dropzone on the home page")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                
                Button("Browse Files") {
                    isFileImporterPresented = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 200)
            .padding(DesignSystem.spacingLarge)
            .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
            
            // Supported formats
            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                Text("Supported Formats")
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundColor(.primaryText)
                
                Text(FileTranscriptionService.supportedFormatsString())
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignSystem.spacingMedium)
            .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
        }
    }
    
    // MARK: - Transcription Progress Section
    
    private var transcriptionProgressSection: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // File info card
            if let fileName = transcriptionService.currentFileName {
                HStack(spacing: DesignSystem.spacingMedium) {
                    Image(systemName: FileTranscriptionService.fileTypeIcon(for: URL(fileURLWithPath: fileName)))
                        .font(.system(size: 32))
                        .foregroundColor(FileTranscriptionService.fileTypeColor(for: URL(fileURLWithPath: fileName)))
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                        Text(fileName)
                            .font(DesignSystem.Typography.bodyLarge)
                            .foregroundColor(.primaryText)
                            .lineLimit(1)
                        
                        HStack(spacing: DesignSystem.spacingMedium) {
                            if let size = transcriptionService.currentFileSize {
                                Label(size, systemImage: "doc")
                                    .font(DesignSystem.Typography.bodySmall)
                                    .foregroundColor(.secondaryText)
                            }
                            
                            if let duration = transcriptionService.currentFileDuration {
                                Label(duration, systemImage: "clock")
                                    .font(DesignSystem.Typography.bodySmall)
                                    .foregroundColor(.secondaryText)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(DesignSystem.spacingLarge)
                .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
            }
            
            // Progress card
            VStack(spacing: DesignSystem.spacingMedium) {
                Text(transcriptionService.currentStatus)
                    .font(DesignSystem.Typography.bodyLarge)
                    .foregroundColor(.primaryText)
                
                ProgressView(value: transcriptionService.progress)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
                    .frame(height: 8)
                
                Text("\(Int(transcriptionService.progress * 100))%")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.secondaryText)
                
                Button("Cancel") {
                    transcriptionService.cancelTranscription()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(DesignSystem.spacingLarge)
            .frame(maxWidth: 600)
            .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
        }
    }
    
    // MARK: - Transcription Result Section
    
    private func transcriptionResultSection(_ result: String) -> some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // Action buttons
            HStack(spacing: DesignSystem.spacingMedium) {
                Button(action: copyToClipboard) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                
                Button(action: { showingSaveDialog = true }) {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("Transcribe Another") {
                    resetForNewFile()
                }
                .buttonStyle(.bordered)
            }
            
            // Editable transcription
            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                HStack {
                    Text("Transcription Result")
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Text("\(result.split(separator: " ").count) words")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.secondaryText)
                }
                
                TextEditor(text: .constant(result))
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.primaryText)
                    .scrollContentBackground(.hidden)
                    .padding(DesignSystem.spacingMedium)
                    .frame(minHeight: 300)
                    .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
            }
        }
        .fileExporter(
            isPresented: $showingSaveDialog,
            document: TextDocument(text: result),
            contentType: .plainText,
            defaultFilename: "transcription.txt"
        ) { result in
            switch result {
            case .success(let url):
                print("Saved to: \(url)")
            case .failure(let error):
                print("Save failed: \(error)")
            }
        }
    }
    
    // MARK: - Error Section
    
    private func errorSection(_ error: FileTranscriptionError) -> some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                Text("Transcription Error")
                    .font(DesignSystem.Typography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Text(error.localizedDescription)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button("Try Again") {
                transcriptionService.error = nil
                if selectedFileURL != nil {
                    startTranscription()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(DesignSystem.spacingLarge)
        .background(Color.orange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(DesignSystem.cornerRadiusMedium)
    }
    
    // MARK: - Helper Methods
    
    private var supportedContentTypes: [UTType] {
        var types: [UTType] = [.audio, .movie, .mpeg4Movie]
        
        // Add specific file types
        for ext in FileTranscriptionService.supportedAudioTypes {
            if let type = UTType(filenameExtension: ext) {
                types.append(type)
            }
        }
        
        for ext in FileTranscriptionService.supportedVideoTypes {
            if let type = UTType(filenameExtension: ext) {
                types.append(type)
            }
        }
        
        return types
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        print("📁 FileTranscriptionView: File selection result received")
        switch result {
        case .success(let urls):
            print("📁 FileTranscriptionView: Success - \(urls.count) files selected")
            if let url = urls.first {
                print("📁 FileTranscriptionView: Selected file: \(url.lastPathComponent)")
                selectedFileURL = url
                startTranscription()
            } else {
                print("❌ FileTranscriptionView: No files in selection")
            }
        case .failure(let error):
            print("❌ FileTranscriptionView: File selection error: \(error)")
        }
    }
    
    private func startTranscription() {
        guard let url = selectedFileURL else { 
            print("❌ FileTranscriptionView: No file URL available for transcription")
            return 
        }
        
        print("🚀 FileTranscriptionView: Starting transcription for: \(url.lastPathComponent)")
        
        Task {
            do {
                print("📝 FileTranscriptionView: Calling transcribeFile...")
                let result = try await transcriptionService.transcribeFile(url)
                print("✅ FileTranscriptionView: Transcription completed with \(result.count) characters")
                editedTranscription = result
            } catch {
                print("❌ FileTranscriptionView: Transcription error: \(error)")
            }
        }
    }
    
    private func copyToClipboard() {
        if let result = transcriptionService.transcriptionResult {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result, forType: .string)
            
            // Could show a toast notification here
        }
    }
    
    private func resetForNewFile() {
        selectedFileURL = nil
        transcriptionService.transcriptionResult = nil
        transcriptionService.error = nil
        editedTranscription = ""
    }
}

// MARK: - Supporting Views

struct DropzoneView<Content: View>: View {
    let acceptedTypes: [UTType]
    let onFileDrop: (URL) -> Void
    @ViewBuilder let content: () -> Content
    
    @State private var isDragOver = false
    
    var body: some View {
        content()
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                    .strokeBorder(
                        isDragOver ? Color.accentColor : Color.tertiaryText.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: isDragOver ? [] : [8, 8])
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                    .fill(isDragOver ? Color.accentColor.opacity(0.05) : Color.clear)
            )
            .animation(DesignSystem.gentleSpring, value: isDragOver)
            .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                print("📥 DropzoneView: Drop received with \(providers.count) providers")
                guard let provider = providers.first else {
                    print("❌ DropzoneView: No providers in drop")
                    return false
                }
                
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    DispatchQueue.main.async {
                        if let url = url {
                            print("✅ DropzoneView: Successfully loaded file: \(url.lastPathComponent)")
                            onFileDrop(url)
                        } else if let error = error {
                            print("❌ DropzoneView: Error loading dropped file: \(error.localizedDescription)")
                        }
                    }
                }
                
                return true
            }
    }
}


// Simple text document for file export
struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let text = String(data: data, encoding: .utf8) {
            self.text = text
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    FileTranscriptionView()
}