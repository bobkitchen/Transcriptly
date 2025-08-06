//
//  EditReviewWindow.swift
//  Transcriptly
//
//  Created by Claude Code on 6/27/25.
//

import SwiftUI
import Combine

struct EditReviewWindow: View {
    @ObservedObject var learningService = LearningService.shared
    
    // Data for this review session
    let originalTranscription: String
    let aiRefinement: String
    let refinementMode: RefinementMode
    
    @State private var userEditedText: String = ""
    @State private var timeRemaining: TimeInterval = 120 // 2 minutes
    @State private var showDiff = false
    
    // Completion handler
    let onComplete: (String, Bool) -> Void // (finalText, wasSkipped)
    
    init(
        originalTranscription: String,
        aiRefinement: String,
        refinementMode: RefinementMode,
        onComplete: @escaping (String, Bool) -> Void
    ) {
        self.originalTranscription = originalTranscription
        self.aiRefinement = aiRefinement
        self.refinementMode = refinementMode
        self.onComplete = onComplete
        _userEditedText = State(initialValue: aiRefinement)
        
        print("EditReviewWindow initialized with:")
        print("  Original: '\(originalTranscription)'")
        print("  AI Refinement: '\(aiRefinement)'")
        print("  Mode: \(refinementMode.rawValue)")
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // Header
            VStack(spacing: DesignSystem.spacingSmall) {
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    Text("Review & Improve")
                        .font(DesignSystem.Typography.titleLarge)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Timer
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Text(timeString(from: timeRemaining))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
                
                Text("Help Transcriptly learn your preferences by editing the text below")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Mode indicator
            HStack {
                Image(systemName: refinementMode.icon)
                    .foregroundColor(.blue)
                Text("Refinement Mode: \(refinementMode.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                
                Button(showDiff ? "Hide Changes" : "Show Changes") {
                    showDiff.toggle()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Diff view (optional)
            if showDiff {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Changes Made by AI:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    DiffView(
                        original: originalTranscription,
                        modified: aiRefinement
                    )
                    .padding(.bottom, 8)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Text editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Edit the refined text (your changes will help improve future transcriptions):")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $userEditedText)
                    .font(.body)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Character count
            HStack {
                Spacer()
                Text("\(userEditedText.count) characters")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Skip Learning") {
                    onComplete(aiRefinement, true) // Use AI version, skip learning
                }
                .buttonStyle(.bordered)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Use Original AI") {
                    onComplete(aiRefinement, false) // Use AI version, but learn from no changes
                }
                .buttonStyle(.bordered)
                
                Button("Submit & Learn") {
                    onComplete(userEditedText, false) // Use edited version and learn
                }
                .buttonStyle(.borderedProminent)
                .disabled(userEditedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(DesignSystem.spacingXLarge)
        .frame(width: 600, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(DesignSystem.cornerRadiusLarge)
        .shadow(radius: DesignSystem.shadowElevated.radius)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Auto-submit when timer expires
                onComplete(userEditedText.isEmpty ? aiRefinement : userEditedText, false)
            }
        }
    }
    
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct DiffView: View {
    let original: String
    let modified: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Simple word-by-word diff visualization
            let changes = findWordChanges(from: original, to: modified)
            
            if changes.isEmpty {
                Text("No changes made")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(Array(changes.enumerated()), id: \.offset) { index, change in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if !change.removed.isEmpty {
                                HStack(spacing: 4) {
                                    Text("−")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    Text(change.removed)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .strikethrough()
                                }
                            }
                            
                            if !change.added.isEmpty {
                                HStack(spacing: 4) {
                                    Text("+")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    Text(change.added)
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
    }
    
    private func findWordChanges(from original: String, to modified: String) -> [WordChange] {
        let originalWords = original.split(separator: " ").map(String.init)
        let modifiedWords = modified.split(separator: " ").map(String.init)
        
        var changes: [WordChange] = []
        
        // Simple diff - find sequences that were replaced
        // This is a simplified implementation
        let longer = max(originalWords.count, modifiedWords.count)
        
        for i in 0..<longer {
            let originalWord = i < originalWords.count ? originalWords[i] : ""
            let modifiedWord = i < modifiedWords.count ? modifiedWords[i] : ""
            
            if originalWord != modifiedWord {
                changes.append(WordChange(
                    removed: originalWord,
                    added: modifiedWord
                ))
            }
        }
        
        return changes
    }
}

struct WordChange {
    let removed: String
    let added: String
}

#Preview {
    EditReviewWindow(
        originalTranscription: "This is a test transcription with some words that need to be fixed.",
        aiRefinement: "This is a test transcription with some words that need to be corrected.",
        refinementMode: .email
    ) { finalText, wasSkipped in
        print("Final text: \(finalText), Skipped: \(wasSkipped)")
    }
}