//
//  RefinementPromptsView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct RefinementPromptsView: View {
    @ObservedObject var refinementService: RefinementService
    @State private var expandedModes: Set<RefinementMode> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach([RefinementMode.cleanup, .email, .messaging], id: \.self) { mode in
                CollapsiblePromptEditorView(
                    mode: mode,
                    prompt: Binding(
                        get: { refinementService.prompts[mode]?.userPrompt ?? "" },
                        set: { refinementService.updatePrompt(for: mode, prompt: $0) }
                    ),
                    isExpanded: Binding(
                        get: { expandedModes.contains(mode) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedModes.insert(mode)
                            } else {
                                expandedModes.remove(mode)
                            }
                        }
                    ),
                    onReset: {
                        refinementService.resetPrompt(for: mode)
                    }
                )
            }
        }
        .padding()
    }
}

struct CollapsiblePromptEditorView: View {
    let mode: RefinementMode
    @Binding var prompt: String
    @Binding var isExpanded: Bool
    let onReset: () -> Void
    @State private var characterCount: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header - always visible
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(mode.rawValue, systemImage: mode.icon)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !isExpanded {
                        Text("Tap to edit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer()
                        Button("Reset", action: onReset)
                            .buttonStyle(.link)
                            .font(.caption)
                    }
                    
                    TextEditor(text: $prompt)
                        .font(.system(.body))
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                        .scrollContentBackground(.hidden)
                        .onChange(of: prompt) { _, newValue in
                            characterCount = newValue.count
                        }
                    
                    HStack {
                        Text("\(characterCount)/500")
                            .font(.caption)
                            .foregroundColor(characterCount > 500 ? .red : .secondary)
                        Spacer()
                        if characterCount > 500 {
                            Text("Too many characters")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                .padding(.leading, 20)
            }
        }
        .onAppear {
            characterCount = prompt.count
        }
    }
}

#Preview {
    RefinementPromptsView(refinementService: RefinementService())
        .padding()
}