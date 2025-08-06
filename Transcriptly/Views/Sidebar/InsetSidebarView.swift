//
//  InsetSidebarView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 6 UI Polish - Apple 2024 Standard Inset Sidebar
//

import SwiftUI

/// Apple-compliant inset sidebar that floats over full-width content
struct InsetSidebarView: View {
    @Binding var selectedSection: SidebarSection
    @State private var hoveredSection: SidebarSection?
    
    var body: some View {
        VStack(spacing: 2) {
            // Navigation header
            HStack {
                Text("NAVIGATION")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.tertiaryText)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Navigation items
            VStack(spacing: 2) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    InsetSidebarItemView(
                        section: section,
                        isSelected: selectedSection == section,
                        isHovered: hoveredSection == section,
                        isEnabled: section.isEnabled
                    )
                    .onTapGesture {
                        if section.isEnabled {
                            withAnimation(DesignSystem.springAnimation) {
                                selectedSection = section
                            }
                            HapticFeedback.selection()
                        }
                    }
                    .onHover { hovering in
                        withAnimation(DesignSystem.fadeAnimation) {
                            hoveredSection = hovering ? section : nil
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
        }
        .frame(width: DesignSystem.Layout.sidebarWidth)
        .padding(.vertical, 12)
        .background(.regularMaterial)  // Apple sidebar-equivalent material
        .cornerRadius(DesignSystem.cornerRadiusMedium)
        .shadow(
            color: .black.opacity(0.15),
            radius: 12,
            x: 0,
            y: 4
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

/// Native macOS-compliant sidebar item
struct InsetSidebarItemView: View {
    let section: SidebarSection
    let isSelected: Bool
    let isHovered: Bool
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with proper hierarchy
            Image(systemName: section.icon)
                .font(.system(size: 16))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            // Section name
            Text(section.rawValue)
                .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                .foregroundColor(textColor)
            
            Spacer()
            
            // "Soon" badge for disabled items
            if !isEnabled {
                Text("Soon")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.tertiary)
                    )
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(selectionBackground)
        .cornerRadius(6)
        .animation(DesignSystem.springAnimation, value: isSelected)
        .animation(DesignSystem.fadeAnimation, value: isHovered)
    }
    
    @ViewBuilder
    private var selectionBackground: some View {
        if isSelected {
            // Native macOS selection style - exact match to Apple's apps
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.20))
        } else if isHovered && isEnabled {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
        } else {
            Color.clear
        }
    }
    
    private var iconColor: Color {
        if !isEnabled { 
            return .tertiaryText 
        }
        return isSelected ? .accentColor : .secondaryText
    }
    
    private var textColor: Color {
        if !isEnabled { 
            return .tertiaryText 
        }
        return isSelected ? .primaryText : .secondaryText
    }
}

#Preview {
    ZStack {
        // Simulated content behind sidebar
        VStack {
            Rectangle()
                .fill(.blue.opacity(0.1))
                .overlay(
                    Text("Content flows behind sidebar")
                        .font(.title2)
                        .foregroundColor(.secondary)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        // Floating sidebar
        HStack {
            InsetSidebarView(selectedSection: .constant(.home))
                .padding(.leading, 16)
                .padding(.vertical, 16)
            
            Spacer()
        }
    }
    .frame(width: 800, height: 600)
}