//
//  TranscriptionCard.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 UI Overhaul - Transcription History Card Component
//

import SwiftUI

/// Card displaying a transcription record with metadata and actions
struct TranscriptionCard: View {
    let transcription: TranscriptionRecord
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                // Title and metadata
                HStack {
                    Text(transcription.title)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Mode badge
                    HStack(spacing: DesignSystem.spacingTiny) {
                        Image(systemName: transcription.mode.icon)
                            .font(.system(size: 12))
                        Text(transcription.mode.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.secondaryText)
                    .padding(.horizontal, DesignSystem.spacingSmall)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                }
                
                // Metadata row
                HStack(spacing: DesignSystem.spacingSmall) {
                    Text(transcription.timeAgo)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.secondaryText)
                    
                    Text("•")
                        .foregroundColor(.tertiaryText)
                    
                    Text("\(transcription.wordCount) words")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.secondaryText)
                    
                    if let duration = transcription.duration {
                        Text("•")
                            .foregroundColor(.tertiaryText)
                        
                        Text(duration)
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                }
                
                // Preview text (if available)
                if let preview = transcription.preview {
                    Text(preview)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.tertiaryText)
                        .lineLimit(2)
                        .padding(.top, DesignSystem.spacingTiny)
                }
            }
            
            // Action buttons (shown on hover)
            if isHovered {
                HStack(spacing: DesignSystem.spacingSmall) {
                    Button(action: {
                        // Copy to clipboard
                        copyToClipboard()
                    }) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondaryText)
                    .help("Copy to clipboard")
                    
                    Button(action: {
                        // View full transcription
                        viewTranscription()
                    }) {
                        Text("View")
                            .font(DesignSystem.Typography.bodySmall)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(DesignSystem.spacingMedium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                .fill(backgroundMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                        .strokeBorder(strokeColor, lineWidth: 0.5)
                )
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .shadow(
            color: .black.opacity(isHovered ? 0.12 : 0.08),
            radius: isHovered ? 10 : 6,
            y: isHovered ? 4 : 2
        )
        .animation(DesignSystem.springAnimation, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewTranscription()
        }
    }
    
    private var backgroundMaterial: Material {
        isHovered ? .regularMaterial : .ultraThinMaterial
    }
    
    private var strokeColor: Color {
        isHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.08)
    }
    
    private func copyToClipboard() {
        // TODO: Implement clipboard copying
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcription.content, forType: .string)
    }
    
    private func viewTranscription() {
        // TODO: Implement view transcription action
        print("View transcription: \(transcription.title)")
    }
}

// MARK: - Supporting Types

struct TranscriptionRecord: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let timeAgo: String
    let wordCount: Int
    let mode: RefinementMode
    let duration: String?
    let preview: String?
    
    static let sampleData: [TranscriptionRecord] = [
        TranscriptionRecord(
            title: "Email to Sarah",
            content: "Hi Sarah, I wanted to follow up on our meeting yesterday about the quarterly review...",
            timeAgo: "10:32 AM",
            wordCount: 234,
            mode: .email,
            duration: "1:23",
            preview: "Hi Sarah, I wanted to follow up on our meeting yesterday about the quarterly review..."
        ),
        TranscriptionRecord(
            title: "Meeting notes",
            content: "Today's standup covered the following items: sprint progress, upcoming deadlines...",
            timeAgo: "9:45 AM",
            wordCount: 567,
            mode: .cleanup,
            duration: "3:45",
            preview: "Today's standup covered the following items: sprint progress, upcoming deadlines..."
        ),
        TranscriptionRecord(
            title: "Project update",
            content: "The new feature is progressing well. We've completed the initial implementation...",
            timeAgo: "Yesterday",
            wordCount: 1023,
            mode: .cleanup,
            duration: "5:12",
            preview: "The new feature is progressing well. We've completed the initial implementation..."
        ),
        TranscriptionRecord(
            title: "Quick voice memo",
            content: "Remember to pick up groceries on the way home. Need milk, bread, and eggs.",
            timeAgo: "2 days ago",
            wordCount: 89,
            mode: .messaging,
            duration: "0:45",
            preview: "Remember to pick up groceries on the way home. Need milk, bread, and eggs."
        )
    ]
}

#Preview {
    VStack(spacing: 12) {
        ForEach(TranscriptionRecord.sampleData.prefix(3)) { transcription in
            TranscriptionCard(transcription: transcription)
        }
    }
    .padding(40)
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}