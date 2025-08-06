# Phase 8 Continuation - Enhanced Dropzone & Home Redesign Task List

## Phase 8A: Home Page Redesign

### Task 8A.0: Setup and Planning
```bash
git checkout main
git pull origin main
git checkout -b phase-8-continuation-enhanced-dropzone
git push -u origin phase-8-continuation-enhanced-dropzone
```

### Task 8A.1: Create Three-Card Home Layout
```swift
// Update Views/Home/HomeView.swift
struct HomeView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showingDictation = false
    @State private var dragOverHomeDropzone = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                // Header
                Text("Transcriptly")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                // Three Main Cards
                HStack(spacing: DesignSystem.spacingLarge) {
                    DictationCard(
                        isRecording: viewModel.isRecording,
                        onStartDictation: {
                            viewModel.toggleRecording()
                        }
                    )
                    
                    ReadDocumentsCard(
                        dragOver: $dragOverHomeDropzone,
                        onDocumentDropped: { url in
                            processDroppedDocument(url)
                        }
                    )
                    
                    TranscribeMediaCard(isEnabled: false)
                }
                .frame(height: 200)
                
                // Statistics Section (Moved Down)
                UsageStatisticsSection()
                
                // Recent Activity (30 days)
                RecentActivitySection()
            }
            .padding(DesignSystem.marginStandard)
        }
        .onDrop(of: [.fileURL], isTargeted: $dragOverHomeDropzone) { providers in
            handleHomeDrop(providers: providers)
        }
    }
    
    private func processDroppedDocument(_ url: URL) {
        // Navigate to Read Aloud section and process
        // This will be implemented in Phase 8B
    }
    
    private func handleHomeDrop(providers: [NSItemProvider]) -> Bool {
        // Implementation in Phase 8B
        return false
    }
}

// Components/Cards/DictationCard.swift
struct DictationCard: View {
    let isRecording: Bool
    let onStartDictation: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onStartDictation) {
            VStack(spacing: 16) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(isRecording ? .red : .accentColor)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(spacing: 4) {
                    Text("Record Dictation")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Text(isRecording ? "Recording..." : "⌘⇧V to start")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isHovered ? Color.accentColor.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Components/Cards/ReadDocumentsCard.swift
struct ReadDocumentsCard: View {
    @Binding var dragOver: Bool
    let onDocumentDropped: (URL) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(dragOver ? .accentColor : .secondaryText)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 4) {
                Text("Read Documents")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text("Drop files here")
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            dragOver ? Color.accentColor : 
                            (isHovered ? Color.accentColor.opacity(0.3) : Color.clear),
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: dragOver ? [8, 4] : []
                            )
                        )
                )
        )
        .scaleEffect(dragOver ? 1.02 : (isHovered ? 1.01 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOver)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Components/Cards/TranscribeMediaCard.swift
struct TranscribeMediaCard: View {
    let isEnabled: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.tertiaryText)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 4) {
                Text("Transcribe Media")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.tertiaryText)
                
                Text("Coming Soon")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .cornerRadius(12)
        .opacity(0.6)
    }
}
```

### Task 8A.2: Create Statistics Section
```swift
// Update Views/Home/HomeView.swift
struct UsageStatisticsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Statistics")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            HStack(spacing: DesignSystem.spacingLarge) {
                StatCard(
                    icon: "chart.bar.fill",
                    title: "Today",
                    value: "1,234",
                    subtitle: "words",
                    secondaryValue: "12 sessions"
                )
                
                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "This Week", 
                    value: "8,456",
                    subtitle: "words",
                    secondaryValue: "45 min saved"
                )
                
                StatCard(
                    icon: "target",
                    title: "Efficiency",
                    value: "87%",
                    subtitle: "refined",
                    secondaryValue: "23 patterns"
                )
            }
        }
    }
}
```

**Test Protocol 8A**:
1. Verify three cards display correctly
2. Test dictation card functionality
3. Check card hover animations
4. Verify statistics section moved down
5. Ensure responsive layout

**Checkpoint 8A**:
- [ ] Three-card layout implemented
- [ ] Dictation card replaces old record button
- [ ] Statistics section relocated
- [ ] Transcription card shows "Coming Soon"
- [ ] Git commit: "Home page redesign with three cards"

