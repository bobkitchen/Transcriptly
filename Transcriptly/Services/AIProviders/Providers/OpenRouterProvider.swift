//
//  OpenRouterProvider.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 7: AI Providers Integration - OpenRouter Provider
//

import Foundation
import SwiftUI
import Combine

@MainActor
class OpenRouterProvider: ObservableObject {
    static let shared = OpenRouterProvider()
    
    @Published var isConfigured = false
    @Published var healthStatus: ProviderHealthStatus = .unavailable
    
    private var apiKey: String?
    private let baseURL = "https://openrouter.ai/api/v1"
    
    private init() {
        loadAPIKey()
    }
    
    private func loadAPIKey() {
        apiKey = try? APIKeyManager.shared.getAPIKey(for: .openrouter)
        isConfigured = apiKey != nil
        healthStatus = isConfigured ? .healthy : .unavailable
    }
}

// MARK: - AIProvider Protocol

extension OpenRouterProvider: AIProvider {
    var type: ProviderType { .openrouter }
    
    var isAvailable: Bool {
        isConfigured
    }
    
    func testConnection() async -> Result<Bool, Error> {
        guard let apiKey = apiKey else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        // Test with a simple models call
        var request = URLRequest(url: URL(string: "\(baseURL)/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("Transcriptly-macOS/1.0", forHTTPHeaderField: "X-Title")
        
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
        
        try APIKeyManager.shared.storeAPIKey(apiKey, for: .openrouter)
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

// MARK: - RefinementProvider Protocol

extension OpenRouterProvider: RefinementProvider {
    func refine(text: String, mode: RefinementMode) async -> Result<String, Error> {
        guard apiKey != nil else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        // Placeholder - implement OpenRouter API call
        // TODO: Implement actual API call
        return .success("OpenRouter refinement: \(text)")
    }
}