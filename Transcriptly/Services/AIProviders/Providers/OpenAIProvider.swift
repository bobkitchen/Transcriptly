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
import AVFoundation

@MainActor
class OpenAIProvider: ObservableObject {
    static let shared = OpenAIProvider()
    
    @Published var isConfigured = false
    @Published var healthStatus: ProviderHealthStatus = .unavailable
    
    private var apiKey: String?
    private let baseURL = "https://api.openai.com/v1"
    private lazy var optimizedURLSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        config.httpMaximumConnectionsPerHost = 2
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()
    
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
    
    func testConnection() async -> Result<Bool, any Error> {
        guard let apiKey = apiKey else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        // Test connection with OpenAI models endpoint
        var request = URLRequest(url: URL(string: "\(baseURL)/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Transcriptly-macOS/1.0", forHTTPHeaderField: "User-Agent")
        
        do {
            let (_, response) = try await optimizedURLSession.data(for: request)
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
    func transcribe(audio: Data) async -> Result<String, any Error> {
        guard let apiKey = apiKey else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        let selectedModel = AIProviderManager.shared.preferences.openaiTranscriptionModel
        
        // GPT-4o transcription uses the chat completions endpoint with audio input
        // This is a newer approach than Whisper's dedicated audio endpoint
        
        // Optimize audio before base64 encoding for better performance
        let optimizedAudio = preprocessAudio(audio)
        let base64Audio = optimizedAudio.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "model": selectedModel,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Please transcribe this audio file accurately. Return only the transcribed text without any additional commentary."
                        ],
                        [
                            "type": "input_audio",
                            "input_audio": [
                                "data": base64Audio,
                                "format": "m4a"
                            ]
                        ]
                    ]
                ]
            ],
            "temperature": 0.0,
            "max_tokens": 1000
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return .failure(ProviderError.invalidResponse)
        }
        
        // Create request to chat completions endpoint
        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Transcriptly-macOS/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = bodyData
        
        do {
            let (data, response) = try await optimizedURLSession.data(for: request)
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
            
            let transcription = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return .success(transcription)
            
        } catch {
            return .failure(ProviderError.networkError(error))
        }
    }
    
    // MARK: - File Transcription Methods
    
    func transcribeFile(_ fileURL: URL) async throws -> String {
        guard let apiKey = apiKey else {
            throw ProviderError.apiKeyMissing
        }
        
        let selectedModel = AIProviderManager.shared.preferences.openaiFileTranscriptionModel
        
        // Read the audio file data
        let audioData = try Data(contentsOf: fileURL)
        
        if selectedModel == "whisper-1" {
            // Use Whisper API endpoint for file transcription
            return try await transcribeWithWhisper(audioData: audioData, fileName: fileURL.lastPathComponent)
        } else {
            // Use GPT-4o audio preview for file transcription
            return try await transcribeWithGPT4oAudio(audioData: audioData)
        }
    }
    
    private func transcribeWithWhisper(audioData: Data, fileName: String) async throws -> String {
        guard let apiKey = apiKey else {
            throw ProviderError.apiKeyMissing
        }
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add file parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add response_format parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("text\r\n".data(using: .utf8)!)
        
        // Add temperature parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        body.append("0\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Create request to Whisper endpoint
        var request = URLRequest(url: URL(string: "\(baseURL)/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Transcriptly-macOS/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = body
        
        do {
            let (data, response) = try await optimizedURLSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            guard httpResponse?.statusCode == 200 else {
                if httpResponse?.statusCode == 401 {
                    throw ProviderError.apiKeyInvalid
                } else if httpResponse?.statusCode == 429 {
                    throw ProviderError.rateLimitExceeded
                } else {
                    // Try to parse error message
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorData["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw ProviderError.serviceUnavailable
                    }
                    throw ProviderError.serviceUnavailable
                }
            }
            
            // For text response format, the response is just the transcribed text
            let transcription = String(data: data, encoding: .utf8) ?? ""
            return transcription.trimmingCharacters(in: .whitespacesAndNewlines)
            
        } catch {
            if error is ProviderError {
                throw error
            }
            throw ProviderError.networkError(error)
        }
    }
    
    private func transcribeWithGPT4oAudio(audioData: Data) async throws -> String {
        guard let apiKey = apiKey else {
            throw ProviderError.apiKeyMissing
        }
        
        // Convert audio to base64 for GPT-4o audio
        let base64Audio = audioData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-audio-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Please transcribe this audio file accurately. Return only the transcribed text without any additional commentary."
                        ],
                        [
                            "type": "input_audio",
                            "input_audio": [
                                "data": base64Audio,
                                "format": "mp3"
                            ]
                        ]
                    ]
                ]
            ],
            "temperature": 0.0,
            "max_tokens": 4000
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw ProviderError.invalidResponse
        }
        
        // Create request to chat completions endpoint
        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Transcriptly-macOS/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = bodyData
        
        do {
            let (data, response) = try await optimizedURLSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            guard httpResponse?.statusCode == 200 else {
                if httpResponse?.statusCode == 401 {
                    throw ProviderError.apiKeyInvalid
                } else if httpResponse?.statusCode == 429 {
                    throw ProviderError.rateLimitExceeded
                } else {
                    throw ProviderError.serviceUnavailable
                }
            }
            
            // Parse JSON response
            guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = jsonResponse["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw ProviderError.invalidResponse
            }
            
            let transcription = content.trimmingCharacters(in: .whitespacesAndNewlines)
            return transcription
            
        } catch {
            if error is ProviderError {
                throw error
            }
            throw ProviderError.networkError(error)
        }
    }
}

// MARK: - RefinementProvider Protocol

extension OpenAIProvider: RefinementProvider {
    func refine(text: String, mode: RefinementMode) async -> Result<String, any Error> {
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
            let (data, response) = try await optimizedURLSession.data(for: request)
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
            
            let refinedText = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
    
    // MARK: - Audio Preprocessing
    
    private func preprocessAudio(_ audioData: Data) -> Data {
        do {
            return try optimizeAudioData(audioData)
        } catch {
            // If optimization fails, use original data
            print("Audio optimization failed, using original: \(error.localizedDescription)")
            return audioData
        }
    }
    
    private func optimizeAudioData(_ audioData: Data) throws -> Data {
        // Simple size-based optimization without deprecated APIs
        // Skip optimization if file is already small (under 1MB)
        let maxSizeBeforeOptimization = 1_000_000 // 1MB
        
        if audioData.count <= maxSizeBeforeOptimization {
            print("Audio file is small (\(audioData.count) bytes), skipping optimization")
            return audioData
        }
        
        print("Audio file is large (\(audioData.count) bytes), would benefit from optimization")
        print("Note: Full audio optimization requires newer AVFoundation APIs")
        
        // For now, return original data - the URLSession optimization provides the main benefit
        // TODO: Implement full audio optimization using newer async AVFoundation APIs when targeting macOS 15+
        return audioData
    }
}