---

## Phase 8B: Universal Dropzone System

### Task 8B.1: Create Enhanced Document Models
```swift
// Update Models/ReadAloud/ProcessedDocument.swift
extension ProcessedDocument {
    enum DocumentType: String, CaseIterable {
        case pdf = "PDF"
        case docx = "Word Document (DOCX)"
        case doc = "Word Document (DOC)"
        case rtf = "Rich Text Format"
        case txt = "Plain Text"
        case web = "Web Content"
        
        var supportedExtensions: [String] {
            switch self {
            case .pdf: return ["pdf"]
            case .docx: return ["docx"]
            case .doc: return ["doc"]
            case .rtf: return ["rtf"]
            case .txt: return ["txt", "text"]
            case .web: return []
            }
        }
        
        var icon: String {
            switch self {
            case .pdf: return "doc.richtext"
            case .docx, .doc: return "doc.text"
            case .rtf: return "doc.richtext"
            case .txt: return "doc.plaintext"
            case .web: return "globe"
            }
        }
        
        var maxFileSize: Int64 {
            switch self {
            case .pdf, .docx, .doc, .rtf: return 50 * 1024 * 1024 // 50MB
            case .txt: return 10 * 1024 * 1024 // 10MB
            case .web: return 0 // No limit for web content
            }
        }
    }
}

// Models/ReadAloud/DropzoneValidation.swift
struct DropzoneValidation {
    enum ValidationResult {
        case valid
        case unsupportedType(String)
        case fileTooLarge(Int64, Int64) // actual size, max size
        case fileNotFound
        case unknownError(String)
        
        var isValid: Bool {
            if case .valid = self { return true }
            return false
        }
        
        var errorMessage: String {
            switch self {
            case .valid:
                return ""
            case .unsupportedType(let type):
                return "Unsupported file type: \(type). Try PDF, Word, RTF, or TXT files."
            case .fileTooLarge(let actual, let max):
                let actualMB = actual / (1024 * 1024)
                let maxMB = max / (1024 * 1024)
                return "File too large (\(actualMB)MB). Maximum size is \(maxMB)MB."
            case .fileNotFound:
                return "File not found or cannot be accessed."
            case .unknownError(let error):
                return "Error: \(error)"
            }
        }
        
        var suggestion: String {
            switch self {
            case .unsupportedType:
                return "Convert to PDF or DOCX format for best results."
            case .fileTooLarge:
                return "Try splitting the document or compressing it."
            default:
                return ""
            }
        }
    }
    
    static func validateFile(_ url: URL) -> ValidationResult {
        // Check file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .fileNotFound
        }
        
        // Get file attributes
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            // Determine document type
            let pathExtension = url.pathExtension.lowercased()
            let documentType = ProcessedDocument.DocumentType.allCases.first { type in
                type.supportedExtensions.contains(pathExtension)
            }
            
            guard let type = documentType else {
                return .unsupportedType(pathExtension.isEmpty ? "unknown" : pathExtension)
            }
            
            // Check file size
            if fileSize > type.maxFileSize {
                return .fileTooLarge(fileSize, type.maxFileSize)
            }
            
            return .valid
            
        } catch {
            return .unknownError(error.localizedDescription)
        }
    }
}
```

