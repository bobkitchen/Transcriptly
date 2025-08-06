//
//  TranscriptionDetailWindow.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Window controller for displaying transcription details
//

import SwiftUI
import AppKit

class TranscriptionDetailWindowController: NSWindowController {
    private let transcription: TranscriptionRecord
    
    init(transcription: TranscriptionRecord) {
        self.transcription = transcription
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties
        window.title = "Transcription Details"
        window.level = .normal
        window.isOpaque = true
        window.backgroundColor = NSColor.controlBackgroundColor
        window.minSize = NSSize(width: 500, height: 600)
        window.maxSize = NSSize(width: 800, height: 1000)
        
        // Center the window
        window.center()
        
        super.init(window: window)
        
        // Create and set the content view
        let detailView = TranscriptionDetailView(transcription: transcription)
        window.contentView = NSHostingView(rootView: detailView)
        
        // Make window key and bring to front
        window.makeKeyAndOrderFront(nil)
        
        // Set window title with transcription info
        updateWindowTitle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateWindowTitle() {
        guard let window = window else { return }
        
        let title = transcription.mode.rawValue
        let timeAgo = formatTimeAgo(transcription.date)
        window.title = "Transcription: \(title) • \(timeAgo)"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Additional window configuration if needed
        window?.titlebarAppearsTransparent = false
        window?.titleVisibility = .visible
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

// MARK: - Window Management Helper

@MainActor
final class TranscriptionDetailWindowManager {
    static let shared = TranscriptionDetailWindowManager()
    
    private var openWindows: [UUID: TranscriptionDetailWindowController] = [:]
    
    private init() {}
    
    func showDetailWindow(for transcription: TranscriptionRecord) {
        // Check if window is already open for this transcription
        if let existingController = openWindows[transcription.id] {
            // Bring existing window to front
            existingController.window?.makeKeyAndOrderFront(nil)
            return
        }
        
        // Create new window
        let windowController = TranscriptionDetailWindowController(transcription: transcription)
        openWindows[transcription.id] = windowController
        
        // Set up window close observation to clean up
        if let window = windowController.window {
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.openWindows.removeValue(forKey: transcription.id)
                }
            }
        }
    }
    
    func closeDetailWindow(for transcriptionId: UUID) {
        if let controller = openWindows[transcriptionId] {
            controller.window?.close()
            openWindows.removeValue(forKey: transcriptionId)
        }
    }
    
    func closeAllDetailWindows() {
        for controller in openWindows.values {
            controller.window?.close()
        }
        openWindows.removeAll()
    }
}