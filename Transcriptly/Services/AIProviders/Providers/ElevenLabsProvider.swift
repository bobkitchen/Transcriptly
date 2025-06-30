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
        let voiceId = preferences.elevenLabsTTSVoice
        
        // Map voice names to ElevenLabs voice IDs
        let voiceMapping: [String: String] = [
            "rachel": "21m00Tcm4TlvDq8ikWAM",
            "adam": "pNInz6obpgDQGcFmaJgB", 
            "drew": "29vD33N1CtxCmqQRPOHJ",
            "clyde": "2EiwWnXFnvU5JabPnv8n",
            "paul": "5Q0t7uMcjvnagumLfvZi",
            "domi": "AZnzlk1XvdvUeBnXmlld",
            "dave": "CYw3kZ02Hs0563khs1Fj",
            "fin": "D38z5RcWu1voky8WS1ja"
        ]
        
        guard let elevenLabsVoiceId = voiceMapping[voiceId] else {
            return .failure(ProviderError.modelNotSupported)
        }
        
        do {
            let request = ElevenLabsTTSRequest(
                text: text,
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
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return .failure(ProviderError.apiKeyInvalid)
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
    let voice_settings: ElevenLabsVoiceSettings
}

struct ElevenLabsVoiceSettings: Codable {
    let stability: Double
    let similarity_boost: Double
}