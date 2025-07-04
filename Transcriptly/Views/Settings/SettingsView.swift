//
//  SettingsView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//  Updated by Claude Code on 6/28/25 for Phase 4 Fixes - Liquid Glass Design
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    let onFloat: () -> Void
    @AppStorage("playCompletionSound") private var playCompletionSound = true
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("recordingShortcut") private var recordingShortcut = "⌘⌥V"
    @State private var showingHistory = false
    
    // Responsive layout properties
    @Environment(\.availableWidth) private var availableWidth
    @Environment(\.sidebarCollapsed) private var sidebarCollapsed
    
    var body: some View {
        VStack(spacing: 0) {
            // Integrated header
            ContentHeader(
                viewModel: viewModel,
                title: "Settings",
                showModeControls: false,
                showFloatButton: true,
                onFloat: onFloat
            )
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                    // Account Section (Placeholder)
                    SettingsSection(
                        title: "Account",
                        icon: "person.circle",
                        content: {
                            AccountSettingsContent()
                        }
                    )
                    
                    // AI Providers Section (moved from main navigation)
                    SettingsSection(
                        title: "AI Providers",
                        icon: "cpu",
                        content: {
                            AIProvidersSettingsContent()
                        }
                    )
                
                    // Notifications Section
                    SettingsSection(
                        title: "Notifications", 
                        icon: "bell",
                        content: {
                            NotificationSettingsContent(
                                playCompletionSound: $playCompletionSound,
                                showNotifications: $showNotifications
                            )
                        }
                    )
                
                    // Keyboard Shortcuts Section
                    SettingsSection(
                        title: "Keyboard Shortcuts",
                        icon: "keyboard",
                        content: {
                            KeyboardShortcutsContent(
                                recordingShortcut: $recordingShortcut
                            )
                        }
                    )
                    
                    // History Section
                    SettingsSection(
                        title: "History",
                        icon: "clock.arrow.circlepath",
                        content: {
                            HistorySettingsContent(showingHistory: $showingHistory)
                        }
                    )
                
                    // About Section
                    SettingsSection(
                        title: "About",
                        icon: "info.circle",
                        content: {
                            AboutSettingsContent()
                        }
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignSystem.marginStandard)
            .padding(.bottom, DesignSystem.spacingLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
    }
}

// MARK: - Supporting Views

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            Button(action: { 
                withAnimation(DesignSystem.springAnimation) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(DesignSystem.quickAnimation, value: isExpanded)
                }
                .padding(DesignSystem.spacingMedium)
            }
            .buttonStyle(.plain)
            .liquidGlassCard()
            
            // Section Content
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    content()
                }
                .padding(.top, DesignSystem.spacingSmall)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }
}

// Account Settings Content
struct AccountSettingsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            Text("Sign in to sync your preferences")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Sign In") {
                // TODO: Implement in future phase
            }
            .buttonStyle(.bordered)
            .disabled(true)
            
            Text("Account features coming soon")
                .font(.caption2)
                .foregroundColor(.tertiaryText)
        }
        .padding(DesignSystem.spacingMedium)
        .liquidGlassCard()
    }
}

// AI Providers Settings Content
struct AIProvidersSettingsContent: View {
    @StateObject private var providerManager = AIProviderManager.shared
    @State private var expandedProvider: ProviderType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            Text("Configure AI services for transcription, refinement, and text-to-speech")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Service Selection
            ServiceSelectionSection()
                .padding(.bottom, DesignSystem.spacingSmall)
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, DesignSystem.spacingSmall)
            
            Text("PROVIDER CONFIGURATION")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.tertiaryText)
                .tracking(0.5)
            
            // All Providers
            VStack(spacing: DesignSystem.spacingSmall) {
                ForEach(ProviderType.allCases, id: \.self) { providerType in
                    ExpandableProviderRow(
                        providerType: providerType,
                        isExpanded: expandedProvider == providerType,
                        onToggle: {
                            withAnimation(DesignSystem.springAnimation) {
                                expandedProvider = expandedProvider == providerType ? nil : providerType
                            }
                        }
                    )
                }
            }
        }
        .padding(DesignSystem.spacingMedium)
        .liquidGlassCard()
    }
}

