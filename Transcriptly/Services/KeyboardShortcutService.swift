//
//  KeyboardShortcutService.swift
//  Transcriptly
//
//  Bridge between legacy code and new ShortcutManager
//

import Foundation
import AppKit
import Combine

@MainActor
final class KeyboardShortcutService: ObservableObject {
    var onShortcutPressed: (@MainActor () -> Void)?
    var onCancelPressed: (@MainActor () -> Void)?
    
    private var isRecording: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setRecordingState(_ recording: Bool) {
        isRecording = recording
    }
    
    private func setupNotificationObservers() {
        // Listen for toggle recording notification from ShortcutManager
        NotificationCenter.default.addObserver(
            forName: .toggleRecording,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.onShortcutPressed?()
            }
        }
        
        // Listen for cancel recording notification
        NotificationCenter.default.addObserver(
            forName: .cancelRecording,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                if self?.isRecording == true {
                    self?.onCancelPressed?()
                }
            }
        }
        
        // Listen for mode switching shortcuts
        NotificationCenter.default.addObserver(
            forName: .switchRefinementMode,
            object: nil,
            queue: .main
        ) { notification in
            if let mode = notification.object as? RefinementMode {
                // Post notification for mode switching - this will be handled by AppViewModel
                NotificationCenter.default.post(
                    name: Notification.Name("SwitchToRefinementMode"),
                    object: mode
                )
            }
        }
    }
}