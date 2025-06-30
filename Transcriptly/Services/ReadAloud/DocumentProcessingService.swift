//
//  DocumentProcessingService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//

import Foundation
import AppKit
import PDFKit
import WebKit
import UniformTypeIdentifiers
import Combine

@MainActor
final class DocumentProcessingService: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var processingStatus = "Ready"
    @Published var lastError: String?
    
    private let maxFileSize: Int = 50 * 1024 * 1024 // 50MB limit
    private let supportedTypes: Set<UTType> = [
        .pdf,
        .plainText,
        .rtf,
        .html,
        UTType(filenameExtension: "docx") ?? .data,
        UTType(filenameExtension: "doc") ?? .data
    ]
    
    init() {
        // Initialize service
    }
    
    /// Processes a document from a file URL
    /// - Parameter url: URL of the document to process
    /// - Returns: ProcessedDocument if successful
    func processDocument(from url: URL) async throws -> ProcessedDocument {
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentProcessingError.accessDenied
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        await updateProcessingState(isProcessing: true, status: "Reading file...")
        
        // Validate file
        try validateFile(at: url)
        
        // Determine file type and process accordingly
        let fileExtension = url.pathExtension.lowercased()
        let content: String
        let metadata: DocumentMetadata
        
        await updateProgress(0.3)
        
        switch fileExtension {
        case "pdf":
            (content, metadata) = try await processPDF(at: url)
        case "docx":
            (content, metadata) = try await processDOCX(at: url)
        case "doc":
            (content, metadata) = try await processDOC(at: url)
        case "txt", "rtf":
            (content, metadata) = try await processTextFile(at: url)
        case "html", "htm":
            (content, metadata) = try await processHTML(at: url)
        default:
            throw DocumentProcessingError.unsupportedFileType
        }
        
        await updateProgress(0.7)
        await updateProcessingState(status: "Processing content...")
        
        // Clean and prepare content
        let cleanedContent = content.cleanedForSpeech()
        let sentences = cleanedContent.sentences().enumerated().map { index, text in
            DocumentSentence(
                id: UUID(),
                index: index,
                text: text,
                startTime: nil,
                duration: nil
            )
        }
        
        await updateProgress(0.9)
        
        // Create processed document
        let document = ProcessedDocument(
            title: extractTitle(from: url, content: cleanedContent),
            originalFilename: url.lastPathComponent,
            filePath: url.path,
            content: cleanedContent,
            sentences: sentences,
            metadata: metadata
        )
        
        await updateProgress(1.0)
        await updateProcessingState(isProcessing: false, status: "Complete")
        
        return document
    }
    
    /// Processes web content from a URL
    /// - Parameter url: Web URL to process
    /// - Returns: ProcessedDocument if successful
    func processWebContent(from url: URL) async throws -> ProcessedDocument {
        await updateProcessingState(isProcessing: true, status: "Loading web page...")
        
        guard url.scheme == "http" || url.scheme == "https" else {
            throw DocumentProcessingError.invalidURL
        }
        
        let content = try await loadWebContent(from: url)
        await updateProgress(0.5)
        
        let cleanedContent = content.cleanedForSpeech()
        let sentences = cleanedContent.sentences().enumerated().map { index, text in
            DocumentSentence(
                id: UUID(),
                index: index,
                text: text,
                startTime: nil,
                duration: nil
            )
        }
        
        let metadata = DocumentMetadata(
            fileSize: content.data(using: .utf8)?.count ?? 0,
            wordCount: cleanedContent.wordCount(),
            characterCount: cleanedContent.count
        )
        
        let document = ProcessedDocument(
            title: extractWebTitle(from: content) ?? url.host ?? "Web Page",
            originalFilename: url.absoluteString,
            filePath: nil,
            content: cleanedContent,
            sentences: sentences,
            metadata: metadata
        )
        
        await updateProcessingState(isProcessing: false, status: "Complete")
        return document
    }
    
    /// Processes plain text content directly
    /// - Parameters:
    ///   - text: Text content to process
    ///   - title: Title for the document
    /// - Returns: ProcessedDocument
    func processText(_ text: String, title: String = "Text Document") async -> ProcessedDocument {
        await updateProcessingState(isProcessing: true, status: "Processing text...")
        
        let cleanedContent = text.cleanedForSpeech()
        let sentences = cleanedContent.sentences().enumerated().map { index, text in
            DocumentSentence(
                id: UUID(),
                index: index,
                text: text,
                startTime: nil,
                duration: nil
            )
        }
        
        let metadata = DocumentMetadata(
            fileSize: text.data(using: .utf8)?.count ?? 0,
            wordCount: cleanedContent.wordCount(),
            characterCount: cleanedContent.count
        )
        
        let document = ProcessedDocument(
            title: title,
            originalFilename: "\(title).txt",
            filePath: nil,
            content: cleanedContent,
            sentences: sentences,
            metadata: metadata
        )
        
        await updateProcessingState(isProcessing: false, status: "Complete")
        return document
    }
    
    // MARK: - Private Processing Methods
    
    private func validateFile(at url: URL) throws {
        let resources = try url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
        
        guard let fileSize = resources.fileSize else {
            throw DocumentProcessingError.unableToReadFile
        }
        
        if fileSize > maxFileSize {
            throw DocumentProcessingError.fileTooLarge
        }
        
        // Additional validation could be added here
    }
    
    private func processPDF(at url: URL) async throws -> (String, DocumentMetadata) {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw DocumentProcessingError.unableToReadFile
        }
        
        let pageCount = pdfDocument.pageCount
        guard pageCount > 0 else {
            throw DocumentProcessingError.processingFailed("PDF contains no pages")
        }
        
        var fullText = ""
        var processedPages = 0
        
        await updateProcessingState(status: "Extracting text from PDF...")
        
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { 
                print("Warning: Could not access page \(pageIndex + 1)")
                continue 
            }
            
            if let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if !pageText.isEmpty {
                    // Add page separator for multi-page documents
                    if !fullText.isEmpty {
                        fullText += "\n\n"
                    }
                    fullText += pageText
                    processedPages += 1
                }
            }
            
            // Update progress more granularly
            let progress = 0.3 + (Double(pageIndex + 1) / Double(pageCount)) * 0.4
            await updateProgress(progress)
            await updateProcessingState(status: "Processing page \(pageIndex + 1) of \(pageCount)...")
        }
        
        guard !fullText.isEmpty else {
            throw DocumentProcessingError.processingFailed("No readable text found in PDF")
        }
        
        // Extract enhanced metadata
        let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        let attributes = pdfDocument.documentAttributes ?? [:]
        
        let metadata = DocumentMetadata(
            fileSize: fileSize,
            wordCount: fullText.wordCount(),
            characterCount: fullText.count,
            pageCount: pageCount,
            author: attributes[PDFDocumentAttribute.authorAttribute] as? String,
            creationDate: attributes[PDFDocumentAttribute.creationDateAttribute] as? Date,
            modificationDate: attributes[PDFDocumentAttribute.modificationDateAttribute] as? Date
        )
        
        print("PDF processing complete: \(processedPages)/\(pageCount) pages, \(fullText.wordCount()) words")
        return (fullText, metadata)
    }
    
    private func processDOCX(at url: URL) async throws -> (String, DocumentMetadata) {
        // For DOCX files, we would need a proper library like DocX or use system tools
        // For now, this is a placeholder implementation
        throw DocumentProcessingError.unsupportedFileType
    }
    
    private func processDOC(at url: URL) async throws -> (String, DocumentMetadata) {
        // For DOC files, we would need system tools or third-party libraries
        // For now, this is a placeholder implementation
        throw DocumentProcessingError.unsupportedFileType
    }
    
    private func processTextFile(at url: URL) async throws -> (String, DocumentMetadata) {
        let content = try String(contentsOf: url, encoding: .utf8)
        
        let metadata = DocumentMetadata(
            fileSize: try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0,
            wordCount: content.wordCount(),
            characterCount: content.count
        )
        
        return (content, metadata)
    }
    
    private func processHTML(at url: URL) async throws -> (String, DocumentMetadata) {
        let htmlContent = try String(contentsOf: url, encoding: .utf8)
        let plainText = stripHTMLTags(from: htmlContent)
        
        let metadata = DocumentMetadata(
            fileSize: try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0,
            wordCount: plainText.wordCount(),
            characterCount: plainText.count
        )
        
        return (plainText, metadata)
    }
    
    private func loadWebContent(from url: URL) async throws -> String {
        await updateProcessingState(status: "Loading web page...")
        
        return try await withCheckedThrowingContinuation { continuation in
            let webView = WKWebView()
            var hasCompleted = false
            
            // Set up timeout
            let timeoutTask = Task {
                try await Task.sleep(for: .seconds(30)) // 30 second timeout
                if !hasCompleted {
                    hasCompleted = true
                    continuation.resume(throwing: DocumentProcessingError.networkError)
                }
            }
            
            let delegate = WebContentDelegate { result in
                guard !hasCompleted else { return }
                hasCompleted = true
                timeoutTask.cancel()
                continuation.resume(with: result)
            }
            
            webView.navigationDelegate = delegate
            
            // Configure web view for better text extraction
            let config = WKWebViewConfiguration()
            config.preferences.javaScriptEnabled = true
            
            let request = URLRequest(url: url, timeoutInterval: 30.0)
            webView.load(request)
        }
    }
    
    private func stripHTMLTags(from html: String) -> String {
        // Simple HTML tag removal - in production, use proper HTML parsing
        return html.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractTitle(from url: URL, content: String) -> String {
        // Try to extract title from filename first
        let filename = url.deletingPathExtension().lastPathComponent
        if !filename.isEmpty && filename != "Untitled" {
            return filename
        }
        
        // Try to extract from first line of content
        let lines = content.components(separatedBy: .newlines)
        let firstNonEmptyLine = lines.first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        if let firstLine = firstNonEmptyLine,
           firstLine.count <= 100,
           !firstLine.contains(".") { // Likely a title, not a sentence
            return firstLine.trimmingCharacters(in: .whitespaces)
        }
        
        return "Document"
    }
    
    private func extractWebTitle(from content: String) -> String? {
        // Simple title extraction from HTML - in production, use proper HTML parsing
        let titlePattern = "<title>(.*?)</title>"
        
        do {
            let regex = try NSRegularExpression(pattern: titlePattern, options: .caseInsensitive)
            let nsString = content as NSString
            let range = NSRange(location: 0, length: nsString.length)
            
            if let match = regex.firstMatch(in: content, options: [], range: range) {
                let titleRange = match.range(at: 1)
                return nsString.substring(with: titleRange)
            }
        } catch {
            // Ignore regex errors
        }
        
        return nil
    }
    
    private func updateProcessingState(isProcessing: Bool? = nil, status: String? = nil) async {
        if let isProcessing = isProcessing {
            self.isProcessing = isProcessing
        }
        if let status = status {
            self.processingStatus = status
        }
        if isProcessing == false {
            self.processingProgress = 0.0
        }
    }
    
    private func updateProgress(_ progress: Double) async {
        self.processingProgress = progress
    }
    
    // MARK: - Supported File Types
    
    func canProcess(url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        let supportedExtensions = ["pdf", "txt", "rtf", "html", "htm", "docx", "doc"]
        return supportedExtensions.contains(fileExtension)
    }
    
    func canProcess(fileType: UTType) -> Bool {
        return supportedTypes.contains(fileType)
    }
    
    var supportedFileExtensions: [String] {
        return ["pdf", "txt", "rtf", "html", "htm", "docx", "doc"]
    }
}

