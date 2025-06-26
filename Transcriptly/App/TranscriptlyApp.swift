//
//  TranscriptlyApp.swift
//  Transcriptly
//
//  Created by Bob Kitchen on 6/25/25.
//

import SwiftUI

@main
struct TranscriptlyApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    init() {
        // Initialize menu bar on app startup
        _ = MenuBarController()
    }
    
    var body: some Scene {
        WindowGroup("Transcriptly") {
            MainWindowView()
                .environmentObject(appViewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .windowResizability(.contentSize)
    }
}
