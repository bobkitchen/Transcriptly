//
//  ProviderTypes.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 7: AI Providers Integration - Core Types
//

import Foundation

enum AIService: String, CaseIterable, Codable {
    case transcription
    case refinement
    
    var displayName: String {
        switch self {
        case .transcription: return "Transcription"
        case .refinement: return "Refinement"
        }
    }
    
    var icon: String {
        switch self {
        case .transcription: return "mic.circle"
        case .refinement: return "wand.and.sparkles"
        }
    }
}

enum ProviderType: String, CaseIterable, Codable {
    case apple
    case openai
    case openrouter
    
    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .openai: return "OpenAI"
        case .openrouter: return "OpenRouter"
        }
    }
    
    var icon: String {
        switch self {
        case .apple: return "apple.logo"
        case .openai: return "brain"
        case .openrouter: return "network"
        }
    }
    
    var requiresAPIKey: Bool {
        switch self {
        case .apple: return false
        case .openai, .openrouter: return true
        }
    }
    
    var isLocal: Bool {
        switch self {
        case .apple: return true
        case .openai, .openrouter: return false
        }
    }
}

enum ProviderError: Error, LocalizedError {
    case apiKeyMissing
    case apiKeyInvalid
    case serviceUnavailable
    case rateLimitExceeded
    case modelNotSupported
    case networkError(Error)
    case invalidResponse
    case audioFormatNotSupported
    case textTooLong
    case quotaExceeded
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing: return "API key is required"
        case .apiKeyInvalid: return "API key is invalid"
        case .serviceUnavailable: return "Service is currently unavailable"
        case .rateLimitExceeded: return "Rate limit exceeded"
        case .modelNotSupported: return "Selected model is not supported"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .invalidResponse: return "Invalid response from provider"
        case .audioFormatNotSupported: return "Audio format not supported"
        case .textTooLong: return "Text is too long for this provider"
        case .quotaExceeded: return "Usage quota exceeded"
        case .custom(let message): return message
        }
    }
}

struct ProviderCapabilities {
    let supportedServices: Set<AIService>
    let maxAudioDuration: TimeInterval?
    let maxTextLength: Int?
    let supportedAudioFormats: [String]
    let supportsStreaming: Bool
    let supportsTimestamps: Bool
    let supportedLanguages: [String]
}

