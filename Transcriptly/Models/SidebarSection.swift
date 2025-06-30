//
//  SidebarSection.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation

enum SidebarSection: String, CaseIterable, Codable {
    case home = "Home"
    case dictation = "Dictation"
    case readAloud = "Read Aloud"
    case aiProviders = "AI Providers"
    case learning = "Learning"
    case settings = "Settings"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .dictation:
            return "text.quote"
        case .readAloud:
            return "speaker.wave.3.fill"
        case .aiProviders:
            return "cpu"
        case .learning:
            return "brain"
        case .settings:
            return "gearshape.fill"
        }
    }
    
    var isEnabled: Bool {
        switch self {
        case .home, .dictation, .readAloud, .aiProviders, .learning, .settings:
            return true
        }
    }
}