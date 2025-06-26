//
//  RefinementMode.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation

enum RefinementMode: String, CaseIterable, Codable {
    case raw = "Raw Transcription"
    case cleanup = "Clean-up Mode"
    case email = "Email Mode"
    case messaging = "Messaging Mode"
    
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
}