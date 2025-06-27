//
//  ABTestingWindow.swift
//  Transcriptly
//
//  Created by Claude Code on 6/27/25.
//

import SwiftUI

struct ABTestingWindow: View {
    @ObservedObject var learningService = LearningService.shared
    
    // Data for this A/B test
    let originalTranscription: String
    let optionA: String
    let optionB: String
    let refinementMode: RefinementMode
    
    @State private var selectedOption: String?
    @State private var showOriginal = false
    
    // Completion handler
    let onComplete: (String) -> Void // Selected option
    
    init(
        originalTranscription: String,
        optionA: String,
        optionB: String,
        refinementMode: RefinementMode,
        onComplete: @escaping (String) -> Void
    ) {
        self.originalTranscription = originalTranscription
        self.optionA = optionA
        self.optionB = optionB
        self.refinementMode = refinementMode
        self.onComplete = onComplete
        
        print("ABTestingWindow initialized with:")
        print("  Original: '\(originalTranscription)'")
        print("  Option A: '\(optionA)'")
        print("  Option B: '\(optionB)'")
        print("  Mode: \(refinementMode.rawValue)")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.white)
                        .font(.title2)
                    
                    Text("Choose Your Preference")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Text("Help Transcriptly learn your style by choosing which version you prefer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Mode indicator and original toggle
            HStack {
                HStack {
                    Image(systemName: refinementMode.icon)
                        .foregroundColor(.purple)
                    Text("Mode: \(refinementMode.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(showOriginal ? "Hide Original" : "Show Original") {
                    showOriginal.toggle()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.purple)
            }
            
            // Original transcription (optional)
            if showOriginal {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Original Transcription:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(originalTranscription)
                        .font(.body)
                        .padding(12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // A/B Options
            VStack(spacing: 16) {
                Text("Which version do you prefer?")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Option A
                OptionCard(
                    title: "Option A",
                    text: optionA,
                    isSelected: selectedOption == optionA,
                    color: .blue
                ) {
                    selectedOption = optionA
                }
                
                // Option B
                OptionCard(
                    title: "Option B",
                    text: optionB,
                    isSelected: selectedOption == optionB,
                    color: .green
                ) {
                    selectedOption = optionB
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Skip This Test") {
                    // Use option A as default and skip learning
                    onComplete(optionA)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Use This Choice") {
                    if let selected = selectedOption {
                        onComplete(selected)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedOption == nil)
            }
        }
        .padding(24)
        .frame(width: 550, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 20)
    }
}

struct OptionCard: View {
    let title: String
    let text: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? color : .secondary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(color)
                            .font(.system(size: 16))
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                }
                
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? color : Color.secondary.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ABTestingWindow(
        originalTranscription: "hey there how are you doing today",
        optionA: "Hey there, how are you doing today?",
        optionB: "Hello there! How are you doing today?",
        refinementMode: .email
    ) { selectedOption in
        print("Selected: \(selectedOption)")
    }
}