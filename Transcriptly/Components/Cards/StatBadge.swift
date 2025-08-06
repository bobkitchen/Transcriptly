//
//  StatBadge.swift
//  Transcriptly
//
//  Created by Claude Code on 1/4/25.
//  Phase 10.4 - Small badge for displaying stats
//

import SwiftUI

struct StatBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    init(icon: String, text: String, color: Color = .secondaryText) {
        self.icon = icon
        self.text = text
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingXSmall) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(color)
        }
        .padding(.horizontal, DesignSystem.spacingSmall)
        .padding(.vertical, DesignSystem.spacingTiny)
        .background(color.opacity(0.1))
        .cornerRadius(DesignSystem.cornerRadiusSmall)
    }
}

#Preview {
    HStack {
        StatBadge(icon: "chart.bar", text: "47 uses")
        StatBadge(icon: "clock", text: "2d ago", color: .orange)
        StatBadge(icon: "app", text: "3 apps", color: .blue)
    }
    .padding()
}