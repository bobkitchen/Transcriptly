//
//  AppDetectionService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  App Detection & Assignment - Core App Detection Service
//

import Foundation
import AppKit
import Combine

@MainActor
class AppDetectionService: ObservableObject {
    static let shared = AppDetectionService()
    
    @Published var currentApp: AppInfo?
    @Published var detectedMode: RefinementMode?
    @Published var isAutoDetectionEnabled = true
    
    private let assignmentManager = AppAssignmentManager.shared
    private let confidenceThreshold: Double = 0.7
    
    private init() {
        loadSettings()
    }
    
    // MARK: - App Detection
    
    func detectActiveApp() -> AppInfo? {
        print("🔍 AppDetectionService.detectActiveApp() called")
        
        guard isAutoDetectionEnabled else {
            print("   ❌ Auto-detection is disabled")
            return nil
        }
        
        // Get frontmost application
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("   ❌ No frontmost application found")
            return nil
        }
        
        print("   📱 Frontmost app: \(frontmostApp.localizedName ?? "Unknown") (\(frontmostApp.bundleIdentifier ?? "none"))")
        
        guard frontmostApp.bundleIdentifier != Bundle.main.bundleIdentifier else {
            print("   ❌ Frontmost app is Transcriptly itself, skipping")
            return nil
        }
        
        let appInfo = AppInfo(from: frontmostApp)
        print("   📋 AppInfo created: \(appInfo.displayName) (\(appInfo.bundleIdentifier))")
        
        // Skip system apps that we shouldn't detect
        guard !appInfo.isSystemApp || shouldDetectSystemApp(appInfo) else {
            print("   ❌ System app that should not be detected")
            return nil
        }
        
        currentApp = appInfo
        print("   ✅ Successfully detected app: \(appInfo.displayName)")
        return appInfo
    }
    
    func getRecommendedMode(for app: AppInfo) async -> RefinementMode? {
        guard isAutoDetectionEnabled else { return nil }
        
        // Check user assignments first (highest priority)
        if let userAssignment = await assignmentManager.getAssignment(for: app) {
            detectedMode = userAssignment.assignedMode
            return userAssignment.assignedMode
        }
        
        // Check built-in defaults
        if let defaultMode = DefaultAppMappings.defaultMode(for: app.bundleIdentifier) {
            detectedMode = defaultMode
            return defaultMode
        }
        
        // No specific assignment found
        detectedMode = nil
        return nil
    }
    
    func getDetectionConfidence(for app: AppInfo) async -> Double {
        // User assignments have highest confidence
        if await assignmentManager.hasUserAssignment(for: app) {
            return 1.0
        }
        
        // Built-in defaults have medium-high confidence
        if DefaultAppMappings.defaultMode(for: app.bundleIdentifier) != nil {
            return 0.8
        }
        
        // Unknown apps have low confidence
        return 0.0
    }
    
    // MARK: - Integration Points
    
    func detectAndRecommendMode() async -> (app: AppInfo?, mode: RefinementMode?) {
        guard let app = detectActiveApp() else {
            return (nil, nil)
        }
        
        let confidence = await getDetectionConfidence(for: app)
        guard confidence >= confidenceThreshold else {
            return (app, nil)
        }
        
        let mode = await getRecommendedMode(for: app)
        return (app, mode)
    }
    
    // MARK: - Settings
    
    func toggleAutoDetection() {
        isAutoDetectionEnabled.toggle()
        saveSettings()
    }
    
    func setAutoDetectionEnabled(_ enabled: Bool) {
        isAutoDetectionEnabled = enabled
        saveSettings()
    }
    
    private func loadSettings() {
        // Check if the key exists first, if not, default to true
        if UserDefaults.standard.object(forKey: "appDetectionEnabled") != nil {
            isAutoDetectionEnabled = UserDefaults.standard.bool(forKey: "appDetectionEnabled")
        } else {
            isAutoDetectionEnabled = true
            // Save the default value
            UserDefaults.standard.set(true, forKey: "appDetectionEnabled")
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(isAutoDetectionEnabled, forKey: "appDetectionEnabled")
    }
    
    // MARK: - Utility
    
    func getDisplayString(for app: AppInfo, mode: RefinementMode) -> String {
        return "\(app.displayName) → \(mode.displayName)"
    }
    
    private func shouldDetectSystemApp(_ app: AppInfo) -> Bool {
        // Allow some specific Apple apps
        let allowedSystemApps = [
            "com.apple.mail",
            "com.apple.MobileSMS",
            "com.apple.Notes",
            "com.apple.TextEdit",
            "com.apple.Safari",
            "com.apple.FaceTime",
            "com.apple.iWork.Pages",
            "com.apple.Terminal"
        ]
        
        return allowedSystemApps.contains(app.bundleIdentifier)
    }
    
    // MARK: - Debug & Testing
    
    func getAllRunningApps() -> [AppInfo] {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.compactMap { app in
            guard let bundleId = app.bundleIdentifier,
                  bundleId != Bundle.main.bundleIdentifier else { return nil }
            return AppInfo(from: app)
        }
    }
    
    func testDetection() -> String {
        guard let app = detectActiveApp() else {
            return "No app detected or detection disabled"
        }
        
        Task {
            let confidence = await getDetectionConfidence(for: app)
            let mode = await getRecommendedMode(for: app)
            
            await MainActor.run {
                print("Detection Test Results:")
                print("App: \(app.displayName) (\(app.bundleIdentifier))")
                print("Confidence: \(confidence)")
                print("Recommended Mode: \(mode?.displayName ?? "None")")
            }
        }
        
        return "Testing \(app.displayName)"
    }
}