//
//  TranscriptlyApp.swift
//  Transcriptly
//
//  Created by Bob Kitchen on 6/25/25.
//

import SwiftUI
import Combine

@main
struct TranscriptlyApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var menuBarController = MenuBarController()
    
    init() {
        // Menu bar controller will be connected to app view model in body
    }
    
    var body: some Scene {
        WindowGroup("Transcriptly") {
            MainWindowView()
                .environmentObject(appViewModel)
                .onAppear {
                    // Connect menu bar controller to app view model
                    connectMenuBarToAppViewModel()
                }
                // Note: Learning windows are now proper NSWindows instead of sheets
                // to support capsule mode presentation
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .windowResizability(.contentSize)
    }
    
    private func connectMenuBarToAppViewModel() {
        // Observe recording state changes and update menu bar
        appViewModel.$isRecording
            .sink { isRecording in
                menuBarController.setRecordingState(isRecording)
            }
            .store(in: &appViewModel.cancellables)
        
        // Observe transcribing state changes and update menu bar
        appViewModel.$isTranscribing
            .sink { isTranscribing in
                menuBarController.setProcessingState(isTranscribing)
            }
            .store(in: &appViewModel.cancellables)
    }
}
