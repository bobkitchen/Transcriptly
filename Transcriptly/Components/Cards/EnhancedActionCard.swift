//
//  EnhancedActionCard.swift
//  Transcriptly
//
//  Created by Claude Code on 1/3/25.
//  Phase 10 - Enhanced action cards with gentle animations
//

import SwiftUI

struct EnhancedActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonText: String
    let buttonColor: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                // Enhanced icon with subtle animation
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(buttonColor)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .animation(DesignSystem.subtleSpring, value: isHovered)
                
                VStack(alignment: .leading, spacing: DesignSystem.spacingXSmall) {
                    Text(title)
                        .font(DesignSystem.Typography.cardTitle)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            // Enhanced button
            Button(action: action) {
                Text(buttonText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [buttonColor, buttonColor.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(DesignSystem.cornerRadiusLarge)
                    .shadow(
                        color: buttonColor.opacity(0.3),
                        radius: isHovered ? 8 : 4,
                        y: isHovered ? 4 : 2
                    )
            }
            .buttonStyle(.plain)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(DesignSystem.subtleSpring, value: isHovered)
        }
        .padding(DesignSystem.spacingXLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlassCard(level: .primary, isHovered: isHovered)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(DesignSystem.gentleSpring, value: isHovered)
        .onHover { hovering in
            withAnimation(DesignSystem.gentleSpring) {
                isHovered = hovering
            }
        }
    }
}