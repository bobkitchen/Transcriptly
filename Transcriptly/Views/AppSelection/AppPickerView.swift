//
//  AppPickerView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  App Detection & Assignment - App Picker Interface
//

import SwiftUI
import AppKit

struct AppPickerView: View {
    @Binding var isPresented: Bool
    let mode: RefinementMode
    let onAppSelected: (AppInfo) -> Void
    
    @State private var availableApps: [AppInfo] = []
    @State private var filteredApps: [AppInfo] = []
    @State private var searchText = ""
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Assign Apps to \(mode.displayName)")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
            }
            .padding(DesignSystem.spacingLarge)
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search applications...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, _ in
                        filterApps()
                    }
            }
            .padding(DesignSystem.spacingMedium)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, DesignSystem.spacingLarge)
            .padding(.top, DesignSystem.spacingMedium)
            
            // App list
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading applications...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.spacingSmall) {
                        ForEach(filteredApps, id: \.bundleIdentifier) { app in
                            AppRowView(
                                app: app,
                                isRecommended: isRecommended(app),
                                onSelect: {
                                    onAppSelected(app)
                                    isPresented = false
                                }
                            )
                        }
                    }
                    .padding(DesignSystem.spacingMedium)
                }
            }
        }
        .frame(width: 500, height: 600)
        .background(.regularMaterial)
        .onAppear {
            loadAvailableApps()
        }
    }
    
    private func loadAvailableApps() {
        Task {
            let apps = await getInstalledApplications()
            await MainActor.run {
                availableApps = apps
                filteredApps = apps
                isLoading = false
            }
        }
    }
    
    private func filterApps() {
        if searchText.isEmpty {
            filteredApps = availableApps
        } else {
            filteredApps = availableApps.filter { app in
                app.displayName.localizedCaseInsensitiveContains(searchText) ||
                app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func isRecommended(_ app: AppInfo) -> Bool {
        DefaultAppMappings.defaultMode(for: app.bundleIdentifier) == mode
    }
    
    private func getInstalledApplications() async -> [AppInfo] {
        let workspace = NSWorkspace.shared
        let applicationURLs = workspace.urlsForApplications(toOpen: URL(fileURLWithPath: "/"))
        
        var apps: [AppInfo] = []
        
        for url in applicationURLs {
            if let bundle = Bundle(url: url),
               let bundleId = bundle.bundleIdentifier,
               let appName = bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String ??
                           bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
                           url.deletingPathExtension().lastPathComponent as String? {
                
                let appInfo = AppInfo(
                    bundleIdentifier: bundleId,
                    localizedName: appName,
                    executablePath: url.path
                )
                
                // Filter out system apps we don't want
                if !shouldExcludeApp(appInfo) {
                    apps.append(appInfo)
                }
            }
        }
        
        // Sort alphabetically
        apps.sort { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
        
        return apps
    }
    
    private func shouldExcludeApp(_ app: AppInfo) -> Bool {
        let excludedPrefixes = [
            "com.apple.ActivityMonitor",
            "com.apple.Console",
            "com.apple.SystemPreferences",
            "com.apple.finder",
            "com.apple.loginwindow",
            "com.apple.dock",
            "com.apple.Spotlight",
            "com.apple.CoreSimulator"
        ]
        
        return excludedPrefixes.contains { app.bundleIdentifier.hasPrefix($0) } || 
               app.bundleIdentifier == Bundle.main.bundleIdentifier // Exclude Transcriptly itself
    }
}

struct AppRowView: View {
    let app: AppInfo
    let isRecommended: Bool
    let onSelect: () -> Void
    
    @State private var appIcon: NSImage?
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DesignSystem.spacingMedium) {
                // App icon
                Group {
                    if let icon = appIcon {
                        Image(nsImage: icon)
                            .resizable()
                    } else {
                        Image(systemName: "app.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 32, height: 32)
                
                // App info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(app.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        if isRecommended {
                            Text("Recommended")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text(app.bundleIdentifier)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 20))
            }
            .padding(DesignSystem.spacingMedium)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            loadAppIcon()
        }
    }
    
    private func loadAppIcon() {
        guard let executablePath = app.executablePath else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let icon = NSWorkspace.shared.icon(forFile: executablePath)
            
            DispatchQueue.main.async {
                appIcon = icon
            }
        }
    }
}

#Preview {
    AppPickerView(
        isPresented: .constant(true),
        mode: .email,
        onAppSelected: { app in
            print("Selected: \(app.displayName)")
        }
    )
}