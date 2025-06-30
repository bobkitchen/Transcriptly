//
//  FullWidthContentView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//  Apple Pattern Implementation - Full Width Content Container
//

import SwiftUI

struct FullWidthContentView: View {
    @Binding var selectedSection: SidebarSection
    @ObservedObject var viewModel: AppViewModel
    let onFloat: () -> Void
    
    var body: some View {
        switch selectedSection {
        case .home:
            HomeView(viewModel: viewModel, onFloat: onFloat)
        case .dictation:
            TranscriptionView(viewModel: viewModel, onFloat: onFloat)
        case .readAloud:
            ReadAloudView()
        case .aiProviders:
            AIProvidersView()
        case .learning:
            LearningView()
        case .settings:
            SettingsView(viewModel: viewModel, onFloat: onFloat)
        }
    }
}

#Preview {
    FullWidthContentView(
        selectedSection: .constant(.home),
        viewModel: AppViewModel(),
        onFloat: {}
    )
}