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
    case aiProviders = "AI Providers"
    case learning = "Learning"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .transcription: return "mic"
        case .aiProviders: return "cpu"
        case .learning: return "brain"
        case .settings: return "gear"
        }
    }
}