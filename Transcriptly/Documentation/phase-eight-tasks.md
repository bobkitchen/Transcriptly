# Transcriptly Phase Eight - Read Aloud Detailed Task List

## Phase 8.0: Setup and Architecture

### Task 8.0.1: Create Phase Eight Branch
```bash
git checkout main
git pull origin main
git checkout -b phase-eight-read-aloud
git push -u origin phase-eight-read-aloud
```

### Task 8.0.2: Create Read Aloud Architecture
```
Transcriptly/
├── Services/
│   └── ReadAloud/
│       ├── DocumentProcessingService.swift
│       ├── ReadAloudService.swift
│       ├── VoiceProviderService.swift
│       └── DocumentHistoryService.swift
├── Views/
│   └── ReadAloud/
│       ├── ReadAloudView.swift
│       ├── DocumentDropZone.swift
│       ├── DocumentReaderWindow.swift
│       └── MiniPlayerView.swift
├── Models/
│   └── ReadAloud/
│       ├── ProcessedDocument.swift
│       ├── VoiceProvider.swift
│       └── ReadingSession.swift
└── Extensions/
    ├── NSAttributedString+Highlighting.swift
    └── String+Chunking.swift
```

### Task 8.0.3: Update Supabase Schema for Document History
```sql
-- Add document history table
CREATE TABLE document_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content_hash TEXT NOT NULL,
    document_type TEXT NOT NULL,
    source_url TEXT,
    last_read_position INTEGER DEFAULT 0,
    total_sentences INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, content_hash)
);

-- Add reading sessions table
CREATE TABLE reading_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    document_id UUID REFERENCES document_history(id) ON DELETE CASCADE,
    voice_provider TEXT NOT NULL,
    voice_name TEXT NOT NULL,
    playback_speed DECIMAL(3,1) NOT NULL,
    start_position INTEGER NOT NULL,
    end_position INTEGER,
    duration_seconds INTEGER,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_document_history_user_accessed ON document_history(user_id, last_accessed DESC);
CREATE INDEX idx_reading_sessions_document ON reading_sessions(document_id, created_at DESC);

-- RLS policies
CREATE POLICY "Users can manage own document history" ON document_history
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own reading sessions" ON reading_sessions
    FOR ALL USING (auth.uid() = user_id);
```

### Task 8.0.4: Update Sidebar Navigation
```swift
// Update SidebarView.swift
enum SidebarSection: String, CaseIterable {
    case home = "Home"
    case dictation = "Dictation"      // Renamed from "transcription"
    case readAloud = "Read Aloud"     // New section
    case aiProviders = "AI Providers"
    case learning = "Learning"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .dictation: return "mic.fill"     // Updated icon
        case .readAloud: return "speaker.wave.3.fill"  // New
        case .aiProviders: return "cpu"
        case .learning: return "brain"
        case .settings: return "gearshape.fill"
        }
    }
    
    var isEnabled: Bool {
        switch self {
        case .home, .dictation, .readAloud, .settings: return true  // readAloud now enabled
        case .aiProviders, .learning: return false
        }
    }
}
```

**Checkpoint 8.0**:
- [ ] Phase Eight branch created
- [ ] File structure created
- [ ] Supabase schema updated
- [ ] Sidebar navigation updated
- [ ] Git commit: "Setup Phase Eight read aloud architecture"

---

## Phase 8.1: Document Processing Infrastructure

### Task 8.1.1: Create Document Models
```swift
// Models/ReadAloud/ProcessedDocument.swift
import Foundation

struct ProcessedDocument: Codable, Identifiable {
    let id: UUID
    let title: String
    let contentHash: String
    let documentType: DocumentType
    let sourceUrl: String?
    let sentences: [String]
    let lastReadPosition: Int
    let totalSentences: Int
    let createdAt: Date
    let lastAccessed: Date
    
    enum DocumentType: String, Codable, CaseIterable {
        case pdf = "PDF"
        case docx = "Word Document"
        case web = "Web Page"
        
        var icon: String {
            switch self {
            case .pdf: return "doc.richtext"
            case .docx: return "doc.text"
            case .web: return "globe"
            }
        }
    }
    
    var progressPercentage: Double {
        guard totalSentences > 0 else { return 0 }
        return Double(lastReadPosition) / Double(totalSentences)
    }
    
    var estimatedReadingTime: TimeInterval {
        // Assume 150 words per minute average reading speed
        let averageWordsPerSentence = 12.0
        let totalWords = Double(totalSentences) * averageWordsPerSentence
        return totalWords / 150.0 * 60.0 // Convert to seconds
    }
}

// Models/ReadAloud/VoiceProvider.swift
enum VoiceProvider: String, CaseIterable {
    case apple = "Apple"
    case googleCloud = "Google Cloud"
    case elevenLabs = "ElevenLabs"
    
    var isAvailable: Bool {
        switch self {
        case .apple: return true  // Always available on macOS
        case .googleCloud: return true  // Free tier available
        case .elevenLabs: return false  // Requires API key setup
        }
    }
    
    var requiresInternet: Bool {
        switch self {
        case .apple: return false
        case .googleCloud, .elevenLabs: return true
        }
    }
}

struct VoiceOption: Identifiable, Codable {
    let id: String
    let name: String
    let provider: VoiceProvider
    let gender: Gender
    let language: String
    let isRecommended: Bool
    
    enum Gender: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
        case neutral = "Neutral"
    }
}

// Models/ReadAloud/ReadingSession.swift
struct ReadingSession: Codable {
    let id: UUID
    let documentId: UUID
    let voiceProvider: VoiceProvider
    let voiceName: String
    let playbackSpeed: Double
    let startPosition: Int
    let endPosition: Int?
    let durationSeconds: TimeInterval?
    let completed: Bool
    let createdAt: Date
}
```

