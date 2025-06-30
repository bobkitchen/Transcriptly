//
//  VoiceProvider.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//

import Foundation
import AVFoundation

enum VoiceProviderType: String, CaseIterable, Codable, Sendable {
    case apple = "apple"
    case googleCloud = "google_cloud"
    case elevenLabs = "eleven_labs"
    
    var displayName: String {
        switch self {
        case .apple:
            return "Apple"
        case .googleCloud:
            return "Google Cloud"
        case .elevenLabs:
            return "ElevenLabs"
        }
    }
    
    var requiresAPIKey: Bool {
        switch self {
        case .apple:
            return false
        case .googleCloud, .elevenLabs:
            return true
        }
    }
}

struct VoiceProvider: Identifiable, Codable, Sendable {
    let id: String
    let type: VoiceProviderType
    let name: String
    let displayName: String
    let gender: VoiceGender
    let language: String
    let languageCode: String // e.g., "en-US"
    let isAvailable: Bool
    let quality: VoiceQuality
    let previewURL: String?
    
    // Apple specific
    let avVoice: String? // AVSpeechSynthesisVoice identifier
    
    // Cloud provider specific
    let providerVoiceId: String?
    let modelType: String?
}

enum VoiceGender: String, CaseIterable, Codable, Sendable {
    case male = "male"
    case female = "female"
    case neutral = "neutral"
    
    var displayName: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        case .neutral:
            return "Neutral"
        }
    }
}

enum VoiceQuality: String, CaseIterable, Codable, Sendable {
    case standard = "standard"
    case enhanced = "enhanced"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .enhanced:
            return "Enhanced"
        case .premium:
            return "Premium"
        }
    }
}

// Voice selection preferences
struct VoicePreferences: Codable, Sendable {
    var selectedVoiceId: String?
    var preferredGender: VoiceGender?
    var preferredProvider: VoiceProviderType?
    var speechRate: Float // 0.5 to 2.0
    var pitch: Float // 0.8 to 1.2
    var volume: Float // 0.0 to 1.0
    
    init() {
        self.selectedVoiceId = nil
        self.preferredGender = nil
        self.preferredProvider = .apple
        self.speechRate = 1.0
        self.pitch = 1.0
        self.volume = 0.8
    }
}

// Default voice providers for different languages
extension VoiceProvider {
    static let defaultEnglishVoices: [VoiceProvider] = [
        // Apple voices (always available)
        VoiceProvider(
            id: "apple-samantha",
            type: .apple,
            name: "Samantha",
            displayName: "Samantha (US)",
            gender: .female,
            language: "English",
            languageCode: "en-US",
            isAvailable: true,
            quality: .enhanced,
            previewURL: nil,
            avVoice: "com.apple.ttsbundle.Samantha-compact",
            providerVoiceId: nil,
            modelType: nil
        ),
        VoiceProvider(
            id: "apple-alex",
            type: .apple,
            name: "Alex",
            displayName: "Alex (US)",
            gender: .male,
            language: "English",
            languageCode: "en-US",
            isAvailable: true,
            quality: .enhanced,
            previewURL: nil,
            avVoice: "com.apple.ttsbundle.Alex-compact",
            providerVoiceId: nil,
            modelType: nil
        ),
        VoiceProvider(
            id: "apple-victoria",
            type: .apple,
            name: "Victoria",
            displayName: "Victoria (UK)",
            gender: .female,
            language: "English",
            languageCode: "en-GB",
            isAvailable: true,
            quality: .enhanced,
            previewURL: nil,
            avVoice: "com.apple.ttsbundle.Victoria-compact",
            providerVoiceId: nil,
            modelType: nil
        ),
        VoiceProvider(
            id: "apple-daniel",
            type: .apple,
            name: "Daniel",
            displayName: "Daniel (UK)",
            gender: .male,
            language: "English",
            languageCode: "en-GB",
            isAvailable: true,
            quality: .enhanced,
            previewURL: nil,
            avVoice: "com.apple.ttsbundle.Daniel-compact",
            providerVoiceId: nil,
            modelType: nil
        )
    ]
    
    static func availableAppleVoices() -> [VoiceProvider] {
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        var providers: [VoiceProvider] = []
        
        for voice in availableVoices {
            // Focus on English voices for now
            guard voice.language.hasPrefix("en") else { continue }
            
            let gender: VoiceGender = inferGender(from: voice.name)
            let provider = VoiceProvider(
                id: "apple-\(voice.identifier)",
                type: .apple,
                name: voice.name,
                displayName: "\(voice.name) (\(voice.language.uppercased()))",
                gender: gender,
                language: "English",
                languageCode: voice.language,
                isAvailable: true,
                quality: voice.quality == .enhanced ? .enhanced : .standard,
                previewURL: nil,
                avVoice: voice.identifier,
                providerVoiceId: nil,
                modelType: nil
            )
            providers.append(provider)
        }
        
        return providers.isEmpty ? defaultEnglishVoices : providers
    }
    
    private static func inferGender(from name: String) -> VoiceGender {
        let femaleNames = ["samantha", "victoria", "karen", "moira", "tessa", "veena", "fiona"]
        let maleNames = ["alex", "daniel", "tom", "aaron", "fred", "jorge", "juan"]
        
        let lowercaseName = name.lowercased()
        
        if femaleNames.contains(where: { lowercaseName.contains($0) }) {
            return .female
        } else if maleNames.contains(where: { lowercaseName.contains($0) }) {
            return .male
        } else {
            return .neutral
        }
    }
}