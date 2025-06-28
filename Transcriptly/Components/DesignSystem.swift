//
//  DesignSystem.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 UI Overhaul - Design System Foundation
//

import SwiftUI

/// Centralized design system for Transcriptly's Liquid Glass UI
struct DesignSystem {
    
    // MARK: - Spacing
    static let marginStandard: CGFloat = 20
    static let spacingLarge: CGFloat = 16
    static let spacingMedium: CGFloat = 12
    static let spacingSmall: CGFloat = 8
    static let spacingTiny: CGFloat = 4
    
    // MARK: - Corner Radius
    static let cornerRadiusLarge: CGFloat = 12
    static let cornerRadiusMedium: CGFloat = 8
    static let cornerRadiusSmall: CGFloat = 6
    static let cornerRadiusTiny: CGFloat = 4
    
    // MARK: - Shadows
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }
    
    static let shadowLight = Shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    static let shadowMedium = Shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    static let shadowHeavy = Shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    
    // MARK: - Animations
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let fastSpringAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let fadeAnimation = Animation.easeInOut(duration: 0.2)
    static let quickFadeAnimation = Animation.easeInOut(duration: 0.15)
    
    // MARK: - Typography
    struct Typography {
        static let titleLarge = Font.system(size: 28, weight: .semibold, design: .default)
        static let titleMedium = Font.system(size: 20, weight: .semibold, design: .default)
        static let titleSmall = Font.system(size: 18, weight: .semibold, design: .default)
        
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let body = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        static let captionLarge = Font.system(size: 12, weight: .medium, design: .default)
        static let caption = Font.system(size: 10, weight: .medium, design: .default)
        
        static let monospacedBody = Font.system(size: 14, weight: .regular, design: .monospaced)
        static let monospacedCaption = Font.system(size: 12, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Colors
    struct Colors {
        // Semantic backgrounds
        static let primaryBackground = Color(NSColor.windowBackgroundColor)
        static let secondaryBackground = Color(NSColor.controlBackgroundColor)
        static let tertiaryBackground = Color(NSColor.textBackgroundColor)
        
        // Semantic text
        static let primaryText = Color(NSColor.labelColor)
        static let secondaryText = Color(NSColor.secondaryLabelColor)
        static let tertiaryText = Color(NSColor.tertiaryLabelColor)
        
        // Accent colors
        static let accent = Color.accentColor
        static let accentWithVibrancy = Color.accentColor.opacity(0.8)
        
        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // Special colors for Liquid Glass
        static let glassStroke = Color.white.opacity(0.1)
        static let hoverOverlay = Color.white.opacity(0.05)
        static let selectionOverlay = Color.accentColor.opacity(0.1)
    }
    
    // MARK: - Transitions
    struct Transitions {
        static let scaleIn = AnyTransition.scale.combined(with: .opacity)
        static let slideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)
        static let slideTrailing = AnyTransition.move(edge: .trailing).combined(with: .opacity)
        static let asymmetricScale = AnyTransition.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        )
    }
    
    // MARK: - Layout Constants
    struct Layout {
        static let topBarHeight: CGFloat = 52
        static let sidebarWidth: CGFloat = 200
        static let sidebarCollapsedWidth: CGFloat = 68
        static let cardHeight: CGFloat = 88
        static let buttonMinHeight: CGFloat = 44
        static let minimumTouchTarget: CGFloat = 44
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply standard shadow with optional hover effect
    func standardShadow(isHovered: Bool = false) -> some View {
        let shadow = isHovered ? DesignSystem.shadowMedium : DesignSystem.shadowLight
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// Apply glass stroke border
    func glassStroke(cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(DesignSystem.Colors.glassStroke, lineWidth: 0.5)
        )
    }
    
    /// Apply hover overlay effect
    func hoverOverlay(isHovered: Bool, cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(isHovered ? DesignSystem.Colors.hoverOverlay : Color.clear)
        )
    }
    
    /// Apply selection overlay effect
    func selectionOverlay(isSelected: Bool, cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(isSelected ? DesignSystem.Colors.selectionOverlay : Color.clear)
        )
    }
    
    /// Apply spring animation to value changes
    func springAnimation<V: Equatable>(value: V) -> some View {
        self.animation(DesignSystem.springAnimation, value: value)
    }
    
    /// Apply fade animation to value changes
    func fadeAnimation<V: Equatable>(value: V) -> some View {
        self.animation(DesignSystem.fadeAnimation, value: value)
    }
}