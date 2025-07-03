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
    @AppStorage("isSidebarCollapsed") private var isSidebarCollapsed = false
    
    init() {
        let vm = AppViewModel()
        self._viewModel = StateObject(wrappedValue: vm)
        self._capsuleManager = StateObject(wrappedValue: CapsuleWindowManager(viewModel: vm))
    }
    
    // Calculate dynamic content padding when sidebar is collapsed
    private var contentLeadingPadding: CGFloat {
        isSidebarCollapsed ? DesignSystem.marginStandard : 0
    }
    
    // Adjust minimum window width based on sidebar state
    private var minimumWindowWidth: CGFloat {
        isSidebarCollapsed ? 600 : 800
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Sidebar - fixed width based on state
            FloatingSidebar(
                selectedSection: $selectedSection,
                isCollapsed: $isSidebarCollapsed
            )
            .frame(width: isSidebarCollapsed ? 68 : 220)
            .padding(.leading, 16)
            .padding(.vertical, 16)
            .animation(DesignSystem.gentleSpring, value: isSidebarCollapsed)
            
            // Main content fills remaining space
            ResponsiveContentWrapper(
                selectedSection: $selectedSection,
                viewModel: viewModel,
                onFloat: capsuleManager.showCapsule,
                sidebarCollapsed: isSidebarCollapsed,
                contentLeadingPadding: contentLeadingPadding
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 16)
            .padding(.trailing, 16)
            .animation(DesignSystem.gentleSpring, value: isSidebarCollapsed)
        }
        .frame(minWidth: minimumWindowWidth, minHeight: 640)
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