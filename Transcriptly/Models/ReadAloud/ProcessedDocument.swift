//
//  ProcessedDocument.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//

import Foundation

struct ProcessedDocument: Identifiable, Codable, Sendable {
    let id: UUID
    let title: String
    let originalFilename: String
    let filePath: String?
    let content: String
    let sentences: [DocumentSentence]
    let metadata: DocumentMetadata
    let createdAt: Date
    let lastReadAt: Date?
    let totalReadTime: TimeInterval
    let bookmarks: [DocumentBookmark]
    
    init(
        title: String,
        originalFilename: String,
        filePath: String? = nil,
        content: String,
        sentences: [DocumentSentence] = [],
        metadata: DocumentMetadata = DocumentMetadata()
    ) {
        self.id = UUID()
        self.title = title
        self.originalFilename = originalFilename
        self.filePath = filePath
        self.content = content
        self.sentences = sentences.isEmpty ? Self.chunkIntoSentences(content) : sentences
        self.metadata = metadata
        self.createdAt = Date()
        self.lastReadAt = nil
        self.totalReadTime = 0
        self.bookmarks = []
    }
    
    private static func chunkIntoSentences(_ text: String) -> [DocumentSentence] {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .compactMap { sentence in
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
        
        return sentences.enumerated().map { index, text in
            DocumentSentence(
                id: UUID(),
                index: index,
                text: text,
                startTime: nil,
                duration: nil
            )
        }
    }
    
    var estimatedReadingTime: TimeInterval {
        // Average reading speed: ~200 words per minute
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).count
        return Double(wordCount) / 200.0 * 60.0
    }
    
    var sizeInBytes: Int {
        return content.data(using: .utf8)?.count ?? 0
    }
}

struct DocumentSentence: Identifiable, Codable, Sendable {
    let id: UUID
    let index: Int
    let text: String
    let startTime: TimeInterval?
    let duration: TimeInterval?
    
    var range: NSRange? {
        // This would be calculated based on the full document content
        return nil
    }
}

struct DocumentMetadata: Codable, Sendable {
    let fileSize: Int
    let wordCount: Int
    let characterCount: Int
    let pageCount: Int?
    let author: String?
    let creationDate: Date?
    let modificationDate: Date?
    
    init(
        fileSize: Int = 0,
        wordCount: Int = 0,
        characterCount: Int = 0,
        pageCount: Int? = nil,
        author: String? = nil,
        creationDate: Date? = nil,
        modificationDate: Date? = nil
    ) {
        self.fileSize = fileSize
        self.wordCount = wordCount
        self.characterCount = characterCount
        self.pageCount = pageCount
        self.author = author
        self.creationDate = creationDate
        self.modificationDate = modificationDate
    }
}

struct DocumentBookmark: Identifiable, Codable, Sendable {
    let id: UUID
    let sentenceIndex: Int
    let title: String
    let note: String?
    let createdAt: Date
    
    init(sentenceIndex: Int, title: String, note: String? = nil) {
        self.id = UUID()
        self.sentenceIndex = sentenceIndex
        self.title = title
        self.note = note
        self.createdAt = Date()
    }
}