//
//  View+Sidebar.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//

import SwiftUI

extension View {
    /// Adjusts content layout to account for floating sidebar overlay
    func adjustForFloatingSidebar() -> some View {
        self.padding(.leading, 260)  // 220 (sidebar) + 40 (margins)
    }
    
    /// Legacy method - maintained for compatibility
    func adjustForInsetSidebar() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}