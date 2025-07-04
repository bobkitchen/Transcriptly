//
//  AIProvidersView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//  Updated for Phase 7: AI Providers Integration
//

import SwiftUI
import AppKit

struct AIProvidersView: View {
    @StateObject private var providerManager = AIProviderManager.shared
    @State private var showingConfigSheet = false
    @State private var configureProviderType: ProviderType?
    @State private var isTestingConnections = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            HStack {
                Text("AI Providers")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                // Test All Connections Button
                Button(action: testAllConnections) {
                    HStack(spacing: DesignSystem.spacingSmall) {
                        if isTestingConnections {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle")
                        }
                        Text("Test All")
                            .fontWeight(.medium)
                    }
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, DesignSystem.spacingMedium)
                    .padding(.vertical, DesignSystem.spacingSmall)
                    .background(.regularMaterial)
                    .cornerRadius(DesignSystem.cornerRadiusSmall)
                }
                .disabled(isTestingConnections)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.regularMaterial.opacity(0.3))
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                    
                    // Service Selection Section
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        HStack(spacing: DesignSystem.spacingMedium) {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                                .foregroundColor(.accentColor)
                                .symbolRenderingMode(.hierarchical)
                            
                            Text("Service Configuration")
                                .font(DesignSystem.Typography.bodyLarge)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryText)
                        }
                        
                        VStack(spacing: DesignSystem.spacingMedium) {
                            // Transcription Provider Selection
                            ServiceSelectionRow(
                                service: .transcription,
                                selectedProvider: providerManager.preferences.transcriptionProvider,
                                onProviderChange: { provider in
                                    var newPrefs = providerManager.preferences
                                    newPrefs.transcriptionProvider = provider
                                    providerManager.updatePreferences(newPrefs)
                                }
                            )
                            
                            // Refinement Provider Selection
                            ServiceSelectionRow(
                                service: .refinement,
                                selectedProvider: providerManager.preferences.refinementProvider,
                                onProviderChange: { provider in
                                    var newPrefs = providerManager.preferences
                                    newPrefs.refinementProvider = provider
                                    providerManager.updatePreferences(newPrefs)
                                }
                            )
                            
                            // Text-to-Speech Provider Selection
                            ServiceSelectionRow(
                                service: .textToSpeech,
                                selectedProvider: providerManager.preferences.textToSpeechProvider,
                                onProviderChange: { provider in
                                    var newPrefs = providerManager.preferences
                                    newPrefs.textToSpeechProvider = provider
                                    providerManager.updatePreferences(newPrefs)
                                }
                            )
                            
                            // File Transcription Provider Selection
                            HStack {
                                VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                                    Text("File Transcription")
                                        .font(DesignSystem.Typography.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primaryText)
                                    
                                    Text("Provider for audio and video file transcription")
                                        .font(DesignSystem.Typography.bodySmall)
                                        .foregroundColor(.secondaryText)
                                }
                                
                                Spacer()
                                
                                Menu {
                                    Button("Apple Speech (Local)") {
                                        // For now, always Apple Speech
                                    }
                                    
                                    Button("GPT-4o Transcribe (Cloud)") {
                                        // Future implementation
                                    }
                                    .disabled(true)
                                } label: {
                                    HStack(spacing: DesignSystem.spacingSmall) {
                                        Image(systemName: "waveform.badge.mic")
                                            .font(.system(size: 14))
                                        Text("Apple Speech")
                                            .font(DesignSystem.Typography.bodySmall)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10))
                                    }
                                    .padding(.horizontal, DesignSystem.spacingMedium)
                                    .padding(.vertical, DesignSystem.spacingSmall)
                                    .background(Color.secondaryBackground)
                                    .cornerRadius(DesignSystem.cornerRadiusSmall)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(DesignSystem.spacingMedium)
                            .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusSmall)
                            
                            // Fallback Hierarchy Toggle
                            HStack {
                                Text("Enable Fallback Hierarchy")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                Toggle("", isOn: .init(
                                    get: { providerManager.preferences.useFallbackHierarchy },
                                    set: { enabled in
                                        var newPrefs = providerManager.preferences
                                        newPrefs.useFallbackHierarchy = enabled
                                        providerManager.updatePreferences(newPrefs)
                                    }
                                ))
                                .tint(.accentColor)
                            }
                            .padding(DesignSystem.spacingMedium)
                            .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusSmall)
                        }
                    }
                    .padding(DesignSystem.spacingLarge)
                    .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
                    
                    // Provider Status Cards
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        HStack(spacing: DesignSystem.spacingMedium) {
                            Image(systemName: "server.rack")
                                .font(.system(size: 20))
                                .foregroundColor(.accentColor)
                                .symbolRenderingMode(.hierarchical)
                            
                            Text("Provider Status")
                                .font(DesignSystem.Typography.bodyLarge)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryText)
                        }
                        
                        VStack(spacing: DesignSystem.spacingMedium) {
                            ForEach(ProviderType.allCases, id: \.self) { providerType in
                                ProviderStatusCard(
                                    providerType: providerType,
                                    onConfigure: {
                                        configureProviderType = providerType
                                        showingConfigSheet = true
                                    }
                                )
                            }
                        }
                    }
                    .padding(DesignSystem.spacingLarge)
                    .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
                    
                    // Information Section
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        HStack(spacing: DesignSystem.spacingMedium) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.accentColor)
                                .symbolRenderingMode(.hierarchical)
                            
                            Text("About AI Providers")
                                .font(DesignSystem.Typography.bodyLarge)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                            InfoItem(
                                icon: "apple.logo",
                                title: "Apple",
                                description: "Local speech recognition, Foundation Models, and built-in voices. Always available, privacy-first."
                            )
                            InfoItem(
                                icon: "brain",
                                title: "OpenAI",
                                description: "Advanced Whisper transcription and GPT refinement. Requires API key."
                            )
                            InfoItem(
                                icon: "network",
                                title: "OpenRouter",
                                description: "Access to free and premium open-source models. Requires API key."
                            )
                            InfoItem(
                                icon: "cloud",
                                title: "Google Cloud",
                                description: "WaveNet and Standard TTS voices with 1M free characters/month. Requires API key."
                            )
                            InfoItem(
                                icon: "waveform",
                                title: "ElevenLabs",
                                description: "Premium quality AI voices with natural speech synthesis. Requires API key."
                            )
                        }
                    }
                    .padding(DesignSystem.spacingLarge)
                    .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .adjustForFloatingSidebar()
        .background(Color.primaryBackground)
        .sheet(isPresented: $showingConfigSheet) {
            if let providerType = configureProviderType {
                ProviderConfigurationSheet(providerType: providerType) {
                    showingConfigSheet = false
                    configureProviderType = nil
                }
            }
        }
    }
    
    private func testAllConnections() {
        isTestingConnections = true
        
        Task {
            let _ = await providerManager.testAllProviders()
            
            await MainActor.run {
                isTestingConnections = false
            }
        }
    }
}

