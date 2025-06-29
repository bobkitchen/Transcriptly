//
//  TranscriptionView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//  Updated by Claude Code on 6/28/25 for Phase 4 Liquid Glass UI
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct TranscriptionView: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject private var historyService = TranscriptionHistoryService.shared
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
                                print("DEBUG: Edit button clicked for mode: \(mode)")
                                editingMode = mode
                                showEditPrompt = true
                                print("DEBUG: editingMode set to: \(String(describing: editingMode))")
                                print("DEBUG: showEditPrompt set to: \(showEditPrompt)")
                            },
                            onAppsConfig: mode != .raw ? {
                                openApplicationPicker(for: mode)
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
                } else if !viewModel.isRecording && !viewModel.isTranscribing && !viewModel.refinementService.isProcessing {
                    // Permission denied state or ready state
                    if !viewModel.canRecord && viewModel.statusText.contains("Microphone access required") {
                        VStack(spacing: DesignSystem.spacingMedium) {
                            Text("Microphone Access Required")
                                .font(DesignSystem.Typography.titleMedium)
                                .foregroundColor(.orange)
                            
                            VStack(spacing: DesignSystem.spacingLarge) {
                                Image(systemName: "mic.slash.circle")
                                    .font(.system(size: 64))
                                    .foregroundColor(.orange)
                                    .symbolRenderingMode(.hierarchical)
                                
                                VStack(spacing: DesignSystem.spacingMedium) {
                                    Text("Transcriptly needs microphone access to record audio")
                                        .font(DesignSystem.Typography.bodyLarge)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primaryText)
                                        .multilineTextAlignment(.center)
                                    
                                    VStack(spacing: DesignSystem.spacingSmall) {
                                        Text("To enable microphone access:")
                                            .font(DesignSystem.Typography.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondaryText)
                                        
                                        VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                                            Text("1. Open System Settings")
                                            Text("2. Go to Privacy & Security")
                                            Text("3. Select Microphone")
                                            Text("4. Enable access for Transcriptly")
                                        }
                                        .font(DesignSystem.Typography.bodySmall)
                                        .foregroundColor(.tertiaryText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    Button("Open System Settings") {
                                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }
                                    .buttonStyle(PrimaryButtonStyle())
                                    .padding(.top, DesignSystem.spacingMedium)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.spacingLarge * 2)
                            .padding(.horizontal, DesignSystem.spacingLarge)
                            .background(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                                    .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(DesignSystem.cornerRadiusMedium)
                        }
                    } else {
                        // Empty state when no activity and no recent result
                        VStack(spacing: DesignSystem.spacingMedium) {
                            Text("Ready to Transcribe")
                                .font(DesignSystem.Typography.titleMedium)
                                .foregroundColor(.primaryText)
                            
                            VStack(spacing: DesignSystem.spacingLarge) {
                                Image(systemName: "mic.circle")
                                    .font(.system(size: 64))
                                    .foregroundColor(.accentColor)
                                    .symbolRenderingMode(.hierarchical)
                                
                                VStack(spacing: DesignSystem.spacingSmall) {
                                    Text("Press ⌘⇧V to start recording")
                                        .font(DesignSystem.Typography.bodyLarge)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primaryText)
                                    
                                    Text("Your transcription will appear here with AI refinement applied")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(.secondaryText)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.spacingLarge * 2)
                            .padding(.horizontal, DesignSystem.spacingLarge)
                            .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
                        }
                    }
                }
                
                // Error State
                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: DesignSystem.spacingMedium) {
                        Text("Error")
                            .font(DesignSystem.Typography.titleMedium)
                            .foregroundColor(.errorColor)
                        
                        HStack(spacing: DesignSystem.spacingMedium) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                                .symbolRenderingMode(.hierarchical)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                                Text("Something went wrong")
                                    .font(DesignSystem.Typography.bodyLarge)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primaryText)
                                
                                Text(errorMessage)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                            
                            Button("Dismiss") {
                                viewModel.errorMessage = nil
                            }
                            .buttonStyle(CompactButtonStyle())
                        }
                        .padding(DesignSystem.spacingLarge)
                        .background(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(DesignSystem.cornerRadiusMedium)
                    }
                }
            }
            .adjustForInsetSidebar()
            .padding(DesignSystem.marginStandard)
        }
        .background(Color.primaryBackground)
        .sheet(item: Binding<EditingModeWrapper?>(
            get: { showEditPrompt && editingMode != nil ? EditingModeWrapper(mode: editingMode!) : nil },
            set: { _ in showEditPrompt = false; editingMode = nil }
        )) { wrapper in
            EditPromptSheet(
                mode: wrapper.mode,
                viewModel: viewModel
            )
            .onAppear {
                print("DEBUG: EditPromptSheet appeared for mode: \(wrapper.mode)")
            }
        }
    }
    
    // MARK: - App Assignment
    
    private func openApplicationPicker(for mode: RefinementMode) {
        let panel = NSOpenPanel()
        panel.title = "Select Application for \(mode.displayName)"
        panel.message = "Choose an application to automatically switch to \(mode.displayName) mode when using it."
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        // Start in Applications folder
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                // Create AppInfo from selected app
                if let bundle = Bundle(url: url) {
                    let appInfo = AppInfo(
                        bundleIdentifier: bundle.bundleIdentifier ?? url.lastPathComponent,
                        localizedName: bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? 
                                     bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? 
                                     url.deletingPathExtension().lastPathComponent,
                        executablePath: url.path
                    )
                    
                    DispatchQueue.main.async {
                        Task {
                            await assignApp(appInfo, to: mode)
                        }
                    }
                } else {
                    // Fallback for apps without bundles
                    let appInfo = AppInfo(
                        bundleIdentifier: url.lastPathComponent,
                        localizedName: url.deletingPathExtension().lastPathComponent,
                        executablePath: url.path
                    )
                    
                    DispatchQueue.main.async {
                        Task {
                            await assignApp(appInfo, to: mode)
                        }
                    }
                }
            }
        }
    }
    
    private func assignApp(_ app: AppInfo, to mode: RefinementMode) async {
        let assignmentManager = AppAssignmentManager.shared
        
        let assignment = AppAssignment(
            appInfo: app,
            mode: mode,
            isUserOverride: true
        )
        
        do {
            try await assignmentManager.saveAssignment(assignment)
            print("Successfully assigned \(app.displayName) to \(mode.displayName) mode")
        } catch {
            print("Failed to assign app: \(error)")
        }
    }
    
    // MARK: - Computed Properties
    
    private var modeStatistics: [RefinementMode: ModeStatistics] {
        _ = historyService.statistics
        var result: [RefinementMode: ModeStatistics] = [:]
        
        for mode in RefinementMode.allCases {
            let modeTranscriptions = historyService.getTranscriptions(mode: mode)
            let usageCount = modeTranscriptions.count
            let lastUsed = modeTranscriptions.first?.timestamp
            
            let lastEditedDisplay: String? = {
                guard let lastUsed = lastUsed else { return nil }
                let timeInterval = Date().timeIntervalSince(lastUsed)
                
                if timeInterval < 86400 { // Less than a day
                    return "today"
                } else if timeInterval < 604800 { // Less than a week
                    let days = Int(timeInterval / 86400)
                    return "\(days) day\(days == 1 ? "" : "s") ago"
                } else {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    return formatter.string(from: lastUsed)
                }
            }()
            
            // For now, use empty assigned apps (future feature)
            let assignedApps: [PreviewAppInfo] = []
            
            result[mode] = ModeStatistics(
                usageCount: usageCount,
                lastEditedDisplay: lastEditedDisplay,
                assignedApps: assignedApps
            )
        }
        
        return result
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
        let initialPrompt = viewModel.refinementService.prompts[mode]?.userPrompt ?? ""
        print("DEBUG EditPromptSheet init: mode=\(mode), initialPrompt='\(initialPrompt)'")
        print("DEBUG EditPromptSheet init: Available prompts keys: \(viewModel.refinementService.prompts.keys)")
        self._prompt = State(initialValue: initialPrompt)
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

// MARK: - Helper Types

struct EditingModeWrapper: Identifiable {
    let id = UUID()
    let mode: RefinementMode
}

#Preview {
    TranscriptionView(viewModel: AppViewModel())
        .padding()
}