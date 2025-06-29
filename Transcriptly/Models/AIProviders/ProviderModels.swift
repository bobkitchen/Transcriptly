//
//  ProviderModels.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 7: AI Providers Integration - Provider Models
//

import Foundation

struct ProviderPreferences: Codable {
    var transcriptionProvider: ProviderType = .apple
    var refinementProvider: ProviderType = .apple
    var useFallbackHierarchy: Bool = true
    
    static let `default` = ProviderPreferences()
}