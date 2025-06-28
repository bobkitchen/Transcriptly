//
//  FloatingCapsuleController.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Capsule Interface Overhaul - Floating Window Controller
//

import AppKit
import SwiftUI
import Combine

/// NSWindowController for the floating capsule with proper window management
class FloatingCapsuleController: NSWindowController, ObservableObject {
    private let viewModel: AppViewModel
    private let screenPositioning = ScreenPositioning()
    private var cancellables = Set<AnyCancellable>()
    @Published var isExpanded = false
    
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        
        // Create floating window with minimal size initially
        let window = NSWindow(
            contentRect: NSRect(
                origin: .zero,
                size: CapsuleDesignSystem.minimalSize
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        setupWindow()
        setupContentView()
        positionWindow()
        setupBindings()
        
        print("FloatingCapsuleController: Initialized")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Window Setup
    
    private func setupWindow() {
        guard let window = window else { return }
        
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false // We handle shadows in SwiftUI
        window.isMovableByWindowBackground = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        
        // Prevent activation to maintain floating behavior
        window.styleMask.insert(.nonactivatingPanel)
        
        print("FloatingCapsuleController: Window configured")
    }
    
    private func setupContentView() {
        guard let window = window else { return }
        
        let capsuleView = CapsuleContainerView(
            viewModel: viewModel,
            onExpand: { [weak self] in
                self?.expandCapsule()
            },
            onCollapse: { [weak self] in
                self?.collapseCapsule()
            },
            onClose: { [weak self] in
                self?.closeCapsule()
            }
        )
        
        window.contentView = NSHostingView(rootView: capsuleView)
        print("FloatingCapsuleController: Content view set")
    }
    
    private func setupBindings() {
        // Monitor screen position changes
        screenPositioning.$capsulePosition
            .receive(on: DispatchQueue.main)
            .sink { [weak self] position in
                self?.updateWindowPosition(to: position)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Positioning
    
    private func positionWindow() {
        screenPositioning.updatePosition()
    }
    
    private func updateWindowPosition(to position: CGPoint) {
        guard let window = window else { return }
        
        let currentSize = window.frame.size
        let newFrame = NSRect(origin: position, size: currentSize)
        
        // Only update if position actually changed to avoid unnecessary updates
        if !window.frame.origin.equalTo(position) {
            window.setFrame(newFrame, display: true, animate: false)
            print("FloatingCapsuleController: Updated position to \(position)")
        }
    }
    
    // MARK: - Expansion/Collapse
    
    func expandCapsule() {
        guard let window = window, !isExpanded else { return }
        
        print("FloatingCapsuleController: Expanding capsule")
        isExpanded = true
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = CapsuleDesignSystem.expandDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            let newSize = CapsuleDesignSystem.expandedSize
            let currentOrigin = window.frame.origin
            
            // Calculate new position to keep centered during expansion
            let newPosition = screenPositioning.calculateExpandedPosition(from: currentOrigin)
            
            window.animator().setFrame(
                NSRect(origin: newPosition, size: newSize),
                display: true
            )
        }
    }
    
    func collapseCapsule() {
        guard let window = window, isExpanded else { return }
        
        print("FloatingCapsuleController: Collapsing capsule")
        isExpanded = false
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = CapsuleDesignSystem.expandDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            let newSize = CapsuleDesignSystem.minimalSize
            let currentOrigin = window.frame.origin
            
            // Calculate new position to keep centered during collapse
            let newPosition = screenPositioning.calculateCollapsedPosition(from: currentOrigin)
            
            window.animator().setFrame(
                NSRect(origin: newPosition, size: newSize),
                display: true
            )
        }
    }
    
    // MARK: - Window Management
    
    private func closeCapsule() {
        print("FloatingCapsuleController: Closing capsule")
        window?.close()
        
        // Signal to main app that capsule closed
        NotificationCenter.default.post(name: .capsuleClosed, object: nil)
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        positionWindow()
        print("FloatingCapsuleController: Window shown")
    }
    
    // MARK: - Debug Info
    
    func getDebugInfo() -> String {
        guard let window = window else { return "No window" }
        
        return """
        FloatingCapsuleController Debug Info:
        - Window Frame: \(window.frame)
        - Is Expanded: \(isExpanded)
        - Window Level: \(window.level.rawValue)
        - Is Visible: \(window.isVisible)
        
        \(screenPositioning.getScreenInfo())
        """
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let capsuleClosed = Notification.Name("capsuleClosed")
    static let capsuleExpanded = Notification.Name("capsuleExpanded")
    static let capsuleCollapsed = Notification.Name("capsuleCollapsed")
}