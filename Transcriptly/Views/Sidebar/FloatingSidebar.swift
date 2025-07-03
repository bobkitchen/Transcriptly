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
            sidebarHeader
            
            // Navigation items
            VStack(spacing: 2) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    sidebarItem(for: section)
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    @ViewBuilder
    private var sidebarHeader: some View {
        HStack(spacing: 8) {
            if !isCollapsed {
                Text("NAVIGATION")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.tertiaryText)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
            }
            
            Button(action: toggleSidebar) {
                Image(systemName: isCollapsed ? "sidebar.left" : "sidebar.leading")
                    .font(.system(size: 12))
                    .foregroundColor(.tertiaryText)
                    .frame(width: 20, height: 20)
                    .frame(maxWidth: isCollapsed ? .infinity : nil)
            }
            .buttonStyle(.plain)
            .help(isCollapsed ? "Expand Sidebar (⌘⌥S)" : "Collapse Sidebar (⌘⌥S)")
        }
        .padding(.horizontal, isCollapsed ? 8 : 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    @ViewBuilder
    private func sidebarItem(for section: SidebarSection) -> some View {
        Button(action: {
            if section.isEnabled {
                selectedSection = section
            }
        }) {
            HStack(spacing: isCollapsed ? 0 : 12) {
                Image(systemName: section.icon)
                    .font(.system(size: 16))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(itemIconColor(for: section))
                    .frame(width: 20)
                    .frame(maxWidth: isCollapsed ? .infinity : nil)
                
                if !isCollapsed {
                    Text(section.title)
                        .font(.system(size: 14, weight: selectedSection == section ? .medium : .regular))
                        .foregroundColor(itemTextColor(for: section))
                    
                    Spacer()
                    
                    if !section.isEnabled {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, isCollapsed ? 8 : 6)
            .padding(.horizontal, 12)
            .background(itemBackground(for: section))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!section.isEnabled)
        .onHover { hovering in
            hoveredSection = hovering ? section : nil
        }
        .hoverOverlay(
            isHovered: hoveredSection == section && section.isEnabled,
            cornerRadius: 6,
            intensity: 0.05
        )
        .cornerRadius(6)
        .help(isCollapsed ? section.title : "")
    }
    
    @ViewBuilder
    private func itemBackground(for section: SidebarSection) -> some View {
        if selectedSection == section {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.15))
        } else if hoveredSection == section && section.isEnabled {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
        } else {
            Color.clear
        }
    }
    
    private func itemIconColor(for section: SidebarSection) -> Color {
        if !section.isEnabled { return .tertiaryText }
        return selectedSection == section ? .accentColor : .secondaryText
    }
    
    private func itemTextColor(for section: SidebarSection) -> Color {
        if !section.isEnabled { return .tertiaryText }
        return selectedSection == section ? .primaryText : .secondaryText
    }
    
    private func toggleSidebar() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isCollapsed.toggle()
        }
    }
}

#Preview {
    HStack {
        FloatingSidebar(selectedSection: .constant(.home), isCollapsed: .constant(false))
        Spacer()
    }
    .frame(width: 800, height: 600)
    .background(Color.primaryBackground)
}