### Task 8B.2: Create Universal Dropzone Component
```swift
// Components/Dropzone/UniversalDropzone.swift
import SwiftUI

struct UniversalDropzone: View {
    let context: DropzoneContext
    @Binding var dragOver: Bool
    let onFileDropped: (URL) -> Void
    let onValidationError: (DropzoneValidation.ValidationResult) -> Void
    
    @State private var isHovered = false
    @State private var showingPreview = false
    @State private var previewFile: URL?
    
    enum DropzoneContext {
        case homeCard
        case readAloudPage
        
        var title: String {
            switch self {
            case .homeCard: return "Drop Documents"
            case .readAloudPage: return "Drop your document here"
            }
        }
        
        var subtitle: String {
            switch self {
            case .homeCard: return "PDF, Word, RTF, TXT"
            case .readAloudPage: return "Supports PDF, Word documents, RTF, and plain text files"
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .homeCard: return 48
            case .readAloudPage: return 64
            }
        }
    }
    
    var body: some View {
        VStack(spacing: context == .homeCard ? 12 : 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: context.iconSize))
                .foregroundColor(dragOver ? .accentColor : .secondary)
                .symbolRenderingMode(.hierarchical)
                .animation(.easeInOut(duration: 0.2), value: dragOver)
            
            VStack(spacing: context == .homeCard ? 2 : 8) {
                Text(context.title)
                    .font(.system(size: context == .homeCard ? 16 : 20, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Text(context.subtitle)
                    .font(.system(size: context == .homeCard ? 12 : 14))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                
                if context == .readAloudPage {
                    Text("Maximum file size: 50MB")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                }
            }
            
            if context == .readAloudPage {
                Button("Choose File") {
                    chooseFile()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: context == .homeCard ? 12 : 16)
                .fill(dragOver ? Color.accentColor.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: context == .homeCard ? 12 : 16)
                        .strokeBorder(
                            dragOver ? Color.accentColor : 
                            (isHovered ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.3)),
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: dragOver ? [8, 4] : []
                            )
                        )
                )
        )
        .scaleEffect(dragOver ? 1.02 : (isHovered ? 1.01 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOver)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onDrop(of: [.fileURL], isTargeted: $dragOver) { providers in
            handleDrop(providers: providers)
        }
        .sheet(isPresented: $showingPreview) {
            if let file = previewFile {
                FilePreviewSheet(
                    file: file,
                    onConfirm: {
                        processFile(file)
                        showingPreview = false
                    },
                    onCancel: {
                        showingPreview = false
                    }
                )
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            DispatchQueue.main.async {
                if let url = url {
                    processFile(url)
                }
            }
        }
        
        return true
    }
    
    private func processFile(_ url: URL) {
        let validation = DropzoneValidation.validateFile(url)
        
        if validation.isValid {
            onFileDropped(url)
        } else {
            onValidationError(validation)
        }
    }
    
    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .pdf,
            UTType("com.microsoft.word.wordml")!,
            UTType("com.microsoft.word.doc")!,
            UTType("public.rtf")!,
            .plainText
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            processFile(url)
        }
    }
}

// Components/Dropzone/FilePreviewSheet.swift
struct FilePreviewSheet: View {
    let file: URL
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var fileInfo: FileInfo?
    
    private struct FileInfo {
        let name: String
        let size: String
        let type: String
        let icon: String
        let estimatedProcessingTime: String
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if let info = fileInfo {
                VStack(spacing: 16) {
                    Image(systemName: info.icon)
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    VStack(spacing: 8) {
                        Text(info.name)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(2)
                        
                        HStack(spacing: 16) {
                            Text(info.type)
                            Text("•")
                            Text(info.size)
                            Text("•")
                            Text(info.estimatedProcessingTime)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)
                    
                    Button("Process Document", action: onConfirm)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ProgressView()
                    .onAppear {
                        loadFileInfo()
                    }
            }
        }
        .padding(24)
        .frame(width: 400)
    }
    
    private func loadFileInfo() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                let fileSizeString = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
                
                let pathExtension = file.pathExtension.lowercased()
                let documentType = ProcessedDocument.DocumentType.allCases.first { type in
                    type.supportedExtensions.contains(pathExtension)
                } ?? .txt
                
                // Estimate processing time based on file size
                let estimatedSeconds = max(5, Int(fileSize / (1024 * 1024)) * 2) // ~2 seconds per MB, minimum 5 seconds
                let timeString = estimatedSeconds < 60 ? "\(estimatedSeconds) seconds" : "\(estimatedSeconds / 60) minutes"
                
                let info = FileInfo(
                    name: file.lastPathComponent,
                    size: fileSizeString,
                    type: documentType.rawValue,
                    icon: documentType.icon,
                    estimatedProcessingTime: "~\(timeString)"
                )
                
                DispatchQueue.main.async {
                    fileInfo = info
                }
            } catch {
                DispatchQueue.main.async {
                    onCancel()
                }
            }
        }
    }
}
```

