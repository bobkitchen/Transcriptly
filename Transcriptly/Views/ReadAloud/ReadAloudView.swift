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
    @StateObject private var documentHistory = DocumentHistoryService()
    @State private var showingDocumentPicker = false
    @State private var showingWebURLInput = false
    @State private var webURL = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isDragOver = false
    @State private var showingMiniPlayer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Integrated header with controls
            HStack {
                Text("Read Aloud")
                    .font(.system(size: 28, weight: .semibold))
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.regularMaterial.opacity(0.3))
            
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
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .adjustForFloatingSidebar()
        .background(Color.primaryBackground)
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
        .sheet(isPresented: $showingMiniPlayer) {
            if let document = readAloudService.currentDocument {
                MiniPlayerView(
                    document: document,
                    service: readAloudService,
                    onExpand: {
                        showingMiniPlayer = false
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var documentReaderContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
            // Document header
            if let document = readAloudService.currentDocument {
                DocumentHeaderCard(
                    document: document,
                    onMinimize: {
                        showingMiniPlayer = true
                    }
                )
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
            
            // Document Drop Zone
            VStack(spacing: DesignSystem.spacingLarge) {
                VStack(spacing: DesignSystem.spacingMedium) {
                    Image(systemName: isDragOver ? "doc.fill.badge.plus" : "doc.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(isDragOver ? .accentColor : .tertiaryText)
                        .symbolEffect(.bounce, value: isDragOver)
                    
                    VStack(spacing: DesignSystem.spacingSmall) {
                        Text(isDragOver ? "Drop document here" : "Drop your document here")
                            .font(DesignSystem.Typography.titleLarge)
                            .foregroundColor(.primaryText)
                            .fontWeight(.medium)
                        
                        Text("Or click to browse files")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Text("Supported formats: PDF, TXT, RTF, HTML, DOCX, DOC")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .frame(maxWidth: 500, minHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                        .strokeBorder(
                            isDragOver ? Color.accentColor : Color.secondary.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                                .fill(isDragOver ? Color.accentColor.opacity(0.1) : Color.clear)
                                .background(.regularMaterial.opacity(0.3))
                        )
                )
                .onTapGesture {
                    showingDocumentPicker = true
                }
                .animation(DesignSystem.fadeAnimation, value: isDragOver)
                
                // Web URL section
                HStack {
                    VStack(spacing: 2) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                    
                    Text("OR")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.secondaryText)
                        .padding(.horizontal, DesignSystem.spacingMedium)
                    
                    VStack(spacing: 2) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                }
                .frame(maxWidth: 300)
                
                Button("Add Web Page") {
                    showingWebURLInput = true
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(documentProcessor.isProcessing)
            }
            
            // Recent Documents Section
            if !documentHistory.recentDocuments.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                    HStack {
                        Text("Recent Documents")
                            .font(DesignSystem.Typography.titleMedium)
                            .foregroundColor(.primaryText)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(documentHistory.recentDocuments.count) documents")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(.tertiaryText)
                    }
                    .padding(.horizontal, DesignSystem.spacingMedium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.spacingMedium) {
                            ForEach(documentHistory.recentDocuments.prefix(5)) { document in
                                RecentDocumentCard(
                                    document: document,
                                    onTapped: {
                                        Task {
                                            await readAloudService.loadProcessedDocument(document)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, DesignSystem.spacingMedium)
                    }
                }
                .padding(.top, DesignSystem.spacingLarge)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDocumentDrop(providers: providers)
        }
    }
    
    private func handleDocumentDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            DispatchQueue.main.async {
                if let url = url {
                    self.processDocumentURL(url)
                } else if let error = error {
                    self.showError("Failed to load dropped file: \(error.localizedDescription)")
                }
            }
        }
        
        return true
    }
    
    private func handleDocumentImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            processDocumentURL(url)
            
        case .failure(let error):
            showError("Failed to select document: \(error.localizedDescription)")
        }
    }
    
    private func processDocumentURL(_ url: URL) {
        // Check if the document processor can handle this file type
        guard documentProcessor.canProcess(url: url) else {
            showError("Unsupported file type. Please select a PDF, TXT, RTF, HTML, DOCX, or DOC file.")
            return
        }
        
        Task {
            do {
                // Process the document first
                let processedDocument = try await documentProcessor.processDocument(from: url)
                
                // Save to history
                await documentHistory.saveDocument(processedDocument)
                
                // Then load it into the read aloud service
                await readAloudService.loadProcessedDocument(processedDocument)
                
            } catch {
                await MainActor.run {
                    showError("Failed to import document: \(error.localizedDescription)")
                }
            }
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
                
                // Save to history
                await documentHistory.saveDocument(processedDocument)
                
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
    let onMinimize: (() -> Void)?
    
    init(document: ProcessedDocument, onMinimize: (() -> Void)? = nil) {
        self.document = document
        self.onMinimize = onMinimize
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                HStack {
                    Text(document.title)
                        .font(DesignSystem.Typography.titleLarge)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    if let onMinimize = onMinimize {
                        Button(action: onMinimize) {
                            Image(systemName: "minus.circle")
                                .font(.title2)
                                .foregroundColor(.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .help("Minimize to mini player")
                    }
                    
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
            progressSection
            playbackControls
            speedControls
        }
        .padding(DesignSystem.spacingLarge)
        .liquidGlassCard()
    }
    
    @ViewBuilder
    private var progressSection: some View {
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
    }
    
    private var playbackControls: some View {
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
    
    private var speedControls: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
            HStack {
                Text("Playback Speed")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                Text("1.0x")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.primaryText)
                    .fontWeight(.medium)
            }
            
            HStack(spacing: DesignSystem.spacingMedium) {
                ForEach([0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                    Button("\(speed == 1.0 ? "1" : String(format: "%.2g", speed))x") {
                        // Placeholder action
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .controlSize(.mini)
                    .foregroundColor(abs(1.0 - speed) < 0.01 ? .accentColor : .secondaryText)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Slider(value: .constant(1.0), in: 0.5...2.5, step: 0.1)
                    .frame(width: 100)
                    
                    HStack {
                        Text("0.5")
                            .font(.caption2)
                            .foregroundColor(.tertiaryText)
                        Spacer()
                        Text("2.5")
                            .font(.caption2)
                            .foregroundColor(.tertiaryText)
                    }
                    .frame(width: 100)
                }
            }
        }
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

struct RecentDocumentCard: View {
    let document: ProcessedDocument
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                HStack {
                    Image(systemName: documentIcon)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    if document.sentences.count > 0 {
                        Text("\(document.sentences.count)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.tertiaryText)
                    }
                }
                
                Text(document.title)
                    .font(DesignSystem.Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text("\(document.metadata.wordCount) words")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    Text("~\(Int(document.estimatedReadingTime / 60))m")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.tertiaryText)
                }
            }
            .padding(DesignSystem.spacingMedium)
            .frame(width: 160, height: 120, alignment: .topLeading)
            .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusSmall)
        }
        .buttonStyle(.plain)
    }
    
    private var documentIcon: String {
        let filename = document.originalFilename
        let fileExtension = URL(fileURLWithPath: filename).pathExtension.lowercased()
        switch fileExtension {
        case "pdf":
            return "doc.richtext"
        case "docx", "doc":
            return "doc.text"
        case "html", "htm":
            return "globe"
        case "txt":
            return "doc.plaintext"
        case "rtf":
            return "doc.richtext"
        default:
            return "doc.text"
        }
    }
}

struct MiniPlayerView: View {
    let document: ProcessedDocument
    @ObservedObject var service: ReadAloudService
    let onExpand: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
            // Header
            HStack {
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Text("Mini Player")
                    .font(DesignSystem.Typography.titleMedium)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Expand") {
                    onExpand()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, DesignSystem.spacingLarge)
            .padding(.top, DesignSystem.spacingLarge)
            
            // Document info
            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                Text(document.title)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                HStack {
                    Text("Sentence \(service.currentSentenceIndex + 1) of \(service.totalSentences)")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    Text("1.0x")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.accentColor)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, DesignSystem.spacingLarge)
            
            // Progress bar
            if service.totalSentences > 0 {
                VStack(spacing: DesignSystem.spacingSmall) {
                    ProgressView(value: service.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    HStack {
                        Text("0:00")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.tertiaryText)
                        
                        Spacer()
                        
                        Text("\(Int(document.estimatedReadingTime / 60)):\(String(format: "%02d", Int(document.estimatedReadingTime) % 60))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.tertiaryText)
                    }
                }
                .padding(.horizontal, DesignSystem.spacingLarge)
            }
            
            // Compact controls
            HStack(spacing: DesignSystem.spacingLarge) {
                Button(action: {
                    Task {
                        await service.seekToSentence(max(0, service.currentSentenceIndex - 3))
                    }
                }) {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                }
                .disabled(service.currentSentenceIndex == 0)
                
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
                    Image(systemName: miniPlayerPlayIcon)
                        .font(.largeTitle)
                        .foregroundColor(.accentColor)
                }
                
                Button(action: {
                    Task {
                        await service.seekToSentence(min(service.totalSentences - 1, service.currentSentenceIndex + 3))
                    }
                }) {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                }
                .disabled(service.currentSentenceIndex >= service.totalSentences - 1)
            }
            .foregroundColor(.primaryText)
            .padding(.horizontal, DesignSystem.spacingLarge)
            .padding(.bottom, DesignSystem.spacingLarge)
        }
        .frame(width: 400, height: 250)
        .background(.regularMaterial)
        .cornerRadius(DesignSystem.cornerRadiusMedium)
    }
    
    private var miniPlayerPlayIcon: String {
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

#Preview {
    ReadAloudView()
        .frame(width: 800, height: 600)
}