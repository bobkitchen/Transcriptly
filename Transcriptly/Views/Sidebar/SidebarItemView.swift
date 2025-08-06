//
//  SidebarItemView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct SidebarItemView: View {
    let section: SidebarSection
    let isSelected: Bool
    let isCollapsed: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.icon)
                .frame(width: 20)
                .foregroundColor(section.isEnabled ? 
                    (isSelected ? .accentColor : .primary) : .secondary)
            
            if !isCollapsed {
                Text(section.title)
                    .foregroundColor(section.isEnabled ? .primary : .secondary)
                
                Spacer()
                
                if !section.isEnabled {
                    Text("Soon")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected && section.isEnabled ? 
                    Color.accentColor.opacity(0.15) : Color.clear)
        )
        .opacity(section.isEnabled ? 1.0 : 0.6)
    }
}

#Preview {
    VStack {
        SidebarItemView(section: .home, isSelected: true, isCollapsed: false)
        SidebarItemView(section: .dictation, isSelected: false, isCollapsed: false)
        SidebarItemView(section: .settings, isSelected: false, isCollapsed: false)
    }
    .padding()
}