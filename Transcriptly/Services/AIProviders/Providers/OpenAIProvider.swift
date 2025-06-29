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
        
        // Test connection with OpenAI models endpoint
        var request = URLRequest(url: URL(string: "\(baseURL)/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Transcriptly-macOS/1.0", forHTTPHeaderField: "User-Agent")
        
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
        guard let apiKey = apiKey else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        // Create multipart form data for Whisper API
        let boundary = UUID().uuidString
        var body = Data()
        
        // Add model parameter
        let selectedModel = AIProviderManager.shared.preferences.openaiTranscriptionModel
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(selectedModel)\r\n".data(using: .utf8)!)
        
        // Add language parameter (English)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)
        
        // Add response format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("text\r\n".data(using: .utf8)!)
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audio)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Create request
        var request = URLRequest(url: URL(string: "\(baseURL)/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Transcriptly-macOS/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            guard httpResponse?.statusCode == 200 else {
                if httpResponse?.statusCode == 401 {
                    return .failure(ProviderError.apiKeyInvalid)
                } else if httpResponse?.statusCode == 429 {
                    return .failure(ProviderError.rateLimitExceeded)
                } else {
                    return .failure(ProviderError.serviceUnavailable)
                }
            }
            
            // Parse response - Whisper returns plain text for response_format=text
            if let transcription = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return .success(transcription)
            } else {
                return .failure(ProviderError.invalidResponse)
            }
            
        } catch {
            return .failure(ProviderError.networkError(error))
        }
    }
}

// MARK: - RefinementProvider Protocol

extension OpenAIProvider: RefinementProvider {
    func refine(text: String, mode: RefinementMode) async -> Result<String, Error> {
        guard let apiKey = apiKey else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        // Build prompt based on refinement mode
        let systemPrompt = buildSystemPrompt(for: mode)
        let userPrompt = "Please refine the following transcribed text:\n\n\(text)"
        
        // Create request body
        let selectedModel = AIProviderManager.shared.preferences.openaiRefinementModel
        let requestBody: [String: Any] = [
            "model": selectedModel,
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
        request.setValue("Transcriptly-macOS/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = bodyData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            guard httpResponse?.statusCode == 200 else {
                if httpResponse?.statusCode == 401 {
                    return .failure(ProviderError.apiKeyInvalid)
                } else if httpResponse?.statusCode == 429 {
                    return .failure(ProviderError.rateLimitExceeded)
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
            You are a text editor. Clean up the following transcribed text by:
            - Removing filler words (um, uh, like, you know)
            - Fixing grammar and punctuation
            - Maintaining the original meaning and tone
            - Ensuring proper capitalization
            Return only the cleaned text without explanations.
            """
            
        case .email:
            return """
            You are a professional email writer. Transform the following transcribed text into a well-formatted email by:
            - Adding appropriate greeting and closing
            - Structuring content with proper paragraphs
            - Using professional language and tone
            - Including proper punctuation and formatting
            Return only the email text without explanations.
            """
            
        case .messaging:
            return """
            You are a casual messaging assistant. Transform the following transcribed text into a conversational message by:
            - Making it concise and friendly
            - Using casual but clear language
            - Removing unnecessary formality
            - Ensuring it sounds natural for messaging
            Return only the message text without explanations.
            """
        }
    }
}