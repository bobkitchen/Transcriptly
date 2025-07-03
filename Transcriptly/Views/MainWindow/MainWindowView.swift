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
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Content area with dynamic padding
            FullWidthContentView(
                selectedSection: $selectedSection,
                viewModel: viewModel,
                onFloat: capsuleManager.showCapsule
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.leading, isSidebarCollapsed ? 100 : 252) // Adjust for sidebar width
            
            // Floating sidebar overlay
            FloatingSidebar(
                selectedSection: $selectedSection,
                isCollapsed: $isSidebarCollapsed
            )
        }
        .frame(minWidth: 800, minHeight: 640) // Adjusted for collapsible sidebar
        .background(Color.primaryBackground)
        .onReceive(NotificationCenter.default.publisher(for: .capsuleClosed)) { _ in
            // Bring main window to front when capsule closes
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .onAppear {
            // Set up keyboard shortcut for sidebar toggle
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // ⌘⌥S to toggle sidebar
                if event.modifierFlags.contains([.command, .option]) && event.charactersIgnoringModifiers == "s" {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.isSidebarCollapsed.toggle()
                    }
                    return nil
                }
                return event
            }
        }
    }
}

#Preview {
    MainWindowView()
}