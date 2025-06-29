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
        let status = SFSpeechRecognizer.authorizationStatus()
        healthStatus = status == .authorized ? .healthy : .unavailable
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
        do {
            // Use the existing refinement service for actual processing
            let refinementService = RefinementService()
            await MainActor.run {
                refinementService.currentMode = mode
            }
            
            let refinedText = try await refinementService.refine(text)
            return .success(refinedText)
            
        } catch {
            return .failure(ProviderError.custom("Refinement failed: \(error.localizedDescription)"))
        }
    }
}