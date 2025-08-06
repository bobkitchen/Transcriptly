//
//  SimpleAppPicker.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Simple file picker for app selection
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SimpleAppPicker: View {
    @Binding var isPresented: Bool
    let mode: RefinementMode
    let onAppSelected: (AppInfo) -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // Header
            HStack {
                Text("Assign App to \(mode.displayName)")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
            }
            
            VStack(spacing: DesignSystem.spacingMedium) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("Select an Application")
                    .font(.system(size: 16, weight: .medium))
                
                Text("Choose an app from your Applications folder to automatically switch to \(mode.displayName) when using it.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Browse Applications") {
                    openApplicationPicker()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(DesignSystem.spacingLarge)
            
            Spacer()
        }
        .padding(DesignSystem.spacingLarge)
        .frame(width: 400, height: 300)
    }
    
    private func openApplicationPicker() {
        let panel = NSOpenPanel()
        panel.title = "Select Application for \(mode.displayName)"
        panel.message = "Choose an application to automatically switch to \(mode.displayName) mode when using it."
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        // Start in Applications folder
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                // Create AppInfo from selected app
                if let bundle = Bundle(url: url) {
                    let appInfo = AppInfo(
                        bundleIdentifier: bundle.bundleIdentifier ?? url.lastPathComponent,
                        localizedName: bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? 
                                     bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? 
                                     url.deletingPathExtension().lastPathComponent,
                        executablePath: url.path
                    )
                    
                    DispatchQueue.main.async {
                        onAppSelected(appInfo)
                        isPresented = false
                    }
                } else {
                    // Fallback for apps without bundles
                    let appInfo = AppInfo(
                        bundleIdentifier: url.lastPathComponent,
                        localizedName: url.deletingPathExtension().lastPathComponent,
                        executablePath: url.path
                    )
                    
                    DispatchQueue.main.async {
                        onAppSelected(appInfo)
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    SimpleAppPicker(
        isPresented: .constant(true),
        mode: .email,
        onAppSelected: { app in
            print("Selected app: \(app.localizedName)")
        }
    )
}