// MARK: - Supporting Views

struct ServiceSelectionRow: View {
    let service: AIService
    let selectedProvider: ProviderType
    let onProviderChange: (ProviderType) -> Void
    
    var body: some View {
        HStack {
            HStack(spacing: DesignSystem.spacingSmall) {
                Image(systemName: service.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                
                Text(service.displayName)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.primaryText)
            }
            
            Spacer()
            
            Picker("", selection: .init(
                get: { selectedProvider },
                set: onProviderChange
            )) {
                ForEach(ProviderType.allCases, id: \.self) { provider in
                    HStack {
                        Image(systemName: provider.icon)
                        Text(provider.displayName)
                    }
                    .tag(provider)
                }
            }
            .pickerStyle(.menu)
            .tint(.accentColor)
        }
        .padding(DesignSystem.spacingMedium)
        .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusSmall)
    }
}

struct ProviderStatusCard: View {
    let providerType: ProviderType
    let onConfigure: () -> Void
    
    @StateObject private var providerManager = AIProviderManager.shared
    
    private var provider: (any AIProvider)? {
        providerManager.providers[providerType]
    }
    
    private var healthStatus: ProviderHealthStatus {
        switch providerType {
        case .apple:
            return (provider as? AppleProvider)?.healthStatus ?? .unavailable
        case .openai:
            return (provider as? OpenAIProvider)?.healthStatus ?? .unavailable
        case .openrouter:
            return (provider as? OpenRouterProvider)?.healthStatus ?? .unavailable
        case .googleCloud:
            return (provider as? GoogleCloudProvider)?.healthStatus ?? .unavailable
        case .elevenLabs:
            return (provider as? ElevenLabsProvider)?.healthStatus ?? .unavailable
        }
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
            // Provider Header
            HStack(spacing: DesignSystem.spacingMedium) {
                // Provider Icon and Info
                HStack(spacing: DesignSystem.spacingMedium) {
                    Image(systemName: providerType.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                        Text(providerType.displayName)
                            .font(DesignSystem.Typography.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryText)
                        
                        Text(providerType.isLocal ? "Local" : "Cloud Service")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(.secondaryText)
                    }
                }
                
                Spacer()
                
                // Status and Actions
                HStack(spacing: DesignSystem.spacingMedium) {
                    // Health Status
                    HStack(spacing: DesignSystem.spacingSmall) {
                        Image(systemName: healthStatus.icon)
                            .font(.system(size: 14))
                            .foregroundColor(healthStatus.color)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text(healthStatus.displayName)
                            .font(DesignSystem.Typography.bodySmall)
                            .fontWeight(.medium)
                            .foregroundColor(healthStatus.color)
                    }
                    .padding(.horizontal, DesignSystem.spacingSmall)
                    .padding(.vertical, 4)
                    .background(healthStatus.color.opacity(0.1))
                    .cornerRadius(DesignSystem.cornerRadiusTiny)
                    
                    // Configure Button (only for providers that need API keys)
                    if providerType.requiresAPIKey {
                        Button(action: onConfigure) {
                            Text(provider?.isConfigured == true ? "Reconfigure" : "Configure")
                                .font(DesignSystem.Typography.bodySmall)
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Model Selection (only for configured cloud providers)
            if (providerType == .openai || providerType == .openrouter || providerType == .googleCloud || providerType == .elevenLabs) && provider?.isConfigured == true {
                ModelSelectionSection(providerType: providerType)
            }
            
        }
        .padding(DesignSystem.spacingMedium)
        .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusSmall)
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.spacingMedium) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                Text(title)
                    .font(DesignSystem.Typography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignSystem.spacingMedium)
        .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusSmall)
    }
}

