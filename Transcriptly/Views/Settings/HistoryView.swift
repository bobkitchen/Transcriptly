//
//  HistoryView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    // TODO: Load actual history
    
    var body: some View {
        VStack {
            HStack {
                Text("Transcription History")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            // Placeholder for history list
            List {
                Text("History will appear here")
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 600, height: 400)
    }
}

#Preview {
    HistoryView()
}