//
//  MainContentView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

@available(macOS 26.0, *)
struct MainContentView: View {
    @Binding var selectedSection: SidebarSection
    @ObservedObject var viewModel: AppViewModel
    let onFloat: () -> Void
    
    var body: some View {
        Group {
            switch selectedSection {
            case .home:
                HomeView(viewModel: viewModel, selectedSection: $selectedSection, onFloat: onFloat)
            case .transcription:
                TranscriptionView(viewModel: viewModel, onFloat: onFloat)
            case .dictation:
                FileTranscriptionView()
            case .aiProviders:
                AIProvidersView()
            case .learning:
                LearningView()
            case .settings:
                SettingsView(viewModel: viewModel, onFloat: onFloat)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}