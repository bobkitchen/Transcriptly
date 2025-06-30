//
//  ReadAloudView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ReadAloudView: View {
    @StateObject private var readAloudService = ReadAloudService()
    @StateObject private var documentProcessor = DocumentProcessingService()
    @State private var showingDocumentPicker = false
    @State private var showingWebURLInput = false
    @State private var webURL = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with controls
            HStack {
                Text("Read Aloud")
                    .font(DesignSystem.Typography.titleLarge)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                // Import controls
                HStack(spacing: DesignSystem.spacingMedium) {
                    Button("Add Web Page") {
                        showingWebURLInput = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(documentProcessor.isProcessing)
                    
                    Button("Import Document") {
                        showingDocumentPicker = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(documentProcessor.isProcessing)
                    
                    // Processing indicator
                    if documentProcessor.isProcessing {
                        HStack(spacing: DesignSystem.spacingSmall) {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(documentProcessor.processingStatus)
                                    .font(DesignSystem.Typography.bodySmall)
                                    .foregroundColor(.primaryText)
                                
                                if documentProcessor.processingProgress > 0 {
                                    ProgressView(value: documentProcessor.processingProgress)
                                        .frame(width: 100)
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.spacingMedium)
                        .padding(.vertical, DesignSystem.spacingSmall)
                        .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusSmall)
                    }
                }
            }
            .padding(DesignSystem.spacingLarge)
            .liquidGlassCard()
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                    if readAloudService.hasDocument {
                        // Document reader content
                        documentReaderContent
                    } else {
                        // Empty state
                        emptyStateContent
                    }
                }
                .padding(DesignSystem.spacingLarge)
            }
        }
        .background(.regularMaterial)
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [
                .pdf, 
                .plainText, 
                .rtf, 
                .html,
                UTType(filenameExtension: "docx") ?? .data,
                UTType(filenameExtension: "doc") ?? .data
            ],
            allowsMultipleSelection: false
        ) { result in
            handleDocumentImport(result)
        }
        .sheet(isPresented: $showingWebURLInput) {
            WebURLInputSheet(
                url: $webURL,
                isPresented: $showingWebURLInput,
                onSubmit: handleWebURLInput
            )
        }
        .alert("Import Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private var documentReaderContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
            // Document header
            if let document = readAloudService.currentDocument {
                DocumentHeaderCard(document: document)
            }
            
            // Playback controls
            PlaybackControlsCard(
                service: readAloudService
            )
            
            // Document content with highlighting
            if let document = readAloudService.currentDocument {
                DocumentContentView(
                    document: document,
                    currentSentenceIndex: readAloudService.currentSentenceIndex,
                    onSentenceTap: { index in
                        Task {
                            await readAloudService.seekToSentence(index)
                        }
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateContent: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            Spacer()
            
            VStack(spacing: DesignSystem.spacingMedium) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.tertiaryText)
                
                Text("Welcome to Read Aloud")
                    .font(DesignSystem.Typography.titleLarge)
                    .foregroundColor(.primaryText)
                
                VStack(spacing: DesignSystem.spacingSmall) {
                    Text("Import a document or add a web page to get started with voice reading")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                    
                    Text("Supported formats: PDF, TXT, RTF, HTML, DOCX, DOC")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.tertiaryText)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Quick action buttons
            VStack(spacing: DesignSystem.spacingMedium) {
                Button("Import Document") {
                    showingDocumentPicker = true
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Add Web Page") {
                    showingWebURLInput = true
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func handleDocumentImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Check if the document processor can handle this file type
            guard documentProcessor.canProcess(url: url) else {
                showError("Unsupported file type. Please select a PDF, TXT, RTF, or HTML file.")
                return
            }
            
            Task {
                do {
                    // Process the document first
                    let processedDocument = try await documentProcessor.processDocument(from: url)
                    
                    // Then load it into the read aloud service
                    await readAloudService.loadProcessedDocument(processedDocument)
                    
                } catch {
                    await MainActor.run {
                        showError("Failed to import document: \(error.localizedDescription)")
                    }
                }
            }
            
        case .failure(let error):
            showError("Failed to select document: \(error.localizedDescription)")
        }
    }
    
    private func handleWebURLInput() {
        guard let url = URL(string: webURL), 
              (url.scheme == "http" || url.scheme == "https") else {
            showError("Please enter a valid web URL (starting with http:// or https://)")
            return
        }
        
        Task {
            do {
                // Process the web content
                let processedDocument = try await documentProcessor.processWebContent(from: url)
                
                // Load it into the read aloud service
                await readAloudService.loadProcessedDocument(processedDocument)
                
            } catch {
                await MainActor.run {
                    showError("Failed to load web page: \(error.localizedDescription)")
                }
            }
        }
        
        webURL = ""
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Supporting Views

struct DocumentHeaderCard: View {
    let document: ProcessedDocument
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                HStack {
                    Text(document.title)
                        .font(DesignSystem.Typography.titleLarge)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Text("\(document.sentences.count) sentences")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.tertiaryText)
                }
                
                HStack {
                    Label("\(document.metadata.wordCount) words", systemImage: "text.word.spacing")
                    
                    Spacer()
                    
                    Text("~\(Int(document.estimatedReadingTime / 60)) min read")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.tertiaryText)
                }
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(.secondaryText)
            }
            .padding(DesignSystem.spacingLarge)
            .liquidGlassCard()
    }
}

