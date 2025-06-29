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
                        .font(.system(size: 15, weight: .medium))
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
                HStack(spacing: 12) {
                    Text(transcription.timeAgo)
                        .font(.system(size: 13))
                        .foregroundColor(.secondaryText)
                    
                    Text("•")
                        .foregroundColor(.quaternaryText)
                    
                    Text("\(transcription.wordCount) words")
                        .font(.system(size: 13))
                        .foregroundColor(.secondaryText)
                    
                    if let duration = transcription.durationDisplay {
                        Text("•")
                            .foregroundColor(.quaternaryText)
                        
                        Text(duration)
                            .font(.system(size: 13))
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
                HStack(spacing: 8) {
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(transcription.content, forType: .string)
                        // Provide haptic feedback
                        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("View") {
                        viewTranscription()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
        )
        .enhancedCard()
        .hoverScale(isHovered: isHovered)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewTranscription()
        }
    }
    
    
    private func viewTranscription() {
        TranscriptionDetailWindowManager.shared.showDetailWindow(for: transcription)
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