### Task 8.1.2: Create Document Processing Service
```swift
// Services/ReadAloud/DocumentProcessingService.swift
import Foundation
import PDFKit
import UniformTypeIdentifiers

@MainActor
class DocumentProcessingService: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0
    @Published var processingStatus = ""
    
    private let maxFileSize: Int64 = 50 * 1024 * 1024 // 50MB
    
    func processDocument(from url: URL) async throws -> ProcessedDocument {
        isProcessing = true
        processingProgress = 0
        defer { isProcessing = false }
        
        // Validate file size
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = fileAttributes[.size] as? Int64 ?? 0
        
        guard fileSize <= maxFileSize else {
            throw DocumentProcessingError.fileTooLarge
        }
        
        // Determine document type
        let documentType = try determineDocumentType(from: url)
        
        processingStatus = "Extracting text content..."
        processingProgress = 0.2
        
        // Extract text based on type
        let extractedText: String
        switch documentType {
        case .pdf:
            extractedText = try await extractTextFromPDF(url: url)
        case .docx:
            extractedText = try await extractTextFromDocx(url: url)
        case .web:
            extractedText = try await extractTextFromWeb(url: url)
        }
        
        processingStatus = "Processing text structure..."
        processingProgress = 0.6
        
        // Clean and structure the text
        let cleanedText = try await cleanText(extractedText)
        
        processingStatus = "Creating reading segments..."
        processingProgress = 0.8
        
        // Split into sentences
        let sentences = splitIntoSentences(cleanedText)
        
        processingStatus = "Finalizing document..."
        processingProgress = 1.0
        
        // Create document model
        let contentHash = cleanedText.sha256
        let title = extractTitle(from: cleanedText, url: url, type: documentType)
        
        let document = ProcessedDocument(
            id: UUID(),
            title: title,
            contentHash: contentHash,
            documentType: documentType,
            sourceUrl: url.isFileURL ? nil : url.absoluteString,
            sentences: sentences,
            lastReadPosition: 0,
            totalSentences: sentences.count,
            createdAt: Date(),
            lastAccessed: Date()
        )
        
        return document
    }
    
    func processWebURL(_ urlString: String) async throws -> ProcessedDocument {
        guard let url = URL(string: urlString) else {
            throw DocumentProcessingError.invalidURL
        }
        
        return try await processDocument(from: url)
    }
    
    // MARK: - PDF Processing
    
    private func extractTextFromPDF(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let pdfDocument = PDFDocument(url: url) else {
                    continuation.resume(throwing: DocumentProcessingError.pdfProcessingFailed)
                    return
                }
                
                var fullText = ""
                let pageCount = pdfDocument.pageCount
                
                for pageIndex in 0..<pageCount {
                    guard let page = pdfDocument.page(at: pageIndex) else { continue }
                    
                    if let pageText = page.string {
                        fullText += pageText + "\n"
                    }
                    
                    // Update progress on main thread
                    DispatchQueue.main.async {
                        self.processingProgress = 0.2 + (Double(pageIndex + 1) / Double(pageCount)) * 0.3
                    }
                }
                
                continuation.resume(returning: fullText)
            }
        }
    }
    
    // MARK: - DOCX Processing
    
    private func extractTextFromDocx(url: URL) async throws -> String {
        // For now, use a simple approach - in production you'd want a proper DOCX parser
        // This is a placeholder that attempts to extract text from the document structure
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // DOCX files are zip archives - extract document.xml
                    let data = try Data(contentsOf: url)
                    
                    // This is a simplified approach - real implementation would parse XML properly
                    if let content = String(data: data, encoding: .utf8) {
                        // Extract text between XML tags (very basic approach)
                        let text = content.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        continuation.resume(returning: text)
                    } else {
                        throw DocumentProcessingError.docxProcessingFailed
                    }
                } catch {
                    continuation.resume(throwing: DocumentProcessingError.docxProcessingFailed)
                }
            }
        }
    }
    
    // MARK: - Web Content Processing
    
    private func extractTextFromWeb(url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw DocumentProcessingError.webProcessingFailed
        }
        
        // Use Apple's Foundation Models or basic HTML parsing to extract main content
        let cleanText = extractMainContentFromHTML(htmlString)
        
        return cleanText
    }
    
    private func extractMainContentFromHTML(_ html: String) -> String {
        // Simple approach - strip HTML tags and extract text
        // In production, you'd want to use proper HTML parsing to identify main content
        
        var text = html
        
        // Remove script and style tags with their content
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        
        // Remove HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        
        // Clean up whitespace
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return text
    }
    
    // MARK: - Text Processing
    
    private func cleanText(_ text: String) async throws -> String {
        // Use Apple Foundation Models for text cleaning if available
        // For now, basic cleanup
        
        var cleanedText = text
        
        // Remove excessive whitespace
        cleanedText = cleanedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Remove page numbers, headers, footers (basic patterns)
        cleanedText = cleanedText.replacingOccurrences(of: "Page \\d+", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "\\n\\d+\\n", with: "\n", options: .regularExpression)
        
        return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func splitIntoSentences(_ text: String) -> [String] {
        // Use NSLinguisticTagger for proper sentence segmentation
        let range = NSRange(location: 0, length: text.utf16.count)
        var sentences: [String] = []
        
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, 
                                options: [.bySentences, .localized]) { substring, _, _, _ in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines),
               !sentence.isEmpty {
                sentences.append(sentence)
            }
            return true
        }
        
        return sentences.isEmpty ? [text] : sentences
    }
    
    private func extractTitle(from text: String, url: URL, type: DocumentType) -> String {
        // Extract first meaningful line as title
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if let firstLine = lines.first, firstLine.count < 100 {
            return firstLine
        }
        
        // Fallback to filename or URL
        switch type {
        case .web:
            return url.host ?? url.absoluteString
        case .pdf, .docx:
            return url.lastPathComponent
        }
    }
    
    private func determineDocumentType(from url: URL) throws -> ProcessedDocument.DocumentType {
        if !url.isFileURL {
            return .web
        }
        
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "pdf":
            return .pdf
        case "docx", "doc":
            return .docx
        default:
            throw DocumentProcessingError.unsupportedFileType
        }
    }
}

enum DocumentProcessingError: LocalizedError {
    case fileTooLarge
    case invalidURL
    case unsupportedFileType
    case pdfProcessingFailed
    case docxProcessingFailed
    case webProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "File is too large (maximum 50MB)"
        case .invalidURL:
            return "Invalid URL provided"
        case .unsupportedFileType:
            return "Unsupported file type"
        case .pdfProcessingFailed:
            return "Failed to process PDF file"
        case .docxProcessingFailed:
            return "Failed to process Word document"
        case .webProcessingFailed:
            return "Failed to process web content"
        }
    }
}

extension String {
    var sha256: String {
        let data = Data(self.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
```

