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
    @State private var expandedSections: Set<SettingsSectionType> = []
    
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
                VStack(spacing: DesignSystem.spacingLarge) {
                    ForEach(SettingsSectionType.allCases, id: \.self) { section in
                        EnhancedSettingsSection(
                            section: section,
                            isExpanded: expandedSections.contains(section),
                            onToggle: {
                                withAnimation(DesignSystem.gentleSpring) {
                                    if expandedSections.contains(section) {
                                        expandedSections.remove(section)
                                    } else {
                                        expandedSections.insert(section)
                                    }
                                }
                            },
                            content: {
                                switch section {
                                case .account:
                                    AccountSettingsContent()
                                case .aiProviders:
                                    AIProvidersSettingsContent()
                                case .notifications:
                                    NotificationSettingsContent(
                                        playCompletionSound: $playCompletionSound,
                                        showNotifications: $showNotifications
                                    )
                                case .keyboardShortcuts:
                                    KeyboardShortcutsContent(
                                        recordingShortcut: $recordingShortcut
                                    )
                                case .history:
                                    HistorySettingsContent(showingHistory: $showingHistory)
                                case .about:
                                    AboutSettingsContent()
                                }
                            }
                        )
                    }
                }
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

// MARK: - Settings Section Type

enum SettingsSectionType: String, CaseIterable {
    case account = "Account"
    case aiProviders = "AI Providers"
    case notifications = "Notifications"
    case keyboardShortcuts = "Keyboard Shortcuts"
    case history = "History"
    case about = "About"
    
    var icon: String {
        switch self {
        case .account: return "person.circle.fill"
        case .aiProviders: return "cpu"
        case .notifications: return "bell.fill"
        case .keyboardShortcuts: return "keyboard"
        case .history: return "clock.arrow.circlepath"
        case .about: return "info.circle.fill"
        }
    }
    
    var subtitle: String {
        switch self {
        case .account: return "Sign in to sync across devices"
        case .aiProviders: return "Configure transcription and refinement services"
        case .notifications: return "Manage alerts and sounds"
        case .keyboardShortcuts: return "Customize recording shortcuts"
        case .history: return "View and manage transcription history"
        case .about: return "Version, help, and privacy information"
        }
    }
}

// MARK: - Supporting Views

struct EnhancedSettingsSection<Content: View>: View {
    let section: SettingsSectionType
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: () -> Content
    
    @State private var isHovered = false
    
    private var previewInfo: String {
        switch section {
        case .account: return "Not signed in"
        case .aiProviders: 
            let providerManager = AIProviderManager.shared
            let activeCount = providerManager.providers.values.filter { $0.isConfigured }.count
            return "\(activeCount) configured"
        case .notifications: 
            @AppStorage("showNotifications") var showNotifs = true
            @AppStorage("playCompletionSound") var playSound = true
            if showNotifs && playSound {
                return "All enabled"
            } else if !showNotifs && !playSound {
                return "All disabled"
            } else {
                return "Partially enabled"
            }
        case .keyboardShortcuts: return "⌘⇧V to record"
        case .history:
            let count = TranscriptionHistoryService.shared.transcriptions.count
            return "\(count) transcriptions"
        case .about: return "Version 1.0.0"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Section Header
            Button(action: onToggle) {
                HStack(spacing: DesignSystem.spacingMedium) {
                    // Prominent icon
                    Image(systemName: section.icon)
                        .font(.system(size: 24))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.accentColor)
                        .frame(width: 32)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(section.rawValue)
                                .font(DesignSystem.Typography.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            // Preview info when collapsed
                            if !isExpanded {
                                Text(previewInfo)
                                    .font(DesignSystem.Typography.bodySmall)
                                    .foregroundColor(.secondaryText)
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                            }
                        }
                        
                        Text(section.subtitle)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.secondaryText)
                            .lineLimit(isExpanded ? nil : 1)
                            .animation(DesignSystem.quickAnimation, value: isExpanded)
                    }
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.tertiaryText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(DesignSystem.springAnimation, value: isExpanded)
                }
                .padding(DesignSystem.spacingLarge)
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    content()
                        .padding(.horizontal, DesignSystem.spacingLarge)
                        .padding(.bottom, DesignSystem.spacingLarge)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .liquidGlassBackground(
            material: isHovered ? .thickMaterial : .regularMaterial,
            cornerRadius: DesignSystem.cornerRadiusLarge
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusLarge)
                .strokeBorder(
                    Color.white.opacity(isHovered ? 0.15 : 0.1),
                    lineWidth: 1
                )
        )
        .scaleEffect(isHovered ? 1.005 : 1.0) // Very subtle scale
        .animation(DesignSystem.gentleSpring, value: isHovered)
        .onHover { hovering in
            withAnimation(DesignSystem.gentleSpring) {
                isHovered = hovering
            }
        }
    }
}

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
        VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
            // Service Configuration Section
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                Text("Service Configuration")
                    .font(DesignSystem.Typography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text("Choose which AI providers to use for each service")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.secondaryText)
                
                ServiceSelectionSection()
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Provider Configuration Section
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                Text("Provider Configuration")
                    .font(DesignSystem.Typography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
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
        }
    }
}

