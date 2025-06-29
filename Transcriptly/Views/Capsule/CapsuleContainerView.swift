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
                    isExpanded = true
                }
            }
        }
    }
    
    // MARK: - Hover Handling
    
    private func handleHover(_ hovering: Bool) {
        // Cancel any pending debounce task
        hoverDebounceTask?.cancel()
        
        isHovered = hovering
        
        if hovering {
            // Expand immediately on hover
            if !isExpanded {
                isExpanded = true
            }
        } else {
            // Only collapse if not recording
            if !viewModel.isRecording {
                // Brief debounce to prevent flicker
                hoverDebounceTask = Task {
                    try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                    
                    await MainActor.run {
                        if !isHovered && !viewModel.isRecording {
                            isExpanded = false
                        }
                    }
                }
            }
        }
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