//
//  ProductivityCard.swift
//  Transcriptly
//
//  Created by Claude Code on 7/1/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ProductivityCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: String
    let color: Color
    let onTap: () -> Void
    let supportedTypes: [UTType]
    let onDrop: ((URL) -> Void)?
    
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var isDragOver = false
    @State private var animationScale: CGFloat = 1.0
    
    // Convenience initializer for non-dropzone cards
    init(
        icon: String,
        title: String,
        subtitle: String,
        action: String,
        color: Color,
        onTap: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.color = color
        self.onTap = onTap
        self.supportedTypes = []
        self.onDrop = nil
    }
    
    // Full initializer for dropzone cards
    init(
        icon: String,
        title: String,
        subtitle: String,
        action: String,
        color: Color,
        supportedTypes: [UTType] = [],
        onTap: @escaping () -> Void,
        onDrop: ((URL) -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.color = color
        self.supportedTypes = supportedTypes
        self.onTap = onTap
        self.onDrop = onDrop
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Icon section with dropzone indicator - Fixed height
            VStack(spacing: DesignSystem.spacingSmall) {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(isDragOver ? .white : color)
                        .symbolRenderingMode(.hierarchical)
                        .frame(height: 40)
                    
                    // Drop overlay when dragging
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(color)
                                .frame(width: 24, height: 24)
                        )
                        .offset(x: 12, y: -12)
                        .opacity(isDragOver && isDropzone ? 1 : 0)
                }
                .frame(height: 40)
                
                Text(title)
                    .font(DesignSystem.Typography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(isDragOver ? .white : .primaryText)
                    .frame(height: 24)
                
                // Use ZStack to overlay text without layout shift
                ZStack {
                    Text(subtitle)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .opacity(isDragOver && isDropzone ? 0 : 1)
                    
                    Text("Drop files here")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(isDragOver && isDropzone ? 1 : 0)
                }
                .frame(height: 40)
            }
            .padding(.top, DesignSystem.spacingLarge)
            
            Spacer(minLength: DesignSystem.spacingMedium)
            
            // Action button with fixed size
            Button(action: onTap) {
                ZStack {
                    // Normal state
                    HStack(spacing: DesignSystem.spacingSmall) {
                        if isDropzone {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .medium))
                        }
                        Text(action)
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.medium)
                    }
                    .opacity(isDragOver ? 0 : 1)
                    
                    // Drag state
                    Text("Drop Here")
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .opacity(isDragOver ? 1 : 0)
                }
                .foregroundColor(.white)
                .frame(width: 140, height: 32)
                .background(
                    Capsule()
                        .fill(isDragOver ? color.opacity(0.8) : color)
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, DesignSystem.spacingLarge)
        }
        .padding(.horizontal, DesignSystem.spacingLarge)
        .frame(width: 220, height: 220)
        .performantGlass(
            material: .regularMaterial,
            cornerRadius: DesignSystem.cornerRadiusMedium,
            strokeOpacity: isDragOver ? 0.3 : 0.15
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                .strokeBorder(
                    isDragOver ? color : Color.clear, 
                    lineWidth: isDragOver ? 1.5 : 0
                )
        )
        .background(
            // Drop highlight background
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                .fill(isDragOver ? color.opacity(0.15) : Color.clear)
        )
        .overlay(
            // Simple hover overlay
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                .fill(Color.white.opacity((isHovered && !isDragOver) ? 0.05 : 0))
                .allowsHitTesting(false)
        )
        .shadow(
            color: .black.opacity((isHovered || isDragOver) ? 0.15 : 0.12),
            radius: (isHovered || isDragOver) ? 10 : 8,
            y: (isHovered || isDragOver) ? 5 : 4
        )
        .scaleEffect(animationScale)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: animationScale)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isDragOver)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
            updateScale()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                    updateScale()
                }
                .onEnded { _ in
                    isPressed = false
                    updateScale()
                    onTap()
                }
        )
        .conditionalDrop(
            isDropzone: isDropzone,
            supportedTypes: supportedTypes,
            isDragOver: $isDragOver,
            onDrop: onDrop,
            onDragChange: updateScale
        )
    }
    
    private var isDropzone: Bool {
        return onDrop != nil && !supportedTypes.isEmpty
    }
    
    private func updateScale() {
        if isPressed {
            animationScale = 0.98
        } else if isHovered || isDragOver {
            animationScale = 1.02
        } else {
            animationScale = 1.0
        }
    }
}

// MARK: - Drop Support Extension

extension View {
    func conditionalDrop(
        isDropzone: Bool,
        supportedTypes: [UTType],
        isDragOver: Binding<Bool>,
        onDrop: ((URL) -> Void)?,
        onDragChange: (() -> Void)? = nil
    ) -> some View {
        Group {
            if isDropzone {
                self.onDrop(
                    of: [.fileURL],
                    isTargeted: Binding(
                        get: { isDragOver.wrappedValue },
                        set: { newValue in
                            isDragOver.wrappedValue = newValue
                            onDragChange?()
                        }
                    )
                ) { providers in
                    handleCardDrop(providers: providers, onDrop: onDrop)
                }
            } else {
                self
            }
        }
    }
}

private func handleCardDrop(providers: [NSItemProvider], onDrop: ((URL) -> Void)?) -> Bool {
    guard let onDrop = onDrop else { return false }
    
    for provider in providers {
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            if let url = url {
                DispatchQueue.main.async {
                    onDrop(url)
                }
            }
        }
        return true
    }
    
    return false
}

#Preview {
    HStack(spacing: 20) {
        ProductivityCard(
            icon: "mic.fill",
            title: "Record Dictation",
            subtitle: "Voice to text with AI refinement",
            action: "Start Recording",
            color: .blue,
            onTap: {}
        )
        
        ProductivityCard(
            icon: "doc.text.fill",
            title: "Read Documents",
            subtitle: "Text to speech for any document",
            action: "Choose Document",
            color: .green,
            supportedTypes: [.pdf, .plainText, .rtf],
            onTap: {},
            onDrop: { url in
                print("Document dropped: \(url)")
            }
        )
        
        ProductivityCard(
            icon: "waveform",
            title: "Transcribe Media",
            subtitle: "Convert audio files to text",
            action: "Select Audio",
            color: .purple,
            supportedTypes: [.audio, .mp3, .wav],
            onTap: {},
            onDrop: { url in
                print("Audio dropped: \(url)")
            }
        )
    }
    .padding()
    .frame(width: 800, height: 300)
}