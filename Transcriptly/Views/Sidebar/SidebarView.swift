//
//  SidebarView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selectedSection: SidebarSection
    @State private var isCollapsed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapse button
            HStack {
                Button(action: { isCollapsed.toggle() }) {
                    Image(systemName: "sidebar.left")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
                
                if !isCollapsed {
                    Spacer()
                }
            }
            
            Divider()
            
            // Sidebar items
            VStack(spacing: 4) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    SidebarItemView(
                        section: section,
                        isSelected: selectedSection == section,
                        isCollapsed: isCollapsed
                    )
                    .onTapGesture {
                        if section.isEnabled {
                            selectedSection = section
                        }
                    }
                }
            }
            .padding(8)
            
            Spacer()
        }
        .frame(width: isCollapsed ? 60 : 200)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    SidebarView(selectedSection: .constant(.home))
        .frame(height: 500)
}