// Service Selection Section
struct ServiceSelectionSection: View {
    @StateObject private var providerManager = AIProviderManager.shared
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingSmall) {
            // Transcription Service
            HStack {
                Label("Transcription", systemImage: "mic.circle")
                    .font(.caption)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Picker("", selection: .init(
                    get: { providerManager.preferences.transcriptionProvider },
                    set: { provider in
                        var newPrefs = providerManager.preferences
                        newPrefs.transcriptionProvider = provider
                        providerManager.updatePreferences(newPrefs)
                    }
                )) {
                    ForEach(ProviderType.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)
            }
            
            // Refinement Service
            HStack {
                Label("Refinement", systemImage: "wand.and.sparkles")
                    .font(.caption)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Picker("", selection: .init(
                    get: { providerManager.preferences.refinementProvider },
                    set: { provider in
                        var newPrefs = providerManager.preferences
                        newPrefs.refinementProvider = provider
                        providerManager.updatePreferences(newPrefs)
                    }
                )) {
                    ForEach(ProviderType.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)
            }
            
            // Text-to-Speech Service
            HStack {
                Label("Text-to-Speech", systemImage: "speaker.wave.3")
                    .font(.caption)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Picker("", selection: .init(
                    get: { providerManager.preferences.textToSpeechProvider },
                    set: { provider in
                        var newPrefs = providerManager.preferences
                        newPrefs.textToSpeechProvider = provider
                        providerManager.updatePreferences(newPrefs)
                    }
                )) {
                    ForEach(ProviderType.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)
            }
        }
    }
}

// Expandable Provider Row
struct ExpandableProviderRow: View {
    let providerType: ProviderType
    let isExpanded: Bool
    let onToggle: () -> Void
    
    @StateObject private var providerManager = AIProviderManager.shared
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var validationStatus: ValidationStatus = .none
    
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
    
    enum ValidationStatus {
        case none, valid, invalid
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Provider Header (always visible)
            Button(action: onToggle) {
                HStack {
                    // Provider Icon
                    Image(systemName: providerType.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                    
                    // Provider Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(providerType.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primaryText)
                        
                        Text(providerDescription)
                            .font(.caption2)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    HStack(spacing: 4) {
                        Image(systemName: healthStatus.icon)
                            .font(.system(size: 10))
                        Text(healthStatus.displayName)
                            .font(.caption2)
                    }
                    .foregroundColor(healthStatus.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(healthStatus.color.opacity(0.1))
                    .cornerRadius(4)
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.tertiaryText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, DesignSystem.spacingSmall)
                .padding(.horizontal, DesignSystem.spacingMedium)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: DesignSystem.spacingMedium) {
                    Divider()
                        .background(Color.white.opacity(0.05))
                    
                    // API Key Configuration (if needed)
                    if providerType.requiresAPIKey {
                        APIKeyConfigurationView(
                            providerType: providerType,
                            apiKey: $apiKey,
                            isValidating: $isValidating,
                            validationStatus: $validationStatus
                        )
                    }
                    
                    // Model/Voice Selection
                    if provider?.isConfigured == true || !providerType.requiresAPIKey {
                        ProviderOptionsView(providerType: providerType)
                    }
                }
                .padding(.horizontal, DesignSystem.spacingMedium)
                .padding(.bottom, DesignSystem.spacingMedium)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(Color.white.opacity(0.02))
        .cornerRadius(DesignSystem.cornerRadiusSmall)
        .onAppear {
            loadAPIKey()
        }
    }
    
    private var providerDescription: String {
        switch providerType {
        case .apple:
            return "Local processing • Always available • Privacy-first"
        case .openai:
            return "Whisper transcription • GPT refinement • TTS voices"
        case .openrouter:
            return "Free & premium models • Flexible refinement"
        case .googleCloud:
            return "WaveNet & Standard voices • 1M free chars/month"
        case .elevenLabs:
            return "Premium AI voices • Natural speech synthesis"
        }
    }
    
    private func loadAPIKey() {
        if let existingKey = try? APIKeyManager.shared.getAPIKey(for: providerType) {
            apiKey = existingKey
            validationStatus = provider?.isConfigured == true ? .valid : .none
        }
    }
}

// API Key Configuration View
struct APIKeyConfigurationView: View {
    let providerType: ProviderType
    @Binding var apiKey: String
    @Binding var isValidating: Bool
    @Binding var validationStatus: ExpandableProviderRow.ValidationStatus
    @StateObject private var providerManager = AIProviderManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
            Text("API KEY")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.tertiaryText)
                .tracking(0.5)
            
            HStack {
                SecureField("Enter your API key", text: $apiKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .disabled(isValidating)
                
                Button(action: validateAndSave) {
                    if isValidating {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Text(validationStatus == .valid ? "Valid" : "Validate")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(apiKey.isEmpty || isValidating)
                
                // Status icon
                switch validationStatus {
                case .valid:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                case .invalid:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                case .none:
                    EmptyView()
                }
            }
            .padding(DesignSystem.spacingSmall)
            .background(Color.white.opacity(0.03))
            .cornerRadius(DesignSystem.cornerRadiusTiny)
        }
    }
    
    private func validateAndSave() {
        isValidating = true
        
        Task {
            do {
                try await providerManager.configureProvider(providerType, with: apiKey)
                await MainActor.run {
                    validationStatus = .valid
                    isValidating = false
                }
            } catch {
                await MainActor.run {
                    validationStatus = .invalid
                    isValidating = false
                }
            }
        }
    }
}

// Provider Options View (Models/Voices)
struct ProviderOptionsView: View {
    let providerType: ProviderType
    @StateObject private var providerManager = AIProviderManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            switch providerType {
            case .apple:
                // Apple has no configurable options
                EmptyView()
                
            case .openai:
                OpenAIOptionsView()
                
            case .openrouter:
                OpenRouterOptionsView()
                
            case .googleCloud:
                GoogleCloudOptionsView()
                
            case .elevenLabs:
                ElevenLabsOptionsView()
            }
        }
    }
}

// OpenAI Options
struct OpenAIOptionsView: View {
    @StateObject private var providerManager = AIProviderManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
            // Transcription Model
            HStack {
                Text("Transcription Model")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(width: 110, alignment: .leading)
                
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
                .controlSize(.small)
            }
            
            // Refinement Model
            HStack {
                Text("Refinement Model")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(width: 110, alignment: .leading)
                
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
                .controlSize(.small)
            }
            
            // TTS Voice
            HStack {
                Text("TTS Voice")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(width: 110, alignment: .leading)
                
                Picker("", selection: .init(
                    get: { providerManager.preferences.openaiTTSVoice ?? "alloy" },
                    set: { newVoice in
                        var newPrefs = providerManager.preferences
                        newPrefs.openaiTTSVoice = newVoice
                        providerManager.updatePreferences(newPrefs)
                    }
                )) {
                    ForEach(Array(OpenAIModels.ttsVoices.keys).sorted(), id: \.self) { voiceKey in
                        Text(OpenAIModels.ttsVoices[voiceKey] ?? voiceKey)
                            .tag(voiceKey)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)
            }
        }
    }
}