### Task 8B.3: Update Document Processing Service
```swift
// Update Services/ReadAloud/DocumentProcessingService.swift
extension DocumentProcessingService {
    
    func processDocumentWithValidation(from url: URL) async throws -> ProcessedDocument {
        // Validate file first
        let validation = DropzoneValidation.validateFile(url)
        
        guard validation.isValid else {
            switch validation {
            case .unsupportedType(let type):
                throw DocumentProcessingError.unsupportedFileType(type)
            case .fileTooLarge(let actual, let max):
                throw DocumentProcessingError.fileTooLarge(actual: actual, max: max)
            case .fileNotFound:
                throw DocumentProcessingError.fileNotFound
            case .unknownError(let error):
                throw DocumentProcessingError.validationError(error)
            default:
                throw DocumentProcessingError.validationError("Unknown validation error")
            }
        }
        
        // Proceed with existing processing
        return try await processDocument(from: url)
    }
    
    // Enhanced DOCX processing
    private func extractTextFromDocx(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Read DOCX as ZIP archive
                    let archive = try Archive(url: url, accessMode: .read)
                    
                    // Find document.xml
                    guard let documentEntry = archive["word/document.xml"] else {
                        throw DocumentProcessingError.docxProcessingFailed
                    }
                    
                    var documentData = Data()
                    _ = try archive.extract(documentEntry) { data in
                        documentData.append(data)
                    }
                    
                    // Parse XML to extract text
                    let text = try parseDocumentXML(documentData)
                    continuation.resume(returning: text)
                    
                } catch {
                    continuation.resume(throwing: DocumentProcessingError.docxProcessingFailed)
                }
            }
        }
    }
    
    // Add DOC support (legacy Word format)
    private func extractTextFromDoc(url: URL) async throws -> String {
        // For DOC files, we'll use a simpler approach
        // In production, you might want to use a proper DOC parser
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try Data(contentsOf: url)
                    
                    // Simple text extraction (this is very basic)
                    // In a real implementation, you'd use a proper DOC format parser
                    let text = String(data: data, encoding: .utf8) ?? 
                              String(data: data, encoding: .ascii) ?? 
                              "Unable to extract text from this DOC file."
                    
                    // Clean up binary artifacts
                    let cleanedText = text.replacingOccurrences(of: "[\\x00-\\x1F\\x7F-\\x9F]", 
                                                              with: " ", 
                                                              options: .regularExpression)
                        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    continuation.resume(returning: cleanedText)
                } catch {
                    continuation.resume(throwing: DocumentProcessingError.docProcessingFailed)
                }
            }
        }
    }
    
    // Add RTF support
    private func extractTextFromRtf(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Use NSAttributedString to parse RTF
                    let rtfData = try Data(contentsOf: url)
                    let attributedString = try NSAttributedString(
                        data: rtfData,
                        options: [.documentType: NSAttributedString.DocumentType.rtf],
                        documentAttributes: nil
                    )
                    
                    continuation.resume(returning: attributedString.string)
                } catch {
                    continuation.resume(throwing: DocumentProcessingError.rtfProcessingFailed)
                }
            }
        }
    }
    
    // Add TXT support with encoding detection
    private func extractTextFromTxt(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    var encoding: String.Encoding = .utf8
                    let text = try String(contentsOf: url, usedEncoding: &encoding)
                    continuation.resume(returning: text)
                } catch {
                    // Try other encodings
                    do {
                        let text = try String(contentsOf: url, encoding: .utf16)
                        continuation.resume(returning: text)
                    } catch {
                        do {
                            let text = try String(contentsOf: url, encoding: .ascii)
                            continuation.resume(returning: text)
                        } catch {
                            continuation.resume(throwing: DocumentProcessingError.txtProcessingFailed)
                        }
                    }
                }
            }
        }
    }
}

// Add new error cases
extension DocumentProcessingError {
    static func unsupportedFileType(_ type: String) -> DocumentProcessingError {
        return .unsupportedFileType
    }
    
    static func fileTooLarge(actual: Int64, max: Int64) -> DocumentProcessingError {
        return .fileTooLarge
    }
    
    case validationError(String)
    case docProcessingFailed
    case rtfProcessingFailed
    case txtProcessingFailed
    case fileNotFound
}
```

**Test Protocol 8B**:
1. Test file validation with different types
2. Verify drag-and-drop visual feedback
3. Test processing with all supported formats
4. Verify error handling and user feedback
5. Test file size warnings

