//
//  LearningDashboard.swift
//  Transcriptly
//
//  Comprehensive dashboard for learning system management and effectiveness tracking
//

import SwiftUI
import Charts

struct LearningDashboard: View {
    @ObservedObject private var learningService = LearningService.shared
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var learnedPatterns: [LearnedPattern] = []
    @State private var effectivenessData: [EffectivenessDataPoint] = []
    @State private var isLoading = false
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedPattern: LearnedPattern?
    @State private var showPatternDetail = false
    
    enum TimeRange: String, CaseIterable {
        case day = "24 Hours"
        case week = "7 Days"
        case month = "30 Days"
        case all = "All Time"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                // Header with controls
                headerSection
                
                // Key Metrics
                metricsSection
                
                // Effectiveness Chart
                effectivenessChartSection
                
                // Pattern Management
                patternManagementSection
                
                // User Preferences
                preferencesSection
            }
            .padding(DesignSystem.spacingLarge)
        }
        .background(Color.primaryBackground)
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showPatternDetail) {
            if let pattern = selectedPattern {
                PatternDetailView(pattern: pattern) {
                    loadData() // Refresh after changes
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    Text("Learning Dashboard")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primaryText)
                    
                    Text("Track and manage AI learning effectiveness")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                // Learning Toggle
                VStack(alignment: .trailing, spacing: 4) {
                    Toggle("Learning", isOn: Binding(
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
                    
                    Text(learningService.isLearningEnabled ? "Active" : "Paused")
                        .font(.caption)
                        .foregroundColor(learningService.isLearningEnabled ? .green : .orange)
                }
            }
            
            if !learningService.isLearningEnabled {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    Text("Learning is paused. New patterns won't be recorded.")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(DesignSystem.spacingSmall)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(DesignSystem.cornerRadiusSmall)
            }
        }
    }
    
    private var metricsSection: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            MetricCard(
                title: "Total Sessions",
                value: "\(learningService.sessionCount)",
                icon: "brain",
                color: .blue
            )
            
            MetricCard(
                title: "Patterns Learned",
                value: "\(learnedPatterns.count)",
                icon: "text.magnifyingglass",
                color: .green
            )
            
            MetricCard(
                title: "Avg. Confidence",
                value: "\(Int(averageConfidence * 100))%",
                icon: "chart.line.uptrend.xyaxis",
                color: averageConfidence > 0.7 ? .green : .orange
            )
            
            MetricCard(
                title: "Learning Quality",
                value: learningQualityText,
                icon: "star.fill",
                color: learningQualityColor
            )
        }
    }
    
    private var effectivenessChartSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack {
                Text("Learning Effectiveness")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 300)
            }
            
            if effectivenessData.isEmpty {
                EmptyChartView()
            } else {
                Chart(effectivenessData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Score", dataPoint.score)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Score", dataPoint.score)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.vertical, DesignSystem.spacingSmall)
                .liquidGlassBackground(
                    material: .ultraThinMaterial,
                    cornerRadius: DesignSystem.cornerRadiusMedium
                )
            }
        }
    }
    
    private var patternManagementSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack {
                Text("Learned Patterns")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button("Refresh") {
                        loadData()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            if learnedPatterns.isEmpty {
                EmptyPatternsView()
            } else {
                LazyVStack(spacing: DesignSystem.spacingSmall) {
                    ForEach(learnedPatterns.sorted(by: { $0.confidence > $1.confidence })) { pattern in
                        PatternRowView(pattern: pattern) {
                            selectedPattern = pattern
                            showPatternDetail = true
                        }
                    }
                }
            }
        }
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            Text("User Preferences")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Text("Transcriptly learns your writing style preferences")
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
            
            // Placeholder for preference insights
            HStack(spacing: DesignSystem.spacingMedium) {
                PreferenceInsight(
                    icon: "text.alignleft",
                    label: "Formality",
                    value: "Professional"
                )
                
                PreferenceInsight(
                    icon: "textformat.size",
                    label: "Conciseness",
                    value: "Balanced"
                )
                
                PreferenceInsight(
                    icon: "doc.text",
                    label: "Structure",
                    value: "Paragraph"
                )
            }
            .padding(DesignSystem.spacingMedium)
            .liquidGlassBackground(
                material: .ultraThinMaterial,
                cornerRadius: DesignSystem.cornerRadiusMedium
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var averageConfidence: Double {
        guard !learnedPatterns.isEmpty else { return 0 }
        let sum = learnedPatterns.reduce(0) { $0 + $1.confidence }
        return sum / Double(learnedPatterns.count)
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
    
    // MARK: - Data Loading
    
    private func loadData() {
        isLoading = true
        
        Task {
            // Load patterns
            let patterns = await learningService.getActivePatterns()
            
            // Generate mock effectiveness data (in real app, this would come from analytics)
            let mockData = generateMockEffectivenessData()
            
            await MainActor.run {
                self.learnedPatterns = patterns
                self.effectivenessData = mockData
                self.isLoading = false
            }
        }
    }
    
    private func generateMockEffectivenessData() -> [EffectivenessDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        var dataPoints: [EffectivenessDataPoint] = []
        
        let days: Int
        switch selectedTimeRange {
        case .day: days = 1
        case .week: days = 7
        case .month: days = 30
        case .all: days = 90
        }
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: endDate) {
                let baseScore = 60.0 + Double(learningService.sessionCount) * 0.3
                let variation = Double.random(in: -10...10)
                let score = min(100, max(0, baseScore + variation))
                dataPoints.append(EffectivenessDataPoint(date: date, score: score))
            }
        }
        
        return dataPoints.reversed()
    }
}

