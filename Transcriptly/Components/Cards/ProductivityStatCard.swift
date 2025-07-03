//
//  ProductivityStatCard.swift
//  Transcriptly
//
//  Created by Claude Code on 1/3/25.
//  Phase 10 - Productivity stat card component
//

import SwiftUI

struct ProductivityStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    @State private var isHovered = false
    @State private var animateValue = false
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.spacingXSmall) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(DesignSystem.slowFade, value: animateValue)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignSystem.spacingLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlassCard(level: .secondary, isHovered: isHovered)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(DesignSystem.gentleSpring, value: isHovered)
        .onHover { hovering in
            withAnimation(DesignSystem.gentleSpring) {
                isHovered = hovering
            }
        }
        .onAppear {
            // Subtle value animation on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateValue = true
            }
        }
    }
}