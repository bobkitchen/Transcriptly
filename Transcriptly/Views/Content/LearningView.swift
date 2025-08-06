//
//  LearningView.swift
//  Transcriptly
//
//  Created by Claude Code on 8/6/25.
//

import SwiftUI

@available(macOS 26.0, *)
struct LearningView: View {
    @StateObject private var learningService = LearningService.shared
    @State private var showResetConfirmation = false
    @Environment(\.availableWidth) private var availableWidth
    @Environment(\.sidebarCollapsed) private var sidebarCollapsed
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacing.xl) {
                // Header
                headerSection
                
                // Learning status
                statusSection
                
                // Learned patterns
                if !learningService.currentPatterns.isEmpty {
                    patternsSection
                }
                
                // Controls
                controlsSection
            }
            .padding(DesignSystem.spacing.lg)
        }
        .alert("Reset All Learning?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task {
                    await learningService.resetAllLearning()
                }
            }
        } message: {
            Text("This will delete all learned patterns and preferences. This action cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: DesignSystem.spacing.md) {
                HStack {
                    Image(systemName: "brain")
                        .font(.largeTitle)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading) {
                        Text("Learning System")
                            .font(DesignSystem.typography.titleLarge)
                        Text("AI learns from your corrections to improve transcriptions")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $learningService.isLearningEnabled)
                        .toggleStyle(SwitchToggleStyle())
                        .labelsHidden()
                }
                
                HStack {
                    StatCard(
                        title: "Sessions",
                        value: "\(learningService.sessionCount)",
                        icon: "number"
                    )
                    
                    StatCard(
                        title: "Quality",
                        value: qualityText,
                        icon: "star.fill"
                    )
                    
                    StatCard(
                        title: "Patterns",
                        value: "\(learningService.currentPatterns.count)",
                        icon: "doc.text.magnifyingglass"
                    )
                }
            }
            .padding(DesignSystem.spacing.xl)
        }
    }
    
    private var statusSection: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: DesignSystem.spacing.md) {
                Text("Learning Status")
                    .font(.headline)
                
                HStack {
                    Image(systemName: learningService.isLearningEnabled ? "checkmark.circle.fill" : "pause.circle.fill")
                        .foregroundColor(learningService.isLearningEnabled ? .green : .orange)
                    
                    Text(learningService.isLearningEnabled ? "Learning is active" : "Learning is paused")
                        .font(.body)
                }
                
                if learningService.sessionCount < 10 {
                    Text("The system needs more learning sessions to improve accuracy.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(DesignSystem.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var patternsSection: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: DesignSystem.spacing.md) {
                Text("Learned Patterns")
                    .font(.headline)
                
                ForEach(learningService.currentPatterns.prefix(5)) { pattern in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\"\(pattern.originalPhrase)\" → \"\(pattern.correctedPhrase)\"")
                                .font(.body)
                            Text("Confidence: \(Int(pattern.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await learningService.deletePattern(pattern)
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, DesignSystem.spacing.xs)
                    
                    if pattern.id != learningService.currentPatterns.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
            .padding(DesignSystem.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var controlsSection: some View {
        LiquidGlassContainer {
            VStack(spacing: DesignSystem.spacing.md) {
                HStack {
                    Button(action: {
                        if learningService.isLearningEnabled {
                            learningService.pauseLearning()
                        } else {
                            learningService.resumeLearning()
                        }
                    }) {
                        HStack {
                            Image(systemName: learningService.isLearningEnabled ? "pause.fill" : "play.fill")
                            Text(learningService.isLearningEnabled ? "Pause Learning" : "Resume Learning")
                        }
                    }
                    
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset All")
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .padding(DesignSystem.spacing.lg)
        }
    }
    
    private var qualityText: String {
        switch learningService.learningQuality {
        case .minimal: return "Minimal"
        case .basic: return "Basic"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
}