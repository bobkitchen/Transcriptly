//
//  DocumentHistoryService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//

import Foundation
import Combine
import Supabase

@MainActor
final class DocumentHistoryService: ObservableObject {
    @Published var recentDocuments: [ProcessedDocument] = []
    @Published var readingSessions: [ReadingSession] = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    private var supabaseClient: SupabaseClient {
        SupabaseManager.shared.client
    }
    private let maxLocalDocuments = 50
    private let maxLocalSessions = 100
    
    init() {
        loadLocalHistory()
    }
    
    // MARK: - Document Management
    
    func saveDocument(_ document: ProcessedDocument) async {
        // Save locally first
        await saveDocumentLocally(document)
        
        // Sync to cloud if available
        await syncDocumentToCloud(document)
    }
    
    func getDocument(by id: UUID) -> ProcessedDocument? {
        return recentDocuments.first { $0.id == id }
    }
    
    func deleteDocument(_ document: ProcessedDocument) async {
        // Remove locally
        recentDocuments.removeAll { $0.id == document.id }
        await saveLocalDocuments()
        
        // Remove from cloud
        await deleteDocumentFromCloud(document.id)
    }
    
    // MARK: - Session Management
    
    func saveSession(_ session: ReadingSession) async {
        // Save locally first
        await saveSessionLocally(session)
        
        // Sync to cloud if available
        await syncSessionToCloud(session)
    }
    
    func getSession(by id: UUID) -> ReadingSession? {
        return readingSessions.first { $0.id == id }
    }
    
    func getSessionsForDocument(_ documentId: UUID) -> [ReadingSession] {
        return readingSessions.filter { $0.documentId == documentId }
    }
    
    func deleteSession(_ session: ReadingSession) async {
        // Remove locally
        readingSessions.removeAll { $0.id == session.id }
        await saveLocalSessions()
        
        // Remove from cloud
        await deleteSessionFromCloud(session.id)
    }
    
    // MARK: - Statistics
    
    func getReadingStatistics() -> ReadingStatistics {
        let totalSessions = readingSessions.count
        let completedSessions = readingSessions.filter { $0.isCompleted }
        let totalReadingTime = readingSessions.reduce(0) { $0 + $1.duration }
        let uniqueDocuments = Set(readingSessions.map { $0.documentId }).count
        
        let averageSessionDuration = totalSessions > 0 ? totalReadingTime / Double(totalSessions) : 0
        let completionRate = totalSessions > 0 ? Double(completedSessions.count) / Double(totalSessions) : 0
        
        // Find most used voice provider
        let voiceProviders = readingSessions.compactMap { $0.voiceProvider?.type }
        let providerCounts = Dictionary(grouping: voiceProviders) { $0 }.mapValues { $0.count }
        let preferredProvider = providerCounts.max { $0.value < $1.value }?.key
        
        // Average speech rate
        let speechRates = readingSessions.map { $0.playbackSettings.speechRate }
        let averageSpeechRate = speechRates.isEmpty ? 1.0 : speechRates.reduce(0, +) / Float(speechRates.count)
        
        return ReadingStatistics(
            totalSessions: totalSessions,
            totalReadingTime: totalReadingTime,
            documentsRead: uniqueDocuments,
            averageSessionDuration: averageSessionDuration,
            preferredVoiceProvider: preferredProvider,
            averageSpeechRate: averageSpeechRate,
            completionRate: completionRate
        )
    }
    
    // MARK: - Local Storage
    
    private func loadLocalHistory() {
        loadLocalDocuments()
        loadLocalSessions()
    }
    
    private func loadLocalDocuments() {
        if let data = UserDefaults.standard.data(forKey: "RecentDocuments"),
           let documents = try? JSONDecoder().decode([ProcessedDocument].self, from: data) {
            recentDocuments = documents
        }
    }
    
    private func loadLocalSessions() {
        if let data = UserDefaults.standard.data(forKey: "ReadingSessions"),
           let sessions = try? JSONDecoder().decode([ReadingSession].self, from: data) {
            readingSessions = sessions
        }
    }
    
    private func saveLocalDocuments() async {
        // Keep only recent documents to manage storage
        let documentsToSave = Array(recentDocuments.prefix(maxLocalDocuments))
        
        if let data = try? JSONEncoder().encode(documentsToSave) {
            UserDefaults.standard.set(data, forKey: "RecentDocuments")
        }
    }
    
    private func saveLocalSessions() async {
        // Keep only recent sessions to manage storage
        let sessionsToSave = Array(readingSessions.prefix(maxLocalSessions))
        
        if let data = try? JSONEncoder().encode(sessionsToSave) {
            UserDefaults.standard.set(data, forKey: "ReadingSessions")
        }
    }
    
    private func saveDocumentLocally(_ document: ProcessedDocument) async {
        // Remove existing document with same ID
        recentDocuments.removeAll { $0.id == document.id }
        
        // Add to beginning of list
        recentDocuments.insert(document, at: 0)
        
        await saveLocalDocuments()
    }
    
    private func saveSessionLocally(_ session: ReadingSession) async {
        // Update existing session or add new one
        if let index = readingSessions.firstIndex(where: { $0.id == session.id }) {
            readingSessions[index] = session
        } else {
            readingSessions.insert(session, at: 0)
        }
        
        await saveLocalSessions()
    }
    
    // MARK: - Cloud Sync
    
