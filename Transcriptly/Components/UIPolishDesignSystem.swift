//
//  UIPolishDesignSystem.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 6 UI Polish - Enhanced Design System Constants
//

import SwiftUI

struct UIPolishDesignSystem {
    // MARK: - Sidebar Specifications (Apple 2024 Standard)
    static let sidebarWidth: CGFloat = 200
    static let sidebarInset: CGFloat = 16
    static let sidebarCornerRadius: CGFloat = 12
    
    // MARK: - Enhanced Visual Contrast
    static let cardContrastMaterial: Material = .regularMaterial
    static let borderOpacity: Double = 0.15
    static let shadowRadius: CGFloat = 8
    static let shadowOffset: CGSize = CGSize(width: 0, height: 4)
    
    // MARK: - Mode Indicator Styling
    static let modeIndicatorHeight: CGFloat = 28
    static let modeIndicatorPadding: CGFloat = 12
    static let modeIndicatorCornerRadius: CGFloat = 14
    
    // MARK: - Enhanced Typography Scale
    struct Typography {
        static let title = Font.system(size: 24, weight: .semibold, design: .default)
        static let headline = Font.system(size: 18, weight: .medium, design: .default)
        static let body = Font.system(size: 14, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let micro = Font.system(size: 10, weight: .medium, design: .default)
        
        // Top bar specific
        static let topBarTitle = Font.system(size: 13, weight: .medium, design: .default)
        static let modeIndicator = Font.system(size: 13, weight: .medium, design: .default)
        static let floatingButton = Font.system(size: 11, weight: .medium, design: .default)
    }
    
    // MARK: - Animation Constants
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.1)
        static let standard = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let selection = SwiftUI.Animation.easeInOut(duration: 0.15)
    }
    
    // MARK: - Hover Effects
    struct Hover {
        static let cardScale: CGFloat = 1.02
        static let buttonScale: CGFloat = 1.05
        static let iconScale: CGFloat = 1.1
        static let pressScale: CGFloat = 0.98
    }
    
    // MARK: - Color Enhancements
    struct Colors {
        static let hoverOverlay = Color.white.opacity(0.05)
        static let selectionBackground = Color.accentColor.opacity(0.15)
        static let pressEffect = Color.black.opacity(0.1)
    }
}

// MARK: - Enhanced View Modifiers

extension View {
    /// Apply enhanced card styling with better contrast
    func enhancedCard() -> some View {
        self
            .background(UIPolishDesignSystem.cardContrastMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(UIPolishDesignSystem.borderOpacity), lineWidth: 0.5)
            )
            .shadow(
                color: .black.opacity(0.1),
                radius: UIPolishDesignSystem.shadowRadius,
                x: UIPolishDesignSystem.shadowOffset.width,
                y: UIPolishDesignSystem.shadowOffset.height
            )
    }
    
    /// Apply native selection background
    func nativeSelection(isSelected: Bool) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? UIPolishDesignSystem.Colors.selectionBackground : Color.clear)
                .animation(UIPolishDesignSystem.Animation.selection, value: isSelected)
        )
    }
    
    /// Apply hover scaling effect
    func hoverScale(isHovered: Bool, scale: CGFloat = UIPolishDesignSystem.Hover.cardScale) -> some View {
        self
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(UIPolishDesignSystem.Animation.standard, value: isHovered)
    }
    
    /// Apply press effect
    func pressEffect() -> some View {
        self.scaleEffect(UIPolishDesignSystem.Hover.pressScale)
            .animation(UIPolishDesignSystem.Animation.quick, value: true)
    }
    
    /// Apply content adjustment for inset sidebar
    func adjustForInsetSidebar() -> some View {
        self.padding(.leading, UIPolishDesignSystem.sidebarWidth + (UIPolishDesignSystem.sidebarInset * 2))
    }
}

// MARK: - Haptic Feedback Helper

struct HapticFeedback {
    static func selection() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
    
    static func impact() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
    
    static func success() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
}