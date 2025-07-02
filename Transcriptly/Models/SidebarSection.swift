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
    case learning = "Learning"
    case settings = "Settings"
    // Remove: case aiProviders = "AI Providers"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .dictation: return "mic.fill"
        case .readAloud: return "speaker.wave.3.fill"
        case .learning: return "brain.head.profile"
        case .settings: return "gearshape.fill"
        }
    }
    
    var isEnabled: Bool {
        switch self {
        case .home, .dictation, .readAloud, .settings: return true
        case .learning: return false  // Still coming soon
        }
    }
}