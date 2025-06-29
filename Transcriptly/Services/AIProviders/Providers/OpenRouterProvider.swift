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
        
        // Test connection with OpenRouter models endpoint
        var request = URLRequest(url: URL(string: "\(baseURL)/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Transcriptly-macOS/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Transcriptly", forHTTPHeaderField: "X-Title")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            await MainActor.run {
                if httpResponse?.statusCode == 200 {
                    healthStatus = .healthy
                } else {
                    healthStatus = .unavailable
                }
            }
            
            if httpResponse?.statusCode == 200 {
                return .success(true)
            } else if httpResponse?.statusCode == 401 {
                return .failure(ProviderError.apiKeyInvalid)
            } else {
                return .failure(ProviderError.serviceUnavailable)
            }
            
        } catch {
            await MainActor.run {
                healthStatus = .unavailable
            }
            return .failure(ProviderError.networkError(error))
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
        guard let apiKey = apiKey else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        // Use selected model from preferences
        let model = AIProviderManager.shared.preferences.openrouterRefinementModel
        
        // Build prompt based on refinement mode
        let systemPrompt = buildSystemPrompt(for: mode)
        let userPrompt = "Please refine the following transcribed text:\n\n\(text)"
        
        // Create request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user", 
                    "content": userPrompt
                ]
            ],
            "temperature": 0.3,
            "max_tokens": 1000
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return .failure(ProviderError.invalidResponse)
        }
        
        // Create request
        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Transcriptly-macOS/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Transcriptly", forHTTPHeaderField: "X-Title")
        request.httpBody = bodyData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            guard httpResponse?.statusCode == 200 else {
                if httpResponse?.statusCode == 401 {
                    return .failure(ProviderError.apiKeyInvalid)
                } else if httpResponse?.statusCode == 429 {
                    return .failure(ProviderError.rateLimitExceeded)
                } else if httpResponse?.statusCode == 402 {
                    return .failure(ProviderError.quotaExceeded)
                } else {
                    return .failure(ProviderError.serviceUnavailable)
                }
            }
            
            // Parse JSON response
            guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = jsonResponse["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return .failure(ProviderError.invalidResponse)
            }
            
            let refinedText = content.trimmingCharacters(in: .whitespacesAndNewlines)
            return .success(refinedText)
            
        } catch {
            return .failure(ProviderError.networkError(error))
        }
    }
    
    private func buildSystemPrompt(for mode: RefinementMode) -> String {
        switch mode {
        case .raw:
            return "Return the text exactly as provided without any changes."
            
        case .cleanup:
            return """
            You are a helpful text editor. Clean up the following transcribed text by:
            - Removing filler words like um, uh, like, you know
            - Fixing grammar and punctuation errors
            - Maintaining the original meaning and tone
            - Ensuring proper capitalization
            Return only the cleaned text without explanations or additional comments.
            """
            
        case .email:
            return """
            You are a professional email assistant. Transform the following transcribed text into a well-formatted email by:
            - Adding appropriate greeting and closing
            - Structuring content with proper paragraphs
            - Using professional language and tone
            - Including proper punctuation and formatting
            Return only the email text without explanations or additional comments.
            """
            
        case .messaging:
            return """
            You are a casual messaging assistant. Transform the following transcribed text into a conversational message by:
            - Making it concise and friendly
            - Using casual but clear language
            - Removing unnecessary formality
            - Ensuring it sounds natural for messaging
            Return only the message text without explanations or additional comments.
            """
        }
    }
}