struct PlaybackControlsCard: View {
    @ObservedObject var service: ReadAloudService
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
                // Progress bar
                if service.totalSentences > 0 {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                        HStack {
                            Text("Progress")
                                .font(DesignSystem.Typography.bodySmall)
                                .foregroundColor(.secondaryText)
                            
                            Spacer()
                            
                            Text("\(service.currentSentenceIndex + 1) of \(service.totalSentences)")
                                .font(DesignSystem.Typography.bodySmall)
                                .foregroundColor(.tertiaryText)
                        }
                        
                        ProgressView(value: service.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                
                // Playback controls
                HStack(spacing: DesignSystem.spacingLarge) {
                    Button(action: {
                        Task {
                            await service.seekToSentence(max(0, service.currentSentenceIndex - 1))
                        }
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                    }
                    .disabled(service.currentSentenceIndex == 0)
                    
                    // Play/Pause button
                    Button(action: {
                        Task {
                            switch service.sessionState {
                            case .idle, .stopped:
                                await service.startReading()
                            case .playing:
                                service.pauseReading()
                            case .paused:
                                await service.resumeReading()
                            default:
                                break
                            }
                        }
                    }) {
                        Image(systemName: playPauseIcon)
                            .font(.title)
                    }
                    .disabled(!service.canLoadDocument && service.sessionState == .idle)
                    
                    Button(action: {
                        service.stopReading()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                    }
                    .disabled(service.sessionState == .idle || service.sessionState == .stopped)
                    
                    Button(action: {
                        Task {
                            await service.seekToSentence(min(service.totalSentences - 1, service.currentSentenceIndex + 1))
                        }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                    }
                    .disabled(service.currentSentenceIndex >= service.totalSentences - 1)
                }
                .foregroundColor(.accentColor)
            }
            .padding(DesignSystem.spacingLarge)
            .liquidGlassCard()
    }
    
    private var playPauseIcon: String {
        switch service.sessionState {
        case .playing:
            return "pause.circle.fill"
        case .paused:
            return "play.circle.fill"
        case .loading:
            return "circle.dotted"
        default:
            return "play.circle.fill"
        }
    }
}

struct DocumentContentView: View {
    let document: ProcessedDocument
    let currentSentenceIndex: Int
    let onSentenceTap: (Int) -> Void
    
    var body: some View {
        ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    ForEach(Array(document.sentences.enumerated()), id: \.element.id) { index, sentence in
                        SentenceView(
                            sentence: sentence,
                            index: index,
                            isCurrent: index == currentSentenceIndex,
                            onTap: { onSentenceTap(index) }
                        )
                    }
                }
                .padding(DesignSystem.spacingLarge)
            }
            .liquidGlassCard()
    }
}

struct SentenceView: View {
    let sentence: DocumentSentence
    let index: Int
    let isCurrent: Bool
    let onTap: () -> Void
    
    var body: some View {
        Text(sentence.text)
            .font(DesignSystem.Typography.body)
            .foregroundColor(isCurrent ? .primaryText : .secondaryText)
            .padding(.vertical, DesignSystem.spacingSmall)
            .padding(.horizontal, DesignSystem.spacingMedium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusSmall)
                    .fill(isCurrent ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .onTapGesture {
                onTap()
            }
            .animation(DesignSystem.fadeAnimation, value: isCurrent)
    }
}

struct WebURLInputSheet: View {
    @Binding var url: String
    @Binding var isPresented: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // Header with buttons
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Text("Add Web Page")
                    .font(DesignSystem.Typography.titleLarge)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Add") {
                    submitURL()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(url.isEmpty)
            }
            .padding(.horizontal, DesignSystem.spacingLarge)
            .padding(.top, DesignSystem.spacingLarge)
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                Text("Enter the URL of a web page to read aloud")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondaryText)
                
                TextField("https://example.com", text: $url)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        submitURL()
                    }
            }
            .padding(.horizontal, DesignSystem.spacingLarge)
            
            Spacer()
        }
        .frame(width: 400, height: 250)
    }
    
    private func submitURL() {
        onSubmit()
        isPresented = false
    }
}

#Preview {
    ReadAloudView()
        .frame(width: 800, height: 600)
}