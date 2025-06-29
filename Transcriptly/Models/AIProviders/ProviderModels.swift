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
    
    // Model selections per provider
    var openaiTranscriptionModel: String = "whisper-1"
    var openaiRefinementModel: String = "gpt-4o-mini"
    var openrouterRefinementModel: String = "mistralai/mistral-7b-instruct:free"
    
    static let `default` = ProviderPreferences()
}

// Available models for each provider
struct OpenAIModels {
    static let transcriptionModels = [
        "whisper-1": "Whisper V1"
    ]
    
    static let refinementModels = [
        "gpt-4o-mini": "GPT-4o Mini",
        "gpt-4o": "GPT-4o",
        "gpt-3.5-turbo": "GPT-3.5 Turbo"
    ]
}

struct OpenRouterModels {
    static let freeRefinementModels = [
        "mistralai/mistral-7b-instruct:free": "Mistral 7B Instruct (Free)",
        "huggingfaceh4/zephyr-7b-beta:free": "Zephyr 7B Beta (Free)",
        "openchat/openchat-7b:free": "OpenChat 7B (Free)",
        "gryphe/mythomist-7b:free": "Mythomist 7B (Free)",
        "undi95/toppy-m-7b:free": "Toppy M 7B (Free)"
    ]
}