**Checkpoint 8B**:
- [ ] Universal dropzone component created
- [ ] File validation system working
- [ ] Visual feedback for drag operations
- [ ] Enhanced document processing
- [ ] Error handling with helpful messages
- [ ] Git commit: "Universal dropzone with validation"

---

## Phase 8C: Document Compatibility Enhancement

### Task 8C.1: Implement Advanced Document Parsers
```swift
// Services/ReadAloud/DocumentParsers/DocxParser.swift
import Foundation
import ZIPFoundation

class DocxParser {
    static func extractText(from url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    guard let archive = Archive(url: url, accessMode: .read) else {
                        throw DocumentProcessingError.docxProcessingFailed
                    }
                    
                    // Extract document.xml
                    guard let documentEntry = archive["word/document.xml"] else {
                        throw DocumentProcessingError.docxProcessingFailed
                    }
                    
                    var documentData = Data()
                    _ = try archive.extract(documentEntry) { data in
                        documentData.append(data)
                    }
                    
                    // Parse XML content
                    let xmlDoc = try XMLDocument(data: documentData)
                    let textNodes = try xmlDoc.nodes(forXPath: "//w:t")
                    
                    let extractedText = textNodes.compactMap { $0.stringValue }.joined(separator: " ")
                    
                    continuation.resume(returning: extractedText)
                } catch {
                    continuation.resume(throwing: DocumentProcessingError.docxProcessingFailed)
                }
            }
        }
    }
}

// Services/ReadAloud/DocumentParsers/RtfParser.swift
class RtfParser {
    static func extractText(from url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let rtfData = try Data(contentsOf: url)
                    
                    // Use NSAttributedString for RTF parsing
                    let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                        .documentType: NSAttributedString.DocumentType.rtf,
                        .characterEncoding: String.Encoding.utf8.rawValue
                    ]
                    
                    let attributedString = try NSAttributedString(
                        data: rtfData,
                        options: options,
                        documentAttributes: nil
                    )
                    
                    continuation.resume(returning: attributedString.string)
                } catch {
                    continuation.resume(throwing: DocumentProcessingError.rtfProcessingFailed)
                }
            }
        }
    }
}

// Services/ReadAloud/DocumentParsers/TextParser.swift
class TextParser {
    static func extractText(from url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Try different encodings in order of likelihood
                let encodings: [String.Encoding] = [.utf8, .utf16, .ascii, .isoLatin1]
                
                for encoding in encodings {
                    do {
                        let text = try String(contentsOf: url, encoding: encoding)
                        continuation.resume(returning: text)
                        return
                    } catch {
                        continue
                    }
                }
                
                continuation.resume(throwing: DocumentProcessingError.txtProcessingFailed)
            }
        }
    }
}
```

### Task 8C.2: Enhanced Web Content Extraction
```swift
// Services/ReadAloud/DocumentParsers/WebContentParser.swift
import Foundation
import SwiftSoup

class WebContentParser {
    static func extractArticleContent(from url: URL) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DocumentProcessingError.webProcessingFailed
        }
        
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw DocumentProcessingError.webProcessingFailed
        }
        
        return try extractMainContent(from: htmlString)
    }
    
    private static func extractMainContent(from html: String) throws -> String {
        let doc = try SwiftSoup.parse(html)
        
        // Remove unwanted elements
        try doc.select("script, style, nav, header, footer, aside, .advertisement, .ads").remove()
        
        // Try to find main content using common selectors
        let contentSelectors = [
            "article",
            "main", 
            ".article-content",
            ".post-content",
            ".entry-content",
            ".content",
            "#content"
        ]
        
        for selector in contentSelectors {
            let elements = try doc.select(selector)
            if !elements.isEmpty() {
                return try elements.first()?.text() ?? ""
            }
        }
        
        // Fallback: extract from body, removing navigation and sidebars
        try doc.select("nav, aside, .sidebar, .menu").remove()
        
        guard let body = try doc.select("body").first() else {
            throw DocumentProcessingError.webProcessingFailed
        }
        
        return try body.text()
    }
}
```

**Test Protocol 8C**:
1. Test DOCX files with complex formatting
2. Test RTF files with various content
3. Test TXT files with different encodings
4. Test web article extraction
5. Verify error handling for corrupted files