// MARK: - Error Types

enum DocumentProcessingError: LocalizedError {
    case unsupportedFileType
    case fileTooLarge
    case unableToReadFile
    case accessDenied
    case invalidURL
    case networkError
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFileType:
            return "This file type is not supported"
        case .fileTooLarge:
            return "File is too large (maximum 50MB)"
        case .unableToReadFile:
            return "Unable to read the file"
        case .accessDenied:
            return "Access to the file was denied"
        case .invalidURL:
            return "Invalid URL provided"
        case .networkError:
            return "Network error occurred"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        }
    }
}

// MARK: - Web Content Delegate

private class WebContentDelegate: NSObject, WKNavigationDelegate {
    private let completion: (Result<String, Error>) -> Void
    private var hasCompleted = false
    
    init(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !hasCompleted else { return }
        
        // Enhanced JavaScript for better content extraction
        let contentExtractionJS = """
            // Remove script and style elements
            var scripts = document.querySelectorAll('script, style, nav, header, footer, aside, .advertisement, .ad, .sidebar');
            scripts.forEach(function(element) {
                element.remove();
            });
            
            // Try to find main content area
            var mainContent = document.querySelector('main, article, .content, .main-content, #content, #main') || document.body;
            
            // Get clean text content
            var text = mainContent.innerText || mainContent.textContent || '';
            
            // Clean up whitespace
            text = text.replace(/\\s+/g, ' ').trim();
            
            text;
        """
        
        webView.evaluateJavaScript(contentExtractionJS) { result, error in
            self.hasCompleted = true
            
            if let error = error {
                // Fallback to simple text extraction
                webView.evaluateJavaScript("document.body.innerText || document.body.textContent || ''") { fallbackResult, _ in
                    if let text = fallbackResult as? String, !text.isEmpty {
                        self.completion(.success(text))
                    } else {
                        self.completion(.failure(DocumentProcessingError.processingFailed("Could not extract text from web page")))
                    }
                }
            } else if let text = result as? String, !text.isEmpty {
                self.completion(.success(text))
            } else {
                self.completion(.failure(DocumentProcessingError.processingFailed("Web page contains no readable text")))
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard !hasCompleted else { return }
        hasCompleted = true
        completion(.failure(error))
    }
}