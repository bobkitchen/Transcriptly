//
//  Colors.swift
//  Transcriptly
//
//  Created by Claude Code on 8/6/25.
//

import SwiftUI

extension Color {
    // Semantic colors that adapt to light/dark mode
    static let primaryBackground = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    static let tertiaryBackground = Color(NSColor.textBackgroundColor)
    
    static let primaryText = Color(NSColor.labelColor)
    static let secondaryText = Color(NSColor.secondaryLabelColor)
    static let tertiaryText = Color(NSColor.tertiaryLabelColor)
    
    static let separator = Color(NSColor.separatorColor)
    static let selectedContentBackground = Color(NSColor.selectedContentBackgroundColor)
    
    // Accent colors with opacity variants
    static let accentLight = Color.accentColor.opacity(0.1)
    static let accentMedium = Color.accentColor.opacity(0.3)
    static let accentHeavy = Color.accentColor.opacity(0.5)
    
    // Adaptive color helper
    func adaptive(light: Color, dark: Color) -> Color {
        let nsColor = NSColor(self)
        if nsColor.isLight {
            return light
        } else {
            return dark
        }
    }
}

extension NSColor {
    var isLight: Bool {
        guard let components = cgColor.components, components.count >= 3 else { return true }
        let brightness = (components[0] * 299 + components[1] * 587 + components[2] * 114) / 1000
        return brightness > 0.5
    }
}