### Task 8.1.3: Create Voice Provider Service
```swift
// Services/ReadAloud/VoiceProviderService.swift
import Foundation
import AVFoundation

@MainActor
class VoiceProviderService: ObservableObject {
    @Published var availableVoices: [VoiceOption] = []
    @Published var selectedVoice: VoiceOption?
    @Published var playbackSpeed: Double = 1.0
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    init() {
        loadAvailableVoices()
        loadUserPreferences()
    }
    
    func loadAvailableVoices() {
        var voices: [VoiceOption] = []
        
        // Load Apple voices
        let appleVoices = loadAppleVoices()
        voices.append(contentsOf: appleVoices)
        
        // Add Google Cloud voices (if configured)
        let googleVoices = loadGoogleCloudVoices()
        voices.append(contentsOf: googleVoices)
        
        // Add ElevenLabs voices (if configured)
        let elevenLabsVoices = loadElevenLabsVoices()
        voices.append(contentsOf: elevenLabsVoices)
        
        availableVoices = voices
        
        // Set default voice if none selected
        if selectedVoice == nil {
            selectedVoice = voices.first { $0.isRecommended } ?? voices.first
        }
    }
    
    private func loadAppleVoices() -> [VoiceOption] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        var voiceOptions: [VoiceOption] = []
        
        // Filter for English voices and categorize by gender
        let englishVoices = voices.filter { $0.language.hasPrefix("en") }
        
        // Define known male and female voices (this is a simplified approach)
        let maleVoiceIdentifiers = ["com.apple.ttsbundle.Daniel-compact", "com.apple.ttsbundle.Alex-compact"]
        let femaleVoiceIdentifiers = ["com.apple.ttsbundle.Samantha-compact", "com.apple.ttsbundle.Victoria-compact"]
        
        for voice in englishVoices {
            let gender: VoiceOption.Gender
            if maleVoiceIdentifiers.contains(voice.identifier) {
                gender = .male
            } else if femaleVoiceIdentifiers.contains(voice.identifier) {
                gender = .female
            } else {
                gender = .neutral
            }
            
            let voiceOption = VoiceOption(
                id: voice.identifier,
                name: voice.name,
                provider: .apple,
                gender: gender,
                language: voice.language,
                isRecommended: voice.identifier == "com.apple.ttsbundle.Samantha-compact"
            )
            
            voiceOptions.append(voiceOption)
        }
        
        return voiceOptions
    }
    
    private func loadGoogleCloudVoices() -> [VoiceOption] {
        // Placeholder for Google Cloud TTS voices
        // In production, you'd query the Google Cloud TTS API for available voices
        
        return [
            VoiceOption(
                id: "google-en-US-Standard-A",
                name: "Google Female (Standard)",
                provider: .googleCloud,
                gender: .female,
                language: "en-US",
                isRecommended: true
            ),
            VoiceOption(
                id: "google-en-US-Standard-B",
                name: "Google Male (Standard)",
                provider: .googleCloud,
                gender: .male,
                language: "en-US",
                isRecommended: true
            ),
            VoiceOption(
                id: "google-en-US-WaveNet-A",
                name: "Google Female (WaveNet)",
                provider: .googleCloud,
                gender: .female,
                language: "en-US",
                isRecommended: false
            ),
            VoiceOption(
                id: "google-en-US-WaveNet-B",
                name: "Google Male (WaveNet)",
                provider: .googleCloud,
                gender: .male,
                language: "en-US",
                isRecommended: false
            )
        ]
    }
    
    private func loadElevenLabsVoices() -> [VoiceOption] {
        // Placeholder for ElevenLabs voices
        // These would be loaded from ElevenLabs API when configured
        
        return [
            VoiceOption(
                id: "elevenlabs-rachel",
                name: "Rachel (Premium)",
                provider: .elevenLabs,
                gender: .female,
                language: "en-US",
                isRecommended: true
            ),
            VoiceOption(
                id: "elevenlabs-adam",
                name: "Adam (Premium)",
                provider: .elevenLabs,
                gender: .male,
                language: "en-US",
                isRecommended: true
            )
        ]
    }
    
    func setSelectedVoice(_ voice: VoiceOption) {
        selectedVoice = voice
        saveUserPreferences()
    }
    
    func setPlaybackSpeed(_ speed: Double) {
        playbackSpeed = max(0.5, min(2.0, speed))
        saveUserPreferences()
    }
    
    private func loadUserPreferences() {
        let defaults = UserDefaults.standard
        playbackSpeed = defaults.object(forKey: "readAloudPlaybackSpeed") as? Double ?? 1.0
        
        if let voiceId = defaults.string(forKey: "readAloudSelectedVoiceId") {
            selectedVoice = availableVoices.first { $0.id == voiceId }
        }
    }
    
    private func saveUserPreferences() {
        let defaults = UserDefaults.standard
        defaults.set(playbackSpeed, forKey: "readAloudPlaybackSpeed")
        defaults.set(selectedVoice?.id, forKey: "readAloudSelectedVoiceId")
    }
}
```

**Test Protocol 8.1**:
1. Drop PDF file and verify text extraction
2. Test Word document processing
3. Test web URL processing
4. Verify sentence segmentation works
5. Test voice provider loading

**Checkpoint 8.1**:
- [ ] Document processing service functional
- [ ] PDF, DOCX, and web extraction working
- [ ] Voice provider service loading Apple voices
- [ ] Text cleaning and sentence splitting works
- [ ] Git commit: "Document processing infrastructure"

---

## Phase 8.2: Read Aloud UI Implementation

### Task 8.2.1: Create Read Aloud Main View
```swift
// Views/ReadAloud/ReadAloudView.swift
import SwiftUI

struct ReadAloudView: View {
    @StateObject private var documentProcessor = DocumentProcessingService()
    @StateObject private var voiceProvider = VoiceProviderService()
    @StateObject private var historyService = DocumentHistoryService()
    
    @State private var showingReaderWindow = false
    @State private var currentDocument: ProcessedDocument?
    @State private var dragOver = false
    
    var body: some View {
        VStack(spacing: 0) {
            if documentProcessor.isProcessing {
                ProcessingView(
                    progress: documentProcessor.processingProgress,
                    status: documentProcessor.processingStatus
                )
            } else if let document = currentDocument {
                DocumentProcessedView(
                    document: document,
                    onStartReading: {
                        showingReaderWindow = true
                    },
                    onClearDocument: {
                        currentDocument = nil
                    }
                )
            } else {
                MainReadAloudInterface(
                    onDocumentProcessed: { document in
                        currentDocument = document
                        historyService.addDocument(document)
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingReaderWindow) {
            if let document = currentDocument {
                DocumentReaderWindow(
                    document: document,
                    voiceProvider: voiceProvider
                )
            }
        }
    }
}

struct MainReadAloudInterface: View {
    let onDocumentProcessed: (ProcessedDocument) -> Void
    
    @StateObject private var documentProcessor = DocumentProcessingService()
    @StateObject private var historyService = DocumentHistoryService()
    @State private var urlText = ""
    @State private var dragOver = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // Header
            VStack(spacing: 8) {
                Text("Read Aloud")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text("Drop documents or paste web links to have them read to you")
                    .font(.system(size: 16))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Document Drop Zone
            DocumentDropZone(
                dragOver: $dragOver,
                onDocumentDropped: processDroppedDocument,
                onError: showError
            )
            
            // URL Input Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Or paste a web link:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryText)
                
                HStack {
                    TextField("https://example.com/article", text: $urlText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            processWebURL()
                        }
                    
                    Button("Read") {
                        processWebURL()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(urlText.isEmpty || documentProcessor.isProcessing)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Document History
            if !historyService.recentDocuments.isEmpty {
                DocumentHistorySection(
                    documents: historyService.recentDocuments,
                    onDocumentSelected: onDocumentProcessed
                )
            }
        }
        .padding(DesignSystem.marginStandard)
        .onDrop(of: [.fileURL], isTargeted: $dragOver) { providers in
            handleDrop(providers: providers)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func processDroppedDocument(_ url: URL) {
        Task {
            do {
                let document = try await documentProcessor.processDocument(from: url)
                onDocumentProcessed(document)
            } catch {
                showError(error.localizedDescription)
            }
        }
    }
    
    private func processWebURL() {
        guard !urlText.isEmpty else { return }
        
        Task {
            do {
                let document = try await documentProcessor.processWebURL(urlText)
                onDocumentProcessed(document)
                urlText = ""
            } catch {
                showError(error.localizedDescription)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            DispatchQueue.main.async {
                if let url = url {
                    processDroppedDocument(url)
                }
            }
        }
        
        return true
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

struct ProcessingView: View {
    let progress: Double
    let status: String
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 300)
                
                Text(status)
                    .font(.system(size: 16))
                    .foregroundColor(.secondaryText)
            }
            .padding(32)
            .background(.regularMaterial)
            .cornerRadius(12)
            
            Spacer()
        }
    }
}

struct DocumentProcessedView: View {
    let document: ProcessedDocument
    let onStartReading: () -> Void
    let onClearDocument: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Document Info
            VStack(spacing: 12) {
                Image(systemName: document.documentType.icon)
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text(document.title)
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Label("\(document.totalSentences) sentences", 
                          systemImage: "text.alignleft")
                    
                    Label("\(Int(document.estimatedReadingTime / 60)) min read", 
                          systemImage: "clock")
                }
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: onStartReading) {
                    Label("Start Reading", systemImage: "play.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Process Another Document", action: onClearDocument)
                    .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding(DesignSystem.marginStandard)
    }
}
```

