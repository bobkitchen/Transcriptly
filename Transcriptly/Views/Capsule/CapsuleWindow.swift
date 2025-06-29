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
            contentRect: NSRect(x: 0, y: 0, width: Int(CapsuleDesignSystem.minimalSize.width), height: Int(CapsuleDesignSystem.minimalSize.height)),
            styleMask: [.borderless],
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
        
        let capsuleContainerView = CapsuleContainerView(
            viewModel: viewModel,
            onExpand: {
                // Expand window size for expanded state
                self.setWindowSize(expanded: true)
            },
            onCollapse: {
                // Shrink window size for minimal state
                self.setWindowSize(expanded: false)
            },
            onClose: {
                viewModel.capsuleController.exitCapsuleMode()
            }
        )
        window.contentView = NSHostingView(rootView: capsuleContainerView)
        
        // Position at top center
        positionAtTopCenter()
    }
    
    func updateRecordingState(_ isRecording: Bool) {
        // The CapsuleContainerView will handle state updates automatically through @ObservedObject
        // No need to recreate the content view
    }
    
    private func setWindowSize(expanded: Bool) {
        guard let window = window else { return }
        
        let newSize: NSSize
        if expanded {
            newSize = NSSize(width: CapsuleDesignSystem.expandedSize.width, height: CapsuleDesignSystem.expandedSize.height)
        } else {
            newSize = NSSize(width: CapsuleDesignSystem.minimalSize.width, height: CapsuleDesignSystem.minimalSize.height)
        }
        
        // Get current frame and calculate new frame
        let currentFrame = window.frame
        let newFrame = NSRect(
            x: currentFrame.midX - newSize.width / 2,  // Keep centered horizontally
            y: currentFrame.maxY - newSize.height,     // Keep top edge at same position
            width: newSize.width,
            height: newSize.height
        )
        
        // Animate the resize
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
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