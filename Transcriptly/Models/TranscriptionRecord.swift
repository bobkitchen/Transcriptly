//
//  TranscriptionRecord.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 Fixes - P1.3: Real Data Models for TranscriptionRecord
//

import Foundation
import SwiftUI

/// Core data model representing a transcription session with all metadata
struct TranscriptionRecord: Identifiable, Codable, Sendable {
    let id: UUID
    let originalText: String         // Raw transcription from speech-to-text
    let refinedText: String          // AI-processed text
    let finalText: String            // User's final version (after learning interactions)
    let mode: RefinementMode         // Which refinement mode was used
    let timestamp: Date              // When the transcription was created
    let duration: TimeInterval?      // Recording duration in seconds
    let wordCount: Int               // Word count of final text
    let wasLearningTriggered: Bool   // Whether learning windows were shown
    let learningType: LearningType?  // Type of learning interaction (if any)
    let deviceIdentifier: String     // Device where transcription was created
    
    // MARK: - Computed Properties
    
    /// Human-readable title generated from content
    var title: String {
        let cleanText = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxLength = 50
        
        if cleanText.isEmpty {
            return "Empty transcription"
        }
        
        // Try to use first sentence or first few words
        let sentences = cleanText.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        if let firstSentence = sentences.first, firstSentence.count <= maxLength {
            return firstSentence.trimmingCharacters(in: .whitespaces)
        }
        
        // Fall back to truncated text
        if cleanText.count <= maxLength {
            return cleanText
        } else {
            return String(cleanText.prefix(maxLength)).trimmingCharacters(in: .whitespaces) + "..."
        }
    }
    
    /// Preview text for display in lists (first 100 characters)
    var preview: String? {
        let cleanText = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty && cleanText.count > title.count else { return nil }
        
        let maxLength = 100
        if cleanText.count <= maxLength {
            return cleanText
        } else {
            return String(cleanText.prefix(maxLength)).trimmingCharacters(in: .whitespaces) + "..."
        }
    }
    
    /// Human-readable time ago string
    var timeAgo: String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(timestamp)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: timestamp)
        }
    }
    
    /// Human-readable duration string
    var durationDisplay: String? {
        guard let duration = duration else { return nil }
        
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Content to use for operations (always the final user version)
    var content: String {
        return finalText
    }
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        originalText: String,
        refinedText: String,
        finalText: String,
        mode: RefinementMode,
        timestamp: Date = Date(),
        duration: TimeInterval? = nil,
        wasLearningTriggered: Bool = false,
        learningType: LearningType? = nil,
        deviceIdentifier: String = ProcessInfo.processInfo.hostName
    ) {
        self.id = id
        self.originalText = originalText
        self.refinedText = refinedText
        self.finalText = finalText
        self.mode = mode
        self.timestamp = timestamp
        self.duration = duration
        self.wordCount = finalText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        self.wasLearningTriggered = wasLearningTriggered
        self.learningType = learningType
        self.deviceIdentifier = deviceIdentifier
    }
    
    // MARK: - Factory Methods
    
    /// Create a transcription record from basic transcription data
    static func create(
        original: String,
        refined: String,
        final: String,
        mode: RefinementMode,
        duration: TimeInterval? = nil,
        wasLearningTriggered: Bool = false,
        learningType: LearningType? = nil
    ) -> TranscriptionRecord {
        return TranscriptionRecord(
            originalText: original,
            refinedText: refined,
            finalText: final,
            mode: mode,
            duration: duration,
            wasLearningTriggered: wasLearningTriggered,
            learningType: learningType
        )
    }
}

// MARK: - Supporting Types

enum LearningType: String, Codable, CaseIterable {
    case editReview = "edit_review"
    case abTesting = "ab_testing"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .editReview: return "Edit Review"
        case .abTesting: return "A/B Testing"
        case .none: return "None"
        }
    }
}

// MARK: - Sample Data for Development

extension TranscriptionRecord {
    static let sampleData: [TranscriptionRecord] = [
        TranscriptionRecord(
            originalText: "um hi sarah i wanted to uh follow up on our meeting yesterday about the quarterly review and see if you had any questions",
            refinedText: "Hi Sarah, I wanted to follow up on our meeting yesterday about the quarterly review and see if you had any questions.",
            finalText: "Hi Sarah, I wanted to follow up on our meeting yesterday about the quarterly review. Do you have any questions?",
            mode: .email,
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            duration: 12.5,
            wasLearningTriggered: true,
            learningType: .editReview
        ),
        TranscriptionRecord(
            originalText: "todays standup covered the following items sprint progress upcoming deadlines and blockers we need to address",
            refinedText: "Today's standup covered the following items: sprint progress, upcoming deadlines, and blockers we need to address.",
            finalText: "Today's standup covered the following items: sprint progress, upcoming deadlines, and blockers we need to address.",
            mode: .cleanup,
            timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
            duration: 28.3,
            wasLearningTriggered: false
        ),
        TranscriptionRecord(
            originalText: "the new feature is progressing well weve completed the initial implementation and are now working on testing",
            refinedText: "The new feature is progressing well. We've completed the initial implementation and are now working on testing.",
            finalText: "The new feature is progressing well. We've completed the initial implementation and are now working on testing.",
            mode: .cleanup,
            timestamp: Date().addingTimeInterval(-86400), // 1 day ago
            duration: 15.7,
            wasLearningTriggered: false
        ),
        TranscriptionRecord(
            originalText: "hey can you pick up groceries on the way home need milk bread and eggs thanks",
            refinedText: "Hey, can you pick up groceries on the way home? Need milk, bread, and eggs. Thanks!",
            finalText: "Can you pick up groceries? Need milk, bread, and eggs. Thanks!",
            mode: .messaging,
            timestamp: Date().addingTimeInterval(-172800), // 2 days ago
            duration: 6.2,
            wasLearningTriggered: true,
            learningType: .abTesting
        ),
        TranscriptionRecord(
            originalText: "just a quick note to remind myself to review the quarterly budget proposal before the meeting tomorrow morning",
            refinedText: "Just a quick note to remind myself to review the quarterly budget proposal before the meeting tomorrow morning.",
            finalText: "Review quarterly budget proposal before tomorrow's meeting.",
            mode: .cleanup,
            timestamp: Date().addingTimeInterval(-259200), // 3 days ago
            duration: 8.1,
            wasLearningTriggered: true,
            learningType: .editReview
        )
    ]
}

// MARK: - Comparable for Sorting

extension TranscriptionRecord: Comparable {
    static func < (lhs: TranscriptionRecord, rhs: TranscriptionRecord) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
}

// MARK: - Hashable for Collections

extension TranscriptionRecord: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}