### Task 8.2.2: Create Document Drop Zone
```swift
// Views/ReadAloud/DocumentDropZone.swift
import SwiftUI

struct DocumentDropZone: View {
    @Binding var dragOver: Bool
    let onDocumentDropped: (URL) -> Void
    let onError: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(dragOver ? .accentColor : .secondary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("Drop your document here")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Text("Supports PDF, Word documents (.docx)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                
                Text("Maximum file size: 50MB")
                    .font(.system(size: 12))
                    .foregroundColor(.tertiaryText)
            }
            
            Button("Choose File") {
                chooseFile()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    dragOver ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(dragOver ? Color.accentColor.opacity(0.1) : Color.clear)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: dragOver)
    }
    
    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .init(filenameExtension: "docx") ?? .data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            onDocumentDropped(url)
        }
    }
}
```

### Task 8.2.3: Create Document History Section
```swift
// Add to ReadAloudView.swift
struct DocumentHistorySection: View {
    let documents: [ProcessedDocument]
    let onDocumentSelected: (ProcessedDocument) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Documents")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(documents.prefix(5)) { document in
                        DocumentHistoryCard(
                            document: document,
                            onSelected: {
                                onDocumentSelected(document)
                            }
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

struct DocumentHistoryCard: View {
    let document: ProcessedDocument
    let onSelected: () -> Void
    
    var body: some View {
        Button(action: onSelected) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: document.documentType.icon)
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    if document.progressPercentage > 0 {
                        CircularProgressView(progress: document.progressPercentage)
                            .frame(width: 16, height: 16)
                    }
                }
                
                Text(document.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text("\(document.totalSentences) sentences")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(width: 160, height: 100, alignment: .topLeading)
            .background(.regularMaterial)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
```

**Test Protocol 8.2**:
1. Test document drop zone with PDF files
2. Test URL input with web articles
3. Verify processing progress display
4. Test document history display
5. Test file picker dialog

**Checkpoint 8.2**:
- [ ] Read Aloud main interface complete
- [ ] Document drop zone functional
- [ ] URL processing works
- [ ] Document history display works
- [ ] Processing states clear to user
- [ ] Git commit: "Read Aloud UI implementation"

---

## Phase 8.3: Document Reader Window and Text-to-Speech

### Task 8.3.1: Create Document Reader Window
```swift
// Views/ReadAloud/DocumentReaderWindow.swift
import SwiftUI
import AVFoundation

struct DocumentReaderWindow: View {
    let document: ProcessedDocument
    @ObservedObject var voiceProvider: VoiceProviderService
    
    @StateObject private var readAloudService = ReadAloudService()
    @Environment(\.dismiss) var dismiss
    
    @State private var showingMiniPlayer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Window Header
            DocumentReaderHeader(
                document: document,
                isPlaying: readAloudService.isPlaying,
                currentPosition: readAloudService.currentSentenceIndex,
                totalSentences: document.totalSentences,
                onClose: { dismiss() },
                onMinimize: { showingMiniPlayer = true }
            )
            
            Divider()
            
            // Main Content Area
            HStack(spacing: 0) {
                // Document Text View
                DocumentTextView(
                    sentences: document.sentences,
                    currentSentenceIndex: readAloudService.currentSentenceIndex,
                    onSentenceSelected: { index in
                        readAloudService.seekToSentence(index)
                    }
                )
                
                Divider()
                
                // Reading Controls Sidebar
                ReadingControlsSidebar(
                    voiceProvider: voiceProvider,
                    readAloudService: readAloudService,
                    document: document
                )
                .frame(width: 300)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            readAloudService.loadDocument(document, voiceProvider: voiceProvider)
        }
        .sheet(isPresented: $showingMiniPlayer) {
            MiniPlayerView(
                document: document,
                readAloudService: readAloudService,
                voiceProvider: voiceProvider,
                onExpand: {
                    showingMiniPlayer = false
                }
            )
        }
    }
}

struct DocumentReaderHeader: View {
    let document: ProcessedDocument
    let isPlaying: Bool
    let currentPosition: Int
    let totalSentences: Int
    let onClose: () -> Void
    let onMinimize: () -> Void
    
    var progressPercentage: Double {
        guard totalSentences > 0 else { return 0 }
        return Double(currentPosition) / Double(totalSentences)
    }
    
    var body: some View {
        HStack {
            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label(document.documentType.rawValue, systemImage: document.documentType.icon)
                    
                    Text("Sentence \(currentPosition + 1) of \(totalSentences)")
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Progress bar
            ProgressView(value: progressPercentage)
                .frame(width: 150)
            
            Spacer()
            
            // Window controls
            HStack(spacing: 8) {
                Button(action: onMinimize) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 16))
                }
                .help("Minimize to mini player")
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 16))
                }
                .help("Close reader")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(DesignSystem.spacingMedium)
        .background(.ultraThinMaterial)
    }
}

struct DocumentTextView: View {
    let sentences: [String]
    let currentSentenceIndex: Int
    let onSentenceSelected: (Int) -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(sentences.enumerated()), id: \.offset) { index, sentence in
                        SentenceView(
                            sentence: sentence,
                            index: index,
                            isCurrentSentence: index == currentSentenceIndex,
                            onTapped: {
                                onSentenceSelected(index)
                            }
                        )
                        .id(index)
                    }
                }
                .padding(DesignSystem.marginStandard)
            }
            .onChange(of: currentSentenceIndex) { newIndex in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
}

struct SentenceView: View {
    let sentence: String
    let index: Int
    let isCurrentSentence: Bool
    let onTapped: () -> Void
    
    var body: some View {
        Text(sentence)
            .font(.system(size: 16, design: .default))
            .foregroundColor(.primaryText)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isCurrentSentence ? Color.accentColor.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isCurrentSentence ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .onTapGesture {
                onTapped()
            }
            .animation(.easeInOut(duration: 0.2), value: isCurrentSentence)
    }
}
```

