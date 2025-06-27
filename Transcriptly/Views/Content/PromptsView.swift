//
//  PromptsView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct PromptsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedMode: RefinementMode = .cleanup
    @State private var editingPrompt: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Custom Prompts")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        // Save the edited prompt
                        viewModel.refinementService.updatePrompt(for: selectedMode, prompt: editingPrompt)
                    } else {
                        // Start editing
                        if let currentPrompt = viewModel.refinementService.prompts[selectedMode] {
                            editingPrompt = currentPrompt.userPrompt
                        }
                    }
                    isEditing.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Mode selection
            Picker("Mode", selection: $selectedMode) {
                ForEach(RefinementMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedMode) { _, newMode in
                // Load prompt for new mode
                if let prompt = viewModel.refinementService.prompts[newMode] {
                    editingPrompt = prompt.userPrompt
                }
                isEditing = false
            }
            
            // Prompt display/editing
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Prompt for \(selectedMode.rawValue)")
                        .font(.headline)
                    
                    Spacer()
                    
                    if !isEditing {
                        Button("Reset to Default") {
                            viewModel.refinementService.resetPrompt(for: selectedMode)
                            if let prompt = viewModel.refinementService.prompts[selectedMode] {
                                editingPrompt = prompt.userPrompt
                            }
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.accentColor)
                    }
                }
                
                if isEditing {
                    TextEditor(text: $editingPrompt)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                        .frame(minHeight: 120)
                } else {
                    ScrollView {
                        Text(viewModel.refinementService.prompts[selectedMode]?.userPrompt ?? "")
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .frame(minHeight: 120)
                }
                
                // Character count
                if isEditing {
                    HStack {
                        Spacer()
                        Text("\(editingPrompt.count)/2000 characters")
                            .font(.caption)
                            .foregroundColor(editingPrompt.count > 2000 ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
        }
        .onAppear {
            // Initialize with current prompt
            if let prompt = viewModel.refinementService.prompts[selectedMode] {
                editingPrompt = prompt.userPrompt
            }
        }
    }
}

#Preview {
    PromptsView()
        .environmentObject(AppViewModel())
        .padding()
}