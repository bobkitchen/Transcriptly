//
//  AIProviderManager.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 7: AI Providers Integration - Provider Manager
//

import Foundation
import SwiftUI

@MainActor
class AIProviderManager: ObservableObject {
    static let shared = AIProviderManager()
    
    @Published var preferences = ProviderPreferences.default
    @Published var isLoading = false
    
    let providers: [ProviderType: any AIProvider] = [
        .apple: AppleProvider.shared,
        .openai: OpenAIProvider.shared,
        .openrouter: OpenRouterProvider.shared
    ]
    
    private let preferencesKey = "ai_provider_preferences"
    
    private init() {
        loadPreferences()
    }
    
    // MARK: - Provider Access
    
    func getProvider(for service: AIService) -> (any AIProvider)? {
        let preferredType: ProviderType
        
        switch service {
        case .transcription:
            preferredType = preferences.transcriptionProvider
        case .refinement:
            preferredType = preferences.refinementProvider
        }
        
        // Try preferred provider
        if let provider = providers[preferredType], provider.isAvailable {
            return provider
        }
        
        // Fallback to Apple if enabled
        if preferences.useFallbackHierarchy, 
           let appleProvider = providers[.apple], 
           appleProvider.isAvailable {
            print("Falling back to Apple provider for \(service.displayName)")
            return appleProvider
        }
        
        return nil
    }
    
    // MARK: - Service Methods
    
    func transcribe(audio: Data) async -> Result<String, Error> {
        guard let provider = getProvider(for: .transcription) as? any TranscriptionProvider else {
            return .failure(ProviderError.serviceUnavailable)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let result = await provider.transcribe(audio: audio)
        
        switch result {
        case .success(let text):
            return .success(text)
        case .failure(let error):
            // Try fallback if enabled
            if preferences.useFallbackHierarchy,
               provider.type != .apple,
               let appleProvider = providers[.apple] as? any TranscriptionProvider,
               appleProvider.isAvailable {
                print("Primary transcription failed, trying Apple fallback")
                let fallbackResult = await appleProvider.transcribe(audio: audio)
                switch fallbackResult {
                case .success(let text):
                    return .success(text)
                case .failure:
                    return .failure(error) // Return original error
                }
            }
            return .failure(error)
        }
    }
    
    func refine(text: String, mode: RefinementMode) async -> Result<String, Error> {
        guard let provider = getProvider(for: .refinement) as? any RefinementProvider else {
            return .failure(ProviderError.serviceUnavailable)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let result = await provider.refine(text: text, mode: mode)
        
        switch result {
        case .success(let refinedText):
            return .success(refinedText)
        case .failure(let error):
            // Try fallback if enabled
            if preferences.useFallbackHierarchy,
               provider.type != .apple,
               let appleProvider = providers[.apple] as? any RefinementProvider,
               appleProvider.isAvailable {
                print("Primary refinement failed, trying Apple fallback")
                let fallbackResult = await appleProvider.refine(text: text, mode: mode)
                switch fallbackResult {
                case .success(let refinedText):
                    return .success(refinedText)
                case .failure:
                    return .failure(error) // Return original error
                }
            }
            return .failure(error)
        }
    }
    
    // MARK: - Configuration
    
    func updatePreferences(_ newPreferences: ProviderPreferences) {
        preferences = newPreferences
        savePreferences()
    }
    
    func configureProvider(_ type: ProviderType, with apiKey: String) async throws {
        guard let provider = providers[type] else {
            throw ProviderError.serviceUnavailable
        }
        
        try await provider.configure(apiKey: apiKey)
    }
    
    // MARK: - Testing
    
    func testAllProviders() async -> [ProviderType: Result<Bool, Error>] {
        var results: [ProviderType: Result<Bool, Error>] = [:]
        
        for (type, provider) in providers {
            results[type] = await provider.testConnection()
        }
        
        return results
    }
    
    // MARK: - Persistence
    
    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(ProviderPreferences.self, from: data) {
            preferences = decoded
        }
    }
    
    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: preferencesKey)
        }
    }
}