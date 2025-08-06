//
//  EnvironmentKeys.swift
//  Transcriptly
//
//  Created by Claude Code on 8/6/25.
//

import SwiftUI

// Define custom environment keys
private struct AvailableWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 800
}

private struct SidebarCollapsedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

// Extend EnvironmentValues
extension EnvironmentValues {
    var availableWidth: CGFloat {
        get { self[AvailableWidthKey.self] }
        set { self[AvailableWidthKey.self] = newValue }
    }
    
    var sidebarCollapsed: Bool {
        get { self[SidebarCollapsedKey.self] }
        set { self[SidebarCollapsedKey.self] = newValue }
    }
}