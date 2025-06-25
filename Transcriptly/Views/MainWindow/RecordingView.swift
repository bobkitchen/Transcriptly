//
//  RecordingView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import SwiftUI

struct RecordingView: View {
    var body: some View {
        VStack(spacing: 8) {
            // Large record button with SF Symbol
            Button(action: {
                // Non-functional for now
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.circle.fill")
                        .font(.title2)
                    Text("Start Recording")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .help("Click to start recording or use ⌘⇧V")
            
            // Keyboard shortcut display using SF Mono
            Text("⌘⇧V")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    RecordingView()
        .padding()
}