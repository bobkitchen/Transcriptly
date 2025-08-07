//
//  SidebarSection.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation

enum SidebarSection: String, CaseIterable {
    case home = "Home"
    case transcription = "Transcription"
    case fileTranscription = "File Transcription"
    case readAloud = "Read Aloud"
    case dictation = "Dictation"
    case aiProviders = "AI Providers"
    case learning = "Learning"
    case settings = "Settings"
    
    var title: String {
        self.rawValue
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .transcription: return "mic"
        case .fileTranscription: return "doc.fill"
        case .readAloud: return "speaker.wave.3"
        case .dictation: return "text.cursor"
        case .aiProviders: return "cpu"
        case .learning: return "brain"
        case .settings: return "gear"
        }
    }
    
    var isEnabled: Bool {
        // All sections are enabled for now
        return true
    }
}