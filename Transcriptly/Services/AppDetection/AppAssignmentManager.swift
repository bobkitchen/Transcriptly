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
        
        print("DEBUG: About to save assignment - User ID: \(assignmentData.userId?.uuidString ?? "nil")")
        print("DEBUG: Supabase authenticated: \(supabase.isAuthenticated)")
        
        // For now, save locally regardless of authentication status
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
        
        print("AppAssignmentManager: Saved assignment for \(assignment.appName) -> \(assignment.assignedMode.displayName)")
        
        // Also try to save to Supabase if authenticated
        if supabase.isAuthenticated {
            try await supabase.saveAppAssignment(assignmentData)
            print("DEBUG: Also saved to Supabase")
        } else {
            print("DEBUG: Saved locally only - not authenticated with Supabase")
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
        
        print("AppAssignmentManager: Removed assignment for \(app.displayName)")
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
            print("AppAssignmentManager: Failed to get app assignment: \(error)")
            return nil
        }
    }
    
    func hasUserAssignment(for app: AppInfo) async -> Bool {
        return await getAssignment(for: app) != nil
    }
    
    func getAssignedApps(for mode: RefinementMode) -> [AppAssignment] {
        let filtered = userAssignments.filter { $0.assignedMode == mode }
        print("DEBUG AppAssignmentManager: getAssignedApps for \(mode.displayName) - Total assignments: \(userAssignments.count), Filtered: \(filtered.count)")
        print("DEBUG AppAssignmentManager: All assignments: \(userAssignments.map { "\($0.appName) -> \($0.assignedMode.displayName)" })")
        return filtered
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
                print("DEBUG: Loading assignments from Supabase...")
                let assignments = try await supabase.getAllAppAssignments()
                print("DEBUG: Received \(assignments.count) assignments from Supabase")
                userAssignments = assignments
                
                // Update cache
                cachedAssignments = Dictionary(uniqueKeysWithValues: 
                    assignments.map { ($0.appBundleId, $0) }
                )
                
                // Save to UserDefaults as backup
                saveToUserDefaults()
                
                print("AppAssignmentManager: Loaded \(assignments.count) assignments from Supabase")
                for assignment in assignments {
                    print("  - \(assignment.appName) -> \(assignment.assignedMode.displayName)")
                }
            } catch {
                print("AppAssignmentManager: Failed to load from Supabase: \(error)")
                print("AppAssignmentManager: Using local assignments instead")
            }
        } else {
            print("AppAssignmentManager: Not authenticated, using local assignments only")
            print("AppAssignmentManager: Loaded \(userAssignments.count) assignments from UserDefaults")
            for assignment in userAssignments {
                print("  - \(assignment.appName) -> \(assignment.assignedMode.displayName)")
            }
        }
    }
    
    func resetAllAssignments() async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await supabase.clearAllAppAssignments()
        userAssignments.removeAll()
        cachedAssignments.removeAll()
        
        print("AppAssignmentManager: Reset all assignments")
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
            print("DEBUG: Saved \(userAssignments.count) assignments to UserDefaults")
        } catch {
            print("DEBUG: Failed to save assignments to UserDefaults: \(error)")
        }
    }
    
    private func loadFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: "AppAssignments") else {
            print("DEBUG: No saved assignments in UserDefaults")
            return
        }
        
        do {
            let assignments = try JSONDecoder().decode([AppAssignment].self, from: data)
            userAssignments = assignments
            
            // Update cache
            cachedAssignments = Dictionary(uniqueKeysWithValues: 
                assignments.map { ($0.appBundleId, $0) }
            )
            
            print("DEBUG: Loaded \(assignments.count) assignments from UserDefaults")
        } catch {
            print("DEBUG: Failed to load assignments from UserDefaults: \(error)")
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