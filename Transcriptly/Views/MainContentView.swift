//
//  MainContentView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct MainContentView: View {
    @Binding var selectedSection: SidebarSection
    @ObservedObject var viewModel: AppViewModel
    let onFloat: () -> Void  // Add this parameter
    
    var body: some View {
        Group {
            switch selectedSection {
            case .home:
                HomeView(viewModel: viewModel, onFloat: onFloat)
            case .transcription:
                TranscriptionView(viewModel: viewModel, onFloat: onFloat)
            case .aiProviders:
                AIProvidersView()
            case .learning:
                LearningView()
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
    }
}