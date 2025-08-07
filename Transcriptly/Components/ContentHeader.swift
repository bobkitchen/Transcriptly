//
//  ContentHeader.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Remove Top Bar Implementation - Content Header Component
//

import SwiftUI

struct ContentHeader: View {
    @ObservedObject var viewModel: AppViewModel
    let title: String
    let showModeControls: Bool
    let showFloatButton: Bool
    let onFloat: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Content title
            Text(title)
                .font(DesignSystem.Typography.pageTitle)
                .foregroundColor(.primaryText)
            
            Spacer()
            
            // Control group
            HStack(spacing: 12) {
                if showModeControls {
                    // Mode selector (compact version)
                    ModeSelector(currentMode: $viewModel.currentRefinementMode)
                    
                    // Record button (prominent)
                    HeaderRecordButton(
                        isRecording: viewModel.isRecording,
                        action: { 
                            Task { 
                                if viewModel.isRecording {
                                    _ = await viewModel.stopRecording()
                                } else {
                                    _ = await viewModel.startRecording()
                                }
                            }
                        }
                    )
                }
                
                if showFloatButton {
                    // Float button (subtle)
                    FloatButton(action: onFloat)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial.opacity(0.3)) // Very subtle background
    }
}

// Compact mode selector for content headers
struct ModeSelector: View {
    @Binding var currentMode: RefinementMode
    
    var body: some View {
        Menu {
            ForEach(RefinementMode.allCases, id: \.self) { mode in
                Button(action: { 
                    currentMode = mode
                    NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
                }) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.displayName)
                                .font(.system(size: 14, weight: .medium))
                            Text(mode.description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: mode.icon)
                            .foregroundColor(mode.accentColor)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: currentMode.icon)
                    .font(.system(size: 13))
                    .foregroundColor(currentMode.accentColor)
                
                Text(currentMode.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.tertiaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
        .menuStyle(.borderlessButton)
        .help("Switch refinement mode")
    }
}

// Compact record button for content headers
struct HeaderRecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 16))
                    .symbolRenderingMode(.hierarchical)
                
                Text(isRecording ? "Stop" : "Record")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: isRecording ? [.red, .red.opacity(0.8)] : [.accentColor, .accentColor.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(16)
            .shadow(
                color: isRecording ? .red.opacity(0.3) : .accentColor.opacity(0.3), 
                radius: 6, 
                y: 2
            )
            .scaleEffect(pulseAnimation && isRecording ? 1.05 : 1.0)
            .animation(
                isRecording ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : .default,
                value: pulseAnimation
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            pulseAnimation = true
        }
    }
}

// Subtle float button for content headers
struct FloatButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "pip.enter")
                    .font(.system(size: 11))
                Text("Float")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? Color.white.opacity(0.1) : Color.clear)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .help("Enter floating recording mode")
        .onHover { hovering in
            isHovered = hovering
        }
    }
}