//
//  DocumentHistoryService.swift
//  Transcriptly
//
//  Created by Claude Code on 8/6/25.
//

import Foundation

@MainActor
class DocumentHistoryService: ObservableObject {
    @Published var documents: [Document] = []
    @Published var selectedDocument: Document?
    
    struct Document: Identifiable {
        let id = UUID()
        let title: String
        let content: String
        let dateCreated: Date
        let source: DocumentSource
        
        enum DocumentSource {
            case transcription
            case imported
            case manual
        }
    }
    
    init() {
        loadDocuments()
    }
    
    private func loadDocuments() {
        // Load from UserDefaults or persistent storage
        if let data = UserDefaults.standard.data(forKey: "documentHistory"),
           let decoded = try? JSONDecoder().decode([Document].self, from: data) {
            documents = decoded
        }
    }
    
    func addDocument(title: String, content: String, source: Document.DocumentSource) {
        let document = Document(
            title: title.isEmpty ? "Untitled Document" : title,
            content: content,
            dateCreated: Date(),
            source: source
        )
        documents.insert(document, at: 0)
        saveDocuments()
    }
    
    func deleteDocument(_ document: Document) {
        documents.removeAll { $0.id == document.id }
        if selectedDocument?.id == document.id {
            selectedDocument = nil
        }
        saveDocuments()
    }
    
    func clearHistory() {
        documents.removeAll()
        selectedDocument = nil
        saveDocuments()
    }
    
    private func saveDocuments() {
        if let encoded = try? JSONEncoder().encode(documents) {
            UserDefaults.standard.set(encoded, forKey: "documentHistory")
        }
    }
}

// Make Document Codable
extension DocumentHistoryService.Document: Codable {
    enum CodingKeys: String, CodingKey {
        case title, content, dateCreated, source
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        source = try container.decode(DocumentSource.self, forKey: .source)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(dateCreated, forKey: .dateCreated)
        try container.encode(source, forKey: .source)
    }
}

extension DocumentHistoryService.Document.DocumentSource: Codable {}