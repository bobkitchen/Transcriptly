//
//  CapsuleWindowManager.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Capsule Interface Overhaul - Integration with Main App
//

import Foundation
import AppKit
import Combine

/// Manages the floating capsule window lifecycle and integration with main app
class CapsuleWindowManager: ObservableObject {
    @Published var isCapsuleVisible = false
    
    private var capsuleController: FloatingCapsuleController?
    private let viewModel: AppViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        setupNotificationObservers()
        print("CapsuleWindowManager: Initialized")
    }
    
    deinit {
        hideCapsule()
        print("CapsuleWindowManager: Deinitialized")
    }
    
    // MARK: - Capsule Management
    
    /// Show the floating capsule window
    func showCapsule() {
        guard capsuleController == nil else {
            print("CapsuleWindowManager: Capsule already visible")
            return
        }
        
        print("CapsuleWindowManager: Creating and showing capsule")
        capsuleController = FloatingCapsuleController(viewModel: viewModel)
        capsuleController?.showWindow(nil)
        isCapsuleVisible = true
        
        // Hide main window when capsule is shown
        hideMainWindow()
    }
    
    /// Hide the floating capsule window
    func hideCapsule() {
        guard let controller = capsuleController else {
            print("CapsuleWindowManager: No capsule to hide")
            return
        }
        
        print("CapsuleWindowManager: Hiding capsule")
        controller.close()
        capsuleController = nil
        isCapsuleVisible = false
        
        // Restore main window when capsule is hidden
        showMainWindow()
    }
    
    /// Toggle capsule visibility
    func toggleCapsule() {
        if isCapsuleVisible {
            hideCapsule()
        } else {
            showCapsule()
        }
    }
    
    // MARK: - Main Window Management
    
    private func hideMainWindow() {
        // Find and hide the main Transcriptly window
        for window in NSApp.windows {
            if window.title.contains("Transcriptly") || 
               window.contentView?.className.contains("MainWindow") == true {
                print("CapsuleWindowManager: Hiding main window: \(window.title)")
                window.orderOut(nil)
                break
            }
        }
    }
    
    private func showMainWindow() {
        // Find and show the main Transcriptly window
        for window in NSApp.windows {
            if window.title.contains("Transcriptly") || 
               window.contentView?.className.contains("MainWindow") == true {
                print("CapsuleWindowManager: Showing main window: \(window.title)")
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                break
            }
        }
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // Listen for capsule close notifications
        NotificationCenter.default.publisher(for: .capsuleClosed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("CapsuleWindowManager: Received capsule closed notification")
                self?.handleCapsuleClosed()
            }
            .store(in: &cancellables)
        
        // Listen for app termination
        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("CapsuleWindowManager: App terminating, cleaning up capsule")
                self?.hideCapsule()
            }
            .store(in: &cancellables)
    }
    
    private func handleCapsuleClosed() {
        capsuleController = nil
        isCapsuleVisible = false
        showMainWindow()
    }
    
    // MARK: - Debug Info
    
    func getDebugInfo() -> String {
        return """
        CapsuleWindowManager Debug Info:
        - Is Capsule Visible: \(isCapsuleVisible)
        - Has Controller: \(capsuleController != nil)
        - Main Windows Count: \(NSApp.windows.count)
        
        \(capsuleController?.getDebugInfo() ?? "No capsule controller")
        """
    }
}

// MARK: - Extension for Main App Integration

extension CapsuleWindowManager {
    /// Check if capsule mode is supported on current system
    var isCapsuleModeSupported: Bool {
        // Capsule mode requires macOS 11.0+ for proper floating window support
        if #available(macOS 11.0, *) {
            return true
        } else {
            return false
        }
    }
    
    /// Get current capsule state for UI updates
    var capsuleState: CapsuleState {
        if !isCapsuleModeSupported {
            return .unsupported
        } else if isCapsuleVisible {
            return .visible
        } else {
            return .hidden
        }
    }
}

enum CapsuleState {
    case unsupported
    case hidden
    case visible
}