// Service Selection Section
struct ServiceSelectionSection: View {
    @StateObject private var providerManager = AIProviderManager.shared
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
            // Transcription Service
            ServiceSelectorRow(
                title: "Transcription",
                icon: "mic.circle",
                selection: Binding(
                    get: { providerManager.preferences.transcriptionProvider },
                    set: { provider in
                        var newPrefs = providerManager.preferences
                        newPrefs.transcriptionProvider = provider
                        providerManager.updatePreferences(newPrefs)
                    }
                )
            )
            
            // Refinement Service
            ServiceSelectorRow(
                title: "Refinement",
                icon: "wand.and.sparkles",
                selection: Binding(
                    get: { providerManager.preferences.refinementProvider },
                    set: { provider in
                        var newPrefs = providerManager.preferences
                        newPrefs.refinementProvider = provider
                        providerManager.updatePreferences(newPrefs)
                    }
                )
            )
            
            // Text-to-Speech Service
            ServiceSelectorRow(
                title: "Text-to-Speech",
                icon: "speaker.wave.3",
                selection: Binding(
                    get: { providerManager.preferences.textToSpeechProvider },
                    set: { provider in
                        var newPrefs = providerManager.preferences
                        newPrefs.textToSpeechProvider = provider
                        providerManager.updatePreferences(newPrefs)
                    }
                )
            )
        }
    }
}

// Service Selector Row
struct ServiceSelectorRow: View {
    let title: String
    let icon: String
    @Binding var selection: ProviderType
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.primaryText)
                .frame(minWidth: 140, alignment: .leading)
            
            Spacer()
            
            Picker("", selection: $selection) {
                ForEach(ProviderType.allCases, id: \.self) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .pickerStyle(.menu)
            .controlSize(.regular)
            .tint(.accentColor)
            .liquidGlassBackground(
                material: .ultraThinMaterial,
                cornerRadius: DesignSystem.cornerRadiusSmall
            )
        }
        .padding(DesignSystem.spacingSmall)
        .background(Color.white.opacity(0.02))
        .cornerRadius(DesignSystem.cornerRadiusSmall)
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
        VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
            // Sound Settings
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                Text("Sound Settings")
                    .font(DesignSystem.Typography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                SettingToggleRow(
                    title: "Play sound on completion",
                    subtitle: "Play a chime when transcription finishes",
                    icon: "speaker.wave.2.fill",
                    isOn: $playCompletionSound
                )
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Notification Settings
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                Text("System Notifications")
                    .font(DesignSystem.Typography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                SettingToggleRow(
                    title: "Show notifications",
                    subtitle: "Display system alerts for completed transcriptions",
                    icon: "bell.fill",
                    isOn: $showNotifications
                )
                
                if showNotifications {
                    Text("Make sure notifications are enabled in System Settings")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.tertiaryText)
                        .padding(.horizontal, DesignSystem.spacingMedium)
                        .padding(.vertical, DesignSystem.spacingSmall)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(DesignSystem.cornerRadiusSmall)
                }
            }
        }
    }
}

// Setting Toggle Row
struct SettingToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.primaryText)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
                .tint(.accentColor)
        }
        .padding(DesignSystem.spacingSmall)
        .background(Color.white.opacity(0.02))
        .cornerRadius(DesignSystem.cornerRadiusSmall)
    }
}

// Keyboard Shortcuts Content
struct KeyboardShortcutsContent: View {
    @Binding var recordingShortcut: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
            // Configurable Shortcuts
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                Text("Configurable Shortcuts")
                    .font(DesignSystem.Typography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                EnhancedShortcutRow(
                    title: "Start/Stop Recording",
                    subtitle: "Toggle recording from anywhere",
                    icon: "mic.circle.fill",
                    shortcut: $recordingShortcut,
                    isEditable: true
                )
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Fixed Shortcuts
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                Text("Fixed Shortcuts")
                    .font(DesignSystem.Typography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                VStack(spacing: DesignSystem.spacingSmall) {
                    FixedShortcutRow(
                        title: "Cancel Recording",
                        shortcut: "Escape",
                        icon: "xmark.circle.fill"
                    )
                    
                    FixedShortcutRow(
                        title: "Raw Mode",
                        shortcut: "⌘1",
                        icon: "text.quote"
                    )
                    
                    FixedShortcutRow(
                        title: "Clean-up Mode",
                        shortcut: "⌘2",
                        icon: "text.justify"
                    )
                    
                    FixedShortcutRow(
                        title: "Email Mode",
                        shortcut: "⌘3",
                        icon: "envelope.fill"
                    )
                    
                    FixedShortcutRow(
                        title: "Messaging Mode",
                        shortcut: "⌘4",
                        icon: "message.fill"
                    )
                }
            }
        }
    }
}

