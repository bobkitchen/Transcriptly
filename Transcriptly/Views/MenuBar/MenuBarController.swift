//
//  MenuBarController.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import SwiftUI
import AppKit
import Combine

enum MenuBarState {
    case idle
    case recording
    case processing
}

@MainActor
final class MenuBarController: ObservableObject {
    private nonisolated(unsafe) var statusItem: NSStatusItem?
    private var waveformView: MenuBarWaveformView?
    private var processingView: MenuBarProcessingView?
    private var cancellables = Set<AnyCancellable>()
    private var currentState: MenuBarState = .idle
    private var isRecording = false
    private var isProcessing = false
    
    init() {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        // Create status item with microphone icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else { return }
        
        // Set up initial idle state
        updateMenuBarIcon()
        
        // Create menu
        let menu = NSMenu()
        
        // "Show Transcriptly" menu item
        let showAppItem = NSMenuItem(
            title: "Show Transcriptly",
            action: #selector(showMainWindow),
            keyEquivalent: ""
        )
        showAppItem.target = self
        menu.addItem(showAppItem)
        
        // Separator
        menu.addItem(.separator())
        
        // "Quit" menu item
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func showMainWindow() {
        // Activate the app and show main window
        NSApp.activate(ignoringOtherApps: true)
        
        // Find and show the main window
        for window in NSApp.windows {
            if window.title == "Transcriptly" {
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    func setRecordingState(_ recording: Bool) {
        isRecording = recording
        updateState()
    }
    
    func setProcessingState(_ processing: Bool) {
        isProcessing = processing
        updateState()
    }
    
    private func updateState() {
        // Priority: recording > processing > idle
        if isRecording {
            currentState = .recording
        } else if isProcessing {
            currentState = .processing
        } else {
            currentState = .idle
        }
        
        updateMenuBarIcon()
    }
    
    private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }
        
        // Clean up any existing views
        cleanupViews()
        
        switch currentState {
        case .idle:
            setupIdleWaveform()
        case .recording:
            setupRecordingWaveform()
        case .processing:
            setupProcessingView()
        }
    }
    
    private func cleanupViews() {
        guard let button = statusItem?.button else { return }
        
        waveformView?.stopAnimating()
        waveformView?.removeFromSuperview()
        waveformView = nil
        
        processingView?.stopAnimating()
        processingView?.removeFromSuperview()
        processingView = nil
        
        button.image = nil
    }
    
    private func setupIdleWaveform() {
        guard let button = statusItem?.button else { return }
        
        let waveform = MenuBarWaveformView(frame: NSRect(x: 0, y: 0, width: 40, height: 22))
        waveform.setIdleState(true)
        waveformView = waveform
        
        button.addSubview(waveform)
        setupViewConstraints(for: waveform, in: button)
    }
    
    private func setupRecordingWaveform() {
        guard let button = statusItem?.button else { return }
        
        let waveform = MenuBarWaveformView(frame: NSRect(x: 0, y: 0, width: 40, height: 22))
        waveform.setIdleState(false)
        waveformView = waveform
        
        button.addSubview(waveform)
        setupViewConstraints(for: waveform, in: button)
        waveform.startAnimating()
    }
    
    private func setupProcessingView() {
        guard let button = statusItem?.button else { return }
        
        let processing = MenuBarProcessingView(frame: NSRect(x: 0, y: 0, width: 40, height: 22))
        processingView = processing
        
        button.addSubview(processing)
        setupViewConstraints(for: processing, in: button)
        processing.startAnimating()
    }
    
    private func setupViewConstraints(for view: NSView, in button: NSButton) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            view.widthAnchor.constraint(equalToConstant: 40),
            view.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    deinit {
        // Cleanup synchronously since this is deinit
        statusItem?.isVisible = false
        statusItem = nil
        // Note: cleanupViews() would need to be called before deinit externally
        // or we'd need to restructure to avoid MainActor requirement in cleanup
    }
}