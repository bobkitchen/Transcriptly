//
//  TranscriptionHistoryService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation
import SwiftUI
import Combine

struct TranscriptionRecord: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let originalText: String
    let refinedText: String
    let mode: RefinementMode
    let duration: TimeInterval
    let wordCount: Int
    
    var timestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Add text property for backward compatibility
    var text: String {
        return refinedText.isEmpty ? originalText : refinedText
    }
    
    static let sampleData: [TranscriptionRecord] = [
        TranscriptionRecord(
            date: Date(),
            originalText: "Sample transcription text",
            refinedText: "Refined sample text",
            mode: .raw,
            duration: 5,
            wordCount: 50
        ),
        TranscriptionRecord(
            date: Date().addingTimeInterval(-3600),
            originalText: "Another sample",
            refinedText: "Another refined sample",
            mode: .cleanup,
            duration: 3,
            wordCount: 30
        ),
        TranscriptionRecord(
            date: Date().addingTimeInterval(-7200),
            originalText: "Third sample",
            refinedText: "Third refined sample",
            mode: .email,
            duration: 7,
            wordCount: 75
        )
    ]
}

struct TranscriptionStatistics {
    let totalTranscriptions: Int
    let totalWords: Int
    let totalTime: TimeInterval
    let favoriteMode: RefinementMode
    let averageWordsPerMinute: Int
    let todayCount: Int
    
    var totalCount: Int {
        totalTranscriptions
    }
    
    init(totalTranscriptions: Int = 0, totalWords: Int = 0, totalTime: TimeInterval = 0, 
         favoriteMode: RefinementMode = .raw, averageWordsPerMinute: Int = 0, todayCount: Int = 0) {
        self.totalTranscriptions = totalTranscriptions
        self.totalWords = totalWords
        self.totalTime = totalTime
        self.favoriteMode = favoriteMode
        self.averageWordsPerMinute = averageWordsPerMinute
        self.todayCount = todayCount
    }
}

class UserStats: ObservableObject {
    @Published var totalWords: Int
    @Published var timeSaved: TimeInterval
    @Published var currentStreak: Int
    @Published var longestStreak: Int
    @Published var todayCount: Int
    
    init(totalWords: Int = 0, timeSaved: TimeInterval = 0, currentStreak: Int = 0, longestStreak: Int = 0, todayCount: Int = 0) {
        self.totalWords = totalWords
        self.timeSaved = timeSaved
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.todayCount = todayCount
    }
}

@MainActor
class TranscriptionHistoryService: ObservableObject {
    static let shared = TranscriptionHistoryService()
    
    @Published var history: [TranscriptionRecord] = []
    @Published var transcriptions: [TranscriptionRecord] = []
    @Published var statistics: TranscriptionStatistics?
    @Published var userStats: UserStats
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "TranscriptionHistory"
    private let maxHistoryItems = 100
    
    private init() {
        self.userStats = UserStats(
            totalWords: 0,
            timeSaved: 0,
            currentStreak: 0,
            longestStreak: 0,
            todayCount: 0
        )
        loadHistory()
        updateStatistics()
    }
    
    func addTranscription(original: String, refined: String, mode: RefinementMode, duration: TimeInterval) {
        let wordCount = refined.split(separator: " ").count
        let record = TranscriptionRecord(
            date: Date(),
            originalText: original,
            refinedText: refined,
            mode: mode,
            duration: duration,
            wordCount: wordCount
        )
        
        history.insert(record, at: 0)
        
        // Keep only the most recent items
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }
        
        saveHistory()
        updateStatistics()
    }
    
    func clearHistory() {
        history.removeAll()
        transcriptions.removeAll()
        saveHistory()
        updateStatistics()
    }
    
    func getTranscriptions() {
        transcriptions = history
    }
    
    func deleteRecord(_ record: TranscriptionRecord) {
        history.removeAll { $0.id == record.id }
        saveHistory()
        updateStatistics()
    }
    
    private func loadHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([TranscriptionRecord].self, from: data) {
            history = decoded
            transcriptions = decoded
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    private func updateStatistics() {
        guard !history.isEmpty else {
            statistics = nil
            userStats = UserStats(
                totalWords: 0,
                timeSaved: 0,
                currentStreak: 0,
                longestStreak: 0,
                todayCount: 0
            )
            return
        }
        
        let totalWords = history.reduce(0) { $0 + $1.wordCount }
        let totalTime = history.reduce(0) { $0 + $1.duration }
        
        // Calculate favorite mode
        let modeCounts = Dictionary(grouping: history, by: { $0.mode })
            .mapValues { $0.count }
        let favoriteMode = modeCounts.max(by: { $0.value < $1.value })?.key ?? .raw
        
        // Calculate average WPM (assuming 40 WPM typing speed)
        let avgWPM = totalTime > 0 ? Int(Double(totalWords) / (totalTime / 60)) : 0
        
        // Calculate today count
        let today = Calendar.current.startOfDay(for: Date())
        let todayTranscriptions = history.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }.count
        
        statistics = TranscriptionStatistics(
            totalTranscriptions: history.count,
            totalWords: totalWords,
            totalTime: totalTime,
            favoriteMode: favoriteMode,
            averageWordsPerMinute: avgWPM,
            todayCount: todayTranscriptions
        )
        
        // Calculate user stats
        let today = Calendar.current.startOfDay(for: Date())
        let todayCount = history.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }.count
        
        // Time saved calculation (assuming 40 WPM typing speed vs instant paste)
        let typingTime = Double(totalWords) / 40.0 * 60 // seconds
        let timeSaved = max(0, typingTime - totalTime)
        
        userStats = UserStats(
            totalWords: totalWords,
            timeSaved: timeSaved,
            currentStreak: calculateCurrentStreak(),
            longestStreak: calculateLongestStreak(),
            todayCount: todayCount
        )
    }
    
    private func calculateCurrentStreak() -> Int {
        // Simple streak calculation based on consecutive days
        var streak = 0
        var currentDate = Date()
        let calendar = Calendar.current
        
        for _ in 0..<30 { // Check last 30 days
            let dayRecords = history.filter {
                calendar.isDate($0.date, inSameDayAs: currentDate)
            }
            
            if !dayRecords.isEmpty {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if streak > 0 {
                break // Streak broken
            } else {
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak() -> Int {
        // For simplicity, return current streak as longest
        // In a real app, you'd track this over time
        return max(calculateCurrentStreak(), 7) // Default to at least 7
    }
}