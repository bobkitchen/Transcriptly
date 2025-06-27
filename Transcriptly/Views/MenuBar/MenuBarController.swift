//
//  MenuBarController.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import SwiftUI
import AppKit
import Combine

final class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var waveformView: MenuBarWaveformView?
    private var cancellables = Set<AnyCancellable>()
    private var isRecording = false
    
    init() {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        DispatchQueue.main.async { [weak self] in
            // Create status item with microphone icon
            self?.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            
            guard let statusItem = self?.statusItem else { return }
            
            // Set up menu bar icon
            if let button = statusItem.button {
                button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Transcriptly")
                button.imagePosition = .imageOnly
            }
            
            // Create menu
            let menu = NSMenu()
            
            // "Show Transcriptly" menu item
            let showAppItem = NSMenuItem(
                title: "Show Transcriptly",
                action: #selector(self?.showMainWindow),
                keyEquivalent: ""
            )
            showAppItem.target = self
            menu.addItem(showAppItem)
            
            // Separator
            menu.addItem(.separator())
            
            // "Quit" menu item
            let quitItem = NSMenuItem(
                title: "Quit",
                action: #selector(self?.quitApp),
                keyEquivalent: "q"
            )
            quitItem.target = self
            menu.addItem(quitItem)
            
            statusItem.menu = menu
        }
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
        DispatchQueue.main.async { [weak self] in
            self?.updateMenuBarIcon()
        }
    }
    
    private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }
        
        if isRecording {
            // Show animated waveform
            setupWaveformView()
        } else {
            // Show static microphone icon
            waveformView?.removeFromSuperview()
            waveformView = nil
            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Transcriptly")
            button.imagePosition = .imageOnly
        }
    }
    
    private func setupWaveformView() {
        guard let button = statusItem?.button else { return }
        
        // Remove existing waveform if any
        waveformView?.removeFromSuperview()
        
        // Create and add waveform view
        let waveform = MenuBarWaveformView(frame: NSRect(x: 0, y: 0, width: 40, height: 22))
        waveformView = waveform
        
        // Clear the button image and add waveform as subview
        button.image = nil
        button.addSubview(waveform)
        
        // Center the waveform in the button
        waveform.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            waveform.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            waveform.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            waveform.widthAnchor.constraint(equalToConstant: 40),
            waveform.heightAnchor.constraint(equalToConstant: 22)
        ])
        
        waveform.startAnimating()
    }
    
    deinit {
        waveformView?.stopAnimating()
        statusItem?.isVisible = false
        statusItem = nil
    }
}