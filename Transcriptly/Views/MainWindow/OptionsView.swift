//
//  OptionsView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import SwiftUI

struct OptionsView: View {
    @State private var autoPasteEnabled = true
    @State private var showPreviewWindow = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text("Options")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Checkbox options
            VStack(alignment: .leading, spacing: 4) {
                OptionToggle(
                    isEnabled: $autoPasteEnabled,
                    title: "Auto-paste after transcription"
                )
                
                OptionToggle(
                    isEnabled: $showPreviewWindow,
                    title: "Show preview window"
                )
            }
            .font(.body)
            
            // Secondary button for shortcuts customization
            Button("Customize Shortcuts...") {
                // Non-functional for now
            }
            .buttonStyle(.link)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OptionToggle: View {
    @Binding var isEnabled: Bool
    let title: String
    
    var body: some View {
        Button(action: {
            isEnabled.toggle()
        }) {
            HStack(spacing: 6) {
                Image(systemName: isEnabled ? "checkmark.square.fill" : "square")
                    .foregroundColor(isEnabled ? .accentColor : .secondary)
                    .font(.system(size: 14))
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview {
    OptionsView()
        .padding()
}