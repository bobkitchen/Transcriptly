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
    
    var body: some View {
        Group {
            switch selectedSection {
            case .home:
                HomeView(viewModel: viewModel)
            case .transcription:
                TranscriptionView(viewModel: viewModel)
            case .aiProviders:
                AIProvidersView()
            case .learning:
                LearningView()
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}