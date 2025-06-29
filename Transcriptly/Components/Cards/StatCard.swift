//
//  StatCard.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 UI Overhaul - Stat Card Component
//

import SwiftUI

/// A statistics card with Liquid Glass styling
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let secondaryValue: String
    
    @State private var isHovered = false
    @State private var displayValue: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            // Header with icon and title
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondaryText)
            }
            
            // Main value and subtitle
            VStack(alignment: .leading, spacing: DesignSystem.spacingTiny) {
                Text(value)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryText)
                    .contentTransition(.numericText())
                
                Text(subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondaryText)
                
                Text(secondaryValue)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.tertiaryText)
                    .padding(.top, DesignSystem.spacingTiny)
            }
        }
        .padding(DesignSystem.spacingLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .enhancedCard()
        .hoverScale(isHovered: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        StatCard(
            icon: "chart.bar.fill",
            title: "Today",
            value: "1,234",
            subtitle: "words",
            secondaryValue: "12 sessions"
        )
        
        StatCard(
            icon: "chart.line.uptrend.xyaxis",
            title: "This Week",
            value: "8,456",
            subtitle: "words", 
            secondaryValue: "45 min saved"
        )
        
        StatCard(
            icon: "target",
            title: "Efficiency",
            value: "87%",
            subtitle: "refined",
            secondaryValue: "23 patterns"
        )
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