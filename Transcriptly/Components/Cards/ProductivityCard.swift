//
//  ProductivityCard.swift
//  Transcriptly
//
//  Created by Claude Code on 7/1/25.
//

import SwiftUI

struct ProductivityCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: String
    let color: Color
    let onTap: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
            // Icon section
            VStack(spacing: DesignSystem.spacingSmall) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)
                
                Text(title)
                    .font(DesignSystem.Typography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Action button
            Button(action: onTap) {
                Text(action)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.spacingMedium)
                    .padding(.vertical, DesignSystem.spacingSmall)
                    .background(
                        Capsule()
                            .fill(color)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.spacingLarge)
        .frame(minHeight: 200)
        .background(
            LiquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.02 : 1.0))
        .animation(DesignSystem.springAnimation, value: isHovered)
        .animation(DesignSystem.springAnimation, value: isPressed)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                    onTap()
                }
        )
    }
}

#Preview {
    HStack(spacing: 20) {
        ProductivityCard(
            icon: "mic.fill",
            title: "Record Dictation",
            subtitle: "Voice to text with AI refinement",
            action: "Start Recording",
            color: .blue,
            onTap: {}
        )
        
        ProductivityCard(
            icon: "doc.text.fill",
            title: "Read Documents",
            subtitle: "Text to speech for any document",
            action: "Choose Document",
            color: .green,
            onTap: {}
        )
        
        ProductivityCard(
            icon: "waveform",
            title: "Transcribe Media",
            subtitle: "Convert audio files to text",
            action: "Select Audio",
            color: .purple,
            onTap: {}
        )
    }
    .padding()
    .frame(width: 800, height: 300)
}