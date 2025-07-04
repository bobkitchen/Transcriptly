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
    // Enhanced Liquid Glass Materials
    static let glassPrimary: Material = .regularMaterial
    static let glassSecondary: Material = .thinMaterial
    static let glassOverlay: Material = .ultraThinMaterial
    static let glassProminent: Material = .thickMaterial
    
    // Legacy material names for compatibility
    static let primaryMaterial: Material = glassPrimary
    static let secondaryMaterial: Material = glassSecondary
    static let overlayMaterial: Material = glassOverlay
    
    // Refined Spacing (more breathing room)
    static let marginLarge: CGFloat = 32       // New for major sections
    static let marginStandard: CGFloat = 24    // Increased from 20
    static let spacingXLarge: CGFloat = 24     // New for major sections
    static let spacingLarge: CGFloat = 20      // Increased from 16
    static let spacingMedium: CGFloat = 16     // Increased from 12
    static let spacingSmall: CGFloat = 12      // Increased from 8
    static let spacingXSmall: CGFloat = 8      // Increased from 4
    
    // Enhanced Corner Radius System
    static let cornerRadiusXLarge: CGFloat = 16  // For hero cards
    static let cornerRadiusLarge: CGFloat = 12   // For main cards
    static let cornerRadiusMedium: CGFloat = 10  // For sections
    static let cornerRadiusSmall: CGFloat = 8    // For buttons
    static let cornerRadiusXSmall: CGFloat = 6   // For badges
    
    // Refined Shadow System
    static let shadowFloating = Shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    static let shadowElevated = Shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    static let shadowSubtle = Shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    static let shadowHover = Shadow(color: .black.opacity(0.15), radius: 20, y: 10)
    
    // Legacy shadow names for compatibility
    static let shadowLight = shadowSubtle
    static let shadowMedium = shadowElevated
    
    // Gentle Animation System (to avoid glitches)
    static let gentleSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let subtleSpring = Animation.spring(response: 0.4, dampingFraction: 0.9)
    static let quickFade = Animation.easeOut(duration: 0.2)
    static let slowFade = Animation.easeInOut(duration: 0.3)
    
    // Legacy animation names for compatibility
    static let springAnimation = gentleSpring
    static let quickAnimation = subtleSpring
    static let fadeAnimation = quickFade
    
    // Safe Animation System - respects user's reduce motion preference
    static func animation(_ base: Animation) -> Animation {
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        return reduceMotion ? .linear(duration: 0) : base
    }
    
    // Safe variants of our animations
    static var safeSpring: Animation {
        animation(gentleSpring)
    }
    
    static var safeSubtleSpring: Animation {
        animation(subtleSpring)
    }
    
    static var safeQuickFade: Animation {
        animation(quickFade)
    }
    
    static var safeSlowFade: Animation {
        animation(slowFade)
    }
    
    // Additional constants needed by existing code
    static let spacingTiny: CGFloat = 2
    static let cornerRadiusTiny: CGFloat = 2
    static let fastSpringAnimation = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let quickFadeAnimation = Animation.easeInOut(duration: 0.15)
    
    // Enhanced Typography Hierarchy
    struct Typography {
        // Primary hierarchy
        static let heroTitle = Font.system(size: 32, weight: .bold)
        static let pageTitle = Font.system(size: 28, weight: .semibold)
        static let sectionTitle = Font.system(size: 20, weight: .semibold)
        static let cardTitle = Font.system(size: 18, weight: .semibold)
        static let subtitle = Font.system(size: 16, weight: .medium)
        static let body = Font.system(size: 14, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let badge = Font.system(size: 11, weight: .medium)
        
        // Legacy names for compatibility
        static let bodySmall = Font.system(size: 11)
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

// Enhanced Liquid Glass Modifiers
extension View {
    func liquidGlassCard(level: GlassLevel = .primary, isHovered: Bool = false) -> some View {
        self
            .background(level.material)
            .cornerRadius(level.cornerRadius)
            .shadow(
                color: .black.opacity(isHovered ? 0.12 : 0.08),
                radius: isHovered ? 16 : 12,
                y: isHovered ? 6 : 3
            )
            .overlay(
                RoundedRectangle(cornerRadius: level.cornerRadius)
                    .strokeBorder(Color.white.opacity(isHovered ? 0.15 : 0.08), lineWidth: 0.5)
            )
    }
    
    func gentleHover() -> some View {
        self.onHover { isHovered in
            // State changes handled by parent view to avoid animation conflicts
        }
    }
    
    // Legacy modifiers for compatibility
    func liquidGlassCard() -> some View {
        self.liquidGlassCard(level: .primary, isHovered: false)
    }
    
    func liquidGlassHover() -> some View {
        self.gentleHover()
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

enum GlassLevel {
    case hero, primary, secondary, overlay
    
    var material: Material {
        switch self {
        case .hero: return DesignSystem.glassProminent
        case .primary: return DesignSystem.glassPrimary  
        case .secondary: return DesignSystem.glassSecondary
        case .overlay: return DesignSystem.glassOverlay
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .hero: return DesignSystem.cornerRadiusXLarge
        case .primary: return DesignSystem.cornerRadiusLarge
        case .secondary: return DesignSystem.cornerRadiusMedium
        case .overlay: return DesignSystem.cornerRadiusSmall
        }
    }
}

enum ButtonStyle {
    case primary, secondary
}

// MARK: - Transition System

extension AnyTransition {
    /// Gentle slide transition for overlays and sheets
    static let gentleSlide = AnyTransition.asymmetric(
        insertion: .move(edge: .top).combined(with: .opacity),
        removal: .move(edge: .top).combined(with: .opacity)
    )
    
    /// Card entry transition for animated content
    static let cardEntry = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.95).combined(with: .opacity),
        removal: .scale(scale: 0.95).combined(with: .opacity)
    )
    
    /// Badge appearance transition
    static let badgeAppear = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.8).combined(with: .opacity),
        removal: .scale(scale: 0.8).combined(with: .opacity)
    )
    
    /// Sidebar transition
    static let slideFromLeading = AnyTransition.asymmetric(
        insertion: .move(edge: .leading),
        removal: .move(edge: .leading)
    )
    
    /// Settings expansion transition
    static let expandFromTop = AnyTransition.asymmetric(
        insertion: .move(edge: .top).combined(with: .opacity),
        removal: .move(edge: .bottom).combined(with: .opacity)
    )
}