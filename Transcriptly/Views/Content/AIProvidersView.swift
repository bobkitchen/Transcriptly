//
//  AIProvidersView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct AIProvidersView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cpu")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("AI Providers")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Cloud-based transcription and refinement options coming soon")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    AIProvidersView()
}