**Checkpoint 8C**:
- [ ] Enhanced DOCX parsing implemented
- [ ] RTF support working correctly
- [ ] TXT encoding detection functional
- [ ] Web content extraction improved
- [ ] All file types processing reliably
- [ ] Git commit: "Enhanced document compatibility"

---

## Phase 8D: Unified History System

### Task 8D.1: Create Activity History Models
```swift
// Models/History/ActivityRecord.swift
import Foundation

struct ActivityRecord: Codable, Identifiable {
    let id: UUID
    let type: ActivityType
    let title: String
    let subtitle: String?
    let timestamp: Date
    let progress: Double // 0.0 to 1.0
    let metadata: ActivityMetadata
    let expiresAt: Date
    
    enum ActivityType: String, Codable, CaseIterable {
        case dictation
        case documentReading
        
        var icon: String {
            switch self {
            case .dictation: return "mic.fill"
            case .documentReading: return "doc.text.fill"
            }
        }
        
        var displayName: String {
            switch self {
            case .dictation: return "Dictation"
            case .documentReading: return "Document Reading"
            }
        }
    }
    
    init(
        type: ActivityType,
        title: String,
        subtitle: String? = nil,
        progress: Double = 0.0,
        metadata: ActivityMetadata
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.timestamp = Date()
        self.progress = progress
        self.metadata = metadata
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

enum ActivityMetadata: Codable {
    case dictation(DictationMetadata)
    case documentReading(DocumentMetadata)
    
    struct DictationMetadata: Codable {
        let originalText: String
        let refinedText: String
        let refinementMode: RefinementMode
        let wordCount: Int
        let language: String
    }
    
    struct DocumentMetadata: Codable {
        let documentId: UUID
        let documentType: ProcessedDocument.DocumentType
        let totalSentences: Int
        let currentSentenceIndex: Int
        let estimatedReadingTime: TimeInterval
        let contentHash: String
    }
}
```

