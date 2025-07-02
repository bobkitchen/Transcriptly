//
//  ElevenLabsProvider.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//  AI Providers Integration - ElevenLabs Provider
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ElevenLabsProvider: ObservableObject {
    static let shared = ElevenLabsProvider()
    
    @Published var isConfigured = false
    @Published var healthStatus: ProviderHealthStatus = .unavailable
    
    private var apiKey: String? {
        didSet {
            isConfigured = apiKey != nil && !apiKey!.isEmpty
            updateHealthStatus()
        }
    }
    
    private init() {
        loadAPIKey()
    }
    
    private func loadAPIKey() {
        apiKey = try? APIKeyManager.shared.getAPIKey(for: .elevenLabs)
    }
    
    private func updateHealthStatus() {
        if !isConfigured {
            healthStatus = .unavailable
        } else {
            healthStatus = .healthy
        }
    }
}

// MARK: - AIProvider Conformance

extension ElevenLabsProvider: AIProvider {
    var type: ProviderType { .elevenLabs }
    var isAvailable: Bool { isConfigured }
    
    func testConnection() async -> Result<Bool, Error> {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        healthStatus = .testing
        
        // Test with a simple API call to get voices
        do {
            let url = URL(string: "https://api.elevenlabs.io/v1/voices")!
            var urlRequest = URLRequest(url: url)
            urlRequest.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
            
            let (_, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                healthStatus = .healthy
                return .success(true)
            } else {
                healthStatus = .degraded
                return .failure(ProviderError.apiKeyInvalid)
            }
        } catch {
            healthStatus = .unavailable
            return .failure(ProviderError.networkError(error))
        }
    }
    
    func configure(apiKey: String?) async throws {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ProviderError.apiKeyMissing
        }
        
        // Save the API key
        try APIKeyManager.shared.saveAPIKey(apiKey, for: .elevenLabs)
        self.apiKey = apiKey
        
        // Test the connection
        let result = await testConnection()
        switch result {
        case .success:
            break
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - TTSProvider Conformance

extension ElevenLabsProvider: TTSProvider {
    func synthesizeSpeech(text: String) async -> Result<Data, Error> {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        // Get current voice preference
        let preferences = AIProviderManager.shared.preferences
        let voiceId = preferences.elevenLabsTTSVoice.lowercased()
        
        // Map voice names to ElevenLabs voice IDs
        // Note: These are the default ElevenLabs voices available to all users
        let voiceMapping: [String: String] = [
            // American English voices
            "rachel": "21m00Tcm4TlvDq8ikWAM",
            "adam": "pNInz6obpgDQGcFmaJgB", 
            "drew": "29vD33N1CtxCmqQRPOHJ",
            "clyde": "2EiwWnXFnvU5JabPnv8n",
            "paul": "5Q0t7uMcjvnagumLfvZi",
            "domi": "AZnzlk1XvdvUeBnXmlld",
            "dave": "CYw3kZ02Hs0563khs1Fj",
            "fin": "D38z5RcWu1voky8WS1ja",
            "bella": "EXAVITQu4vr4xnSDxMaL",
            "antoni": "ErXwobaYiN019PkySvjV",
            "elli": "MF3mGyEYCl7XYWbV9V6O",
            "josh": "TxGEqnHWrfWFTfGW9XjX",
            "arnold": "VR6AewLTigWG4xSOukaG",
            "sam": "yoZ06aMxZJJ28mfd3POQ",
            
            // British English voices
            "charlotte": "XB0fDUnXU5powFXDhCwa",
            "daniel": "onwK4e9ZLuTAKqWW03F9",
            "george": "JBFqnCBsd6RMkjVDRZzb",
            "freya": "jsCqWAovK2LkecY7zXl4",
            "lily": "pFZP5JQG7iQjIQuC4Bku",
            "harry": "SOYHLrjzK2X1ezoPC6cr",
            "alice": "Xb7hH8MSUJpSbSDYk0k2",
            "charlie": "IKne3meq5aSn9XLyUdCD",
            
            // Other English accents
            "matilda": "XrExE9yKIg1WjnnlVkGX",  // Australian
            "james": "ZQe5CZNOzWyzPSCn5a3c",     // Australian
            "patrick": "ODq5zmih8GrVes37Pwof",  // Irish
            "aisling": "IiUjD2J4jKsE1XFwRlX5",  // Irish
            "callum": "N2lVS1w4EtoT3dr4eOWO",   // Scottish
            "grace": "oWAxZDx7w5VEj9dCyTzz",    // Scottish
            "ethan": "FGY2WhTYpPnrIDTdsKH5",    // New Zealand
            "nicole": "piTKgcLEGmPE4e6mEKli",   // South African
            "giovanni": "zcAOhNBS3c14rBihAFp1", // Italian accent
            "glinda": "z9fAnlkpzviPz146aGWa"    // Witch
        ]
        
        guard let elevenLabsVoiceId = voiceMapping[voiceId] else {
            print("ElevenLabs: Voice '\(voiceId)' not found in mapping. Available voices: \(voiceMapping.keys.sorted().joined(separator: ", "))")
            return .failure(ProviderError.custom("Voice '\(preferences.elevenLabsTTSVoice)' is not available. Please select a different voice."))
        }
        
        do {
            // Get the model preference, default to eleven_multilingual_v2
            let modelId = preferences.elevenLabsTTSModel ?? "eleven_multilingual_v2"
            
            let request = ElevenLabsTTSRequest(
                text: text,
                model_id: modelId,
                voice_settings: ElevenLabsVoiceSettings(
                    stability: 0.5,
                    similarity_boost: 0.5
                )
            )
            
            let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(elevenLabsVoiceId)")!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(ProviderError.invalidResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                // Try to parse error response
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let detail = errorData["detail"] as? [String: Any],
                   let message = detail["message"] as? String {
                    print("ElevenLabs API Error: \(message)")
                    return .failure(ProviderError.custom(message))
                }
                
                switch httpResponse.statusCode {
                case 401:
                    return .failure(ProviderError.apiKeyInvalid)
                case 422:
                    return .failure(ProviderError.custom("Invalid request: Check voice and model compatibility"))
                case 429:
                    return .failure(ProviderError.rateLimitExceeded)
                default:
                    return .failure(ProviderError.custom("HTTP \(httpResponse.statusCode) error"))
                }
            }
            
            // ElevenLabs returns raw audio data
            return .success(data)
        } catch {
            return .failure(ProviderError.networkError(error))
        }
    }
}

// MARK: - Request/Response Models

struct ElevenLabsTTSRequest: Codable {
    let text: String
    let model_id: String
    let voice_settings: ElevenLabsVoiceSettings
}

struct ElevenLabsVoiceSettings: Codable {
    let stability: Double
    let similarity_boost: Double
}