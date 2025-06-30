//
//  GoogleCloudProvider.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//  AI Providers Integration - Google Cloud Provider
//

import Foundation
import SwiftUI
import Combine

@MainActor
class GoogleCloudProvider: ObservableObject {
    static let shared = GoogleCloudProvider()
    
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
        apiKey = try? APIKeyManager.shared.getAPIKey(for: .googleCloud)
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

extension GoogleCloudProvider: AIProvider {
    var type: ProviderType { .googleCloud }
    var isAvailable: Bool { isConfigured }
    
    func testConnection() async -> Result<Bool, Error> {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        healthStatus = .testing
        
        // Test with a simple API call
        do {
            let url = URL(string: "https://texttospeech.googleapis.com/v1/voices?key=\(apiKey)")!
            let (_, response) = try await URLSession.shared.data(from: url)
            
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
        try APIKeyManager.shared.saveAPIKey(apiKey, for: .googleCloud)
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

extension GoogleCloudProvider: TTSProvider {
    func synthesizeSpeech(text: String) async -> Result<Data, Error> {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        // Get current voice preference
        let preferences = AIProviderManager.shared.preferences
        let voiceId = preferences.googleCloudTTSVoice
        
        do {
            let request = GoogleTTSRequest(
                input: GoogleTTSInput(text: text),
                voice: GoogleTTSVoice(
                    languageCode: "en-US",
                    name: voiceId,
                    ssmlGender: voiceId.contains("Wavenet-A") || voiceId.contains("Standard-A") || voiceId.contains("Standard-C") ? "FEMALE" : "MALE"
                ),
                audioConfig: GoogleTTSAudioConfig(
                    audioEncoding: "MP3",
                    speakingRate: 1.0,
                    pitch: 0.0
                )
            )
            
            let url = URL(string: "https://texttospeech.googleapis.com/v1/text:synthesize?key=\(apiKey)")!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return .failure(ProviderError.apiKeyInvalid)
            }
            
            let responseData = try JSONDecoder().decode(GoogleTTSResponse.self, from: data)
            
            guard let audioData = Data(base64Encoded: responseData.audioContent) else {
                return .failure(ProviderError.invalidResponse)
            }
            
            return .success(audioData)
        } catch {
            return .failure(ProviderError.networkError(error))
        }
    }
}

// MARK: - Request/Response Models

struct GoogleTTSRequest: Codable {
    let input: GoogleTTSInput
    let voice: GoogleTTSVoice
    let audioConfig: GoogleTTSAudioConfig
}

struct GoogleTTSInput: Codable {
    let text: String
}

struct GoogleTTSVoice: Codable {
    let languageCode: String
    let name: String
    let ssmlGender: String
}

struct GoogleTTSAudioConfig: Codable {
    let audioEncoding: String
    let speakingRate: Double
    let pitch: Double
}

struct GoogleTTSResponse: Codable {
    let audioContent: String
}