// Enhanced Shortcut Row
struct EnhancedShortcutRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var shortcut: String
    let isEditable: Bool
    @State private var isWaitingForKeypress = false
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.primaryText)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            if isWaitingForKeypress {
                Text("Press keys...")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.orange)
                    .padding(.horizontal, DesignSystem.spacingMedium)
                    .padding(.vertical, DesignSystem.spacingSmall)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(DesignSystem.cornerRadiusSmall)
            } else {
                HStack(spacing: DesignSystem.spacingSmall) {
                    Text(shortcut)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primaryText)
                        .padding(.horizontal, DesignSystem.spacingMedium)
                        .padding(.vertical, DesignSystem.spacingSmall)
                        .liquidGlassBackground(
                            material: .ultraThinMaterial,
                            cornerRadius: DesignSystem.cornerRadiusSmall
                        )
                    
                    if isEditable {
                        Button(action: {
                            isWaitingForKeypress = true
                        }) {
                            Text("Edit")
                                .font(DesignSystem.Typography.bodySmall)
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(DesignSystem.spacingSmall)
        .background(Color.white.opacity(0.02))
        .cornerRadius(DesignSystem.cornerRadiusSmall)
    }
}

// Fixed Shortcut Row
struct FixedShortcutRow: View {
    let title: String
    let shortcut: String
    let icon: String
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.secondaryText)
                .frame(width: 24)
            
            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.primaryText)
            
            Spacer()
            
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondaryText)
                .padding(.horizontal, DesignSystem.spacingSmall)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.05))
                .cornerRadius(4)
        }
        .padding(.horizontal, DesignSystem.spacingSmall)
        .padding(.vertical, DesignSystem.spacingTiny)
    }
}

// History Settings Content
struct HistorySettingsContent: View {
    @Binding var showingHistory: Bool
    @ObservedObject private var historyService = TranscriptionHistoryService.shared
    
    private var weekCount: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            return 0
        }
        return historyService.transcriptions.filter { $0.timestamp >= weekAgo }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            // History Stats
            HStack(spacing: DesignSystem.spacingLarge) {
                HistoryStatItem(
                    title: "Total",
                    value: "\(historyService.transcriptions.count)",
                    icon: "doc.text.fill"
                )
                
                HistoryStatItem(
                    title: "This Week",
                    value: "\(weekCount)",
                    icon: "calendar"
                )
                
                HistoryStatItem(
                    title: "Today",
                    value: "\(historyService.getTodayTranscriptions().count)",
                    icon: "clock.fill"
                )
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // View History Button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Full History")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.primaryText)
                    
                    Text("View all transcriptions with search and filters")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Button("View History") {
                    showingHistory = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

// History Stat Item
struct HistoryStatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingSmall) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(DesignSystem.Typography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text(title)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.spacingSmall)
        .background(Color.white.opacity(0.02))
        .cornerRadius(DesignSystem.cornerRadiusSmall)
    }
}

// About Settings Content
struct AboutSettingsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
            // App Info
            HStack(spacing: DesignSystem.spacingMedium) {
                Image(systemName: "app.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transcriptly")
                        .font(DesignSystem.Typography.titleLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryText)
                    
                    Text("Version 1.0.0 (Build 100)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.secondaryText)
                    
                    Text("© 2025 Transcriptly Inc.")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.tertiaryText)
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Links
            VStack(spacing: DesignSystem.spacingSmall) {
                AboutLinkRow(
                    title: "Help & Support",
                    subtitle: "Get help with Transcriptly",
                    icon: "questionmark.circle.fill",
                    url: URL(string: "https://transcriptly.app/help")!
                )
                
                AboutLinkRow(
                    title: "Privacy Policy",
                    subtitle: "How we handle your data",
                    icon: "lock.shield.fill",
                    url: URL(string: "https://transcriptly.app/privacy")!
                )
                
                AboutLinkRow(
                    title: "Terms of Service",
                    subtitle: "Our service agreement",
                    icon: "doc.text.fill",
                    url: URL(string: "https://transcriptly.app/terms")!
                )
                
                AboutLinkRow(
                    title: "Send Feedback",
                    subtitle: "Help us improve Transcriptly",
                    icon: "envelope.fill",
                    url: URL(string: "mailto:feedback@transcriptly.app")!
                )
            }
        }
    }
}

// About Link Row
struct AboutLinkRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let url: URL
    @State private var isHovered = false
    
    var body: some View {
        Link(destination: url) {
            HStack(spacing: DesignSystem.spacingMedium) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.primaryText)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(.tertiaryText)
                    .opacity(isHovered ? 1 : 0.5)
            }
            .padding(DesignSystem.spacingSmall)
            .background(Color.white.opacity(isHovered ? 0.05 : 0.02))
            .cornerRadius(DesignSystem.cornerRadiusSmall)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(DesignSystem.quickAnimation, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
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