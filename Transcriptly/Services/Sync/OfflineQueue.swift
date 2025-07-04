//
//  OfflineQueue.swift
//  Transcriptly
//
//  Manages offline operations queue for syncing when connection is restored
//

import Foundation
import SwiftUI

@MainActor
class OfflineQueue: ObservableObject {
    static let shared = OfflineQueue()
    
    @Published var pendingOperations: [OfflineOperation] = []
    @Published var isProcessingQueue = false
    @Published var lastProcessedOperation: OfflineOperation?
    
    private let supabase = SupabaseManager.shared
    private let queueKey = "offlineOperationQueue"
    
    private init() {
        loadQueue()
    }
    
    func addOperation(_ operation: OfflineOperation) {
        pendingOperations.append(operation)
        saveQueue()
    }
    
    func processQueue() async {
        guard !isProcessingQueue, !pendingOperations.isEmpty else { return }
        
        isProcessingQueue = true
        
        var operationsToRemove: [UUID] = []
        
        for operation in pendingOperations {
            do {
                let success = try await processOperation(operation)
                if success {
                    operationsToRemove.append(operation.id)
                    lastProcessedOperation = operation
                }
            } catch {
                print("Failed to process operation \(operation.id): \(error)")
                // Mark operation as failed but don't remove it
                operation.lastAttempt = Date()
                operation.attemptCount += 1
                
                // Remove operations that have failed too many times
                if operation.attemptCount >= 5 {
                    operationsToRemove.append(operation.id)
                }
            }
        }
        
        // Remove successful operations
        pendingOperations.removeAll { operationsToRemove.contains($0.id) }
        saveQueue()
        
        isProcessingQueue = false
    }
    
    func clearQueue() {
        pendingOperations.removeAll()
        saveQueue()
    }
    
    func retryOperation(_ operationId: UUID) async {
        guard let operation = pendingOperations.first(where: { $0.id == operationId }) else { return }
        
        do {
            let success = try await processOperation(operation)
            if success {
                pendingOperations.removeAll { $0.id == operationId }
                saveQueue()
            }
        } catch {
            operation.lastAttempt = Date()
            operation.attemptCount += 1
            saveQueue()
        }
    }
    
    // MARK: - Private Methods
    
    private func processOperation(_ operation: OfflineOperation) async throws -> Bool {
        switch operation.type {
        case .saveLearningSession(let session):
            try await supabase.saveLearningSession(session)
            return true
            
        case .savePattern(let pattern):
            try await supabase.saveOrUpdatePattern(pattern)
            return true
            
        case .savePreference(let preference):
            try await supabase.saveOrUpdatePreference(preference)
            return true
            
        case .deletePattern(let patternId):
            // Implement pattern deletion
            try await supabase.deletePattern(patternId)
            return true
        }
    }
    
    private func saveQueue() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(pendingOperations)
            UserDefaults.standard.set(data, forKey: queueKey)
        } catch {
            print("Failed to save offline queue: \(error)")
        }
    }
    
    private func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            pendingOperations = try decoder.decode([OfflineOperation].self, from: data)
        } catch {
            print("Failed to load offline queue: \(error)")
            pendingOperations = []
        }
    }
}

// MARK: - Offline Operation Types

class OfflineOperation: Codable, Identifiable, ObservableObject {
    let id = UUID()
    let type: OfflineOperationType
    let createdAt: Date
    var lastAttempt: Date?
    var attemptCount: Int = 0
    
    init(type: OfflineOperationType) {
        self.type = type
        self.createdAt = Date()
    }
    
    var displayName: String {
        switch type {
        case .saveLearningSession: return "Save Learning Session"
        case .savePattern: return "Save Learning Pattern"
        case .savePreference: return "Save User Preference"
        case .deletePattern: return "Delete Pattern"
        }
    }
    
    var statusText: String {
        if attemptCount == 0 {
            return "Pending"
        } else {
            return "Retry \(attemptCount)/5"
        }
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, type, createdAt, lastAttempt, attemptCount
    }
}

enum OfflineOperationType: Codable {
    case saveLearningSession(LearningSession)
    case savePattern(LearnedPattern)
    case savePreference(UserPreference)
    case deletePattern(UUID)
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    enum OperationType: String, Codable {
        case saveLearningSession
        case savePattern
        case savePreference
        case deletePattern
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(OperationType.self, forKey: .type)
        
        switch type {
        case .saveLearningSession:
            let session = try container.decode(LearningSession.self, forKey: .data)
            self = .saveLearningSession(session)
        case .savePattern:
            let pattern = try container.decode(LearnedPattern.self, forKey: .data)
            self = .savePattern(pattern)
        case .savePreference:
            let preference = try container.decode(UserPreference.self, forKey: .data)
            self = .savePreference(preference)
        case .deletePattern:
            let id = try container.decode(UUID.self, forKey: .data)
            self = .deletePattern(id)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .saveLearningSession(let session):
            try container.encode(OperationType.saveLearningSession, forKey: .type)
            try container.encode(session, forKey: .data)
        case .savePattern(let pattern):
            try container.encode(OperationType.savePattern, forKey: .type)
            try container.encode(pattern, forKey: .data)
        case .savePreference(let preference):
            try container.encode(OperationType.savePreference, forKey: .type)
            try container.encode(preference, forKey: .data)
        case .deletePattern(let id):
            try container.encode(OperationType.deletePattern, forKey: .type)
            try container.encode(id, forKey: .data)
        }
    }
}