//
//  ReadingSession.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//

import Foundation

struct ReadingSession: Identifiable, Codable, Sendable {
    let id: UUID
    let documentId: UUID
    let startTime: Date
    var endTime: Date?
    var currentSentenceIndex: Int
    var isCompleted: Bool
    var progress: Double // 0.0 to 1.0
    var voiceProvider: VoiceProvider?
    var playbackSettings: PlaybackSettings
    var bookmarks: [SessionBookmark]
    
    init(documentId: UUID, voiceProvider: VoiceProvider? = nil) {
        self.id = UUID()
        self.documentId = documentId
        self.startTime = Date()
        self.endTime = nil
        self.currentSentenceIndex = 0
        self.isCompleted = false
        self.progress = 0.0
        self.voiceProvider = voiceProvider
        self.playbackSettings = PlaybackSettings()
        self.bookmarks = []
    }
    
    init(
        id: UUID,
        documentId: UUID,
        startTime: Date,
        endTime: Date?,
        currentSentenceIndex: Int,
        isCompleted: Bool,
        progress: Double,
        voiceProvider: VoiceProvider?,
        playbackSettings: PlaybackSettings,
        bookmarks: [SessionBookmark]
    ) {
        self.id = id
        self.documentId = documentId
        self.startTime = startTime
        self.endTime = endTime
        self.currentSentenceIndex = currentSentenceIndex
        self.isCompleted = isCompleted
        self.progress = progress
        self.voiceProvider = voiceProvider
        self.playbackSettings = playbackSettings
        self.bookmarks = bookmarks
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        return endTime == nil && !isCompleted
    }
    
    mutating func updateProgress(sentenceIndex: Int, totalSentences: Int) {
        self.currentSentenceIndex = sentenceIndex
        self.progress = totalSentences > 0 ? Double(sentenceIndex) / Double(totalSentences) : 0.0
        
        if sentenceIndex >= totalSentences - 1 {
            self.isCompleted = true
            self.endTime = Date()
        }
    }
    
    mutating func addBookmark(at sentenceIndex: Int, title: String, note: String? = nil) {
        let bookmark = SessionBookmark(
            sentenceIndex: sentenceIndex,
            title: title,
            note: note,
            timestamp: Date()
        )
        bookmarks.append(bookmark)
    }
    
    mutating func complete() {
        self.isCompleted = true
        self.endTime = Date()
        self.progress = 1.0
    }
    
    mutating func pause() {
        // Update any pause-related state if needed
    }
    
    mutating func resume() {
        // Update any resume-related state if needed
    }
}

struct PlaybackSettings: Codable, Sendable {
    var speechRate: Float // 0.5 to 2.0x
    var pitch: Float // 0.8 to 1.2
    var volume: Float // 0.0 to 1.0
    var autoAdvance: Bool // Automatically advance to next sentence
    var highlightCurrentSentence: Bool
    var showMiniPlayer: Bool
    
    init() {
        self.speechRate = 1.0
        self.pitch = 1.0
        self.volume = 0.8
        self.autoAdvance = true
        self.highlightCurrentSentence = true
        self.showMiniPlayer = true
    }
}

struct SessionBookmark: Identifiable, Codable, Sendable {
    let id: UUID
    let sentenceIndex: Int
    let title: String
    let note: String?
    let timestamp: Date
    
    init(sentenceIndex: Int, title: String, note: String? = nil, timestamp: Date) {
        self.id = UUID()
        self.sentenceIndex = sentenceIndex
        self.title = title
        self.note = note
        self.timestamp = timestamp
    }
}

// Reading statistics
struct ReadingStatistics: Codable, Sendable {
    let totalSessions: Int
    let totalReadingTime: TimeInterval
    let documentsRead: Int
    let averageSessionDuration: TimeInterval
    let preferredVoiceProvider: VoiceProviderType?
    let averageSpeechRate: Float
    let completionRate: Double // Percentage of sessions completed
    
    init(
        totalSessions: Int = 0,
        totalReadingTime: TimeInterval = 0,
        documentsRead: Int = 0,
        averageSessionDuration: TimeInterval = 0,
        preferredVoiceProvider: VoiceProviderType? = nil,
        averageSpeechRate: Float = 1.0,
        completionRate: Double = 0.0
    ) {
        self.totalSessions = totalSessions
        self.totalReadingTime = totalReadingTime
        self.documentsRead = documentsRead
        self.averageSessionDuration = averageSessionDuration
        self.preferredVoiceProvider = preferredVoiceProvider
        self.averageSpeechRate = averageSpeechRate
        self.completionRate = completionRate
    }
}

// Session states for UI binding
enum ReadingSessionState: String, CaseIterable, Sendable {
    case idle = "idle"
    case loading = "loading"
    case playing = "playing"
    case paused = "paused"
    case stopped = "stopped"
    case completed = "completed"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .idle:
            return "Ready"
        case .loading:
            return "Loading..."
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .stopped:
            return "Stopped"
        case .completed:
            return "Completed"
        case .error:
            return "Error"
        }
    }
    
    var isActive: Bool {
        return self == .playing || self == .loading
    }
    
    var canPlay: Bool {
        return self == .idle || self == .paused || self == .stopped
    }
    
    var canPause: Bool {
        return self == .playing
    }
    
    var canStop: Bool {
        return self == .playing || self == .paused
    }
}