//
//  LiquidGlassEffects.swift
//  Transcriptly
//
//  Created by Claude Code on 7/2/25.
//  Phase 9.5 - Enhanced Liquid Glass Effects
//

import SwiftUI

// MARK: - Optimized Hover Overlay

struct OptimizedHoverOverlay: ViewModifier {
    let isHovered: Bool
    let cornerRadius: CGFloat
    let intensity: Double
    
    init(isHovered: Bool, cornerRadius: CGFloat, intensity: Double = 0.1) {
        self.isHovered = isHovered
        self.cornerRadius = cornerRadius
        self.intensity = intensity
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered ? intensity : 0),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
                    .animation(.easeOut(duration: 0.15), value: isHovered)
            )
    }
}

// MARK: - Performance-Optimized Glass Layer

struct PerformantGlassLayer: View {
    let material: Material
    let cornerRadius: CGFloat
    let strokeWidth: CGFloat
    let strokeOpacity: Double
    
    init(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium,
        strokeWidth: CGFloat = 0.5,
        strokeOpacity: Double = 0.1
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.strokeWidth = strokeWidth
        self.strokeOpacity = strokeOpacity
    }
    
    var body: some View {
        ZStack {
            // Base material layer
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(material)
            
            // Single stroke overlay for performance
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(strokeOpacity),
                            Color.white.opacity(strokeOpacity * 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: strokeWidth
                )
        }
    }
}

// MARK: - Adaptive Shadow System

struct AdaptiveShadow: ViewModifier {
    let isHovered: Bool
    let isSelected: Bool
    let baseRadius: CGFloat
    let baseOpacity: Double
    
    init(
        isHovered: Bool,
        isSelected: Bool = false,
        baseRadius: CGFloat = 8,
        baseOpacity: Double = 0.1
    ) {
        self.isHovered = isHovered
        self.isSelected = isSelected
        self.baseRadius = baseRadius
        self.baseOpacity = baseOpacity
    }
    
    private var shadowRadius: CGFloat {
        if isSelected { return baseRadius * 1.5 }
        if isHovered { return baseRadius * 1.25 }
        return baseRadius
    }
    
    private var shadowOpacity: Double {
        if isSelected { return baseOpacity * 1.5 }
        if isHovered { return baseOpacity * 1.25 }
        return baseOpacity
    }
    
    private var shadowY: CGFloat {
        if isSelected { return baseRadius * 0.75 }
        if isHovered { return baseRadius * 0.625 }
        return baseRadius * 0.5
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }
}

// MARK: - Liquid Glass Button Style

struct LiquidGlassButtonStyle: SwiftUI.ButtonStyle {
    let cornerRadius: CGFloat
    let material: Material
    
    init(
        cornerRadius: CGFloat = DesignSystem.cornerRadiusSmall,
        material: Material = .ultraThinMaterial
    ) {
        self.cornerRadius = cornerRadius
        self.material = material
    }
    
    func makeBody(configuration: Configuration) -> some View {
        LiquidGlassButtonView(configuration: configuration, cornerRadius: cornerRadius, material: material)
    }
    
    struct LiquidGlassButtonView: View {
        let configuration: ButtonStyleConfiguration
        let cornerRadius: CGFloat
        let material: Material
        @State private var isHovered = false
        @State private var isPressed = false
        
        var body: some View {
            configuration.label
                .background(
                    PerformantGlassLayer(
                        material: material,
                        cornerRadius: cornerRadius,
                        strokeOpacity: isHovered ? 0.2 : 0.1
                    )
                )
                .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
                .modifier(
                    AdaptiveShadow(
                        isHovered: isHovered,
                        isSelected: configuration.isPressed,
                        baseRadius: 4,
                        baseOpacity: 0.08
                    )
                )
                .modifier(
                    OptimizedHoverOverlay(
                        isHovered: isHovered,
                        cornerRadius: cornerRadius
                    )
                )
                .animation(Animation.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
                .animation(Animation.easeOut(duration: 0.1), value: configuration.isPressed)
                .onHover { hovering in
                    isHovered = hovering
                }
                .onChange(of: configuration.isPressed) { _, pressed in
                    if pressed {
                        HapticFeedback.impact()
                    }
                }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply optimized hover overlay
    func hoverOverlay(
        isHovered: Bool,
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium,
        intensity: Double = 0.1
    ) -> some View {
        modifier(OptimizedHoverOverlay(
            isHovered: isHovered,
            cornerRadius: cornerRadius,
            intensity: intensity
        ))
    }
    
    /// Apply adaptive shadow system
    func adaptiveShadow(
        isHovered: Bool,
        isSelected: Bool = false,
        baseRadius: CGFloat = 8,
        baseOpacity: Double = 0.1
    ) -> some View {
        modifier(AdaptiveShadow(
            isHovered: isHovered,
            isSelected: isSelected,
            baseRadius: baseRadius,
            baseOpacity: baseOpacity
        ))
    }
    
    /// Apply performant glass background
    func performantGlass(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium,
        strokeWidth: CGFloat = 0.5,
        strokeOpacity: Double = 0.1
    ) -> some View {
        self.background(
            PerformantGlassLayer(
                material: material,
                cornerRadius: cornerRadius,
                strokeWidth: strokeWidth,
                strokeOpacity: strokeOpacity
            )
        )
    }
}


#Preview {
    VStack(spacing: 20) {
        // Test button with Liquid Glass style
        Button("Liquid Glass Button") {
            print("Tapped")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .buttonStyle(LiquidGlassButtonStyle())
        
        // Test hover overlay
        Text("Hover Overlay Test")
            .padding(20)
            .performantGlass()
            .hoverOverlay(isHovered: true, cornerRadius: 12)
        
        // Test adaptive shadow
        HStack(spacing: 20) {
            Text("Normal")
                .padding(20)
                .performantGlass()
                .adaptiveShadow(isHovered: false)
            
            Text("Hovered")
                .padding(20)
                .performantGlass()
                .adaptiveShadow(isHovered: true)
            
            Text("Selected")
                .padding(20)
                .performantGlass()
                .adaptiveShadow(isHovered: false, isSelected: true)
        }
    }
    .padding(40)
    .background(Color.gray.opacity(0.2))
}