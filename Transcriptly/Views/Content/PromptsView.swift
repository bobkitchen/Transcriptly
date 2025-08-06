//
//  PromptsView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct PromptsView: View {
    @ObservedObject var viewModel: AppViewModel
    let onFloat: () -> Void
    @State private var selectedMode: RefinementMode = .cleanup
    @State private var editingPrompt: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Integrated header
            ContentHeader(
                viewModel: viewModel,
                title: "Custom Prompts",
                showModeControls: false,
                showFloatButton: true,
                onFloat: onFloat
            )
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                    
                    // Edit Controls
                    HStack {
                        Spacer()
                        
                        Button(isEditing ? "Done" : "Edit") {
                            if isEditing {
                                // Save the edited prompt
                                viewModel.updateRefinementPrompt(for: selectedMode, prompt: editingPrompt)
                            } else {
                                // Start editing
                                if let currentPrompt = viewModel.refinementPrompts[selectedMode] {
                                    editingPrompt = currentPrompt.userPrompt
                                }
                            }
                            isEditing.toggle()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
            
                    // Mode selection
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        Text("Select Mode")
                            .font(DesignSystem.Typography.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryText)
                        
                        Picker("Mode", selection: $selectedMode) {
                            ForEach(RefinementMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedMode) { _, newMode in
                            // Load prompt for new mode
                            if let prompt = viewModel.refinementPrompts[newMode] {
                                editingPrompt = prompt.userPrompt ?? ""
                            }
                            isEditing = false
                        }
                    }
                    .padding(DesignSystem.spacingLarge)
                    .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
                    
                    // Prompt display/editing
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        HStack {
                            Text("Prompt for \(selectedMode.displayName)")
                                .font(DesignSystem.Typography.bodyLarge)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            if !isEditing {
                                Button("Reset to Default") {
                                    viewModel.resetRefinementPrompt(for: selectedMode)
                                    if let prompt = viewModel.refinementPrompts[selectedMode] {
                                        editingPrompt = prompt.userPrompt ?? ""
                                    }
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                        }
                        
                        if isEditing {
                            TextEditor(text: $editingPrompt)
                                .font(.system(.body, design: .monospaced))
                                .padding(DesignSystem.spacingMedium)
                                .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusSmall)
                                .frame(minHeight: 120)
                        } else {
                            ScrollView {
                                Text(viewModel.refinementPrompts[selectedMode]?.userPrompt ?? "")
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(DesignSystem.spacingMedium)
                                    .background(Color.secondaryBackground.opacity(0.3))
                                    .cornerRadius(DesignSystem.cornerRadiusSmall)
                            }
                            .frame(minHeight: 120)
                        }
                        
                        // Character count
                        if isEditing {
                            HStack {
                                Spacer()
                                Text("\(editingPrompt.count)/2000 characters")
                                    .font(DesignSystem.Typography.bodySmall)
                                    .foregroundColor(editingPrompt.count > 2000 ? .red : .tertiaryText)
                            }
                        }
                    }
                    .padding(DesignSystem.spacingLarge)
                    .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.primaryBackground)
        .onAppear {
            // Initialize with current prompt
            if let prompt = viewModel.refinementPrompts[selectedMode] {
                editingPrompt = prompt.userPrompt ?? "" ?? ""
            }
        }
    }
}

#Preview {
    PromptsView(viewModel: AppViewModel(), onFloat: {})
        .padding()
}