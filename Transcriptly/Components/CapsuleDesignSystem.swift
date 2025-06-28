//
//  CapsuleDesignSystem.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Capsule Interface Overhaul - Design System Constants
//

import Foundation
import SwiftUI

/// Design system constants for the ultra-minimal floating capsule interface
struct CapsuleDesignSystem {
    // MARK: - Sizing
    static let minimalSize = CGSize(width: 60, height: 20)
    static let expandedSize = CGSize(width: 150, height: 40)
    
    // MARK: - Positioning
    static let topMargin: CGFloat = 20
    static let menuBarHeight: CGFloat = 24
    
    // MARK: - Animation
    static let expandDuration: TimeInterval = 0.25
    static let springResponse: Double = 0.3
    static let springDamping: Double = 0.8
    static let hoverScaleEffect: CGFloat = 1.05
    
    // MARK: - Visual Elements
    static let waveformHeight: CGFloat = 20
    static let waveformBarWidth: CGFloat = 2
    static let waveformBarSpacing: CGFloat = 2
    static let waveformBarCount: Int = 8
    static let borderOpacity: Double = 0.8
    
    // MARK: - Component Sizes
    static let recordButtonSize: CGFloat = 24
    static let expandButtonSize: CGFloat = 20
    static let minimalCornerRadius: CGFloat = 10
    static let expandedCornerRadius: CGFloat = 20
    
    // MARK: - Typography
    static let modeNameFont = Font.system(size: 10, weight: .medium)
    static let timeFont = Font.system(.caption2, design: .monospaced)
    
    // MARK: - Colors
    static let primaryMaterial: Material = .ultraThinMaterial
    static let borderColor = Color.gray.opacity(borderOpacity)
    static let waveformIdleOpacity: Double = 0.4
    static let waveformActiveOpacity: Double = 0.9
    static let textOpacity: Double = 0.8
    
    // MARK: - Computed Properties
    static var springAnimation: Animation {
        .spring(response: springResponse, dampingFraction: springDamping)
    }
    
    static var quickFadeAnimation: Animation {
        .easeInOut(duration: 0.15)
    }
    
    static var centerOffset: CGFloat {
        (expandedSize.width - minimalSize.width) / 2
    }
}