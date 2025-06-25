//
//  MenuBarController.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import SwiftUI
import AppKit

final class MenuBarController {
    private var statusItem: NSStatusItem?
    
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
    
    deinit {
        statusItem?.isVisible = false
        statusItem = nil
    }
}