//
//  UserStats.swift
//  Transcriptly
//
//  Created by Claude Code on 1/3/25.
//  User productivity statistics model for Phase 10
//

import Foundation
import SwiftUI
import Combine

@MainActor
class UserStats: ObservableObject {
    @Published var todayWords: Int = 0
    @Published var todayMinutesSaved: Int = 0
    @Published var todaySessions: Int = 0
    @Published var currentStreak: Int = 0
    @Published var weeklyGrowth: Double = 0.0 // Percentage change
    
    // Computed properties for display
    var wordsFormatted: String {
        if todayWords > 1000 {
            return String(format: "%.1fK", Double(todayWords) / 1000.0)
        }
        return "\(todayWords)"
    }
    
    var growthFormatted: String {
        let symbol = weeklyGrowth >= 0 ? "↗" : "↘"
        return "\(symbol) \(Int(abs(weeklyGrowth)))%"
    }
    
    var streakText: String {
        if currentStreak >= 3 {
            return "🔥 \(currentStreak) day streak"
        } else if currentStreak > 0 {
            return "\(currentStreak) day\(currentStreak > 1 ? "s" : "")"
        } else {
            return "Start your streak!"
        }
    }
    
    static let preview = UserStats()
    
    init() {
        loadTodayStats()
    }
    
    func loadTodayStats() {
        // Connect to TranscriptionHistoryService for real data
        Task { @MainActor in
            let history = TranscriptionHistoryService.shared
            let todayTranscriptions = history.getTodayTranscriptions()
            
            // Calculate today's stats
            todaySessions = todayTranscriptions.count
            todayWords = todayTranscriptions.reduce(0) { sum, transcription in
                sum + transcription.refinedText.split(separator: " ").count
            }
            
            // Calculate time saved (rough estimate: 40 words per minute typing speed)
            let typingSpeed = 40.0 // words per minute
            todayMinutesSaved = Int(Double(todayWords) / typingSpeed)
            
            // Calculate streak
            currentStreak = calculateStreak()
            
            // Calculate weekly growth
            weeklyGrowth = calculateWeeklyGrowth()
        }
    }
    
    private func calculateStreak() -> Int {
        let history = TranscriptionHistoryService.shared
        var streak = 0
        var currentDate = Date()
        let calendar = Calendar.current
        
        // Check consecutive days backwards
        while true {
            let dayTranscriptions = history.getTranscriptions(for: currentDate)
            if dayTranscriptions.isEmpty && streak > 0 {
                break
            } else if !dayTranscriptions.isEmpty {
                streak += 1
                // Move to previous day
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                    currentDate = previousDay
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateWeeklyGrowth() -> Double {
        let history = TranscriptionHistoryService.shared
        let calendar = Calendar.current
        
        // Get this week's word count
        let thisWeekWords = getWordsForWeek(Date())
        
        // Get last week's word count
        guard let lastWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) else {
            return 0.0
        }
        let lastWeekWords = getWordsForWeek(lastWeekDate)
        
        // Calculate growth percentage
        if lastWeekWords > 0 {
            return ((Double(thisWeekWords) - Double(lastWeekWords)) / Double(lastWeekWords)) * 100.0
        } else {
            return thisWeekWords > 0 ? 100.0 : 0.0
        }
    }
    
    private func getWordsForWeek(_ date: Date) -> Int {
        let history = TranscriptionHistoryService.shared
        let calendar = Calendar.current
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
            return 0
        }
        
        var totalWords = 0
        for dayOffset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                let dayTranscriptions = history.getTranscriptions(for: day)
                totalWords += dayTranscriptions.reduce(0) { sum, transcription in
                    sum + transcription.refinedText.split(separator: " ").count
                }
            }
        }
        
        return totalWords
    }
}

// Extension to TranscriptionHistoryService for date-based queries
extension TranscriptionHistoryService {
    func getTodayTranscriptions() -> [TranscriptionRecord] {
        return getTranscriptions(for: Date())
    }
    
    func getTranscriptions(for date: Date) -> [TranscriptionRecord] {
        let calendar = Calendar.current
        return transcriptions.filter { record in
            calendar.isDate(record.timestamp, inSameDayAs: date)
        }
    }
}