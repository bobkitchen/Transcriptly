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
    var textToSpeechProvider: ProviderType = .apple
    var useFallbackHierarchy: Bool = true
    
    // Model selections per provider
    var openaiTranscriptionModel: String = "gpt-4o-mini-transcribe"
    var openaiRefinementModel: String = "gpt-4o-mini"
    var openrouterRefinementModel: String = "mistralai/mistral-7b-instruct:free"
    
    // TTS voice selections per provider
    var googleCloudTTSVoice: String = "en-US-Wavenet-A"
    var elevenLabsTTSVoice: String = "rachel"
    
    static let `default` = ProviderPreferences()
}

// Available models for each provider
struct OpenAIModels {
    static let transcriptionModels = [
        "gpt-4o-mini-transcribe": "GPT-4o Mini Transcribe",
        "gpt-4o-transcribe": "GPT-4o Transcribe"
    ]
    
    static let refinementModels = [
        "gpt-4o-mini": "GPT-4o Mini",
        "gpt-4o": "GPT-4o",
        "gpt-3.5-turbo": "GPT-3.5 Turbo"
    ]
    
}

struct GoogleCloudModels {
    static let ttsVoices = [
        "en-US-Wavenet-A": "WaveNet-A (US Female)",
        "en-US-Wavenet-B": "WaveNet-B (US Male)", 
        "en-US-Wavenet-C": "WaveNet-C (US Female)",
        "en-US-Wavenet-D": "WaveNet-D (US Male)",
        "en-US-Standard-A": "Standard-A (US Female)",
        "en-US-Standard-B": "Standard-B (US Male)",
        "en-US-Standard-C": "Standard-C (US Female)",
        "en-US-Standard-D": "Standard-D (US Male)"
    ]
}

struct ElevenLabsModels {
    static let ttsVoices = [
        "rachel": "Rachel (Premium Female)",
        "adam": "Adam (Premium Male)",
        "drew": "Drew (Premium Male)",
        "clyde": "Clyde (Premium Male)",
        "paul": "Paul (Premium Male)",
        "domi": "Domi (Premium Female)",
        "dave": "Dave (Premium Male)",
        "fin": "Fin (Premium Male)"
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