struct ProviderConfigurationSheet: View {
    let providerType: ProviderType
    let onDismiss: () -> Void
    
    @State private var apiKey = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @StateObject private var providerManager = AIProviderManager.shared
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // Header
            VStack(spacing: DesignSystem.spacingMedium) {
                Image(systemName: providerType.icon)
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Configure \(providerType.displayName)")
                    .font(DesignSystem.Typography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text("Enter your API key to enable \(providerType.displayName) services")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, DesignSystem.spacingLarge)
            
            // API Key Input
            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                Text("API Key")
                    .font(DesignSystem.Typography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                SecureField("Enter your API key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isLoading)
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: DesignSystem.spacingMedium) {
                Button(action: saveConfiguration) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Testing Connection..." : "Save & Test")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.spacingMedium)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(DesignSystem.cornerRadiusSmall)
                }
                .disabled(apiKey.isEmpty || isLoading)
                .buttonStyle(.plain)
                
                Button("Cancel", action: onDismiss)
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(DesignSystem.spacingLarge)
        .frame(width: 400, height: 500)
        .alert("Configuration Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Load existing API key if available
            if let existingKey = try? APIKeyManager.shared.getAPIKey(for: providerType) {
                apiKey = existingKey
            }
        }
    }
    
    private func saveConfiguration() {
        isLoading = true
        
        Task {
            do {
                try await providerManager.configureProvider(providerType, with: apiKey)
                
                await MainActor.run {
                    isLoading = false
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct ModelSelectionSection: View {
    let providerType: ProviderType
    @StateObject private var providerManager = AIProviderManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
            if providerType == .openai {
                // OpenAI Model Selection
                HStack {
                    Text("Transcription Model")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.primaryText)
                        .frame(width: 130, alignment: .leading)
                    
                    Picker("", selection: .init(
                        get: { providerManager.preferences.openaiTranscriptionModel },
                        set: { newModel in
                            var newPrefs = providerManager.preferences
                            newPrefs.openaiTranscriptionModel = newModel
                            providerManager.updatePreferences(newPrefs)
                        }
                    )) {
                        ForEach(Array(OpenAIModels.transcriptionModels.keys), id: \.self) { modelKey in
                            Text(OpenAIModels.transcriptionModels[modelKey] ?? modelKey)
                                .tag(modelKey)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.accentColor)
                }
                
                HStack {
                    Text("Refinement Model")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.primaryText)
                        .frame(width: 130, alignment: .leading)
                    
                    Picker("", selection: .init(
                        get: { providerManager.preferences.openaiRefinementModel },
                        set: { newModel in
                            var newPrefs = providerManager.preferences
                            newPrefs.openaiRefinementModel = newModel
                            providerManager.updatePreferences(newPrefs)
                        }
                    )) {
                        ForEach(Array(OpenAIModels.refinementModels.keys), id: \.self) { modelKey in
                            Text(OpenAIModels.refinementModels[modelKey] ?? modelKey)
                                .tag(modelKey)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.accentColor)
                }
                
                
            } else if providerType == .openrouter {
                // OpenRouter Model Selection
                HStack {
                    Text("Refinement Model")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.primaryText)
                        .frame(width: 130, alignment: .leading)
                    
                    Picker("", selection: .init(
                        get: { providerManager.preferences.openrouterRefinementModel },
                        set: { newModel in
                            var newPrefs = providerManager.preferences
                            newPrefs.openrouterRefinementModel = newModel
                            providerManager.updatePreferences(newPrefs)
                        }
                    )) {
                        ForEach(Array(OpenRouterModels.freeRefinementModels.keys), id: \.self) { modelKey in
                            Text(OpenRouterModels.freeRefinementModels[modelKey] ?? modelKey)
                                .tag(modelKey)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.accentColor)
                }
                
                // Browse Free Models button
                HStack {
                    Spacer()
                    Button("Browse Free Models") {
                        if let url = URL(string: "https://openrouter.ai/models?type=free") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.accentColor)
                    .buttonStyle(.plain)
                }
                
            } else if providerType == .googleCloud {
                // Google Cloud Voice Selection
                Text("Google Cloud TTS Settings")
                    .font(DesignSystem.Typography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 4)
                
                HStack {
                    Text("TTS Voice")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.primaryText)
                        .frame(width: 130, alignment: .leading)
                    
                    Picker("", selection: .init(
                        get: { providerManager.preferences.googleCloudTTSVoice },
                        set: { newVoice in
                            var newPrefs = providerManager.preferences
                            newPrefs.googleCloudTTSVoice = newVoice
                            providerManager.updatePreferences(newPrefs)
                        }
                    )) {
                        ForEach(Array(GoogleCloudModels.ttsVoices.keys), id: \.self) { voiceKey in
                            Text(GoogleCloudModels.ttsVoices[voiceKey] ?? voiceKey)
                                .tag(voiceKey)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.accentColor)
                }
                
            } else if providerType == .elevenLabs {
                // ElevenLabs Voice Selection
                Text("ElevenLabs TTS Settings")
                    .font(DesignSystem.Typography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 4)
                
                HStack {
                    Text("TTS Voice")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.primaryText)
                        .frame(width: 130, alignment: .leading)
                    
                    Picker("", selection: .init(
                        get: { providerManager.preferences.elevenLabsTTSVoice },
                        set: { newVoice in
                            var newPrefs = providerManager.preferences
                            newPrefs.elevenLabsTTSVoice = newVoice
                            providerManager.updatePreferences(newPrefs)
                        }
                    )) {
                        ForEach(Array(ElevenLabsModels.ttsVoices.keys), id: \.self) { voiceKey in
                            Text(ElevenLabsModels.ttsVoices[voiceKey] ?? voiceKey)
                                .tag(voiceKey)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.accentColor)
                }
            }
        }
        .padding(.top, DesignSystem.spacingSmall)
    }
}

#Preview {
    AIProvidersView()
}