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
        VStack(spacing: DesignSystem.spacingMedium) {
            // Icon section with dropzone indicator
            VStack(spacing: DesignSystem.spacingSmall) {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(isDragOver ? .white : color)
                        .symbolRenderingMode(.hierarchical)
                    
                    // Drop overlay when dragging
                    if isDragOver && isDropzone {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(color)
                                    .frame(width: 24, height: 24)
                            )
                            .offset(x: 12, y: -12)
                    }
                }
                
                Text(title)
                    .font(DesignSystem.Typography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(isDragOver ? .white : .primaryText)
                
                Text(isDragOver && isDropzone ? "Drop files here" : subtitle)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(isDragOver ? .white.opacity(0.9) : .secondaryText)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: isDragOver)
            }
            
            Spacer()
            
            // Action button with dropzone hint
            Button(action: onTap) {
                HStack(spacing: DesignSystem.spacingSmall) {
                    if isDropzone && !isDragOver {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    Text(isDragOver ? "Drop Here" : action)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.spacingMedium)
                .padding(.vertical, DesignSystem.spacingSmall)
                .background(
                    Capsule()
                        .fill(isDragOver ? color.opacity(0.8) : color)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.spacingLarge)
        .frame(minHeight: 200)
        .background(
            LiquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                        .strokeBorder(
                            isDragOver ? color : color.opacity(0.3), 
                            lineWidth: isDragOver ? 2 : 1
                        )
                        .animation(DesignSystem.springAnimation, value: isDragOver)
                )
        )
        .background(
            // Drop highlight background
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                .fill(isDragOver ? color.opacity(0.2) : Color.clear)
                .animation(DesignSystem.springAnimation, value: isDragOver)
        )
        .scaleEffect(isPressed ? 0.98 : (isHovered || isDragOver ? 1.02 : 1.0))
        .animation(DesignSystem.springAnimation, value: isHovered)
        .animation(DesignSystem.springAnimation, value: isPressed)
        .animation(DesignSystem.springAnimation, value: isDragOver)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                    onTap()
                }
        )
        .conditionalDrop(
            isDropzone: isDropzone,
            supportedTypes: supportedTypes,
            isDragOver: $isDragOver,
            onDrop: onDrop
        )
    }
    
    private var isDropzone: Bool {
        return onDrop != nil && !supportedTypes.isEmpty
    }
}

// MARK: - Drop Support Extension

extension View {
    func conditionalDrop(
        isDropzone: Bool,
        supportedTypes: [UTType],
        isDragOver: Binding<Bool>,
        onDrop: ((URL) -> Void)?
    ) -> some View {
        Group {
            if isDropzone {
                self.onDrop(
                    of: [.fileURL],
                    isTargeted: isDragOver
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