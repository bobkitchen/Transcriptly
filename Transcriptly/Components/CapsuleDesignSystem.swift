//
//  CapsuleDesignSystem.swift
//  Transcriptly
//
//  Design constants for capsule mode
//

import SwiftUI

struct CapsuleDesignSystem {
    // Materials
    static let primaryMaterial = Material.ultraThinMaterial
    static let secondaryMaterial = Material.regularMaterial
    
    // Colors
    static let borderColor = Color.secondary.opacity(0.3)
    static let textColor = Color.primary
    static let secondaryTextColor = Color.secondary
    
    // Corner radii
    static let minimalCornerRadius: CGFloat = 16
    static let expandedCornerRadius: CGFloat = 20
    
    // Animations
    static let quickFadeAnimation = Animation.easeInOut(duration: 0.2)
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let expandDuration: TimeInterval = 0.3
    
    // Spacing
    static let padding: CGFloat = 12
    static let largePadding: CGFloat = 20
    
    // Sizes
    static let minimalWidth: CGFloat = 180
    static let minimalHeight: CGFloat = 44
    static let expandedWidth: CGFloat = 320
    static let expandedHeight: CGFloat = 400
    
    // Button sizes
    static let buttonSize: CGFloat = 32
    static let smallButtonSize: CGFloat = 24
    
    // Additional sizes
    static let waveformHeight: CGFloat = 40
    static let minimalSize = CGSize(width: minimalWidth, height: minimalHeight)
    static let expandedSize = CGSize(width: expandedWidth, height: expandedHeight)
    
    // Menu bar specific
    static let menuBarHeight: CGFloat = 22
    static let topMargin: CGFloat = 10
    static let centerOffset: CGFloat = 0
}