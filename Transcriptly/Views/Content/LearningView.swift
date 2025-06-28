//
//  LearningView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//  Updated by Claude Code on 6/28/25 for Phase 4 Fixes - Liquid Glass Design
//

import SwiftUI

struct LearningView: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @ObservedObject private var learningService = LearningService.shared
    @State private var learnedPatterns: [LearnedPattern] = []
    @State private var userPreferences: [UserPreference] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var showResetAlert = false
    @State private var selectedPattern: LearnedPattern?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                // Header section
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    Text("Learning")
                        .font(DesignSystem.Typography.titleLarge)
                        .foregroundColor(.primaryText)
                        .padding(.top, DesignSystem.marginStandard)
                    
                    Text("Transcriptly learns from your corrections to improve accuracy over time")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.secondaryText)
                }
                
                // Authentication Status Card
                AuthStatusCard()
                
                // Learning Status Card
                LearningStatusCard(
                    learningService: learningService,
                    onResetTapped: { showResetAlert = true }
                )
                
                // Learned Patterns Section
                VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                    HStack {
                        Text("Learned Patterns")
                            .font(DesignSystem.Typography.titleMedium)
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                        
                        Button("Refresh") {
                            loadPatterns()
                        }
                        .buttonStyle(CompactButtonStyle())
                    }
                    
                    if isLoading {
                        LoadingCard()
                    } else if learnedPatterns.isEmpty {
                        EmptyPatternsCard()
                    } else {
                        VStack(spacing: DesignSystem.spacingSmall) {
                            ForEach(learnedPatterns) { pattern in
                                PatternCard(pattern: pattern) {
                                    selectedPattern = pattern
                                }
                            }
                        }
                    }
                }
                
                // Error Display
                if let error = error {
                    ErrorCard(error: error) {
                        self.error = nil
                    }
                }
            }
            .padding(DesignSystem.marginStandard)
        }
        .background(Color.primaryBackground)
        .onAppear {
            loadPatterns()
            loadPreferences()
        }
        .alert("Reset All Learning Data", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllLearning()
            }
        } message: {
            Text("This will permanently delete all learned patterns and preferences. This action cannot be undone.")
        }
        .alert("Delete Pattern", isPresented: .constant(selectedPattern != nil)) {
            Button("Cancel", role: .cancel) {
                selectedPattern = nil
            }
            Button("Delete", role: .destructive) {
                if let pattern = selectedPattern {
                    deletePattern(pattern)
                    selectedPattern = nil
                }
            }
        } message: {
            if let pattern = selectedPattern {
                Text("Delete pattern: \"\(pattern.originalPhrase)\" → \"\(pattern.correctedPhrase)\"?")
            }
        }
    }
    
    private var learningQualityText: String {
        switch learningService.learningQuality {
        case .minimal: return "Getting Started"
        case .basic: return "Basic"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    private var learningQualityColor: Color {
        switch learningService.learningQuality {
        case .minimal: return .orange
        case .basic: return .yellow
        case .good: return .blue
        case .excellent: return .green
        }
    }
    
    private func loadPatterns() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let patterns = try await supabaseManager.getActivePatterns()
                await MainActor.run {
                    self.learnedPatterns = patterns
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load patterns: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadPreferences() {
        Task {
            do {
                let preferences = try await supabaseManager.getPreferences()
                await MainActor.run {
                    self.userPreferences = preferences
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load preferences: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deletePattern(_ pattern: LearnedPattern) {
        Task {
            await learningService.deletePattern(pattern)
            loadPatterns() // Refresh the list
        }
    }
    
    private func resetAllLearning() {
        Task {
            await learningService.resetAllLearning()
            loadPatterns()
            loadPreferences()
        }
    }
}

// MARK: - Supporting Views

struct AuthStatusCard: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack(spacing: DesignSystem.spacingMedium) {
                Image(systemName: supabaseManager.isAuthenticated ? "checkmark.circle.fill" : "cloud.slash")
                    .font(.system(size: 20))
                    .foregroundColor(supabaseManager.isAuthenticated ? .green : .orange)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                    Text(supabaseManager.isAuthenticated ? "Connected to Cloud" : "Offline Mode")
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                    
                    Text(supabaseManager.isAuthenticated ? "Learning data syncs across devices" : "Sign in to sync learning data across devices")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                if supabaseManager.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if !supabaseManager.isAuthenticated {
                    Button("Sign In") {
                        // TODO: Implement auth UI
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(true) // Disabled for now
                }
            }
        }
        .padding(DesignSystem.spacingLarge)
        .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
    }
}

struct LearningStatusCard: View {
    @ObservedObject var learningService: LearningService
    let onResetTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack(spacing: DesignSystem.spacingMedium) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Learning Status")
                    .font(DesignSystem.Typography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { learningService.isLearningEnabled },
                    set: { enabled in
                        if enabled {
                            learningService.resumeLearning()
                        } else {
                            learningService.pauseLearning()
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle())
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                HStack {
                    Text("Sessions: \(learningService.sessionCount)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.secondaryText)
                    
                    Text("•")
                        .foregroundColor(.tertiaryText)
                    
                    Text(learningQualityText)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(learningQualityColor)
                }
                
                if !learningService.isLearningEnabled {
                    Text("Learning is paused. Enable to continue improving accuracy.")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.secondaryText)
                        .padding(.vertical, DesignSystem.spacingSmall)
                        .padding(.horizontal, DesignSystem.spacingMedium)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(DesignSystem.cornerRadiusTiny)
                }
                
                HStack {
                    Spacer()
                    Button("Reset All Data") {
                        onResetTapped()
                    }
                    .buttonStyle(CompactButtonStyle())
                    .foregroundColor(.red)
                    .disabled(learningService.sessionCount == 0)
                }
            }
        }
        .padding(DesignSystem.spacingLarge)
        .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
    }
    
    private var learningQualityText: String {
        switch learningService.learningQuality {
        case .minimal: return "Getting Started"
        case .basic: return "Learning Basics"
        case .good: return "Good Progress"
        case .excellent: return "Highly Trained"
        }
    }
    
    private var learningQualityColor: Color {
        switch learningService.learningQuality {
        case .minimal: return .orange
        case .basic: return .yellow
        case .good: return .blue
        case .excellent: return .green
        }
    }
}

struct LoadingCard: View {
    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Loading patterns...")
                .font(DesignSystem.Typography.body)
                .foregroundColor(.secondaryText)
            
            Spacer()
        }
        .padding(DesignSystem.spacingLarge)
        .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
    }
}

struct EmptyPatternsCard: View {
    var body: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
            Image(systemName: "brain")
                .font(.system(size: 48))
                .foregroundColor(.tertiaryText)
                .symbolRenderingMode(.hierarchical)
            
            Text("No patterns learned yet")
                .font(DesignSystem.Typography.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(.secondaryText)
            
            Text("As you use Transcriptly, it will learn from your corrections and preferences to improve accuracy.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.spacingLarge * 2)
        .padding(.horizontal, DesignSystem.spacingLarge)
        .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
    }
}

struct PatternCard: View {
    let pattern: LearnedPattern
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                    HStack {
                        Text(pattern.originalPhrase)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.primaryText)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.tertiaryText)
                        
                        Text(pattern.correctedPhrase)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.accentColor)
                            .fontWeight(.medium)
                    }
                    
                    if let mode = pattern.refinementMode {
                        Text("Mode: \(mode.rawValue)")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(.tertiaryText)
                    }
                }
                
                Spacer()
                
                HStack(spacing: DesignSystem.spacingMedium) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(pattern.occurrenceCount)x")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(.secondaryText)
                        
                        Text("\(Int(pattern.confidence * 100))%")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(pattern.confidence > 0.8 ? .green : .orange)
                    }
                    
                    if isHovered {
                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Delete this pattern")
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
        }
        .padding(DesignSystem.spacingMedium)
        .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusSmall)
        .onHover { hovering in
            withAnimation(DesignSystem.fadeAnimation) {
                isHovered = hovering
            }
        }
    }
}

struct ErrorCard: View {
    let error: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundColor(.orange)
            
            Text(error)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button("Dismiss") {
                onDismiss()
            }
            .buttonStyle(CompactButtonStyle())
        }
        .padding(DesignSystem.spacingLarge)
        .background(Color.orange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(DesignSystem.cornerRadiusMedium)
    }
}

#Preview {
    LearningView()
}