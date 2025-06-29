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

@MainActor
class AppleProvider: ObservableObject {
    static let shared = AppleProvider()
    
    @Published var isConfigured = true // Always configured
    @Published var healthStatus: ProviderHealthStatus = .healthy
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
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
            
            // Use the transcription service for actual transcription
            let transcriptionService = TranscriptionService()
            
            // Check permissions
            guard transcriptionService.hasSpeechPermission else {
                return .failure(ProviderError.serviceUnavailable)
            }
            
            // Perform transcription
            if let text = await transcriptionService.transcribeAudioFile(at: tempURL) {
                // Clean up temporary file
                try? FileManager.default.removeItem(at: tempURL)
                return .success(text)
            } else {
                // Clean up temporary file
                try? FileManager.default.removeItem(at: tempURL)
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
            // Use Foundation Models on macOS 26+
            do {
                let refinementService = RefinementService()
                await MainActor.run {
                    refinementService.currentMode = mode
                }
                
                let refinedText = try await refinementService.refine(text)
                return .success(refinedText)
                
            } catch {
                return .failure(ProviderError.custom("Foundation Models refinement failed: \(error.localizedDescription)"))
            }
        } else {
            // Fallback for older macOS versions - suggest using cloud providers
            return .failure(ProviderError.custom("Foundation Models not available on this macOS version. Please configure OpenAI or OpenRouter for refinement."))
        }
    }
}