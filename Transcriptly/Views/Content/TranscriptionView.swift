//
//  TranscriptionView.swift
//  Transcriptly
//
//  Created by Claude Code on 8/6/25.
//

import SwiftUI

@available(macOS 26.0, *)
struct TranscriptionView: View {
    @ObservedObject var viewModel: AppViewModel
    let onFloat: () -> Void
    
    @State private var showRefinementPrompts = false
    @Environment(\.availableWidth) private var availableWidth
    @Environment(\.sidebarCollapsed) private var sidebarCollapsed
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacing.xl) {
                // Top Bar
                TopBar(
                    currentMode: viewModel.refinementMode,
                    onModeChange: { viewModel.refinementMode = $0 },
                    onCapsuleToggle: onFloat
                )
                
                // Main content
                VStack(spacing: DesignSystem.spacing.lg) {
                    // Recording section
                    recordingSection
                    
                    // Mode cards
                    modeSelection
                    
                    // Transcription result
                    if !viewModel.transcriptionText.isEmpty {
                        transcriptionResult
                    }
                    
                    // Refinement prompts button
                    if viewModel.refinementMode != .raw {
                        refinementPromptsButton
                    }
                }
                .padding(DesignSystem.spacing.lg)
            }
        }
        .sheet(isPresented: $showRefinementPrompts) {
            RefinementPromptsView()
        }
    }
    
    private var recordingSection: some View {
        LiquidGlassContainer {
            VStack(spacing: DesignSystem.spacing.md) {
                RecordButton(
                    isRecording: viewModel.isRecording,
                    isProcessing: viewModel.isTranscribing || viewModel.isRefining,
                    action: {
                        Task {
                            await viewModel.toggleRecording()
                        }
                    }
                )
                
                if viewModel.isRecording {
                    Text("Recording...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if viewModel.isTranscribing {
                    Text("Transcribing...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if viewModel.isRefining {
                    Text("Refining with AI...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .padding(DesignSystem.spacing.xl)
        }
    }
    
    private var modeSelection: some View {
        HStack(spacing: DesignSystem.spacing.md) {
            ForEach(RefinementMode.allCases, id: \.self) { mode in
                ModeCard(
                    mode: mode,
                    isSelected: viewModel.refinementMode == mode,
                    characterCount: mode == .raw ? viewModel.transcriptionText.count : nil,
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.refinementMode = mode
                        }
                    }
                )
            }
        }
    }
    
    private var transcriptionResult: some View {
        TranscriptionCard(
            text: viewModel.transcriptionText,
            mode: viewModel.refinementMode,
            onCopy: {
                viewModel.copyToClipboard()
            }
        )
    }
    
    private var refinementPromptsButton: some View {
        Button(action: {
            showRefinementPrompts = true
        }) {
            HStack {
                Image(systemName: "text.bubble")
                Text("Edit Refinement Prompts")
            }
            .padding(.vertical, DesignSystem.spacing.sm)
            .padding(.horizontal, DesignSystem.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadius.small)
                    .fill(Color.accentColor.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(.accentColor)
    }
}