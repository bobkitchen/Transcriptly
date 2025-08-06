//
//  MaterialEffects.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Phase 4 UI Overhaul - Material Effects and Elevation
//

import SwiftUI

// MARK: - Elevated Card Modifier

struct ElevatedCard: ViewModifier {
    @State private var isHovered = false
    let cornerRadius: CGFloat
    let enableHover: Bool
    let material: Material
    
    init(
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium,
        enableHover: Bool = true,
        material: Material = .regularMaterial
    ) {
        self.cornerRadius = cornerRadius
        self.enableHover = enableHover
        self.material = material
    }
    
    func body(content: Content) -> some View {
        content
            .liquidGlassBackground(
                material: material,
                cornerRadius: cornerRadius,
                strokeOpacity: isHovered ? 0.2 : 0.1
            )
            .shadow(
                color: .black.opacity(isHovered ? 0.15 : 0.1),
                radius: isHovered ? 12 : 8,
                y: isHovered ? 6 : 4
            )
            .scaleEffect(isHovered && enableHover ? 1.02 : 1.0)
            .animation(DesignSystem.springAnimation, value: isHovered)
            .onHover { hovering in
                if enableHover {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Floating Card Modifier

struct FloatingCard: ViewModifier {
    @State private var isHovered = false
    let cornerRadius: CGFloat
    let enableHover: Bool
    
    init(
        cornerRadius: CGFloat = DesignSystem.cornerRadiusLarge,
        enableHover: Bool = true
    ) {
        self.cornerRadius = cornerRadius
        self.enableHover = enableHover
    }
    
    func body(content: Content) -> some View {
        content
            .liquidGlassBackground(
                material: .thickMaterial,
                cornerRadius: cornerRadius,
                strokeOpacity: 0.2
            )
            .shadow(
                color: .black.opacity(isHovered ? 0.25 : 0.2),
                radius: isHovered ? 20 : 16,
                y: isHovered ? 10 : 8
            )
            .scaleEffect(isHovered && enableHover ? 1.03 : 1.0)
            .animation(DesignSystem.springAnimation, value: isHovered)
            .onHover { hovering in
                if enableHover {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Interactive Surface Modifier

struct InteractiveSurface: ViewModifier {
    @State private var isHovered = false
    @State private var isPressed = false
    let cornerRadius: CGFloat
    let hapticFeedback: Bool
    
    init(
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium,
        hapticFeedback: Bool = true
    ) {
        self.cornerRadius = cornerRadius
        self.hapticFeedback = hapticFeedback
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.01 : 1.0))
            .animation(DesignSystem.fastSpringAnimation, value: isHovered)
            .animation(DesignSystem.quickFadeAnimation, value: isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                if hapticFeedback {
                    NSHapticFeedbackManager.defaultPerformer.perform(
                        .levelChange,
                        performanceTime: .now
                    )
                }
                withAnimation(DesignSystem.quickFadeAnimation) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(DesignSystem.quickFadeAnimation) {
                        isPressed = false
                    }
                }
            }
    }
}

// MARK: - Selection State Modifier

struct SelectableCard: ViewModifier {
    @State private var isHovered = false
    let isSelected: Bool
    let cornerRadius: CGFloat
    let accentColor: Color
    
    init(
        isSelected: Bool,
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium,
        accentColor: Color = .accentColor
    ) {
        self.isSelected = isSelected
        self.cornerRadius = cornerRadius
        self.accentColor = accentColor
    }
    
    func body(content: Content) -> some View {
        content
            .liquidGlassBackground(
                material: isSelected ? .regularMaterial : .ultraThinMaterial,
                cornerRadius: cornerRadius,
                strokeOpacity: isSelected ? 0.3 : 0.1
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isSelected ? accentColor.opacity(0.5) : Color.clear,
                        lineWidth: isSelected ? 1.5 : 0
                    )
            )
            .shadow(
                color: isSelected ? accentColor.opacity(0.2) : .black.opacity(0.1),
                radius: isSelected ? 8 : 4,
                y: isSelected ? 4 : 2
            )
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(DesignSystem.springAnimation, value: isSelected)
            .animation(DesignSystem.fadeAnimation, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply elevated card styling with hover effects
    func elevatedCard(
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium,
        enableHover: Bool = true,
        material: Material = .regularMaterial
    ) -> some View {
        modifier(ElevatedCard(cornerRadius: cornerRadius, enableHover: enableHover, material: material))
    }
    
    /// Apply floating card styling with pronounced elevation
    func floatingCard(
        cornerRadius: CGFloat = DesignSystem.cornerRadiusLarge,
        enableHover: Bool = true
    ) -> some View {
        modifier(FloatingCard(cornerRadius: cornerRadius, enableHover: enableHover))
    }
    
    /// Apply interactive surface effects
    func interactiveSurface(
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium,
        hapticFeedback: Bool = true
    ) -> some View {
        modifier(InteractiveSurface(cornerRadius: cornerRadius, hapticFeedback: hapticFeedback))
    }
    
    /// Apply selectable card styling
    func selectableCard(
        isSelected: Bool,
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium,
        accentColor: Color = .accentColor
    ) -> some View {
        modifier(SelectableCard(isSelected: isSelected, cornerRadius: cornerRadius, accentColor: accentColor))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Elevated Card")
            .padding(20)
            .elevatedCard()
        
        Text("Floating Card")
            .padding(20)
            .floatingCard()
        
        HStack(spacing: 20) {
            Text("Unselected")
                .padding(20)
                .selectableCard(isSelected: false)
            
            Text("Selected")
                .padding(20)
                .selectableCard(isSelected: true)
        }
        
        Text("Interactive Surface")
            .padding(20)
            .interactiveSurface()
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