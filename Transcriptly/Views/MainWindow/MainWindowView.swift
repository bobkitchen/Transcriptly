//
//  MainWindowView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import SwiftUI

struct MainWindowView: View {
    @StateObject var viewModel = AppViewModel()
    @State private var selectedSection: SidebarSection = .home
    @State private var showCapsuleMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Persistent Top Bar
            TopBar(
                viewModel: viewModel,
                showCapsuleMode: $showCapsuleMode
            )
            
            // Main Content
            HStack(spacing: 0) {
                SidebarView(selectedSection: $selectedSection)
                
                Divider()
                    .background(Color.dividerColor)
                
                MainContentView(
                    selectedSection: $selectedSection,
                    viewModel: viewModel
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Color.primaryBackground)
        .sheet(isPresented: $showCapsuleMode) {
            CapsuleView(viewModel: viewModel)
        }
    }
}

#Preview {
    MainWindowView()
}