//
//  ScreenPositioning.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Capsule Interface Overhaul - Smart Screen Positioning
//

import AppKit
import Foundation
import Combine

/// Handles intelligent positioning of the floating capsule with notch detection
class ScreenPositioning: ObservableObject {
    @Published var capsulePosition: CGPoint = .zero
    @Published var currentScreen: NSScreen?
    
    private var screenMonitor: AnyCancellable?
    
    init() {
        updatePosition()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    /// Calculate optimal capsule position accounting for menu bar and notch
    func calculateCapsulePosition(for size: CGSize = CapsuleDesignSystem.minimalSize) -> CGPoint {
        guard let screen = NSScreen.main else {
            print("Warning: No main screen found, using fallback position")
            return CGPoint(x: 400, y: 100)
        }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        // Calculate top safe area (accounts for MacBook notches)
        let topSafeArea = screenFrame.maxY - visibleFrame.maxY
        let menuBarHeight = CapsuleDesignSystem.menuBarHeight
        
        // Position below the LOWER of: menu bar OR notch
        let topOffset = max(menuBarHeight, topSafeArea) + CapsuleDesignSystem.topMargin
        
        // Center horizontally on screen
        let x = screenFrame.midX - (size.width / 2)
        let y = screenFrame.maxY - topOffset - size.height
        
        let position = CGPoint(x: x, y: y)
        
        // Debug logging for positioning
        print("ScreenPositioning: Screen frame: \(screenFrame)")
        print("ScreenPositioning: Visible frame: \(visibleFrame)")
        print("ScreenPositioning: Top safe area: \(topSafeArea)")
        print("ScreenPositioning: Calculated position: \(position)")
        
        return position
    }
    
    /// Update the capsule position
    func updatePosition() {
        let newPosition = calculateCapsulePosition()
        
        DispatchQueue.main.async { [weak self] in
            self?.capsulePosition = newPosition
            self?.currentScreen = NSScreen.main
        }
    }
    
    /// Calculate position for expanded capsule (keeps centered during expansion)
    func calculateExpandedPosition(from currentPosition: CGPoint) -> CGPoint {
        let xOffset = CapsuleDesignSystem.centerOffset
        return CGPoint(x: currentPosition.x - xOffset, y: currentPosition.y)
    }
    
    /// Calculate position for collapsed capsule (keeps centered during collapse)
    func calculateCollapsedPosition(from currentPosition: CGPoint) -> CGPoint {
        let xOffset = CapsuleDesignSystem.centerOffset
        return CGPoint(x: currentPosition.x + xOffset, y: currentPosition.y)
    }
    
    /// Check if we're on a MacBook with notch
    private func hasNotch() -> Bool {
        guard let screen = NSScreen.main else { return false }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let topSafeArea = screenFrame.maxY - visibleFrame.maxY
        
        // If top safe area is significantly larger than standard menu bar, we likely have a notch
        return topSafeArea > CapsuleDesignSystem.menuBarHeight + 5
    }
    
    /// Start monitoring for screen changes
    private func startMonitoring() {
        // Monitor screen parameter changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("ScreenPositioning: Screen parameters changed, updating position")
            self?.updatePosition()
        }
        
        // Monitor active space changes
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("ScreenPositioning: Active space changed, updating position")
            self?.updatePosition()
        }
    }
    
    /// Stop monitoring screen changes
    private func stopMonitoring() {
        NotificationCenter.default.removeObserver(self)
        screenMonitor?.cancel()
    }
    
    /// Get screen info for debugging
    func getScreenInfo() -> String {
        guard let screen = NSScreen.main else {
            return "No main screen"
        }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let topSafeArea = screenFrame.maxY - visibleFrame.maxY
        let hasNotchDetected = hasNotch()
        
        return """
        Screen Info:
        - Frame: \(screenFrame)
        - Visible: \(visibleFrame)
        - Top Safe Area: \(topSafeArea)
        - Has Notch: \(hasNotchDetected)
        - Capsule Position: \(capsulePosition)
        """
    }
}