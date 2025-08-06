//
//  TranscriptionDetailView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Transcription Detail Window - Shows full transcription with metadata
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct TranscriptionDetailView: View {
    let transcription: TranscriptionRecord
    @Environment(\.dismiss) var dismiss
    @State private var selectedTextVersion: TextVersion = .final
    
    enum TextVersion: String, CaseIterable {
        case original = "Original"
        case refined = "AI Refined"  
        case final = "Final"
        
        var description: String {
            switch self {
            case .original: return "Raw speech-to-text output"
            case .refined: return "AI processed with refinement mode"
            case .final: return "Final version (after user edits)"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Metadata section
                    metadataSection
                    
                    Divider()
                    
                    // Text versions section
                    textVersionsSection
                    
                    // Actions section
                    actionsSection
                }
                .padding(24)
            }
        }
        .frame(width: 600, height: 700)
        .background(Color.primaryBackground)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Transcription Details")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text(transcription.mode.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(20)
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Metadata")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), alignment: .leading),
                GridItem(.flexible(), alignment: .leading)
            ], spacing: 12) {
                MetadataItem(label: "Mode", value: transcription.mode.displayName, icon: transcription.mode.icon, color: transcription.mode.accentColor)
                MetadataItem(label: "Created", value: formatFullDate(transcription.date))
                MetadataItem(label: "Word Count", value: "\(transcription.wordCount) words")
                
                if transcription.duration != nil {
                    MetadataItem(label: "Duration", value: formatDuration(transcription.duration ?? 0))
                }
                
                if transcription.learningType != nil {
                    MetadataItem(
                        label: "Learning", 
                        value: transcription.learningType?.displayName ?? "Yes",
                        icon: "brain.head.profile",
                        color: .blue
                    )
                }
                
                MetadataItem(label: "Device", value: transcription.deviceId)
            }
        }
        .padding(16)
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Text Versions Section
    
    private var textVersionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Text Versions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            // Version selector
            Picker("Text Version", selection: $selectedTextVersion) {
                ForEach(TextVersion.allCases, id: \.self) { version in
                    Text(version.rawValue).tag(version)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Description
            Text(selectedTextVersion.description)
                .font(.system(size: 13))
                .foregroundColor(.secondaryText)
                .padding(.top, 4)
            
            // Text content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(currentTextContent)
                        .font(.system(size: 14))
                        .foregroundColor(.primaryText)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
            }
            .frame(height: 200)
            .background(Color.tertiaryBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            HStack(spacing: 12) {
                Button(action: copyCurrentText) {
                    Label("Copy Text", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button(action: copyAllVersions) {
                    Label("Copy All Versions", systemImage: "doc.on.doc")
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Button(action: exportAsText) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentTextContent: String {
        switch selectedTextVersion {
        case .original:
            return transcription.originalText
        case .refined:
            return transcription.refinedText
        case .final:
            return transcription.refinedText
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func copyCurrentText() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentTextContent, forType: .string)
        
        // Show feedback (you could add a toast notification here)
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
    }
    
    private func copyAllVersions() {
        let allVersions = """
        TRANSCRIPTION DETAILS
        ==================
        Created: \(formatFullDate(transcription.date))
        Mode: \(transcription.mode.displayName)
        Word Count: \(transcription.wordCount)
        Duration: \(formatDuration(transcription.duration ?? 0))
        
        ORIGINAL (Raw Speech-to-Text):
        \(transcription.originalText)
        
        AI REFINED (\(transcription.mode.displayName) Mode):
        \(transcription.refinedText)
        
        FINAL (User Version):
        \(transcription.refinedText)
        """
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(allVersions, forType: .string)
        
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
    }
    
    private func exportAsText() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Transcription"
        savePanel.message = "Choose where to save the transcription file"
        savePanel.nameFieldStringValue = "transcription-\(transcription.date.timeIntervalSince1970).txt"
        savePanel.allowedContentTypes = [.plainText]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let content = """
                    TRANSCRIPTION EXPORT
                    ===================
                    Title: \(transcription.mode.rawValue)
                    Created: \(formatFullDate(transcription.date))
                    Mode: \(transcription.mode.displayName)
                    Word Count: \(transcription.wordCount)
                    Duration: \(formatDuration(transcription.duration ?? 0))
                    
                    FINAL TEXT:
                    \(transcription.refinedText)
                    
                    AI REFINED TEXT:
                    \(transcription.refinedText)
                    
                    ORIGINAL TEXT:
                    \(transcription.originalText)
                    """
                    
                    try content.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Export failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MetadataItem: View {
    let label: String
    let value: String
    let icon: String?
    let color: Color?
    
    init(label: String, value: String, icon: String? = nil, color: Color? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondaryText)
                .textCase(.uppercase)
            
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color ?? .accentColor)
                }
                
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryText)
            }
        }
    }
}


#Preview {
    TranscriptionDetailView(transcription: TranscriptionRecord.sampleData[0])
}