### Task 8.3.2: Create Reading Controls Sidebar
```swift
// Add to DocumentReaderWindow.swift
struct ReadingControlsSidebar: View {
    @ObservedObject var voiceProvider: VoiceProviderService
    @ObservedObject var readAloudService: ReadAloudService
    let document: ProcessedDocument
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Playback Controls
            VStack(alignment: .leading, spacing: 16) {
                Text("Playback")
                    .font(.system(size: 18, weight: .semibold))
                
                // Main play/pause button
                Button(action: {
                    if readAloudService.isPlaying {
                        readAloudService.pause()
                    } else {
                        readAloudService.play()
                    }
                }) {
                    HStack {
                        Image(systemName: readAloudService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 24))
                        
                        Text(readAloudService.isPlaying ? "Pause" : "Play")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                
                // Skip controls
                HStack {
                    Button(action: { readAloudService.skipBackward() }) {
                        Label("15s", systemImage: "gobackward.15")
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button(action: { readAloudService.skipForward() }) {
                        Label("15s", systemImage: "goforward.15")
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Divider()
            
            // Voice Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Voice")
                    .font(.system(size: 18, weight: .semibold))
                
                if !voiceProvider.availableVoices.isEmpty {
                    VoiceSelectionView(voiceProvider: voiceProvider)
                }
            }
            
            Divider()
            
            // Speed Control
            VStack(alignment: .leading, spacing: 16) {
                Text("Speed")
                    .font(.system(size: 18, weight: .semibold))
                
                SpeedControlView(
                    speed: $voiceProvider.playbackSpeed,
                    onSpeedChanged: { newSpeed in
                        readAloudService.setPlaybackSpeed(newSpeed)
                    }
                )
            }
            
            Spacer()
            
            // Document Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Document Info")
                    .font(.system(size: 16, weight: .medium))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Sentences:")
                        Spacer()
                        Text("\(document.totalSentences)")
                    }
                    
                    HStack {
                        Text("Estimated time:")
                        Spacer()
                        Text("\(Int(document.estimatedReadingTime / 60)):\(String(format: "%02d", Int(document.estimatedReadingTime) % 60))")
                    }
                    
                    HStack {
                        Text("Progress:")
                        Spacer()
                        Text("\(Int(Double(readAloudService.currentSentenceIndex) / Double(document.totalSentences) * 100))%")
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            }
            .padding(12)
            .background(.regularMaterial)
            .cornerRadius(8)
        }
        .padding(DesignSystem.marginStandard)
        .background(Color.secondaryBackground)
    }
}

struct VoiceSelectionView: View {
    @ObservedObject var voiceProvider: VoiceProviderService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(VoiceProvider.allCases, id: \.self) { provider in
                if provider.isAvailable {
                    VoiceProviderSection(
                        provider: provider,
                        voices: voiceProvider.availableVoices.filter { $0.provider == provider },
                        selectedVoice: voiceProvider.selectedVoice,
                        onVoiceSelected: { voice in
                            voiceProvider.setSelectedVoice(voice)
                        }
                    )
                }
            }
        }
    }
}

struct VoiceProviderSection: View {
    let provider: VoiceProvider
    let voices: [VoiceOption]
    let selectedVoice: VoiceOption?
    let onVoiceSelected: (VoiceOption) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(provider.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            ForEach(voices) { voice in
                VoiceOptionRow(
                    voice: voice,
                    isSelected: selectedVoice?.id == voice.id,
                    onSelected: {
                        onVoiceSelected(voice)
                    }
                )
            }
        }
    }
}

struct VoiceOptionRow: View {
    let voice: VoiceOption
    let isSelected: Bool
    let onSelected: () -> Void
    
    var body: some View {
        Button(action: onSelected) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(voice.name)
                        .font(.system(size: 14))
                    
                    Text(voice.gender.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if voice.isRecommended {
                    Text("★")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct SpeedControlView: View {
    @Binding var speed: Double
    let onSpeedChanged: (Double) -> Void
    
    private let speedOptions: [Double] = [0.5, 1.0, 1.5, 2.0]
    
    var body: some View {
        VStack(spacing: 12) {
            // Speed buttons
            HStack {
                ForEach(speedOptions, id: \.self) { speedOption in
                    Button("\(speedOption, specifier: "%.1f")x") {
                        speed = speedOption
                        onSpeedChanged(speedOption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(speed == speedOption ? .accentColor : .primary)
                }
            }
            
            // Speed slider
            HStack {
                Text("0.5x")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: $speed, in: 0.5...2.0, step: 0.1) { _ in
                    onSpeedChanged(speed)
                }
                
                Text("2.0x")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Current: \(speed, specifier: "%.1f")x")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

**Test Protocol 8.3**:
1. Open document in reader window
2. Test sentence highlighting and scrolling
3. Test play/pause controls
4. Test voice selection switching
5. Test speed adjustment

**Checkpoint 8.3**:
- [ ] Document reader window functional
- [ ] Sentence highlighting works
- [ ] Voice controls integrated
- [ ] Speed adjustment works
- [ ] Click-to-jump functionality
- [ ] Git commit: "Document reader window and controls"

---

## Phase 8.4: Text-to-Speech Service Integration

### Task 8.4.1: Create Read Aloud Service
```swift
// Services/ReadAloud/ReadAloudService.swift
import Foundation
import AVFoundation
import Combine

