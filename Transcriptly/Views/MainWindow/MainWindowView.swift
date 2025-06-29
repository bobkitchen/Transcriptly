//
//  MainWindowView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//  Updated by Claude Code on 6/29/25 for Phase 6 UI Polish - Inset Sidebar
//

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedSection: SidebarSection = .home
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Top Bar
            TopBar(
                viewModel: viewModel,
                showCapsuleMode: {
                    // Use the viewModel's capsule controller
                    viewModel.capsuleController.enterCapsuleMode()
                }
            )
            
            // NEW LAYOUT: Full-width content with floating inset sidebar
            ZStack(alignment: .leading) {
                // Full-width content area (extends behind sidebar)
                MainContentView(
                    selectedSection: $selectedSection,
                    viewModel: viewModel
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primaryBackground)
                
                // Floating inset sidebar (Apple 2024 standard)
                InsetSidebarView(selectedSection: $selectedSection)
                    .padding(.leading, UIPolishDesignSystem.sidebarInset)
                    .padding(.vertical, UIPolishDesignSystem.sidebarInset)
            }
        }
        .frame(minWidth: 920, minHeight: 640)
        .background(Color.primaryBackground)
    }
}

#Preview {
    MainWindowView()
}