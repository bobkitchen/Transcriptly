//
//  OpenAIProvider.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 7: AI Providers Integration - OpenAI Provider
//

import Foundation
import SwiftUI
import Combine

@MainActor
class OpenAIProvider: ObservableObject {
    static let shared = OpenAIProvider()
    
    @Published var isConfigured = false
    @Published var healthStatus: ProviderHealthStatus = .unavailable
    
    private var apiKey: String?
    private let baseURL = "https://api.openai.com/v1"
    
    private init() {
        loadAPIKey()
    }
    
    private func loadAPIKey() {
        apiKey = try? APIKeyManager.shared.getAPIKey(for: .openai)
        isConfigured = apiKey != nil
        healthStatus = isConfigured ? .healthy : .unavailable
    }
}

// MARK: - AIProvider Protocol

extension OpenAIProvider: AIProvider {
    var type: ProviderType { .openai }
    
    var isAvailable: Bool {
        isConfigured
    }
    
    func testConnection() async -> Result<Bool, Error> {
        guard let apiKey = apiKey else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        // Simple API test call
        var request = URLRequest(url: URL(string: "\(baseURL)/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            await MainActor.run {
                healthStatus = httpResponse?.statusCode == 200 ? .healthy : .unavailable
            }
            
            return httpResponse?.statusCode == 200 ? .success(true) : .failure(ProviderError.apiKeyInvalid)
        } catch {
            await MainActor.run {
                healthStatus = .unavailable
            }
            return .failure(error)
        }
    }
    
    func configure(apiKey: String?) async throws {
        guard let apiKey = apiKey else {
            throw ProviderError.apiKeyMissing
        }
        
        try APIKeyManager.shared.storeAPIKey(apiKey, for: .openai)
        self.apiKey = apiKey
        isConfigured = true
        
        // Test the connection
        let result = await testConnection()
        if case .failure(let error) = result {
            // Revert configuration if test fails
            self.apiKey = nil
            isConfigured = false
            healthStatus = .unavailable
            throw error
        }
    }
}

// MARK: - TranscriptionProvider Protocol

extension OpenAIProvider: TranscriptionProvider {
    func transcribe(audio: Data) async -> Result<String, Error> {
        guard apiKey != nil else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        // Placeholder - implement OpenAI Whisper API call
        // TODO: Implement actual API call
        return .success("OpenAI transcription placeholder")
    }
}

// MARK: - RefinementProvider Protocol

extension OpenAIProvider: RefinementProvider {
    func refine(text: String, mode: RefinementMode) async -> Result<String, Error> {
        guard apiKey != nil else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        // Placeholder - implement OpenAI Chat API call
        // TODO: Implement actual API call
        return .success("OpenAI refinement: \(text)")
    }
}