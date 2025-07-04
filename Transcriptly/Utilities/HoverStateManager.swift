//
//  HoverStateManager.swift
//  Transcriptly
//
//  Created by Claude Code on 1/4/25.
//  Phase 10.5 - Memory optimization for hover states
//

import SwiftUI
import Combine

/// Efficient hover state manager to prevent state conflicts and memory leaks
@MainActor
class HoverStateManager: ObservableObject {
    @Published private var hoveredElements: Set<String> = []
    
    /// Set the hover state for a specific element
    func setHovered(_ id: String, isHovered: Bool) {
        if isHovered {
            hoveredElements.insert(id)
        } else {
            hoveredElements.remove(id)
        }
    }
    
    /// Check if an element is currently hovered
    func isHovered(_ id: String) -> Bool {
        hoveredElements.contains(id)
    }
    
    /// Clear all hover states
    func clearAll() {
        hoveredElements.removeAll()
    }
    
    /// Remove specific hover state
    func removeHover(_ id: String) {
        hoveredElements.remove(id)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply managed hover state to a view
    func managedHover(_ id: String, manager: HoverStateManager, action: @escaping (Bool) -> Void = { _ in }) -> some View {
        self.onHover { hovering in
            manager.setHovered(id, isHovered: hovering)
            action(hovering)
        }
    }
}

// MARK: - Environment Key

private struct HoverStateManagerKey: EnvironmentKey {
    static let defaultValue = HoverStateManager()
}

extension EnvironmentValues {
    var hoverStateManager: HoverStateManager {
        get { self[HoverStateManagerKey.self] }
        set { self[HoverStateManagerKey.self] = newValue }
    }
}