@MainActor
class ReadAloudService: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var currentSentenceIndex = 0
    @Published var playbackSpeed: Double = 1.0
    
    private var document: ProcessedDocument?
    private var voiceProvider: VoiceProviderService?
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var sentences: [String] = []
    private var readingStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }
    
    func loadDocument(_ document: ProcessedDocument, voiceProvider: VoiceProviderService) {
        self.document = document
        self.voiceProvider = voiceProvider
        self.sentences = document.sentences
        self.currentSentenceIndex = document.lastReadPosition
        self.playbackSpeed = voiceProvider.playbackSpeed
        
        // Subscribe to voice provider changes
        voiceProvider.$selectedVoice
            .sink { [weak self] _ in
                self?.updateCurrentVoice()
            }
            .store(in: &cancellables)
        
        voiceProvider.$playbackSpeed
            .sink { [weak self] speed in
                self?.setPlaybackSpeed(speed)
            }
            .store(in: &cancellables)
    }
    
    func play() {
        guard !sentences.isEmpty else { return }
        
        if isPaused {
            speechSynthesizer.continueSpeaking()
            isPaused = false
        } else {
            startReadingFromCurrentPosition()
        }
        
        isPlaying = true
        readingStartTime = Date()
    }
    
    func pause() {
        speechSynthesizer.pauseSpeaking(at: .immediate)
        isPlaying = false
        isPaused = true
        saveReadingProgress()
    }
    
    func stop() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isPaused = false
        currentUtterance = nil
        saveReadingProgress()
    }
    
    func seekToSentence(_ index: Int) {
        guard index >= 0 && index < sentences.count else { return }
        
        let wasPlaying = isPlaying
        stop()
        
        currentSentenceIndex = index
        
        if wasPlaying {
            play()
        }
    }
    
    func skipForward() {
        seekToSentence(min(currentSentenceIndex + 3, sentences.count - 1))
    }
    
    func skipBackward() {
        seekToSentence(max(currentSentenceIndex - 3, 0))
    }
    
    func setPlaybackSpeed(_ speed: Double) {
        playbackSpeed = speed
        
        // If currently speaking, restart with new speed
        if isPlaying && !isPaused {
            let currentIndex = currentSentenceIndex
            stop()
            currentSentenceIndex = currentIndex
            play()
        }
    }
    
    private func startReadingFromCurrentPosition() {
        guard currentSentenceIndex < sentences.count else { return }
        
        let sentence = sentences[currentSentenceIndex]
        speakSentence(sentence)
    }
    
    private func speakSentence(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        
        // Configure utterance based on selected voice
        if let selectedVoice = voiceProvider?.selectedVoice {
            switch selectedVoice.provider {
            case .apple:
                if let avVoice = AVSpeechSynthesisVoice(identifier: selectedVoice.id) {
                    utterance.voice = avVoice
                }
            case .googleCloud:
                // TODO: Implement Google Cloud TTS
                break
            case .elevenLabs:
                // TODO: Implement ElevenLabs TTS
                break
            }
        }
        
        utterance.rate = Float(playbackSpeed * 0.5) // AVSpeechUtterance rate is different scale
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        currentUtterance = utterance
        speechSynthesizer.speak(utterance)
    }
    
    private func updateCurrentVoice() {
        // If currently speaking, restart with new voice
        if isPlaying && !isPaused {
            let currentIndex = currentSentenceIndex
            stop()
            currentSentenceIndex = currentIndex
            play()
        }
    }
    
    private func saveReadingProgress() {
        guard let document = document else { return }
        
        // Update document progress
        let updatedDocument = ProcessedDocument(
            id: document.id,
            title: document.title,
            contentHash: document.contentHash,
            documentType: document.documentType,
            sourceUrl: document.sourceUrl,
            sentences: document.sentences,
            lastReadPosition: currentSentenceIndex,
            totalSentences: document.totalSentences,
            createdAt: document.createdAt,
            lastAccessed: Date()
        )
        
        // Save to history service
        Task {
            await DocumentHistoryService.shared.updateDocument(updatedDocument)
        }
    }
}

extension ReadAloudService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Move to next sentence
        currentSentenceIndex += 1
        
        if currentSentenceIndex < sentences.count {
            // Continue with next sentence
            startReadingFromCurrentPosition()
        } else {
            // Finished reading document
            isPlaying = false
            isPaused = false
            saveReadingProgress()
            
            // Create reading session record
            createReadingSession()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        // Utterance started successfully
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isPaused = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isPaused = false
    }
    
    private func createReadingSession() {
        guard let document = document,
              let voiceProvider = voiceProvider,
              let selectedVoice = voiceProvider.selectedVoice,
              let startTime = readingStartTime else { return }
        
        let session = ReadingSession(
            id: UUID(),
            documentId: document.id,
            voiceProvider: selectedVoice.provider,
            voiceName: selectedVoice.name,
            playbackSpeed: playbackSpeed,
            startPosition: 0,
            endPosition: currentSentenceIndex,
            durationSeconds: Date().timeIntervalSince(startTime),
            completed: currentSentenceIndex >= document.totalSentences,
            createdAt: Date()
        )
        
        Task {
            await DocumentHistoryService.shared.saveReadingSession(session)
        }
    }
}
```

### Task 8.4.2: Create Document History Service
```swift
// Services/ReadAloud/DocumentHistoryService.swift
import Foundation

@MainActor
class DocumentHistoryService: ObservableObject {
    static let shared = DocumentHistoryService()
    
    @Published var recentDocuments: [ProcessedDocument] = []
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared
    private let maxRecentDocuments = 20
    
    private init() {
        Task {
            await loadRecentDocuments()
        }
    }
    
    func addDocument(_ document: ProcessedDocument) {
        // Add to local array
        if let existingIndex = recentDocuments.firstIndex(where: { $0.contentHash == document.contentHash }) {
            recentDocuments[existingIndex] = document
        } else {
            recentDocuments.insert(document, at: 0)
        }
        
        // Keep only recent documents
        if recentDocuments.count > maxRecentDocuments {
            recentDocuments = Array(recentDocuments.prefix(maxRecentDocuments))
        }
        
        // Save to Supabase
        Task {
            await saveDocumentToCloud(document)
        }
    }
    
    func updateDocument(_ document: ProcessedDocument) {
        // Update local array
        if let index = recentDocuments.firstIndex(where: { $0.id == document.id }) {
            recentDocuments[index] = document
        }
        
        // Update in Supabase
        Task {
            await saveDocumentToCloud(document)
        }
    }
    
    func removeDocument(_ document: ProcessedDocument) {
        recentDocuments.removeAll { $0.id == document.id }
        
        Task {
            await removeDocumentFromCloud(document)
        }
    }
    
    func saveReadingSession(_ session: ReadingSession) async {
        do {
            try await supabase.saveReadingSession(session)
        } catch {
            print("Failed to save reading session: \(error)")
        }
    }
    
    private func loadRecentDocuments() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let documents = try await supabase.getDocumentHistory()
            recentDocuments = documents
        } catch {
            print("Failed to load document history: \(error)")
            // Load from UserDefaults as fallback
            loadLocalDocuments()
        }
    }
    
    private func saveDocumentToCloud(_ document: ProcessedDocument) async {
        do {
            try await supabase.saveDocumentHistory(document)
        } catch {
            print("Failed to save document to cloud: \(error)")
            // Save locally as fallback
            saveLocalDocument(document)
        }
    }
    
    private func removeDocumentFromCloud(_ document: ProcessedDocument) async {
        do {
            try await supabase.removeDocumentHistory(document)
        } catch {
            print("Failed to remove document from cloud: \(error)")
        }
    }
    
    // MARK: - Local Storage Fallback
    
    private func loadLocalDocuments() {
        guard let data = UserDefaults.standard.data(forKey: "documentHistory"),
              let documents = try? JSONDecoder().decode([ProcessedDocument].self, from: data) else {
            return
        }
        
        recentDocuments = documents
    }
    
    private func saveLocalDocument(_ document: ProcessedDocument) {
        var documents = recentDocuments
        
        if let existingIndex = documents.firstIndex(where: { $0.contentHash == document.contentHash }) {
            documents[existingIndex] = document
        } else {
            documents.insert(document, at: 0)
        }
        
        if documents.count > maxRecentDocuments {
            documents = Array(documents.prefix(maxRecentDocuments))
        }
        
        if let data = try? JSONEncoder().encode(documents) {
            UserDefaults.standard.set(data, forKey: "documentHistory")
        }
    }
}