// OpenRouter Options
struct OpenRouterOptionsView: View {
    @StateObject private var providerManager = AIProviderManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
            // Refinement Model
            HStack {
                Text("Refinement Model")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(width: 110, alignment: .leading)
                
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
                .controlSize(.small)
            }
            
            // Browse Models Link
            HStack {
                Spacer()
                Button("Browse Free Models →") {
                    if let url = URL(string: "https://openrouter.ai/models?type=free") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .font(.caption2)
                .foregroundColor(.accentColor)
                .buttonStyle(.plain)
            }
        }
    }
}

// Google Cloud Options
struct GoogleCloudOptionsView: View {
    @StateObject private var providerManager = AIProviderManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
            // TTS Voice
            HStack {
                Text("TTS Voice")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(width: 110, alignment: .leading)
                
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
                .controlSize(.small)
            }
            
            // Voice Type Info
            Text("WaveNet voices are higher quality but cost more")
                .font(.caption2)
                .foregroundColor(.tertiaryText)
        }
    }
}

// ElevenLabs Options
struct ElevenLabsOptionsView: View {
    @StateObject private var providerManager = AIProviderManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
            // TTS Voice
            HStack {
                Text("TTS Voice")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(width: 110, alignment: .leading)
                
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
                .controlSize(.small)
            }
            
            // Model Selection
            HStack {
                Text("Model")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(width: 110, alignment: .leading)
                
                Picker("", selection: .init(
                    get: { providerManager.preferences.elevenLabsTTSModel ?? "eleven_multilingual_v2" },
                    set: { newModel in
                        var newPrefs = providerManager.preferences
                        newPrefs.elevenLabsTTSModel = newModel
                        providerManager.updatePreferences(newPrefs)
                    }
                )) {
                    Text("Multilingual v2").tag("eleven_multilingual_v2")
                    Text("Monolingual v1").tag("eleven_monolingual_v1")
                    Text("Turbo v2").tag("eleven_turbo_v2")
                }
                .pickerStyle(.menu)
                .controlSize(.small)
            }
        }
    }
}

