//
//  OfflineQueue.swift
//  Transcriptly
//
//  Created by Claude Code on 8/6/25.
//

import Foundation
import Combine

@MainActor
class OfflineQueue: ObservableObject {
    static let shared = OfflineQueue()
    
    @Published var pendingOperations: [QueuedOperation] = []
    
    private init() {
        loadPendingOperations()
    }
    
    struct QueuedOperation: Identifiable, Codable {
        let id = UUID()
        let type: OperationType
        let data: Data
        let timestamp: Date
        
        enum OperationType: String, Codable {
            case savePattern
            case savePreference
            case saveLearningSession
        }
    }
    
    func addOperation(type: QueuedOperation.OperationType, data: Data) {
        let operation = QueuedOperation(
            type: type,
            data: data,
            timestamp: Date()
        )
        pendingOperations.append(operation)
        savePendingOperations()
    }
    
    func processQueue() async {
        // Process pending operations when online
        for operation in pendingOperations {
            // Process each operation
            print("Processing offline operation: \(operation.type)")
        }
        pendingOperations.removeAll()
        savePendingOperations()
    }
    
    func clearQueue() {
        pendingOperations.removeAll()
        savePendingOperations()
    }
    
    private func loadPendingOperations() {
        if let data = UserDefaults.standard.data(forKey: "offlineQueue"),
           let operations = try? JSONDecoder().decode([QueuedOperation].self, from: data) {
            pendingOperations = operations
        }
    }
    
    private func savePendingOperations() {
        if let data = try? JSONEncoder().encode(pendingOperations) {
            UserDefaults.standard.set(data, forKey: "offlineQueue")
        }
    }
}