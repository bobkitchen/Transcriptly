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
    @Binding var isCollapsed: Bool
    @State private var hoveredSection: SidebarSection?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if !isCollapsed {
                    Text("NAVIGATION")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.tertiaryText)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Spacer()
                }
                
                // Collapse button
                Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { isCollapsed.toggle() } }) {
                    Image(systemName: isCollapsed ? "sidebar.left" : "sidebar.leading")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .help(isCollapsed ? "Expand Sidebar (⌘⌥S)" : "Collapse Sidebar (⌘⌥S)")
            }
            .padding(.horizontal, isCollapsed ? 8 : 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Navigation items
            VStack(spacing: 2) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    FloatingSidebarItem(
                        section: section,
                        isSelected: selectedSection == section,
                        isHovered: hoveredSection == section,
                        isEnabled: section.isEnabled,
                        isCollapsed: isCollapsed
                    )
                    .onTapGesture {
                        if section.isEnabled {
                            selectedSection = section
                        }
                    }
                    .onHover { hovering in
                        hoveredSection = hovering ? section : nil
                    }
                    .help(isCollapsed ? section.title : "")
                }
            }
            .padding(.horizontal, isCollapsed ? 4 : 8)
            .padding(.bottom, 16)
            
            Spacer()
        }
        .frame(width: isCollapsed ? 68 : 220)
        .performantGlass(
            material: .regularMaterial,
            cornerRadius: 12,
            strokeOpacity: 0.15
        )
        .adaptiveShadow(
            isHovered: false,
            baseRadius: 12,
            baseOpacity: 0.15
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isCollapsed)
    }
}

struct FloatingSidebarItem: View {
    let section: SidebarSection
    let isSelected: Bool
    let isHovered: Bool
    let isEnabled: Bool
    let isCollapsed: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.icon)
                .font(.system(size: 16))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            if !isCollapsed {
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
        }
        .padding(.vertical, 6)
        .padding(.horizontal, isCollapsed ? 8 : 12)
        .background(selectionBackground)
        .hoverOverlay(
            isHovered: isHovered && isEnabled,
            cornerRadius: 6,
            intensity: 0.05
        )
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
    FloatingSidebar(selectedSection: .constant(.home), isCollapsed: .constant(false))
        .padding(20)
        .background(Color.primaryBackground)
}