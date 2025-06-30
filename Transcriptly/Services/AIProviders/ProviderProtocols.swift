//
//  ProviderProtocols.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 7: AI Providers Integration - Core Protocols
//

import Foundation
import SwiftUI

// MARK: - Core Provider Protocol

protocol AIProvider: ObservableObject {
    var type: ProviderType { get }
    var isAvailable: Bool { get }
    var isConfigured: Bool { get }
    
    func testConnection() async -> Result<Bool, Error>
    func configure(apiKey: String?) async throws
}

// MARK: - Service-Specific Protocols

protocol TranscriptionProvider: AIProvider {
    func transcribe(audio: Data) async -> Result<String, Error>
}

protocol RefinementProvider: AIProvider {
    func refine(text: String, mode: RefinementMode) async -> Result<String, Error>
}

protocol TTSProvider: AIProvider {
    func synthesizeSpeech(text: String) async -> Result<Data, Error>
}

// MARK: - Health Status

enum ProviderHealthStatus {
    case healthy
    case degraded
    case unavailable
    case testing
    
    var displayName: String {
        switch self {
        case .healthy: return "Healthy"
        case .degraded: return "Degraded"
        case .unavailable: return "Unavailable"
        case .testing: return "Testing..."
        }
    }
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .degraded: return .orange
        case .unavailable: return .red
        case .testing: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .unavailable: return "xmark.circle.fill"
        case .testing: return "arrow.clockwise.circle.fill"
        }
    }
}


