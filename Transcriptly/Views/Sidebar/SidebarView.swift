//
//  SidebarView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//  Updated by Claude Code on 6/28/25 for Phase 4 Liquid Glass UI
//

import SwiftUI

struct SidebarView: View {
    @Binding var selectedSection: SidebarSection
    @State private var isCollapsed = false
    @State private var hoveredSection: SidebarSection?
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingSmall) {
            // Navigation items
            ForEach(SidebarSection.allCases, id: \.self) { section in
                SidebarItem(
                    section: section,
                    isSelected: selectedSection == section,
                    isHovered: hoveredSection == section,
                    isEnabled: section.isEnabled,
                    isCollapsed: isCollapsed
                )
                .onTapGesture {
                    if section.isEnabled {
                        withAnimation(DesignSystem.springAnimation) {
                            selectedSection = section
                        }
                    }
                }
                .onHover { hovering in
                    withAnimation(DesignSystem.fadeAnimation) {
                        hoveredSection = hovering ? section : nil
                    }
                }
            }
            
            Spacer()
        }
        .padding(DesignSystem.spacingMedium)
        .frame(width: isCollapsed ? DesignSystem.Layout.sidebarCollapsedWidth : DesignSystem.Layout.sidebarWidth)
        .liquidGlassSidebar()
        .animation(DesignSystem.springAnimation, value: isCollapsed)
    }
}

struct SidebarItem: View {
    let section: SidebarSection
    let isSelected: Bool
    let isHovered: Bool
    let isEnabled: Bool
    let isCollapsed: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            // Icon
            Image(systemName: section.icon)
                .font(.system(size: 18))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            if !isCollapsed {
                // Label
                Text(section.rawValue)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(textColor)
                
                Spacer()
                
                // "Soon" badge for disabled items
                if !isEnabled {
                    Text("Soon")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.tertiaryText)
                        .padding(.horizontal, DesignSystem.spacingSmall)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .opacity(isHovered ? 1.0 : 0.7)
                }
            }
        }
        .padding(.vertical, DesignSystem.spacingSmall)
        .padding(.horizontal, DesignSystem.spacingMedium)
        .frame(minHeight: DesignSystem.Layout.minimumTouchTarget)
        .background(backgroundView)
        .cornerRadius(DesignSystem.cornerRadiusSmall)
        .contentShape(Rectangle())
        .animation(DesignSystem.springAnimation, value: isSelected)
        .animation(DesignSystem.fadeAnimation, value: isHovered)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusSmall)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.2),
                            Color.accentColor.opacity(0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusSmall)
                        .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
        } else if isHovered && isEnabled {
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusSmall)
                .fill(Color.white.opacity(0.05))
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
    SidebarView(selectedSection: .constant(.home))
        .frame(height: 500)
}