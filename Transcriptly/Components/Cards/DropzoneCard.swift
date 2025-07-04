//
//  DropzoneCard.swift
//  Transcriptly
//
//  Enhanced dropzone card with clear visual indicators and file support
//

import SwiftUI
import UniformTypeIdentifiers

struct DropzoneCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonText: String
    let buttonColor: Color
    let acceptedTypes: [UTType]
    let supportedFormats: String
    let action: () -> Void
    let onFileDrop: ((URL) -> Void)?
    
    @State private var isDragOver = false
    @State private var isProcessing = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
            // Icon and content section
            VStack(spacing: DesignSystem.spacingSmall) {
                ZStack {
                    // Background icon for dropzone
                    if acceptsFiles {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 60))
                            .foregroundColor(isDragOver ? buttonColor.opacity(0.3) : Color.tertiaryText.opacity(0.1))
                            .scaleEffect(isDragOver ? 1.1 : 1.0)
                            .animation(DesignSystem.gentleSpring, value: isDragOver)
                    }
                    
                    // Main icon
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(isDragOver ? buttonColor : .primaryText)
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(isHovered || isDragOver ? 1.1 : 1.0)
                        .animation(DesignSystem.gentleSpring, value: isHovered || isDragOver)
                }
                .frame(height: 60)
                
                VStack(spacing: DesignSystem.spacingTiny) {
                    Text(title)
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(.primaryText)
                        .fontWeight(.semibold)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer(minLength: DesignSystem.spacingSmall)
            
            // Dropzone indicator or action button
            if acceptsFiles && isDragOver {
                VStack(spacing: DesignSystem.spacingTiny) {
                    Text("Drop files here")
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(buttonColor)
                    
                    Text(supportedFormats)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.spacingSmall)
                .background(buttonColor.opacity(0.1))
                .cornerRadius(DesignSystem.cornerRadiusSmall)
            } else {
                VStack(spacing: DesignSystem.spacingTiny) {
                    Button(action: action) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Text(buttonText)
                                    .fontWeight(.medium)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.spacingSmall)
                        .background(buttonColor)
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.cornerRadiusSmall)
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                    
                    if acceptsFiles {
                        HStack(spacing: DesignSystem.spacingTiny) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 10))
                                .foregroundColor(.tertiaryText)
                            Text("or drop \(supportedFormats)")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.tertiaryText)
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.spacingLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                .fill(isDragOver ? buttonColor.opacity(0.05) : Color.clear)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                        .fill(Material.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                        .strokeBorder(
                            isDragOver ? buttonColor : (acceptsFiles ? Color.tertiaryText.opacity(0.3) : Color.clear),
                            style: StrokeStyle(
                                lineWidth: isDragOver ? 2 : 1,
                                dash: acceptsFiles && !isDragOver ? [5, 5] : []
                            )
                        )
                )
        )
        .scaleEffect((isHovered && !isDragOver) ? 1.02 : 1.0)
        .animation(DesignSystem.gentleSpring, value: isHovered)
        .animation(DesignSystem.gentleSpring, value: isDragOver)
        .onHover { hovering in
            isHovered = hovering
        }
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            print("📥 DropzoneCard: Drop received with \(providers.count) providers")
            guard let provider = providers.first else {
                print("❌ DropzoneCard: No providers in drop")
                return false
            }
            
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                DispatchQueue.main.async {
                    if let url = url {
                        print("✅ DropzoneCard: Successfully loaded file: \(url.lastPathComponent)")
                        onFileDrop?(url)
                    } else if let error = error {
                        print("❌ DropzoneCard: Error loading dropped file: \(error.localizedDescription)")
                    }
                }
            }
            
            return true
        }
    }
    
    private var acceptsFiles: Bool {
        onFileDrop != nil && !acceptedTypes.isEmpty
    }
}


#Preview {
    HStack(spacing: 20) {
        EnhancedActionCard(
            icon: "mic.circle.fill",
            title: "Record Dictation",
            subtitle: "Voice to text with AI refinement",
            buttonText: "Start Recording",
            buttonColor: .blue,
            action: {}
        )
        
        EnhancedActionCard(
            icon: "doc.text.fill",
            title: "Read Documents",
            subtitle: "Text to speech for any document",
            buttonText: "Choose Document",
            buttonColor: .green,
            acceptedTypes: [.pdf, .plainText, .rtf, .html],
            supportedFormats: "PDF, TXT, RTF, HTML",
            action: {},
            onFileDrop: { url in
                print("Document dropped: \(url)")
            }
        )
        
        EnhancedActionCard(
            icon: "waveform",
            title: "Transcribe Media",
            subtitle: "Convert audio files to text",
            buttonText: "Select Audio",
            buttonColor: .purple,
            acceptedTypes: [.audio, .movie, .mpeg4Movie],
            supportedFormats: "MP3, MP4, WAV, M4A",
            action: {},
            onFileDrop: { url in
                print("Media dropped: \(url)")
            }
        )
    }
    .frame(height: 200)
    .padding()
    .background(Color.primaryBackground)
}