//
//  AppAssignmentManager.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  App Detection & Assignment - App Assignment Management
//

import Foundation
import Combine
import Auth

@MainActor
class AppAssignmentManager: ObservableObject {
    static let shared = AppAssignmentManager()
    
    @Published var userAssignments: [AppAssignment] = []
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared
    private var cachedAssignments: [String: AppAssignment] = [:]
    
    private init() {
        Task {
            await loadAssignments()
        }
    }
    
    // MARK: - Assignment Management
    
    func saveAssignment(_ assignment: AppAssignment) async throws {
        isLoading = true
        defer { isLoading = false }
        
        var assignmentData = assignment
        assignmentData.userId = supabase.currentUser?.id
        
        // Save locally regardless of authentication status
        // Update local cache
        cachedAssignments[assignment.appBundleId] = assignmentData
        
        // Update published array
        if let index = userAssignments.firstIndex(where: { $0.appBundleId == assignment.appBundleId }) {
            userAssignments[index] = assignmentData
        } else {
            userAssignments.append(assignmentData)
        }
        
        // Save to UserDefaults for persistence
        saveToUserDefaults()
        
        // Also try to save to Supabase if authenticated
        if supabase.isAuthenticated {
            try await supabase.saveAppAssignment(assignmentData)
        }
    }
    
    func removeAssignment(for app: AppInfo) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await supabase.removeAppAssignment(bundleId: app.bundleIdentifier)
        
        // Update local cache
        cachedAssignments.removeValue(forKey: app.bundleIdentifier)
        
        // Update published array
        userAssignments.removeAll { $0.appBundleId == app.bundleIdentifier }
    }
    
    func getAssignment(for app: AppInfo) async -> AppAssignment? {
        // Check cache first
        if let cached = cachedAssignments[app.bundleIdentifier] {
            return cached
        }
        
        // Check Supabase (with error handling)
        do {
            let assignment = try await supabase.getAppAssignment(bundleId: app.bundleIdentifier)
            if let assignment = assignment {
                cachedAssignments[app.bundleIdentifier] = assignment
            }
            return assignment
        } catch {
            return nil
        }
    }
    
    func hasUserAssignment(for app: AppInfo) async -> Bool {
        return await getAssignment(for: app) != nil
    }
    
    func getAssignedApps(for mode: RefinementMode) -> [AppAssignment] {
        return userAssignments.filter { $0.assignedMode == mode }
    }
    
    // MARK: - Bulk Operations
    
    func loadAssignments() async {
        isLoading = true
        defer { isLoading = false }
        
        // First load from UserDefaults
        loadFromUserDefaults()
        
        // Then try to load from Supabase if authenticated
        if supabase.isAuthenticated {
            do {
                let assignments = try await supabase.getAllAppAssignments()
                userAssignments = assignments
                
                // Update cache
                cachedAssignments = Dictionary(uniqueKeysWithValues: 
                    assignments.map { ($0.appBundleId, $0) }
                )
                
                // Save to UserDefaults as backup
                saveToUserDefaults()
            } catch {
                // Silently use local assignments if Supabase fails
            }
        }
    }
    
    func resetAllAssignments() async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await supabase.clearAllAppAssignments()
        userAssignments.removeAll()
        cachedAssignments.removeAll()
    }
    
    // MARK: - Statistics
    
    var assignmentCount: Int {
        return userAssignments.count
    }
    
    var assignmentsByMode: [RefinementMode: Int] {
        var counts: [RefinementMode: Int] = [:]
        for assignment in userAssignments {
            counts[assignment.assignedMode, default: 0] += 1
        }
        return counts
    }
    
    // MARK: - UserDefaults Persistence
    
    private func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(userAssignments)
            UserDefaults.standard.set(data, forKey: "AppAssignments")
        } catch {
            print("Failed to save assignments to UserDefaults: \(error)")
        }
    }
    
    private func loadFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: "AppAssignments") else {
            return
        }
        
        do {
            // First try to decode with new format
            let assignments = try JSONDecoder().decode([AppAssignment].self, from: data)
            userAssignments = assignments
            
            // Update cache
            cachedAssignments = Dictionary(uniqueKeysWithValues: 
                assignments.map { ($0.appBundleId, $0) }
            )
        } catch {
            print("Failed to decode with new format, trying migration: \(error)")
            
            // Try to load as raw JSON and migrate
            if let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                var migratedAssignments: [AppAssignment] = []
                
                for dict in jsonArray {
                    if let appBundleId = dict["appBundleId"] as? String,
                       let appName = dict["appName"] as? String,
                       let modeString = dict["assignedMode"] as? String {
                        
                        // Map old format to new format
                        let mode: RefinementMode
                        switch modeString {
                        case "Raw Transcription", "raw":
                            mode = .raw
                        case "Clean-up Mode", "cleanup":
                            mode = .cleanup
                        case "Email Mode", "email":
                            mode = .email
                        case "Messaging Mode", "messaging":
                            mode = .messaging
                        default:
                            continue // Skip unknown modes
                        }
                        
                        let assignment = AppAssignment(
                            appInfo: AppInfo(
                                bundleIdentifier: appBundleId,
                                localizedName: appName,
                                executablePath: ""
                            ),
                            mode: mode,
                            isUserOverride: true
                        )
                        
                        migratedAssignments.append(assignment)
                    }
                }
                
                if !migratedAssignments.isEmpty {
                    userAssignments = migratedAssignments
                    cachedAssignments = Dictionary(uniqueKeysWithValues: 
                        migratedAssignments.map { ($0.appBundleId, $0) }
                    )
                    
                    // Save migrated data in new format
                    saveToUserDefaults()
                }
            }
        }
    }
    
    // MARK: - Debug
    
    func printAssignments() {
        print("Current App Assignments:")
        for assignment in userAssignments.sorted(by: { $0.appName < $1.appName }) {
            print("  \(assignment.appName) -> \(assignment.assignedMode.displayName)")
        }
    }
}