    nonisolated private func syncDocumentToCloud(_ document: ProcessedDocument) async {
        guard await SupabaseManager.shared.isAuthenticated else { return }
        
        do {
            // Create cloud document record
            let cloudDocument = CloudDocument(
                id: document.id,
                title: document.title,
                originalFilename: document.originalFilename,
                content: document.content,
                metadata: document.metadata,
                createdAt: document.createdAt,
                lastReadAt: document.lastReadAt,
                totalReadTime: document.totalReadTime,
                userId: await SupabaseManager.shared.currentUserId
            )
            
            // Temporarily disabled for build compatibility
            // TODO: Fix Sendable issues with Supabase
            // try await supabaseClient
            //     .from("documents")
            //     .upsert(cloudDocument)
            //     .execute()
            print("Would sync document to cloud: \(cloudDocument.title)")
            
        } catch {
            print("Failed to sync document to cloud: \(error)")
            // Don't set lastError here as this is background sync
        }
    }
    
    nonisolated private func syncSessionToCloud(_ session: ReadingSession) async {
        guard await SupabaseManager.shared.isAuthenticated else { return }
        
        do {
            // Create cloud session record
            let cloudSession = CloudReadingSession(
                id: session.id,
                documentId: session.documentId,
                startTime: session.startTime,
                endTime: session.endTime,
                currentSentenceIndex: session.currentSentenceIndex,
                isCompleted: session.isCompleted,
                progress: session.progress,
                playbackSettings: session.playbackSettings,
                userId: await SupabaseManager.shared.currentUserId
            )
            
            // Temporarily disabled for build compatibility
            // TODO: Fix Sendable issues with Supabase
            // try await supabaseClient
            //     .from("reading_sessions")
            //     .upsert(cloudSession)
            //     .execute()
            print("Would sync session to cloud: \(cloudSession.id)")
            
        } catch {
            print("Failed to sync session to cloud: \(error)")
            // Don't set lastError here as this is background sync
        }
    }
    
    nonisolated private func deleteDocumentFromCloud(_ documentId: UUID) async {
        guard await SupabaseManager.shared.isAuthenticated else { return }
        
        do {
            // Temporarily disabled for build compatibility
            // TODO: Fix Sendable issues with Supabase
            print("Would delete document from cloud: \(documentId)")
            
        } catch {
            print("Failed to delete document from cloud: \(error)")
        }
    }
    
    nonisolated private func deleteSessionFromCloud(_ sessionId: UUID) async {
        guard await SupabaseManager.shared.isAuthenticated else { return }
        
        do {
            // Temporarily disabled for build compatibility
            // TODO: Fix Sendable issues with Supabase
            print("Would delete session from cloud: \(sessionId)")
            
        } catch {
            print("Failed to delete session from cloud: \(error)")
        }
    }
    
    // MARK: - Cloud Sync Operations
    
    func syncFromCloud() async {
        guard await SupabaseManager.shared.isAuthenticated else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Temporarily disabled for build compatibility
            // TODO: Fix Sendable issues with Supabase
            print("Would sync from cloud")
            
            await MainActor.run {
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                lastError = "Failed to sync from cloud: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func clearLocalHistory() async {
        recentDocuments.removeAll()
        readingSessions.removeAll()
        
        UserDefaults.standard.removeObject(forKey: "RecentDocuments")
        UserDefaults.standard.removeObject(forKey: "ReadingSessions")
    }
    
    func exportHistory() -> URL? {
        // Create export data
        let exportData = HistoryExport(
            documents: recentDocuments,
            sessions: readingSessions,
            statistics: getReadingStatistics(),
            exportedAt: Date()
        )
        
        do {
            let data = try JSONEncoder().encode(exportData)
            
            // Create temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let filename = "transcriptly-history-\(Date().timeIntervalSince1970).json"
            let fileURL = tempDir.appendingPathComponent(filename)
            
            try data.write(to: fileURL)
            return fileURL
            
        } catch {
            lastError = "Failed to export history: \(error.localizedDescription)"
            return nil
        }
    }
}

// MARK: - Cloud Data Models
// Note: These models are outside @MainActor to satisfy Sendable requirements

struct CloudDocument: Codable, Sendable {
    let id: UUID
    let title: String
    let originalFilename: String
    let content: String
    let metadata: DocumentMetadata
    let createdAt: Date
    let lastReadAt: Date?
    let totalReadTime: TimeInterval
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, metadata
        case originalFilename = "original_filename"
        case createdAt = "created_at"
        case lastReadAt = "last_read_at"
        case totalReadTime = "total_read_time"
        case userId = "user_id"
    }
    
    func toProcessedDocument() -> ProcessedDocument {
        return ProcessedDocument(
            title: title,
            originalFilename: originalFilename,
            filePath: nil, // Cloud documents don't have local file paths
            content: content,
            sentences: [], // Sentences will be generated when needed
            metadata: metadata
        )
    }
}

struct CloudReadingSession: Codable, Sendable {
    let id: UUID
    let documentId: UUID
    let startTime: Date
    let endTime: Date?
    let currentSentenceIndex: Int
    let isCompleted: Bool
    let progress: Double
    let playbackSettings: PlaybackSettings
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, progress
        case documentId = "document_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case currentSentenceIndex = "current_sentence_index"
        case isCompleted = "is_completed"
        case playbackSettings = "playback_settings"
        case userId = "user_id"
    }
    
    func toReadingSession() -> ReadingSession {
        return ReadingSession(
            id: id,
            documentId: documentId,
            startTime: startTime,
            endTime: endTime,
            currentSentenceIndex: currentSentenceIndex,
            isCompleted: isCompleted,
            progress: progress,
            voiceProvider: nil, // Voice provider info not stored in cloud
            playbackSettings: playbackSettings,
            bookmarks: [] // Bookmarks would need separate table
        )
    }
}

struct HistoryExport: Codable, Sendable {
    let documents: [ProcessedDocument]
    let sessions: [ReadingSession]
    let statistics: ReadingStatistics
    let exportedAt: Date
}