// MARK: - Supporting Types

struct EffectivenessDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Double
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingSmall) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primaryText)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.spacingMedium)
        .liquidGlassBackground(
            material: .ultraThinMaterial,
            cornerRadius: DesignSystem.cornerRadiusMedium
        )
    }
}

struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.tertiaryText)
            
            Text("No effectiveness data yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondaryText)
            
            Text("Use Transcriptly more to see learning progress")
                .font(.system(size: 14))
                .foregroundColor(.tertiaryText)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .liquidGlassBackground(
            material: .ultraThinMaterial,
            cornerRadius: DesignSystem.cornerRadiusMedium
        )
    }
}

struct EmptyPatternsView: View {
    var body: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
            Image(systemName: "brain")
                .font(.system(size: 32))
                .foregroundColor(.tertiaryText)
            
            Text("No patterns learned yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.spacingLarge)
        .liquidGlassBackground(
            material: .ultraThinMaterial,
            cornerRadius: DesignSystem.cornerRadiusMedium
        )
    }
}

struct PatternRowView: View {
    let pattern: LearnedPattern
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(pattern.originalPhrase)
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundColor(.tertiaryText)
                        
                        Text(pattern.correctedPhrase)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    
                    HStack(spacing: 12) {
                        Label("\(pattern.occurrenceCount)x", systemImage: "number")
                            .font(.caption)
                            .foregroundColor(.tertiaryText)
                        
                        Label("\(Int(pattern.confidence * 100))%", systemImage: "chart.bar.fill")
                            .font(.caption)
                            .foregroundColor(pattern.confidence > 0.8 ? .green : .orange)
                        
                        if let mode = pattern.refinementMode {
                            Label(mode.rawValue, systemImage: "text.bubble")
                                .font(.caption)
                                .foregroundColor(.tertiaryText)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.tertiaryText)
                    .opacity(isHovered ? 1 : 0.5)
            }
            .padding(DesignSystem.spacingMedium)
            .background(isHovered ? Color.white.opacity(0.05) : Color.clear)
            .cornerRadius(DesignSystem.cornerRadiusSmall)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct PreferenceInsight: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingSmall) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondaryText)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pattern Detail View

struct PatternDetailView: View {
    let pattern: LearnedPattern
    let onDismiss: () -> Void
    @State private var showDeleteConfirmation = false
    @ObservedObject private var learningService = LearningService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.spacingLarge) {
                // Pattern Info
                VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                    Text("Pattern Details")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primaryText)
                    
                    HStack(alignment: .top, spacing: DesignSystem.spacingLarge) {
                        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                            Label("Original", systemImage: "text.alignleft")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                            Text(pattern.originalPhrase)
                                .font(.system(size: 16))
                                .foregroundColor(.primaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                            Label("Corrected", systemImage: "text.badge.checkmark")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                            Text(pattern.correctedPhrase)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.accentColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(DesignSystem.spacingMedium)
                    .liquidGlassBackground(
                        material: .ultraThinMaterial,
                        cornerRadius: DesignSystem.cornerRadiusMedium
                    )
                }
                
                // Statistics
                HStack(spacing: DesignSystem.spacingMedium) {
                    StatCard(
                        label: "Occurrences",
                        value: "\(pattern.occurrenceCount)",
                        icon: "number.circle"
                    )
                    
                    StatCard(
                        label: "Confidence",
                        value: "\(Int(pattern.confidence * 100))%",
                        icon: "chart.bar.fill"
                    )
                    
                    if let mode = pattern.refinementMode {
                        StatCard(
                            label: "Mode",
                            value: mode.rawValue,
                            icon: "text.bubble"
                        )
                    }
                }
                
                // Effectiveness Score
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    Text("Effectiveness Score")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    HStack {
                        ProgressView(value: pattern.confidence)
                            .tint(pattern.confidence > 0.8 ? .green : .orange)
                        
                        Text("\(Int(pattern.confidence * 100))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(pattern.confidence > 0.8 ? .green : .orange)
                    }
                    
                    Text("Based on \(pattern.occurrenceCount) occurrences and user acceptance rate")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                .padding(DesignSystem.spacingMedium)
                .liquidGlassBackground(
                    material: .ultraThinMaterial,
                    cornerRadius: DesignSystem.cornerRadiusMedium
                )
                
                Spacer()
                
                // Actions
                HStack(spacing: DesignSystem.spacingMedium) {
                    Button("Delete Pattern") {
                        showDeleteConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(DesignSystem.spacingLarge)
            .frame(width: 600, height: 500)
        }
        .alert("Delete Pattern", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await learningService.deletePattern(pattern)
                    dismiss()
                    onDismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this pattern? This action cannot be undone.")
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingSmall) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primaryText)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.spacingMedium)
        .liquidGlassBackground(
            material: .ultraThinMaterial,
            cornerRadius: DesignSystem.cornerRadiusMedium
        )
    }
}