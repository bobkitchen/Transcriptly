//
//  ResponsiveContentWrapper.swift
//  Transcriptly
//
//  Created by Claude Code on 1/3/25.
//  Phase 10.2 - Responsive content wrapper that adapts to sidebar state
//

import SwiftUI

struct ResponsiveContentWrapper: View {
    @Binding var selectedSection: SidebarSection
    @ObservedObject var viewModel: AppViewModel
    let onFloat: () -> Void
    let sidebarCollapsed: Bool
    let contentLeadingPadding: CGFloat
    
    // Track available width for smart reflow
    @State private var contentWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                switch selectedSection {
                case .home:
                    ResponsiveHomeWrapper(
                        viewModel: viewModel,
                        selectedSection: $selectedSection,
                        onFloat: onFloat,
                        availableWidth: geometry.size.width,
                        sidebarCollapsed: sidebarCollapsed
                    )
                case .dictation:
                    ResponsiveDictationWrapper(
                        viewModel: viewModel,
                        onFloat: onFloat,
                        availableWidth: geometry.size.width
                    )
                case .fileTranscription:
                    ResponsiveFileTranscriptionWrapper(
                        availableWidth: geometry.size.width
                    )
                case .readAloud:
                    ResponsiveReadAloudWrapper(
                        availableWidth: geometry.size.width
                    )
                case .learning:
                    ResponsiveLearningWrapper(
                        availableWidth: geometry.size.width
                    )
                case .settings:
                    ResponsiveSettingsWrapper(
                        viewModel: viewModel,
                        onFloat: onFloat,
                        availableWidth: geometry.size.width
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.leading, contentLeadingPadding)
            .animation(DesignSystem.gentleSpring, value: sidebarCollapsed)
            .onAppear {
                contentWidth = geometry.size.width
            }
            .onChange(of: geometry.size.width) { newWidth in
                contentWidth = newWidth
            }
        }
    }
}

// Responsive wrapper for HomeView
struct ResponsiveHomeWrapper: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var selectedSection: SidebarSection
    let onFloat: () -> Void
    let availableWidth: CGFloat
    let sidebarCollapsed: Bool
    
    var body: some View {
        HomeView(
            viewModel: viewModel,
            selectedSection: $selectedSection,
            onFloat: onFloat
        )
        .environment(\.availableWidth, availableWidth)
        .environment(\.sidebarCollapsed, sidebarCollapsed)
    }
}

// Responsive wrapper for TranscriptionView (Dictation)
struct ResponsiveDictationWrapper: View {
    @ObservedObject var viewModel: AppViewModel
    let onFloat: () -> Void
    let availableWidth: CGFloat
    
    var body: some View {
        TranscriptionView(
            viewModel: viewModel,
            onFloat: onFloat
        )
        .environment(\.availableWidth, availableWidth)
    }
}

// Responsive wrapper for ReadAloudView
struct ResponsiveReadAloudWrapper: View {
    let availableWidth: CGFloat
    
    var body: some View {
        ReadAloudView()
            .environment(\.availableWidth, availableWidth)
    }
}

// Responsive wrapper for LearningView
struct ResponsiveLearningWrapper: View {
    let availableWidth: CGFloat
    
    var body: some View {
        LearningView()
            .environment(\.availableWidth, availableWidth)
    }
}

// Responsive wrapper for FileTranscriptionView
struct ResponsiveFileTranscriptionWrapper: View {
    let availableWidth: CGFloat
    
    var body: some View {
        FileTranscriptionView()
            .environment(\.availableWidth, availableWidth)
    }
}

// Responsive wrapper for SettingsView
struct ResponsiveSettingsWrapper: View {
    @ObservedObject var viewModel: AppViewModel
    let onFloat: () -> Void
    let availableWidth: CGFloat
    
    var body: some View {
        SettingsView(viewModel: viewModel, onFloat: onFloat)
            .environment(\.availableWidth, availableWidth)
    }
}

// Environment keys for responsive layout
private struct AvailableWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 800
}

private struct SidebarCollapsedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

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