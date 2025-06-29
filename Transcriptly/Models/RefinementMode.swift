//
//  RefinementMode.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation

enum RefinementMode: String, CaseIterable, Codable {
    case raw = "raw"
    case cleanup = "cleanup"
    case email = "email"
    case messaging = "messaging"
    
    var icon: String {
        switch self {
        case .raw: return "doc.plaintext"
        case .cleanup: return "sparkles"
        case .email: return "envelope"
        case .messaging: return "message"
        }
    }
    
    var shortcutNumber: Int {
        switch self {
        case .raw: return 1
        case .cleanup: return 2
        case .email: return 3
        case .messaging: return 4
        }
    }
    
    var displayName: String {
        switch self {
        case .raw:
            return "Raw Transcription"
        case .cleanup:
            return "Clean-up Mode"
        case .email:
            return "Email Mode"
        case .messaging:
            return "Messaging Mode"
        }
    }
    
    var description: String {
        switch self {
        case .raw:
            return "No AI processing - exactly what you said"
        case .cleanup:
            return "Removes filler words and fixes grammar"
        case .email:
            return "Professional formatting with greetings and signatures"
        case .messaging:
            return "Concise and casual for quick messages"
        }
    }
    
    var defaultPrompt: String {
        switch self {
        case .raw:
            return ""
        case .cleanup:
            return "Remove filler words (um, uh, like, you know), fix grammar and punctuation, and improve sentence structure while preserving the original meaning and tone."
        case .email:
            return "Format as a professional email with appropriate greeting, clear paragraphs, proper salutation, and business-appropriate tone. Add subject line suggestions if the content warrants it."
        case .messaging:
            return "Make the text concise and conversational. Remove unnecessary words, use casual tone, and format for quick messaging platforms. Keep it friendly but brief."
        }
    }
}