### Task 8D.2: Create History Service
```swift
// Services/History/ActivityHistoryService.swift
import Foundation

@MainActor
class ActivityHistoryService: ObservableObject {
    static let shared = ActivityHistoryService()
    
    @Published var recentActivities: [ActivityRecord] = []
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared
    private let maxLocalActivities = 100
    
    private init() {
        Task {
            await loadRecentActivities()
            startExpirationTimer()
        }
    }
    
    // MARK: - Activity Management
    
    func addDictationActivity(
        originalText: String,
        refinedText: String,
        mode: RefinementMode
    ) {
        let metadata = ActivityMetadata.dictation(
            ActivityMetadata.DictationMetadata(
                originalText: originalText,
                refinedText: refinedText,
                refinementMode: mode,
                wordCount: refinedText.split(separator: " ").count,
                language: "en-US"
            )
        )
        
        let activity = ActivityRecord(
            type: .dictation,
            title: "Voice Dictation",
            subtitle: "\(refinedText.split(separator: " ").count) words • \(mode.displayName)",
            progress: 1.0,
            metadata: metadata
        )
        
        addActivity(activity)
    }
    
    func addDocumentActivity(_ document: ProcessedDocument) {
        let metadata = ActivityMetadata.documentReading(
            ActivityMetadata.DocumentMetadata(
                documentId: document.id,
                documentType: document.documentType,
                totalSentences: document.totalSentences,
                currentSentenceIndex: document.lastReadPosition,
                estimatedReadingTime: document.estimatedReadingTime,
                contentHash: document.contentHash
            )
        )
        
        let progress = Double(document.lastReadPosition) / Double(document.totalSentences)
        
        let activity = ActivityRecord(
            type: .documentReading,
            title: document.title,
            subtitle: "\(document.totalSentences) sentences • \(Int(progress * 100))% read",
            progress: progress,
            metadata: metadata
        )
        
        addActivity(activity)
    }
    
    func updateDocumentProgress(_ document: ProcessedDocument) {
        // Find existing activity and update it
        if let index = recentActivities.firstIndex(where: { activity in
            if case .documentReading(let metadata) = activity.metadata {
                return metadata.documentId == document.id
            }
            return false
        }) {
            let oldActivity = recentActivities[index]
            let progress = Double(document.lastReadPosition) / Double(document.totalSentences)
            
            if case .documentReading(var metadata) = oldActivity.metadata {
                metadata.currentSentenceIndex = document.lastReadPosition
                
                let updatedActivity = ActivityRecord(
                    type: oldActivity.type,
                    title: oldActivity.title,
                    subtitle: "\(document.totalSentences) sentences • \(Int(progress * 100))% read",
                    progress: progress,
                    metadata: .documentReading(metadata)
                )
                
                recentActivities[index] = updatedActivity
                
                Task {
                    await saveActivityToCloud(updatedActivity)
                }
            }
        }
    }
    
    func removeActivity(_ activity: ActivityRecord) {
        recentActivities.removeAll { $0.id == activity.id }
        
        Task {
            await removeActivityFromCloud(activity)
        }
    }
    
    func clearExpiredActivities() {
        let expiredActivities = recentActivities.filter { $0.isExpired }
        recentActivities.removeAll { $0.isExpired }
        
        Task {
            for activity in expiredActivities {
                await removeActivityFromCloud(activity)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func addActivity(_ activity: ActivityRecord) {
        // Remove any existing activity with same content hash for documents
        if case .documentReading(let metadata) = activity.metadata {
            recentActivities.removeAll { existing in
                if case .documentReading(let existingMetadata) = existing.metadata {
                    return existingMetadata.contentHash == metadata.contentHash
                }
                return false
            }
        }
        
        // Add to beginning of list
        recentActivities.insert(activity, at: 0)
        
        // Keep only recent activities
        if recentActivities.count > maxLocalActivities {
            recentActivities = Array(recentActivities.prefix(maxLocalActivities))
        }
        
        Task {
            await saveActivityToCloud(activity)
        }
    }
    
    private func loadRecentActivities() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let activities = try await supabase.getActivityHistory()
            recentActivities = activities.filter { !$0.isExpired }
        } catch {
            print("Failed to load activity history: \(error)")
            loadLocalActivities()
        }
    }
    
    private func saveActivityToCloud(_ activity: ActivityRecord) async {
        do {
            try await supabase.saveActivityRecord(activity)
        } catch {
            print("Failed to save activity to cloud: \(error)")
            saveLocalActivity(activity)
        }
    }
    
    private func removeActivityFromCloud(_ activity: ActivityRecord) async {
        do {
            try await supabase.removeActivityRecord(activity)
        } catch {
            print("Failed to remove activity from cloud: \(error)")
        }
    }
    
    private func startExpirationTimer() {
        // Check for expired activities every hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task {
                await self.clearExpiredActivities()
            }
        }
    }
    
    // MARK: - Local Storage Fallback
    
    private func loadLocalActivities() {
        guard let data = UserDefaults.standard.data(forKey: "activityHistory"),
              let activities = try? JSONDecoder().decode([ActivityRecord].self, from: data) else {
            return
        }
        
        recentActivities = activities.filter { !$0.isExpired }
    }
    
    private func saveLocalActivity(_ activity: ActivityRecord) {
        if let data = try? JSONEncoder().encode(recentActivities) {
            UserDefaults.standard.set(data, forKey: "activityHistory")
        }
    }
}
```

### Task 8D.3: Create Recent Activity UI
```swift
// Views/Home/RecentActivitySection.swift
import SwiftUI

struct RecentActivitySection: View {
    @StateObject private var historyService = ActivityHistoryService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                if !historyService.recentActivities.isEmpty {
                    Button("Clear All") {
                        clearAllActivities()
                    }
                    .font(.system(size: 14))
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
            
            if historyService.recentActivities.isEmpty {
                EmptyActivityView()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(historyService.recentActivities.prefix(10)) { activity in
                        ActivityRowView(
                            activity: activity,
                            onTap: {
                                handleActivityTap(activity)
                            },
                            onRemove: {
                                historyService.removeActivity(activity)
                            }
                        )
                    }
                    
                    if historyService.recentActivities.count > 10 {
                        Button("View All (\(historyService.recentActivities.count - 10) more)") {
                            // TODO: Show full history view
                        }
                        .font(.system(size: 14))
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .padding(.top, 8)
                    }
                }
            }
        }
    }
    
    private func handleActivityTap(_ activity: ActivityRecord) {
        switch activity.type {
        case .dictation:
            // Could show dictation details or copy text
            break
        case .documentReading:
            if case .documentReading(let metadata) = activity.metadata {
                // Reopen document and continue reading
                reopenDocument(documentId: metadata.documentId)
            }
        }
    }
    
    private func reopenDocument(documentId: UUID) {
        // TODO: Implement document reopening
        // This would need to coordinate with DocumentHistoryService
        // to reload the document and open it in the reader
    }
    
    private func clearAllActivities() {
        historyService.recentActivities.removeAll()
    }
}

struct ActivityRowView: View {
    let activity: ActivityRecord
    let onTap: () -> Void
    let onRemove: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: activity.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primaryText)
                        .lineLimit(1)
                    
                    if let subtitle = activity.subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(activity.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                    
                    if activity.progress > 0 && activity.progress < 1 {
                        ProgressView(value: activity.progress)
                            .frame(width: 60)
                    }
                }
                
                if isHovered {
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No recent activity")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Your dictations and document reading will appear here")
                .font(.system(size: 14))
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
```