// MARK: - Supabase Extensions

extension SupabaseManager {
    func saveDocumentHistory(_ document: ProcessedDocument) async throws {
        guard let userId = currentUser?.id else {
            queueOfflineOperation(.saveDocumentHistory(document))
            return
        }
        
        let documentData: [String: Any] = [
            "id": document.id.uuidString,
            "user_id": userId.uuidString,
            "title": document.title,
            "content_hash": document.contentHash,
            "document_type": document.documentType.rawValue,
            "source_url": document.sourceUrl as Any,
            "last_read_position": document.lastReadPosition,
            "total_sentences": document.totalSentences,
            "created_at": document.createdAt.toISOString(),
            "last_accessed": document.lastAccessed.toISOString()
        ]
        
        try await client
            .from("document_history")
            .upsert(documentData)
            .execute()
    }
    
    func getDocumentHistory() async throws -> [ProcessedDocument] {
        guard let userId = currentUser?.id else { return [] }
        
        let response = try await client
            .from("document_history")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("last_accessed", ascending: false)
            .limit(20)
            .execute()
        
        // Parse response manually since we need custom decoding
        guard let data = response.data else { return [] }
        
        return try parseDocumentHistory(from: data)
    }
    
    func removeDocumentHistory(_ document: ProcessedDocument) async throws {
        guard let userId = currentUser?.id else { return }
        
        try await client
            .from("document_history")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("id", value: document.id.uuidString)
            .execute()
    }
    
    func saveReadingSession(_ session: ReadingSession) async throws {
        guard let userId = currentUser?.id else {
            queueOfflineOperation(.saveReadingSession(session))
            return
        }
        
        let sessionData: [String: Any] = [
            "id": session.id.uuidString,
            "user_id": userId.uuidString,
            "document_id": session.documentId.uuidString,
            "voice_provider": session.voiceProvider.rawValue,
            "voice_name": session.voiceName,
            "playback_speed": session.playbackSpeed,
            "start_position": session.startPosition,
            "end_position": session.endPosition as Any,
            "duration_seconds": session.durationSeconds as Any,
            "completed": session.completed,
            "created_at": session.createdAt.toISOString()
        ]
        
        try await client
            .from("reading_sessions")
            .insert(sessionData)
            .execute()
    }
    
    private func parseDocumentHistory(from data: Data) throws -> [ProcessedDocument] {
        // Custom parsing logic for document history
        // This is simplified - in production you'd want more robust parsing
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        
        return json.compactMap { dict in
            guard let idString = dict["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let title = dict["title"] as? String,
                  let contentHash = dict["content_hash"] as? String,
                  let documentTypeString = dict["document_type"] as? String,
                  let documentType = ProcessedDocument.DocumentType(rawValue: documentTypeString),
                  let lastReadPosition = dict["last_read_position"] as? Int,
                  let totalSentences = dict["total_sentences"] as? Int,
                  let createdAtString = dict["created_at"] as? String,
                  let lastAccessedString = dict["last_accessed"] as? String,
                  let createdAt = Date.fromISOString(createdAtString),
                  let lastAccessed = Date.fromISOString(lastAccessedString) else {
                return nil
            }
            
            let sourceUrl = dict["source_url"] as? String
            
            // Note: sentences are not stored in cloud to save space
            // They would need to be re-extracted when document is opened
            let sentences: [String] = []
            
            return ProcessedDocument(
                id: id,
                title: title,
                contentHash: contentHash,
                documentType: documentType,
                sourceUrl: sourceUrl,
                sentences: sentences,
                lastReadPosition: lastReadPosition,
                totalSentences: totalSentences,
                createdAt: createdAt,
                lastAccessed: lastAccessed
            )
        }
    }
}

// Add to PendingOperation enum
private enum PendingOperation {
    // ... existing cases
    case saveDocumentHistory(ProcessedDocument)
    case saveReadingSession(ReadingSession)
}

extension Date {
    func toISOString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
    
    static func fromISOString(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }
}
```

### Task 8.4.3: Create Mini Player View
```swift
// Views/ReadAloud/MiniPlayerView.swift
import SwiftUI

struct MiniPlayerView: View {
    let document: ProcessedDocument
    @ObservedObject var readAloudService: ReadAloudService
    @ObservedObject var voiceProvider: VoiceProviderService
    let onExpand: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack(spacing: 16) {
            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                Text("Sentence \(readAloudService.currentSentenceIndex + 1) of \(document.totalSentences)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Playback controls
            HStack(spacing: 12) {
                Button(action: { readAloudService.skipBackward() }) {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    if readAloudService.isPlaying {
                        readAloudService.pause()
                    } else {
                        readAloudService.play()
                    }
                }) {
                    Image(systemName: readAloudService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                
                Button(action: { readAloudService.skipForward() }) {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            
            // Speed indicator
            Text("\(voiceProvider.playbackSpeed, specifier: "%.1f")x")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            // Window controls
            HStack(spacing: 8) {
                Button(action: onExpand) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14))
                }
                .help("Expand to full reader")
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14))
                }
                .help("Close mini player")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(width: 500, height: 80)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}
```

**Test Protocol 8.4**:
1. Test speech synthesis with Apple voices
2. Test play/pause/stop functionality
3. Test sentence progression and highlighting
4. Test speed changes during playback
5. Test mini player controls

**Checkpoint 8.4**:
- [ ] Read Aloud service functional
- [ ] Speech synthesis working
- [ ] Sentence progression synced
- [ ] Speed control working
- [ ] Mini player functional
- [ ] Git commit: "Text-to-speech service integration"

---

## Phase 8.5: Final Polish and Testing

### Task 8.5.1: Add Google Cloud TTS Integration
```swift
// Services/ReadAloud/GoogleCloudTTSService.swift
import Foundation

class GoogleCloudTTSService {
    private let apiKey: String
    private let baseURL = "https://texttospeech.googleapis.com/v1/text:synthesize"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func synthesizeSpeech(text: String, voice: VoiceOption) async throws -> Data {
        let request = GoogleTTSRequest(
            input: GoogleTTSInput(text: text),
            voice: GoogleTTSVoice(
                languageCode: voice.language,
                name: voice.id,
                ssmlGender: voice.gender == .male ? "MALE" : "FEMALE"
            ),
            audioConfig: GoogleTTSAudioConfig(
                audioEncoding: "MP3",
                speakingRate: 1.0,
                pitch: 0.0
            )
        )
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GoogleTTSError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GoogleTTSError.apiError
        }
        
        let responseData = try JSONDecoder().decode(GoogleTTSResponse.self, from: data)
        
        guard let audioData = Data(base64Encoded: responseData.audioContent) else {
            throw GoogleTTSError.invalidAudioData
        }
        
        return audioData
    }
}

struct GoogleTTSRequest: Codable {
    let input: GoogleTTSInput
    let voice: GoogleTTSVoice
    let audioConfig: GoogleTTSAudioConfig
}

