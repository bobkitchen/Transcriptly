//
//  MainWindowView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import SwiftUI

struct MainWindowView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area with proper margins (20pt)
            VStack(spacing: 16) {
                // Recording section
                RecordingView()
                    .environmentObject(viewModel)
                
                Divider()
                
                // Refinement mode section
                RefinementModeView(viewModel: viewModel)
                
                Divider()
                
                // Options section
                OptionsView()
                
                Spacer()
            }
            .padding(20) // Standard 20pt margins
            
            // Status bar
            StatusView()
        }
        .frame(width: 400, height: 500) // Fixed window size as specified
        .background(Color(.windowBackgroundColor)) // Respects system appearance
    }
}

#Preview {
    MainWindowView()
}