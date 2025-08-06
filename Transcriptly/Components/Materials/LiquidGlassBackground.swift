//
//  LiquidGlassBackground.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 UI Overhaul - Liquid Glass Materials
//

import SwiftUI

/// Core Liquid Glass background component with translucent materials
struct LiquidGlassBackground: View {
    let material: Material
    let cornerRadius: CGFloat
    let strokeOpacity: CGFloat
    
    init(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium,
        strokeOpacity: CGFloat = 0.1
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.strokeOpacity = strokeOpacity
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(material)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(strokeOpacity), lineWidth: 0.5)
            )
    }
}

/// Container version with content
struct LiquidGlassContainer<Content: View>: View {
    let content: Content
    let material: Material
    let cornerRadius: CGFloat
    let strokeOpacity: CGFloat
    
    init(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium,
        strokeOpacity: CGFloat = 0.1,
        @ViewBuilder content: () -> Content
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.strokeOpacity = strokeOpacity
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(material)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.white.opacity(strokeOpacity), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - View Extension for Convenience

extension View {
    func liquidGlassBackground(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium,
        strokeOpacity: CGFloat = 0.1
    ) -> some View {
        self.background(
            LiquidGlassBackground(
                material: material,
                cornerRadius: cornerRadius,
                strokeOpacity: strokeOpacity
            )
        )
    }
}

// MARK: - Preset Material Backgrounds

struct LiquidGlassCard: View {
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        LiquidGlassBackground(
            material: .regularMaterial,
            cornerRadius: cornerRadius,
            strokeOpacity: 0.15
        )
    }
}

struct LiquidGlassSidebar: View {
    var body: some View {
        LiquidGlassBackground(
            material: .ultraThinMaterial,
            cornerRadius: 0,
            strokeOpacity: 0.05
        )
    }
}

struct LiquidGlassHeader: View {
    var body: some View {
        LiquidGlassBackground(
            material: .thickMaterial,
            cornerRadius: 0,
            strokeOpacity: 0.1
        )
    }
}

// MARK: - View Extension

extension View {
    /// Apply standard card background with liquid glass
    func liquidGlassCard(cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium) -> some View {
        self.background(LiquidGlassCard(cornerRadius: cornerRadius))
    }
    
    /// Apply sidebar background with liquid glass
    func liquidGlassSidebar() -> some View {
        self.background(LiquidGlassSidebar())
    }
    
    /// Apply header background with liquid glass
    func liquidGlassHeader() -> some View {
        self.background(LiquidGlassHeader())
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Ultra Thin Material")
            .padding(20)
            .liquidGlassBackground()
        
        Text("Regular Material Card")
            .padding(20)
            .liquidGlassCard()
        
        Text("Thick Material")
            .padding(20)
            .liquidGlassBackground(material: .thickMaterial)
    }
    .padding(40)
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}