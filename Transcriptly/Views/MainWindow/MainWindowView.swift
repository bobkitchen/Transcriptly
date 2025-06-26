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
    
    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedSection: $selectedSection)
            
            Divider()
            
            MainContentView(
                selectedSection: $selectedSection,
                viewModel: viewModel
            )
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    MainWindowView()
}