//
//  FloatingSidebar.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//  Apple Pattern Implementation - Floating Overlay Sidebar
//

import SwiftUI

struct FloatingSidebar: View {
    @Binding var selectedSection: SidebarSection
    @State private var hoveredSection: SidebarSection?
    @State private var isCollapsed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("NAVIGATION")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.tertiaryText)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                // Optional collapse button
                Button(action: { isCollapsed.toggle() }) {
                    Image(systemName: isCollapsed ? "sidebar.left" : "sidebar.leading")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            if !isCollapsed {
                // Navigation items
                VStack(spacing: 2) {
                    ForEach(SidebarSection.allCases, id: \.self) { section in
                        FloatingSidebarItem(
                            section: section,
                            isSelected: selectedSection == section,
                            isHovered: hoveredSection == section,
                            isEnabled: section.isEnabled
                        )
                        .onTapGesture {
                            if section.isEnabled {
                                selectedSection = section
                            }
                        }
                        .onHover { hovering in
                            hoveredSection = hovering ? section : nil
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 16)
            }
            
            Spacer()
        }
        .frame(width: isCollapsed ? 60 : 220)
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(
            color: .black.opacity(0.15),
            radius: 12,
            x: 0,
            y: 4
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isCollapsed)
    }
}

struct FloatingSidebarItem: View {
    let section: SidebarSection
    let isSelected: Bool
    let isHovered: Bool
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.icon)
                .font(.system(size: 16))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(section.title)
                .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                .foregroundColor(textColor)
            
            Spacer()
            
            if !isEnabled {
                Text("Soon")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.tertiaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.quaternary)
                    )
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(selectionBackground)
        .cornerRadius(6)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var selectionBackground: some View {
        if isSelected {
            // Native macOS selection style
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.15))
        } else if isHovered && isEnabled {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
        } else {
            Color.clear
        }
    }
    
    private var iconColor: Color {
        if !isEnabled { return .tertiaryText }
        return isSelected ? .accentColor : .secondaryText
    }
    
    private var textColor: Color {
        if !isEnabled { return .tertiaryText }
        return isSelected ? .primaryText : .secondaryText
    }
}

#Preview {
    FloatingSidebar(selectedSection: .constant(.home))
        .padding(20)
        .background(Color.primaryBackground)
}