**Test Protocol 8D**:
1. Create dictation activities and verify they appear
2. Process documents and check activity creation
3. Test activity removal and clearing
4. Verify 30-day expiration logic
5. Test progress tracking for documents

**Checkpoint 8D**:
- [ ] Activity history models created
- [ ] History service implemented
- [ ] Recent activity UI functional
- [ ] 30-day retention working
- [ ] Progress tracking accurate
- [ ] Git commit: "Unified activity history system"

---

## Phase 8E: Integration and Polish

### Task 8E.1: Connect All Systems
```swift
// Update ViewModels/MainViewModel.swift
extension MainViewModel {
    func processHomeDropzoneDocument(_ url: URL) {
        Task {
            do {
                let document = try await documentProcessor.processDocumentWithValidation(from: url)
                
                // Add to history
                ActivityHistoryService.shared.addDocumentActivity(document)
                
                // Navigate to Read Aloud section
                // This would need to be coordinated with the navigation system
                
                // Open document reader
                openDocumentReader(document)
                
            } catch {
                showError(error.localizedDescription)
            }
        }
    }
    
    private func openDocumentReader(_ document: ProcessedDocument) {
        // Implementation depends on navigation structure
        // Could use NotificationCenter, delegate pattern, or state management
    }
}
```

### Task 8E.2: Final UI Polish
```swift
// Add loading states and animations
// Improve error messages
// Add haptic feedback where appropriate
// Ensure all animations are smooth
// Add keyboard shortcuts for common actions
```

### Task 8E.3: Performance Optimization
```swift
// Implement document caching
// Optimize memory usage for large files
// Add background processing where possible
// Implement lazy loading for history
```

**Final Test Protocol**:
1. Complete end-to-end workflow from home dropzone
2. Test all supported file formats
3. Verify history tracking works correctly
4. Test performance with large documents
5. Ensure no regressions in existing features

**Phase 8 Continuation Final Checkpoint**:
- [ ] Home page redesigned with three cards
- [ ] Universal dropzone system working
- [ ] Enhanced document compatibility
- [ ] Unified activity history functional
- [ ] All integrations complete
- [ ] Performance optimized
- [ ] Git commit: "Complete Phase 8 continuation"
- [ ] Tag: v1.2.0-enhanced-dropzone-complete

---

## Success Metrics

### User Experience
- **Intuitive Discovery**: Users immediately understand the three-card layout
- **Seamless Document Processing**: 95%+ success rate across all file types
- **Visual Feedback**: Clear, responsive drag-and-drop interactions
- **Activity Tracking**: Users can easily return to previous work

### Technical Performance
- **Processing Speed**: Documents ready within 10-15 seconds
- **Memory Efficiency**: Stable performance with 50MB files
- **Format Support**: Reliable parsing of PDF, DOCX, DOC, RTF, TXT
- **Cache Effectiveness**: Instant reopening of processed documents

### Feature Integration
- **Cross-Feature Harmony**: Dictation and document reading work seamlessly together
- **History Utility**: Users actively return to previous activities
- **Error Recovery**: Clear feedback and solutions for any issues

This continuation successfully transforms Transcriptly into a unified productivity platform with intuitive document handling and comprehensive activity tracking.