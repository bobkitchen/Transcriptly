//
//  CapsuleController.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation
import AppKit
import Combine

class CapsuleController: ObservableObject {
    private var capsuleWindowController: CapsuleWindowController?
    @Published var isCapsuleModeActive = false
    private weak var viewModel: AppViewModel?
    private var storedMainWindow: NSWindow?
    private var recordingStateObserver: AnyCancellable?
    
    func setViewModel(_ viewModel: AppViewModel) {
        self.viewModel = viewModel
        
        // Subscribe to recording state changes to keep capsule in sync
        recordingStateObserver = viewModel.$isRecording
            .sink { [weak self] isRecording in
                // Force update the capsule window if it exists
                if self?.isCapsuleModeActive == true {
                    self?.capsuleWindowController?.updateRecordingState(isRecording)
                }
            }
    }
    
    func enterCapsuleMode() {
        guard capsuleWindowController == nil,
              let viewModel = viewModel else { return }
        
        // Store reference to current main window
        storedMainWindow = NSApp.mainWindow
        
        capsuleWindowController = CapsuleWindowController(viewModel: viewModel)
        capsuleWindowController?.showWindow(nil)
        isCapsuleModeActive = true
        
        // Hide main window
        storedMainWindow?.orderOut(nil)
    }
    
    func exitCapsuleMode() {
        capsuleWindowController?.close()
        capsuleWindowController = nil
        isCapsuleModeActive = false
        
        // Restore main window
        if let mainWindow = storedMainWindow {
            mainWindow.makeKeyAndOrderFront(nil)
            storedMainWindow = nil
        } else {
            // Fallback: try to find and show any available window
            for window in NSApp.windows {
                if window.className.contains("MainWindow") || window.title.contains("Transcriptly") {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }
        }
    }
    
    func toggleCapsuleMode() {
        if isCapsuleModeActive {
            exitCapsuleMode()
        } else {
            enterCapsuleMode()
        }
    }
}