// Notification Settings Content
struct NotificationSettingsContent: View {
    @Binding var playCompletionSound: Bool
    @Binding var showNotifications: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            Toggle("Play sound on completion", isOn: $playCompletionSound)
                .toggleStyle(SwitchToggleStyle())
                .tint(.accentColor)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            Toggle("Show notifications", isOn: $showNotifications)
                .toggleStyle(SwitchToggleStyle())
                .tint(.accentColor)
        }
        .padding(DesignSystem.spacingMedium)
        .liquidGlassCard()
    }
}

// Keyboard Shortcuts Content
struct KeyboardShortcutsContent: View {
    @Binding var recordingShortcut: String
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingSmall) {
            ShortcutRow(
                title: "Start/Stop Recording",
                shortcut: $recordingShortcut,
                isEditable: true
            )
            
            Text("Only recording shortcut is configurable. Refinement modes can be selected using the interface.")
                .font(.caption)
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.top, DesignSystem.spacingSmall)
        }
        .padding(DesignSystem.spacingMedium)
        .liquidGlassCard()
    }
}

// History Settings Content
struct HistorySettingsContent: View {
    @Binding var showingHistory: Bool
    
    var body: some View {
        HStack {
            Text("View transcription history")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("View History") {
                showingHistory = true
            }
            .buttonStyle(.bordered)
        }
        .padding(DesignSystem.spacingMedium)
        .liquidGlassCard()
    }
}

// About Settings Content
struct AboutSettingsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack {
                Text("Transcriptly")
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: DesignSystem.spacingLarge) {
                Link("Help", destination: URL(string: "https://transcriptly.app/help")!)
                    .foregroundColor(.accentColor)
                
                Link("Privacy Policy", destination: URL(string: "https://transcriptly.app/privacy")!)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(DesignSystem.spacingMedium)
        .liquidGlassCard()
    }
}

/// Reusable settings card component with Liquid Glass design
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack(spacing: DesignSystem.spacingMedium) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(accentColor)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 24)
                
                Text(title)
                    .font(DesignSystem.Typography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
            }
            
            content
        }
        .padding(DesignSystem.spacingLarge)
        .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
    }
}

struct ShortcutRow: View {
    let title: String
    @Binding var shortcut: String
    let isEditable: Bool
    @State private var isWaitingForKeypress = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.primaryText)
            
            Spacer()
            
            if isWaitingForKeypress {
                ZStack {
                    Text("Press keys... (ESC to cancel)")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.orange)
                        .padding(.horizontal, DesignSystem.spacingSmall)
                        .padding(.vertical, DesignSystem.spacingTiny)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(DesignSystem.cornerRadiusTiny)
                    
                    KeyboardShortcutRecorder(
                        shortcut: $shortcut,
                        onStartRecording: {
                            // Already in recording state
                        },
                        onStopRecording: {
                            isWaitingForKeypress = false
                        }
                    )
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .onAppear {
                        // Start recording when the recorder appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let recorderView = findRecorderView() {
                                recorderView.startRecording()
                            }
                        }
                    }
                }
            } else {
                Text(shortcut)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .padding(.horizontal, DesignSystem.spacingSmall)
                    .padding(.vertical, DesignSystem.spacingTiny)
                    .background(Color.tertiaryBackground)
                    .cornerRadius(DesignSystem.cornerRadiusTiny)
            }
            
            if isEditable {
                Button(isWaitingForKeypress ? "Cancel" : "Edit") {
                    if isWaitingForKeypress {
                        if let recorderView = findRecorderView() {
                            recorderView.stopRecording()
                        }
                        isWaitingForKeypress = false
                    } else {
                        isWaitingForKeypress = true
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func findRecorderView() -> SimpleKeyRecorderView? {
        // Helper function to find the recorder view in the view hierarchy
        guard let window = NSApplication.shared.keyWindow else { return nil }
        return findRecorderInView(window.contentView)
    }
    
    private func findRecorderInView(_ view: NSView?) -> SimpleKeyRecorderView? {
        guard let view = view else { return nil }
        
        if let recorder = view as? SimpleKeyRecorderView {
            return recorder
        }
        
        for subview in view.subviews {
            if let recorder = findRecorderInView(subview) {
                return recorder
            }
        }
        
        return nil
    }
}

#Preview {
    SettingsView(viewModel: AppViewModel(), onFloat: {})
}