struct GoogleTTSInput: Codable {
    let text: String
}

struct GoogleTTSVoice: Codable {
    let languageCode: String
    let name: String
    let ssmlGender: String
}

struct GoogleTTSAudioConfig: Codable {
    let audioEncoding: String
    let speakingRate: Double
    let pitch: Double
}

struct GoogleTTSResponse: Codable {
    let audioContent: String
}

enum GoogleTTSError: LocalizedError {
    case invalidURL
    case apiError
    case invalidAudioData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Google Cloud TTS URL"
        case .apiError:
            return "Google Cloud TTS API error"
        case .invalidAudioData:
            return "Invalid audio data received"
        }
    }
}
```

### Task 8.5.2: Add Error Handling and Settings
```swift
// Update SettingsView.swift to include Read Aloud preferences
// Add to existing SettingsView:

// Read Aloud Settings
GroupBox("Read Aloud") {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Text("Default voice provider:")
            Spacer()
            Picker("Provider", selection: $defaultVoiceProvider) {
                ForEach(VoiceProvider.allCases, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
        }
        
        HStack {
            Text("Default playback speed:")
            Spacer()
            Picker("Speed", selection: $defaultPlaybackSpeed) {
                Text("0.5x").tag(0.5)
                Text("1.0x").tag(1.0)
                Text("1.5x").tag(1.5)
                Text("2.0x").tag(2.0)
            }
            .pickerStyle(.menu)
            .frame(width: 80)
        }
        
        Toggle("Auto-save reading progress", isOn: $autoSaveProgress)
        
        Toggle("Show sentence highlighting", isOn: $showSentenceHighlighting)
        
        HStack {
            Text("Google Cloud TTS API Key:")
            SecureField("Enter API key", text: $googleCloudAPIKey)
                .textFieldStyle(.roundedBorder)
        }
        
        HStack {
            Text("ElevenLabs API Key:")
            SecureField("Enter API key", text: $elevenLabsAPIKey)
                .textFieldStyle(.roundedBorder)
        }
    }
    .padding(.vertical, 4)
}
```

### Task 8.5.3: Performance Optimization
```swift
// Add to DocumentProcessingService.swift
private func optimizeTextForReading(_ text: String) -> String {
    var optimizedText = text
    
    // Replace abbreviations with full words for better pronunciation
    let replacements = [
        "Dr.": "Doctor",
        "Mr.": "Mister",
        "Mrs.": "Missus",
        "Ms.": "Miss",
        "Prof.": "Professor",
        "etc.": "etcetera",
        "i.e.": "that is",
        "e.g.": "for example",
        "&": "and",
        "%": "percent",
        "$": "dollars"
    ]
    
    for (abbreviation, fullForm) in replacements {
        optimizedText = optimizedText.replacingOccurrences(of: abbreviation, with: fullForm)
    }
    
    // Remove or replace problematic characters
    optimizedText = optimizedText.replacingOccurrences(of: "—", with: " - ")
    optimizedText = optimizedText.replacingOccurrences(of: """, with: "\"")
    optimizedText = optimizedText.replacingOccurrences(of: """, with: "\"")
    optimizedText = optimizedText.replacingOccurrences(of: "'", with: "'")
    optimizedText = optimizedText.replacingOccurrences(of: "'", with: "'")
    
    return optimizedText
}

// Add memory management for large documents
private func chunkLargeDocument(_ sentences: [String]) -> [[String]] {
    let maxChunkSize = 50 // sentences per chunk
    var chunks: [[String]] = []
    
    for i in stride(from: 0, to: sentences.count, by: maxChunkSize) {
        let endIndex = min(i + maxChunkSize, sentences.count)
        let chunk = Array(sentences[i..<endIndex])
        chunks.append(chunk)
    }
    
    return chunks
}
```

### Task 8.5.4: Comprehensive Testing
1. **Document Processing Test**: Test with various PDF and DOCX files
2. **Web Content Test**: Test with different websites and article formats
3. **Voice Quality Test**: Compare all available voices for clarity
4. **Performance Test**: Test with large documents (1000+ sentences)
5. **Error Handling Test**: Test with corrupted files, network issues
6. **Memory Test**: Monitor memory usage during long reading sessions

### Task 8.5.5: Documentation Update
```markdown
# Update CLAUDE.md with Phase Eight completion
## Phase Eight Complete - Read Aloud System ✅

### Major Features Added:
- Complete document processing pipeline (PDF, DOCX, web content)
- Multi-provider voice system (Apple, Google Cloud, ElevenLabs)
- Advanced document reader with sentence-level highlighting
- Reading progress tracking and document history
- Mini player for background reading
- Speed control (0.5x to 2.0x) and voice selection
- Supabase integration for cross-device sync

### Technical Implementation:
- DocumentProcessingService for content extraction
- ReadAloudService for TTS coordination and playback
- VoiceProviderService for multi-provider voice management
- DocumentHistoryService for progress tracking
- Separate document reader window with full controls

### UI/UX Features:
- Renamed "Transcription" to "Dictation" 
- Added "Read Aloud" sidebar section
- Document drop zone with visual feedback
- URL input for web content processing
- Sentence-level highlighting with click-to-jump
- Floating mini player for background reading

**Status**: Phase Eight Complete - Transcriptly now supports both voice input (dictation) and voice output (read aloud)
**Version**: 1.1.0-phase8-read-aloud-complete
**Next Phase**: UI overhaul and advanced reading features
```

**Phase 8 Final Checkpoint**:
- [ ] All document formats supported (PDF, DOCX, web)
- [ ] Multiple voice providers working
- [ ] Sentence highlighting synced with audio
- [ ] Speed control functional (0.5x-2.0x)
- [ ] Mini player and full reader modes
- [ ] Document history and progress tracking
- [ ] Supabase integration complete
- [ ] No regressions in existing dictation features
- [ ] Memory usage optimized for large documents
- [ ] Git commit: "Complete Phase Eight - Read Aloud system"
- [ ] Tag: v1.1.0-read-aloud-complete

---

## Success Metrics

### Functionality ✅
- Successfully processes PDF, DOCX, and web content
- Accurate sentence-level highlighting synchronized with speech
- Reliable voice playback with multiple provider options
- Progress tracking persists between sessions
- Background reading with mini player controls

### User Experience ✅  
- Intuitive document drop workflow
- Clear visual feedback during processing
- Smooth transitions between reader and mini player
- Responsive speed and voice switching
- Document history for easy re-access

### Technical ✅
- No impact on existing dictation functionality
- Stable memory usage during long documents
- Proper cleanup when switching documents
- Offline capability with Apple voices
- Cross-device sync via Supabase

### Innovation ✅
- Transforms Transcriptly into comprehensive voice productivity suite
- Seamless integration of input (dictation) and output (read aloud)
- Advanced document intelligence with content optimization
- Multi-provider voice ecosystem with user choice

This completes Phase Eight, successfully transforming Transcriptly from a dictation-only tool into a full voice productivity platform that handles both creating content through speech and consuming content through AI reading.
        