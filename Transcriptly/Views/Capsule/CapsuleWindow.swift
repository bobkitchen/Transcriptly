//
//  CapsuleWindow.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI
import AppKit
import Combine

class CapsuleWindowController: NSWindowController {
    private weak var viewModel: AppViewModel?
    
    convenience init(viewModel: AppViewModel) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 150, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.init(window: window)
        self.viewModel = viewModel
        
        let expandedCapsuleView = ExpandedCapsuleView(
            viewModel: viewModel,
            onHover: { _ in },
            onClose: {
                viewModel.capsuleController.exitCapsuleMode()
            }
        )
        window.contentView = NSHostingView(rootView: expandedCapsuleView)
        
        // Position at top center
        positionAtTopCenter()
    }
    
    func updateRecordingState(_ isRecording: Bool) {
        // Force update the window content
        if let viewModel = viewModel {
            let expandedCapsuleView = ExpandedCapsuleView(
                viewModel: viewModel,
                onHover: { _ in },
                onClose: {
                    viewModel.capsuleController.exitCapsuleMode()
                }
            )
            window?.contentView = NSHostingView(rootView: expandedCapsuleView)
        }
    }
    
    private func positionAtTopCenter() {
        guard let window = window,
              let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        
        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.maxY - windowFrame.height - 20
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}