//
//  CapsuleContainerView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Capsule Interface Overhaul - Container with State Management
//

import SwiftUI

/// Container view that manages capsule state transitions between minimal and expanded
struct CapsuleContainerView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isExpanded = false
    @State private var isHovered = false
    @State private var hoverDebounceTask: Task<Void, Never>?
    
    let onExpand: () -> Void
    let onCollapse: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        Group {
            if isExpanded {
                ExpandedCapsuleView(
                    viewModel: viewModel,
                    onHover: handleHover,
                    onClose: onClose
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
            } else {
                MinimalCapsuleView(
                    onHover: handleHover
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 1.2).combined(with: .opacity),
                    removal: .scale(scale: 1.2).combined(with: .opacity)
                ))
            }
        }
        .animation(CapsuleDesignSystem.springAnimation, value: isExpanded)
        .onChange(of: isExpanded) { _, newValue in
            if newValue {
                onExpand()
            } else {
                onCollapse()
            }
        }
        .onChange(of: viewModel.isRecording) { _, isRecording in
            // Keep expanded while recording
            if isRecording {
                if !isExpanded {
                    print("CapsuleContainer: Expanding for recording")
                    isExpanded = true
                }
            }
        }
    }
    
    // MARK: - Hover Handling
    
    private func handleHover(_ hovering: Bool) {
        // Cancel any pending debounce task
        hoverDebounceTask?.cancel()
        
        print("CapsuleContainer: Hover state: \(hovering), Recording: \(viewModel.isRecording), Current isHovered: \(isHovered)")
        
        if hovering {
            // Update hover state immediately
            isHovered = true
            
            // Expand immediately on hover
            if !isExpanded {
                print("CapsuleContainer: Expanding on hover")
                isExpanded = true
            }
        } else {
            // Debounce hover leave to prevent rapid toggling
            hoverDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms debounce for stability
                
                await MainActor.run {
                    // Check if we're still not hovered after debounce period
                    let currentMouseLocation = NSEvent.mouseLocation
                    let shouldCollapse = !viewModel.isRecording && !isMouseInCapsuleArea(currentMouseLocation)
                    
                    if shouldCollapse && isExpanded {
                        print("CapsuleContainer: Collapsing after confirmed hover leave")
                        isHovered = false
                        isExpanded = false
                    }
                }
            }
        }
    }
    
    // Helper to check if mouse is in the capsule area (with buffer)
    private func isMouseInCapsuleArea(_ mouseLocation: CGPoint) -> Bool {
        // Get the current window frame and add a buffer area
        guard let window = NSApp.windows.first(where: { $0.contentView is NSHostingView<CapsuleContainerView> }) else {
            return false
        }
        
        let windowFrame = window.frame
        let buffer: CGFloat = 20 // Buffer area around capsule
        let expandedFrame = CGRect(
            x: windowFrame.minX - buffer,
            y: windowFrame.minY - buffer,
            width: windowFrame.width + (buffer * 2),
            height: windowFrame.height + (buffer * 2)
        )
        
        return expandedFrame.contains(mouseLocation)
    }
}

#Preview("Minimal State") {
    ZStack {
        Rectangle()
            .fill(.black.opacity(0.8))
            .ignoresSafeArea()
        
        CapsuleContainerView(
            viewModel: AppViewModel(),
            onExpand: { print("Expanded") },
            onCollapse: { print("Collapsed") },
            onClose: { print("Closed") }
        )
    }
    .frame(width: 200, height: 100)
}

#Preview("Expanded State") {
    ZStack {
        Rectangle()
            .fill(.black.opacity(0.8))
            .ignoresSafeArea()
        
        ExpandedCapsuleView(
            viewModel: AppViewModel(),
            onHover: { _ in },
            onClose: { print("Closed") }
        )
    }
    .frame(width: 300, height: 200)
}