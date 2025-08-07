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
                    Text(transcription.text.prefix(50) + (transcription.text.count > 50 ? "..." : ""))
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Mode badge
                    HStack(spacing: DesignSystem.spacingTiny) {
                        Image(systemName: transcription.mode.icon)
                            .font(.system(size: 12))
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
                    Text(transcription.timestamp)
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
                        
                        Text("\(Int(duration))s")
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
        NSPasteboard.general.setString(transcription.text, forType: .string)
    }
    
    private func viewTranscription() {
        // TODO: Implement view transcription action
        print("View transcription: \(transcription.text.prefix(50))")
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