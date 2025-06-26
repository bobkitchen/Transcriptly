//
//  LearningView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct LearningView: View {
    @State private var isLearningEnabled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Learning")
                .font(.title)
                .fontWeight(.semibold)
            
            HStack {
                Toggle("Enable Learning", isOn: $isLearningEnabled)
                    .disabled(true)
                
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text("Learning features will help improve transcription accuracy based on your corrections and preferences.")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    LearningView()
}