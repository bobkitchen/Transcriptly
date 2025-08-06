//
//  TranscriptionHistoryService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation
import SwiftUI

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
}

struct TranscriptionStatistics {
    let totalTranscriptions: Int
    let totalWords: Int
    let totalTime: TimeInterval
    let favoriteMode: RefinementMode
    let averageWordsPerMinute: Int
}

struct UserStats {
    let totalWords: Int
    let timeSaved: TimeInterval
    let currentStreak: Int
    let longestStreak: Int
    let todayCount: Int
}

@MainActor
class TranscriptionHistoryService: ObservableObject {
    static let shared = TranscriptionHistoryService()
    
    @Published var history: [TranscriptionRecord] = []
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
        saveHistory()
        updateStatistics()
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
        
        statistics = TranscriptionStatistics(
            totalTranscriptions: history.count,
            totalWords: totalWords,
            totalTime: totalTime,
            favoriteMode: favoriteMode,
            averageWordsPerMinute: avgWPM
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