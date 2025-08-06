//
//  UniversalDropzone.swift
//  Transcriptly
//
//  Created by Claude Code on 7/1/25.
//  Phase 8 Continuation - Universal file drop component
//

import SwiftUI
import UniformTypeIdentifiers

struct UniversalDropzone: View {
    let title: String
    let subtitle: String
    let supportedTypes: [UTType]
    let onDrop: (URL) -> Void
    
    @State private var isDragOver = false
    @State private var lastDroppedFile: String?
    
    private var dropTypes: [UTType] {
        return supportedTypes.isEmpty ? [.fileURL] : supportedTypes
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
            // Icon
            Image(systemName: isDragOver ? "plus.circle.fill" : "plus.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(isDragOver ? .accentColor : .secondaryText)
                .symbolRenderingMode(.hierarchical)
                .animation(DesignSystem.springAnimation, value: isDragOver)
            
            // Title and subtitle
            VStack(spacing: DesignSystem.spacingSmall) {
                Text(title)
                    .font(DesignSystem.Typography.titleMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Supported formats
            if !supportedTypes.isEmpty {
                Text(formatSupportedTypes())
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(.tertiaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Last dropped file indicator
            if let lastFile = lastDroppedFile {
                HStack(spacing: DesignSystem.spacingSmall) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                    
                    Text("Last: \(lastFile)")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, DesignSystem.spacingSmall)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding(DesignSystem.spacingLarge)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                        .strokeBorder(
                            isDragOver ? Color.accentColor : Color.clear,
                            lineWidth: 2,
                            antialiased: true
                        )
                        .animation(DesignSystem.springAnimation, value: isDragOver)
                )
        )
        .scaleEffect(isDragOver ? 1.02 : 1.0)
        .animation(DesignSystem.springAnimation, value: isDragOver)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private func formatSupportedTypes() -> String {
        let extensions = supportedTypes.compactMap { type in
            if let ext = type.preferredFilenameExtension?.uppercased() {
                return ext
            }
            // Handle some common types manually
            switch type {
            case .pdf: return "PDF"
            case .plainText: return "TXT"
            case .rtf: return "RTF" 
            case .html: return "HTML"
            case .audio: return "AUDIO"
            case .movie: return "VIDEO"
            default: return nil
            }
        }
        
        if extensions.isEmpty {
            return "Drag and drop files here"
        } else if extensions.count == 1 {
            return "Supports \(extensions[0]) files"
        } else if extensions.count <= 3 {
            return "Supports \(extensions.joined(separator: ", ")) files"
        } else {
            let first = extensions.prefix(2).joined(separator: ", ")
            return "Supports \(first) and \(extensions.count - 2) more"
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            DispatchQueue.main.async {
                if let url = url {
                    print("✅ UniversalDropzone: File dropped: \(url.lastPathComponent)")
                    self.lastDroppedFile = url.lastPathComponent
                    self.onDrop(url)
                } else if let error = error {
                    print("❌ UniversalDropzone: Error loading dropped file: \(error.localizedDescription)")
                }
            }
        }
        
        return true
    }
}

// MARK: - Convenience Initializers

extension UniversalDropzone {
    /// Creates a dropzone for document files (PDF, DOCX, TXT, etc.)
    static func forDocuments(
        title: String = "Drop Document Here",
        subtitle: String = "Import documents for text-to-speech reading",
        onDrop: @escaping (URL) -> Void
    ) -> UniversalDropzone {
        UniversalDropzone(
            title: title,
            subtitle: subtitle,
            supportedTypes: [
                .pdf,
                .plainText,
                .rtf,
                .html,
                UTType(filenameExtension: "docx") ?? .data,
                UTType(filenameExtension: "doc") ?? .data
            ],
            onDrop: onDrop
        )
    }
    
    /// Creates a dropzone for audio files
    static func forAudio(
        title: String = "Drop Audio Here", 
        subtitle: String = "Import audio files for transcription",
        onDrop: @escaping (URL) -> Void
    ) -> UniversalDropzone {
        UniversalDropzone(
            title: title,
            subtitle: subtitle,
            supportedTypes: [
                .audio,
                .mp3,
                .wav,
                UTType(filenameExtension: "m4a") ?? .data,
                UTType(filenameExtension: "aac") ?? .data
            ],
            onDrop: onDrop
        )
    }
    
    /// Creates a dropzone for any file type
    static func forAnyFile(
        title: String = "Drop Files Here",
        subtitle: String = "Import any supported file",
        onDrop: @escaping (URL) -> Void
    ) -> UniversalDropzone {
        UniversalDropzone(
            title: title,
            subtitle: subtitle,
            supportedTypes: [], // Empty means accept all files
            onDrop: onDrop
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        UniversalDropzone.forDocuments { url in
            print("Document dropped: \(url)")
        }
        
        UniversalDropzone.forAudio { url in
            print("Audio dropped: \(url)")
        }
        
        UniversalDropzone(
            title: "Custom Dropzone",
            subtitle: "Accepts only PDF files",
            supportedTypes: [.pdf]
        ) { url in
            print("PDF dropped: \(url)")
        }
    }
    .padding()
    .frame(width: 400)
}