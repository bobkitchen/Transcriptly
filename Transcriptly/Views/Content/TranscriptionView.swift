//
//  TranscriptionView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct TranscriptionView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showPrompts: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Recording section
            VStack(alignment: .leading, spacing: 8) {
                Text("Recording")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                RecordingView()
                    .environmentObject(viewModel)
            }
            
            Divider()
            
            // Refinement mode section
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Refinement")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                RefinementModeView(viewModel: viewModel)
            }
            
            // Prompts section (collapsible, only visible for non-raw modes)
            if viewModel.refinementService.currentMode != .raw {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPrompts.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: showPrompts ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Edit Prompts")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                Text("Customize AI refinement instructions for each mode")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if showPrompts {
                        RefinementPromptsView(refinementService: viewModel.refinementService)
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    }
                }
                
                Divider()
            }
            
            // Options section
            VStack(alignment: .leading, spacing: 12) {
                Text("Options")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                OptionsView()
            }
            
            Spacer()
        }
        .padding(20)
        .onChange(of: viewModel.refinementService.currentMode) { _, newMode in
            // Collapse prompts when switching to raw mode
            if newMode == .raw {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPrompts = false
                }
            }
        }
    }
}

#Preview {
    TranscriptionView(viewModel: AppViewModel())
        .padding()
}