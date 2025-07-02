//
//  DesignSystem.swift
//  Transcriptly
//
//  Created by Claude Code on 7/2/25.
//  Central design system constants for Liquid Glass UI
//

import Foundation
import SwiftUI

/// Central design system for consistent spacing, typography, colors, and animations
struct DesignSystem {
    // Liquid Glass Materials
    static let primaryMaterial: Material = .regularMaterial
    static let secondaryMaterial: Material = .thinMaterial
    static let overlayMaterial: Material = .ultraThinMaterial
    
    // Spacing System (Liquid Glass compliant)
    static let marginStandard: CGFloat = 20
    static let spacingLarge: CGFloat = 16
    static let spacingMedium: CGFloat = 12
    static let spacingSmall: CGFloat = 8
    static let spacingXSmall: CGFloat = 4
    
    // Corner Radius (Capsule-first approach)
    static let cornerRadiusLarge: CGFloat = 12  // Large controls (capsules)
    static let cornerRadiusMedium: CGFloat = 8  // Medium controls
    static let cornerRadiusSmall: CGFloat = 6   // Small elements
    
    
    // Shadows (Liquid Glass depth)
    static let shadowLight = Shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    static let shadowMedium = Shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    static let shadowHover = Shadow(color: .black.opacity(0.2), radius: 12, y: 6)
    
    // Animation (Spring-based)
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let quickAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let fadeAnimation = Animation.easeInOut(duration: 0.2)
    
    // Additional constants needed by existing code
    static let spacingTiny: CGFloat = 2
    static let cornerRadiusTiny: CGFloat = 2
    static let fastSpringAnimation = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let quickFadeAnimation = Animation.easeInOut(duration: 0.15)
    
    // Typography (keeping what's in use)
    struct Typography {
        static let caption = Font.caption
        static let bodySmall = Font.system(size: 11)
        static let body = Font.system(size: 13)
        static let bodyMedium = Font.system(size: 14)
        static let bodyLarge = Font.system(size: 16)
        static let titleSmall = Font.system(size: 15, weight: .medium)
        static let titleMedium = Font.system(size: 18, weight: .medium)
        static let titleLarge = Font.system(size: 24, weight: .semibold)
        static let floatingButton = Font.system(size: 12, weight: .medium)
        static let modeIndicator = Font.system(size: 10, weight: .medium)
        static let monospacedCaption = Font.system(.caption, design: .monospaced)
    }
    
    // Colors (keeping what's in use)
    struct Colors {
        static let hoverOverlay = Color.white.opacity(0.1)
    }
    
    // Layout (keeping what's in use)
    struct Layout {
        static let buttonMinHeight: CGFloat = 32
        static let topBarHeight: CGFloat = 52
        static let sidebarWidth: CGFloat = 220
        static let sidebarCollapsedWidth: CGFloat = 60
        static let minimumTouchTarget: CGFloat = 44
    }
}

/// Shadow properties for custom shadows
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat = 0
    let y: CGFloat
}

// Liquid Glass View Modifiers
extension View {
    func liquidGlassCard() -> some View {
        self
            .background(DesignSystem.primaryMaterial)
            .cornerRadius(DesignSystem.cornerRadiusMedium)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
    
    func liquidGlassHover() -> some View {
        self.onHover { isHovered in
            // Implement hover state changes
        }
    }
    
    func liquidGlassButton(style: ButtonStyle = .primary) -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(style == .primary ? 
                DesignSystem.primaryMaterial : DesignSystem.secondaryMaterial)
            .cornerRadius(style == .primary ? 
                DesignSystem.cornerRadiusLarge : DesignSystem.cornerRadiusMedium)
    }
}

enum ButtonStyle {
    case primary, secondary
}