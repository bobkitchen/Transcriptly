//
//  RefinementModeView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//  Updated by Claude Code on 6/26/25 for Phase 2.
//

import SwiftUI

struct RefinementModeView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Refinement mode selection using Picker
            Picker("Refinement Mode", selection: $viewModel.currentRefinementMode) {
                ForEach(RefinementMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(RadioGroupPickerStyle())
            
            // Processing indicator
            if viewModel.isRefinementProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Refining...")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    RefinementModeView(viewModel: AppViewModel())
        .padding()
}