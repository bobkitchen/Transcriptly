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
    case dictation = "Dictation"
    case aiProviders = "AI Providers"
    case learning = "Learning"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .transcription: return "mic"
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