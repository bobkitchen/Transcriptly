//
//  Colors.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 UI Overhaul - Semantic Color Extensions
//

import SwiftUI
import AppKit

extension Color {
    
    // MARK: - Semantic Background Colors
    
    /// Primary window background that adapts to appearance
    static let primaryBackground = Color(NSColor.windowBackgroundColor)
    
    /// Secondary control background that adapts to appearance
    static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    
    /// Tertiary text background that adapts to appearance
    static let tertiaryBackground = Color(NSColor.textBackgroundColor)
    
    /// Quaternary background for subtle elements
    static let quaternaryBackground = Color(NSColor.quaternaryLabelColor.withAlphaComponent(0.1))
    
    // MARK: - Semantic Text Colors
    
    /// Primary label color that adapts to appearance
    static let primaryText = Color(NSColor.labelColor)
    
    /// Secondary label color that adapts to appearance
    static let secondaryText = Color(NSColor.secondaryLabelColor)
    
    /// Tertiary label color that adapts to appearance
    static let tertiaryText = Color(NSColor.tertiaryLabelColor)
    
    /// Quaternary label color for very subtle text
    static let quaternaryText = Color(NSColor.quaternaryLabelColor)
    
    // MARK: - Accent Colors with Vibrancy
    
    /// Accent color with reduced opacity for subtle emphasis
    static let accentWithVibrancy = Color.accentColor.opacity(0.8)
    
    /// Accent color with very subtle opacity for backgrounds
    static let accentSubtle = Color.accentColor.opacity(0.1)
    
    /// Accent color with medium opacity for selection states
    static let accentMedium = Color.accentColor.opacity(0.2)
    
    // MARK: - Liquid Glass Specific Colors
    
    /// Stroke color for glass borders
    static let glassStroke = Color.white.opacity(0.1)
    
    /// Strong stroke color for emphasized glass borders
    static let glassStrokeStrong = Color.white.opacity(0.2)
    
    /// Hover overlay for interactive elements
    static let hoverOverlay = Color.white.opacity(0.05)
    
    /// Selection overlay for selected states
    static let selectionOverlay = Color.accentColor.opacity(0.1)
    
    /// Shadow color for light mode
    static let shadowLight = Color.black.opacity(0.1)
    
    /// Shadow color for medium elevation
    static let shadowMedium = Color.black.opacity(0.15)
    
    /// Shadow color for heavy elevation
    static let shadowHeavy = Color.black.opacity(0.25)
    
    // MARK: - Status Colors
    
    /// Success state color (green)
    static let successColor = Color.green
    
    /// Warning state color (orange/yellow)
    static let warningColor = Color.orange
    
    /// Error state color (red)
    static let errorColor = Color.red
    
    /// Recording state color
    static let recordingColor = Color.red
    
    /// Processing state color
    static let processingColor = Color.orange
    
    // MARK: - Special UI Colors
    
    /// Divider color that adapts to appearance
    static let dividerColor = Color(NSColor.separatorColor)
    
    /// Link color for interactive text
    static let linkColor = Color(NSColor.linkColor)
    
    /// Control accent color for buttons and controls
    static let controlAccent = Color(NSColor.controlAccentColor)
    
    // MARK: - Dynamic Color Helpers
    
    /// Create a color that adapts between light and dark mode
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(NSColor(name: nil) { appearance in
            switch appearance.name {
            case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                return NSColor(dark)
            default:
                return NSColor(light)
            }
        })
    }
    
    /// Create a color with adaptive opacity
    func adaptiveOpacity(light: Double, dark: Double) -> Color {
        Color.adaptive(
            light: self.opacity(light),
            dark: self.opacity(dark)
        )
    }
    
    // MARK: - Gradient Helpers
    
    /// Create a subtle gradient for buttons
    static func buttonGradient(base: Color = .accentColor) -> LinearGradient {
        LinearGradient(
            colors: [base, base.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Create a glass-like gradient
    static func glassGradient(opacity: Double = 0.1) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(opacity),
                Color.white.opacity(opacity * 0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Create a selection gradient
    static func selectionGradient(accentColor: Color = .accentColor) -> LinearGradient {
        LinearGradient(
            colors: [
                accentColor.opacity(0.2),
                accentColor.opacity(0.1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - NSColor Extensions

extension NSColor {
    /// Convenience method to get color for current appearance
    static func colorForCurrentAppearance(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            switch appearance.name {
            case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                return dark
            default:
                return light
            }
        }
    }
}