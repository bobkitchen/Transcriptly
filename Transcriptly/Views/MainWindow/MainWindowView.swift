//
//  MainWindowView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import SwiftUI

struct MainWindowView: View {
    @StateObject var viewModel = AppViewModel()
    @StateObject private var capsuleManager: CapsuleWindowManager
    @State private var selectedSection: SidebarSection = .home
    
    init() {
        let vm = AppViewModel()
        self._viewModel = StateObject(wrappedValue: vm)
        self._capsuleManager = StateObject(wrappedValue: CapsuleWindowManager(viewModel: vm))
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Full-width content (no top bar)
            FullWidthContentView(
                selectedSection: $selectedSection,
                viewModel: viewModel,
                onFloat: capsuleManager.showCapsule
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Floating sidebar overlay
            FloatingSidebar(selectedSection: $selectedSection)
                .padding(.leading, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
        }
        .frame(minWidth: 920, minHeight: 640) // Adjusted for new layout
        .background(Color.primaryBackground)
        .onReceive(NotificationCenter.default.publisher(for: .capsuleClosed)) { _ in
            // Bring main window to front when capsule closes
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

#Preview {
    MainWindowView()
}