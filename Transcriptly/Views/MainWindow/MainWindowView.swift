//
//  MainWindowView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedSection: SidebarSection = .home
    
    var body: some View {
        VStack(spacing: 0) {
            // Subtle Top Bar
            TopBar(
                viewModel: viewModel,
                showCapsuleMode: {
                    // Use the viewModel's capsule controller
                    viewModel.capsuleController.enterCapsuleMode()
                }
            )
            
            // Main Content with sidebar getting visual priority
            HStack(spacing: 0) {
                // Prominent sidebar
                SidebarView(selectedSection: $selectedSection)
                
                // Main content area
                MainContentView(
                    selectedSection: $selectedSection,
                    viewModel: viewModel
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 920, minHeight: 640) // Adjusted for new layout
        .background(Color.primaryBackground)
    }
}

#Preview {
    MainWindowView()
}