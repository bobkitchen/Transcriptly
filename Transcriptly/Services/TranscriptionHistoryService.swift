//
//  TranscriptionHistoryService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 Fixes - P1.3: TranscriptionRecord Storage Service
//

import Foundation
import Combine

/// Service responsible for managing transcription history storage and retrieval
@MainActor
final class TranscriptionHistoryService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var transcriptions: [TranscriptionRecord] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "TranscriptionHistory"
    private let maxHistoryCount = 1000 // Limit to prevent unbounded growth
    
    // MARK: - Singleton
    
    static let shared = TranscriptionHistoryService()
    
    private init() {
        loadHistory()
    }
    
    // MARK: - Public Interface
    
    /// Save a new transcription record to history
    func saveTranscription(_ record: TranscriptionRecord) {
        transcriptions.insert(record, at: 0) // Add to beginning for newest-first ordering
        
        // Limit history size
        if transcriptions.count > maxHistoryCount {
            transcriptions = Array(transcriptions.prefix(maxHistoryCount))
        }
        
        persistHistory()
        
        print("Saved transcription to history: \(record.title)")
    }
    
    /// Create and save a transcription from the current app state
    func createAndSaveTranscription(
        original: String,
        refined: String,
        final: String,
        mode: RefinementMode,
        duration: TimeInterval? = nil,
        wasLearningTriggered: Bool = false,
        learningType: LearningType? = nil
    ) {
        let record = TranscriptionRecord.create(
            original: original,
            refined: refined,
            final: final,
            mode: mode,
            duration: duration,
            wasLearningTriggered: wasLearningTriggered,
            learningType: learningType
        )
        
        saveTranscription(record)
    }
    
    /// Get transcriptions filtered by criteria
    func getTranscriptions(
        mode: RefinementMode? = nil,
        limit: Int? = nil,
        searchText: String? = nil
    ) -> [TranscriptionRecord] {
        var filtered = transcriptions
        
        // Filter by mode
        if let mode = mode {
            filtered = filtered.filter { $0.mode == mode }
        }
        
        // Filter by search text
        if let searchText = searchText, !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            filtered = filtered.filter { record in
                record.title.lowercased().contains(lowercasedSearch) ||
                record.finalText.lowercased().contains(lowercasedSearch)
            }
        }
        
        // Apply limit
        if let limit = limit {
            filtered = Array(filtered.prefix(limit))
        }
        
        return filtered
    }
    
    /// Get the most recent transcription
    var mostRecentTranscription: TranscriptionRecord? {
        return transcriptions.first
    }
    
    /// Get statistics about transcription usage
    var statistics: TranscriptionStatistics {
        let totalCount = transcriptions.count
        let todayCount = transcriptions.filter { Calendar.current.isDateInToday($0.timestamp) }.count
        let weekCount = transcriptions.filter { 
            $0.timestamp > Date().addingTimeInterval(-7 * 24 * 3600) 
        }.count
        
        let modeDistribution = Dictionary(grouping: transcriptions, by: { $0.mode })
            .mapValues { $0.count }
        
        let averageWordCount = transcriptions.isEmpty ? 0 : 
            transcriptions.map { $0.wordCount }.reduce(0, +) / transcriptions.count
        
        let totalDuration = transcriptions.compactMap { $0.duration }.reduce(0, +)
        
        return TranscriptionStatistics(
            totalCount: totalCount,
            todayCount: todayCount,
            weekCount: weekCount,
            modeDistribution: modeDistribution,
            averageWordCount: averageWordCount,
            totalDuration: totalDuration
        )
    }
    
    /// Delete a specific transcription
    func deleteTranscription(withId id: UUID) {
        transcriptions.removeAll { $0.id == id }
        persistHistory()
        print("Deleted transcription with ID: \(id)")
    }
    
    /// Delete transcriptions older than a certain date
    func deleteTranscriptionsOlderThan(_ date: Date) {
        let countBefore = transcriptions.count
        transcriptions.removeAll { $0.timestamp < date }
        let countAfter = transcriptions.count
        persistHistory()
        print("Deleted \(countBefore - countAfter) transcriptions older than \(date)")
    }
    
    /// Clear all transcription history
    func clearAllHistory() {
        transcriptions.removeAll()
        persistHistory()
        print("Cleared all transcription history")
    }
    
    /// Export transcriptions as JSON
    func exportTranscriptions() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(transcriptions)
        } catch {
            self.error = "Failed to export transcriptions: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// Import transcriptions from JSON data
    func importTranscriptions(from data: Data, replaceExisting: Bool = false) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedTranscriptions = try decoder.decode([TranscriptionRecord].self, from: data)
            
            if replaceExisting {
                transcriptions = importedTranscriptions
            } else {
                // Merge, avoiding duplicates based on ID
                let existingIds = Set(transcriptions.map { $0.id })
                let newTranscriptions = importedTranscriptions.filter { !existingIds.contains($0.id) }
                transcriptions.append(contentsOf: newTranscriptions)
                transcriptions.sort { $0.timestamp > $1.timestamp } // Keep newest first
            }
            
            // Apply size limit
            if transcriptions.count > maxHistoryCount {
                transcriptions = Array(transcriptions.prefix(maxHistoryCount))
            }
            
            persistHistory()
            print("Imported \(importedTranscriptions.count) transcriptions")
        } catch {
            self.error = "Failed to import transcriptions: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    
    private func loadHistory() {
        isLoading = true
        error = nil
        
        guard let data = userDefaults.data(forKey: historyKey) else {
            // No existing history, start with empty array
            transcriptions = []
            isLoading = false
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            transcriptions = try decoder.decode([TranscriptionRecord].self, from: data)
            print("Loaded \(transcriptions.count) transcriptions from history")
        } catch {
            print("Failed to load transcription history: \(error)")
            print("Attempting to clear corrupted history data...")
            
            // Clear the corrupted data to prevent future crashes
            userDefaults.removeObject(forKey: historyKey)
            
            self.error = "Transcription history was corrupted and has been reset. This is a one-time recovery action."
            transcriptions = []
            
            // Log the specific error for debugging
            if error.localizedDescription.contains("Cannot initialize RefinementMode") {
                print("Corruption was due to invalid RefinementMode enum value - likely from app update")
            }
        }
        
        isLoading = false
    }
    
    private func persistHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(transcriptions)
            userDefaults.set(data, forKey: historyKey)
            print("Persisted \(transcriptions.count) transcriptions to UserDefaults")
        } catch {
            print("Failed to persist transcription history: \(error)")
            self.error = "Failed to save history: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Types

struct TranscriptionStatistics {
    let totalCount: Int
    let todayCount: Int
    let weekCount: Int
    let modeDistribution: [RefinementMode: Int]
    let averageWordCount: Int
    let totalDuration: TimeInterval
    
    var averageDurationPerTranscription: TimeInterval {
        return totalCount > 0 ? totalDuration / Double(totalCount) : 0
    }
    
    var mostUsedMode: RefinementMode? {
        return modeDistribution.max(by: { $0.value < $1.value })?.key
    }
}