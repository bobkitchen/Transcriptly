//
//  RefinementModeView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import SwiftUI

struct RefinementModeView: View {
    @State private var selectedMode: RefinementMode = .email
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text("Refinement Mode")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Radio button group with proper grouping and spacing
            VStack(alignment: .leading, spacing: 4) {
                RefinementModeButton(
                    mode: .email,
                    selectedMode: $selectedMode,
                    title: "Email Mode"
                )
                
                RefinementModeButton(
                    mode: .cleanup,
                    selectedMode: $selectedMode,
                    title: "Clean-up Mode"
                )
                
                RefinementModeButton(
                    mode: .professional,
                    selectedMode: $selectedMode,
                    title: "Professional"
                )
                
                RefinementModeButton(
                    mode: .raw,
                    selectedMode: $selectedMode,
                    title: "Raw Transcription"
                )
            }
            .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RefinementModeButton: View {
    let mode: RefinementMode
    @Binding var selectedMode: RefinementMode
    let title: String
    
    var body: some View {
        Button(action: {
            selectedMode = mode
        }) {
            HStack(spacing: 6) {
                Image(systemName: selectedMode == mode ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selectedMode == mode ? .accentColor : .secondary)
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

enum RefinementMode: String, CaseIterable, Codable, Sendable {
    case email
    case cleanup
    case professional
    case raw
}

#Preview {
    RefinementModeView()
        .padding()
}