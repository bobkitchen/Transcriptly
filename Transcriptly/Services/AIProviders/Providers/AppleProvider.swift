//
//  AppleProvider.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 7: AI Providers Integration - Apple Provider
//

import Foundation
import Speech
import SwiftUI
import Combine
#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
class AppleProvider: ObservableObject {
    static let shared = AppleProvider()
    
    @Published var isConfigured = true // Always configured
    @Published var healthStatus: ProviderHealthStatus = .healthy
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let refinementService = RefinementService() // Shared instance
    
    private init() {
        checkAvailability()
    }
    
    private func checkAvailability() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let speechAvailable = speechStatus == .authorized && speechRecognizer?.isAvailable == true
        
        // Check for Foundation Models availability (macOS 26+)
        var foundationModelsAvailable = false
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            foundationModelsAvailable = true
        }
        #endif
        
        // Apple provider is healthy if either Speech Recognition is available
        // Foundation Models availability is a bonus but not required
        if speechAvailable {
            healthStatus = .healthy
        } else {
            healthStatus = .unavailable
        }
        
        print("📱 Apple Provider Status:")
        print("  - Speech Recognition: \(speechAvailable ? "✅ Available" : "❌ Unavailable")")
        print("  - Foundation Models: \(foundationModelsAvailable ? "✅ Available" : "❌ Unavailable (requires macOS 26+)")")
        print("  - Overall Status: \(healthStatus == .healthy ? "✅ Healthy" : "❌ Unavailable")")
    }
}

// MARK: - AIProvider Protocol

extension AppleProvider: AIProvider {
    var type: ProviderType { .apple }
    
    var isAvailable: Bool {
        speechRecognizer?.isAvailable == true
    }
    
    func testConnection() async -> Result<Bool, Error> {
        let status = SFSpeechRecognizer.authorizationStatus()
        return status == .authorized ? .success(true) : .failure(ProviderError.serviceUnavailable)
    }
    
    func configure(apiKey: String?) async throws {
        // Apple provider doesn't need configuration
    }
}

// MARK: - TranscriptionProvider Protocol

extension AppleProvider: TranscriptionProvider {
    func transcribe(audio: Data) async -> Result<String, Error> {
        // Save audio data to temporary file for Speech Recognition API
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
        
        do {
            try audio.write(to: tempURL)
            
            // Check permissions directly
            guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
                try? FileManager.default.removeItem(at: tempURL)
                return .failure(ProviderError.serviceUnavailable)
            }
            
            guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
                try? FileManager.default.removeItem(at: tempURL)
                return .failure(ProviderError.serviceUnavailable)
            }
            
            // Perform transcription directly using Speech Recognition API
            let request = SFSpeechURLRecognitionRequest(url: tempURL)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = true // For privacy
            
            let result: String? = await withCheckedContinuation { continuation in
                speechRecognizer.recognitionTask(with: request) { result, error in
                    if let error = error {
                        print("Apple transcription error: \(error.localizedDescription)")
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    if let result = result, result.isFinal {
                        let transcribedText = result.bestTranscription.formattedString
                        continuation.resume(returning: transcribedText)
                    } else if result == nil {
                        print("Apple transcription: No result")
                        continuation.resume(returning: nil)
                    }
                }
            }
            
            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempURL)
            
            if let text = result {
                return .success(text)
            } else {
                return .failure(ProviderError.serviceUnavailable)
            }
            
        } catch {
            // Clean up temporary file if it exists
            try? FileManager.default.removeItem(at: tempURL)
            return .failure(ProviderError.networkError(error))
        }
    }
}

// MARK: - RefinementProvider Protocol

extension AppleProvider: RefinementProvider {
    func refine(text: String, mode: RefinementMode) async -> Result<String, Error> {
        // Check for Foundation Models availability first
        var hasFoundationModels = false
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            hasFoundationModels = true
        }
        #endif
        
        if hasFoundationModels {
            // Use Foundation Models directly to avoid circular dependency
            if #available(macOS 26.0, *) {
                do {
                    let refinedText = try await refineWithFoundationModelsDirect(text: text, mode: mode)
                    return .success(refinedText)
                    
                } catch {
                    return .failure(ProviderError.custom("Foundation Models refinement failed: \(error.localizedDescription)"))
                }
            } else {
                return .failure(ProviderError.custom("Foundation Models not available on this macOS version."))
            }
        } else {
            // Fallback for older macOS versions - suggest using cloud providers
            return .failure(ProviderError.custom("Foundation Models not available on this macOS version. Please configure OpenAI or OpenRouter for refinement."))
        }
    }
    
    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private func refineWithFoundationModelsDirect(text: String, mode: RefinementMode) async throws -> String {
        // Get the system model directly
        let systemModel = SystemLanguageModel.default
        guard systemModel.isAvailable else {
            throw ProviderError.serviceUnavailable
        }
        
        // Create system instructions for refinement tasks
        let instructions = Instructions("""
            You are a text refinement assistant. Your task is to improve transcribed text according to specific modes:
            - Clean-up Mode: Remove filler words, fix grammar, maintain original meaning
            - Email Mode: Format as professional email with greeting and closing
            - Messaging Mode: Make conversational and concise for quick messaging
            Always return only the refined text without explanations.
            """)
        
        // Create language model session with instructions
        let session = LanguageModelSession(instructions: instructions)
        
        // Build the prompt with mode-specific context
        let userPrompt = buildPromptForMode(text: text, mode: mode)
        
        // Check context limits (approximate token count)
        let estimatedTokens = userPrompt.count / 4 // Rough estimate: 4 chars per token
        if estimatedTokens > 4000 { // Conservative limit
            throw ProviderError.custom("Text is too long for processing")
        }
        
        // Create prompt object and get response
        let promptObject = Prompt(userPrompt)
        let response = try await session.respond(to: promptObject)
        
        // Extract and clean the response
        let refinedText = cleanResponseText(response.content, originalText: text)
        
        return refinedText
    }
    
    private func buildPromptForMode(text: String, mode: RefinementMode) -> String {
        let modePrompt: String
        switch mode {
        case .raw:
            return text // No refinement needed
        case .cleanup:
            modePrompt = "Clean up this transcribed text by removing filler words, fixing grammar, and improving clarity while maintaining the original meaning."
        case .email:
            modePrompt = "Format this transcribed text as a professional email with appropriate greeting and closing."
        case .messaging:
            modePrompt = "Make this transcribed text conversational and concise for quick messaging."
        }
        
        return """
            Mode: \(mode.rawValue)
            Task: \(modePrompt)
            
            Please refine the following transcribed text according to the mode and task above.
            Return only the refined text without any explanations or metadata.
            
            Text to refine:
            \(text)
            """
    }
    
    private func cleanResponseText(_ response: String, originalText: String) -> String {
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If response is empty or suspiciously short, return original
        if cleaned.isEmpty || cleaned.count < originalText.count / 3 {
            return originalText
        }
        
        return cleaned
    }
    #endif
}