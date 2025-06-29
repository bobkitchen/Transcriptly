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
                    
                    // Mode badge with enhanced color
                    HStack(spacing: DesignSystem.spacingTiny) {
                        Image(systemName: transcription.mode.icon)
                            .font(.system(size: 12))
                            .foregroundColor(transcription.mode.accentColor)
                        Text(transcription.mode.displayName)
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
                    
                    if let duration = transcription.durationDisplay {
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
        .enhancedCard()
        .hoverScale(isHovered: isHovered)
        .onHover { hovering in
            withAnimation(UIPolishDesignSystem.Animation.standard) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewTranscription()
        }
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

// Note: TranscriptionRecord is now defined in Models/TranscriptionRecord.swift

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