//
//  MinimalCapsuleView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Capsule Interface Overhaul - Minimal State View
//

import SwiftUI

/// Ultra-minimal 60×20px capsule that expands on hover
struct MinimalCapsuleView: View {
    @State private var isHovered = false
    let onHover: (Bool) -> Void
    
    var body: some View {
        RoundedRectangle(cornerRadius: CapsuleDesignSystem.minimalCornerRadius)
            .fill(CapsuleDesignSystem.primaryMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: CapsuleDesignSystem.minimalCornerRadius)
                    .strokeBorder(
                        CapsuleDesignSystem.borderColor,
                        lineWidth: 1
                    )
            )
            .frame(
                width: CapsuleDesignSystem.minimalSize.width,
                height: CapsuleDesignSystem.minimalSize.height
            )
            .scaleEffect(isHovered ? CapsuleDesignSystem.hoverScaleEffect : 1.0)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .animation(CapsuleDesignSystem.springAnimation, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
                onHover(hovering)
            }
            .accessibilityElement()
            .accessibilityLabel("Recording capsule - minimized")
            .accessibilityHint("Hover to expand recording interface")
            .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ZStack {
        Rectangle()
            .fill(.black.opacity(0.8))
            .ignoresSafeArea()
        
        MinimalCapsuleView { hovering in
            print("Hover: \(hovering)")
        }
    }
    .frame(width: 200, height: 100)
}