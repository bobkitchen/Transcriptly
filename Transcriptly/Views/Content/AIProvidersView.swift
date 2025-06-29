//
//  AIProvidersView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct AIProvidersView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                // Header
                Text("AI Providers")
                    .font(DesignSystem.Typography.titleLarge)
                    .foregroundColor(.primaryText)
                    .padding(.top, DesignSystem.marginStandard)
                
                // Coming Soon Card
                VStack(spacing: DesignSystem.spacingLarge) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(spacing: DesignSystem.spacingMedium) {
                        Text("AI Provider Integration")
                            .font(DesignSystem.Typography.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text("Connect with leading AI services for enhanced transcription and refinement capabilities")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Feature Preview
                    VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                        Text("Coming Soon:")
                            .font(DesignSystem.Typography.bodySmall)
                            .fontWeight(.medium)
                            .foregroundColor(.tertiaryText)
                        
                        FeatureItem(icon: "cloud", text: "OpenAI GPT integration")
                        FeatureItem(icon: "waveform", text: "Advanced speech recognition")
                        FeatureItem(icon: "globe", text: "Multi-language support")
                        FeatureItem(icon: "personalhotspot", text: "Custom AI model endpoints")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.spacingLarge * 2)
                .padding(.horizontal, DesignSystem.spacingLarge)
                .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
                
                // Current Status
                VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                    HStack(spacing: DesignSystem.spacingMedium) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("Current Setup")
                            .font(DesignSystem.Typography.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryText)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                        StatusItem(icon: "mic.fill", text: "Apple Speech Recognition", status: "Active")
                        StatusItem(icon: "cpu", text: "Apple Foundation Models", status: "Active")
                        StatusItem(icon: "brain", text: "Local Learning System", status: "Active")
                    }
                }
                .padding(DesignSystem.spacingLarge)
                .liquidGlassBackground(cornerRadius: DesignSystem.cornerRadiusMedium)
            }
            .adjustForInsetSidebar()
            .padding(DesignSystem.marginStandard)
        }
        .background(Color.primaryBackground)
    }
}

// MARK: - Supporting Views

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingSmall) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
                .frame(width: 16)
            
            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.secondaryText)
        }
    }
}

struct StatusItem: View {
    let icon: String
    let text: String
    let status: String
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingSmall) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.green)
                .frame(width: 16)
            
            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.primaryText)
            
            Spacer()
            
            Text(status)
                .font(DesignSystem.Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(.green)
                .padding(.horizontal, DesignSystem.spacingSmall)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.1))
                .cornerRadius(DesignSystem.cornerRadiusTiny)
        }
    }
}

#Preview {
    AIProvidersView()
}