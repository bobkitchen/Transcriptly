//
//  TranscriptionView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//  Updated by Claude Code on 6/28/25 for Phase 4 Liquid Glass UI
//

import SwiftUI

struct TranscriptionView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showEditPrompt = false
    @State private var editingMode: RefinementMode?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                // Section Header
                Text("AI Refinement Modes")
                    .font(DesignSystem.Typography.titleLarge)
                    .foregroundColor(.primaryText)
                    .padding(.top, DesignSystem.marginStandard)
                
                // Mode Cards
                VStack(spacing: DesignSystem.spacingMedium) {
                    ForEach(RefinementMode.allCases, id: \.self) { mode in
                        ModeCard(
                            mode: mode,
                            selectedMode: $viewModel.refinementService.currentMode,
                            stats: modeStatistics[mode],
                            onEdit: {
                                editingMode = mode
                                showEditPrompt = true
                            },
                            onAppsConfig: mode != .raw ? {
                                // TODO: Future Phase 5 - App assignment
                                print("Configure apps for \(mode.rawValue)")
                            } : nil
                        )
                    }
                }
                
                // Current Status Section
                if viewModel.isRecording || viewModel.isTranscribing || viewModel.refinementService.isProcessing {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        Text("Current Activity")
                            .font(DesignSystem.Typography.titleMedium)
                            .foregroundColor(.primaryText)
                        
                        StatusCard(viewModel: viewModel)
                    }
                }
                
                // Last Transcription Section
                if !viewModel.transcribedText.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        Text("Latest Result")
                            .font(DesignSystem.Typography.titleMedium)
                            .foregroundColor(.primaryText)
                        
                        TranscriptionResultCard(
                            text: viewModel.transcribedText,
                            mode: viewModel.refinementService.currentMode
                        )
                    }
                }
            }
            .padding(DesignSystem.marginStandard)
        }
        .background(Color.primaryBackground)
        .sheet(isPresented: $showEditPrompt) {
            if let mode = editingMode {
                EditPromptSheet(
                    mode: mode,
                    viewModel: viewModel
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var modeStatistics: [RefinementMode: ModeStatistics] {
        // TODO: Get actual statistics from viewModel
        // For now, return sample data
        ModeStatistics.sampleData
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            // Status icon
            Group {
                if viewModel.isRecording {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.red)
                } else if viewModel.isTranscribing {
                    Image(systemName: "waveform")
                        .foregroundColor(.orange)
                } else if viewModel.refinementService.isProcessing {
                    Image(systemName: "cpu")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .font(.system(size: 24))
            .symbolRenderingMode(.hierarchical)
            
            // Status text
            VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                Text(statusTitle)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Text(statusDescription)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            // Progress indicator
            if viewModel.isRecording || viewModel.isTranscribing || viewModel.refinementService.isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(DesignSystem.spacingLarge)
        .elevatedCard()
    }
    
    private var statusTitle: String {
        if viewModel.isRecording {
            return "Recording..."
        } else if viewModel.isTranscribing {
            return "Transcribing..."
        } else if viewModel.refinementService.isProcessing {
            return "Refining..."
        } else {
            return "Ready"
        }
    }
    
    private var statusDescription: String {
        if viewModel.isRecording {
            return "Listening to your voice"
        } else if viewModel.isTranscribing {
            return "Converting speech to text"
        } else if viewModel.refinementService.isProcessing {
            return "Applying AI refinement"
        } else {
            return "Ready to record"
        }
    }
}

struct TranscriptionResultCard: View {
    let text: String
    let mode: RefinementMode
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            // Header
            HStack {
                HStack(spacing: DesignSystem.spacingSmall) {
                    Image(systemName: mode.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                    
                    Text(mode.displayName)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                }
                
                Spacer()
                
                Button(action: {
                    // Copy to clipboard
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondaryText)
                .help("Copy to clipboard")
            }
            
            // Text content
            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.primaryText)
                .lineLimit(isExpanded ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)
            
            // Expand/collapse button (if text is long)
            if text.count > 150 {
                Button(isExpanded ? "Show less" : "Show more") {
                    withAnimation(DesignSystem.springAnimation) {
                        isExpanded.toggle()
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .font(DesignSystem.Typography.bodySmall)
            }
        }
        .padding(DesignSystem.spacingLarge)
        .elevatedCard()
    }
}

struct EditPromptSheet: View {
    let mode: RefinementMode
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var prompt: String
    
    init(mode: RefinementMode, viewModel: AppViewModel) {
        self.mode = mode
        self.viewModel = viewModel
        self._prompt = State(initialValue: viewModel.refinementService.prompts[mode]?.userPrompt ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit \(mode.displayName) Prompt")
                    .font(DesignSystem.Typography.titleMedium)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondaryText)
            }
            .padding(DesignSystem.marginStandard)
            
            Divider()
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                Text("Customize the AI instructions for this mode:")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondaryText)
                
                TextEditor(text: $prompt)
                    .font(DesignSystem.Typography.body)
                    .padding(DesignSystem.spacingMedium)
                    .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
                    .frame(height: 150)
                
                HStack {
                    Text("\(prompt.count)/2000")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(prompt.count > 2000 ? .errorColor : .tertiaryText)
                    
                    Spacer()
                    
                    Button("Reset to Default") {
                        prompt = viewModel.refinementService.prompts[mode]?.defaultPrompt ?? ""
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .font(DesignSystem.Typography.bodySmall)
                }
            }
            .padding(DesignSystem.marginStandard)
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Save") {
                    viewModel.refinementService.updatePrompt(for: mode, prompt: prompt)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(prompt.isEmpty || prompt.count > 2000)
            }
            .padding(DesignSystem.marginStandard)
        }
        .frame(width: 500, height: 450)
        .liquidGlassBackground(material: .regularMaterial, cornerRadius: DesignSystem.cornerRadiusLarge)
    }
}

#Preview {
    TranscriptionView(viewModel: AppViewModel())
        .padding()
}