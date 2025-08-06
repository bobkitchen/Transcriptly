//
//  SyncMonitor.swift
//  Transcriptly
//
//  Monitors and manages Supabase sync status and operations
//

import Foundation
import Combine
// Temporarily disabled - Supabase package needs to be added via Swift Package Manager
// import Supabase
// import PostgREST
import SwiftUI

@MainActor
class SyncMonitor: ObservableObject {
    static let shared = SyncMonitor()
    
    @Published var connectionStatus: ConnectionStatus = .unknown
    @Published var lastSyncTime: Date?
    @Published var syncProgress: SyncProgress?
    @Published var isManualSyncInProgress = false
    @Published var hasOfflineOperations = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared
    private let offlineQueue = OfflineQueue.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    
    private init() {
        setupMonitoring()
        startPeriodicSync()
    }
    
    func setupMonitoring() {
        // Monitor Supabase connection status
        supabase.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                self?.updateConnectionStatus()
            }
            .store(in: &cancellables)
        
        // Monitor offline queue
        offlineQueue.$pendingOperations
            .sink { [weak self] operations in
                self?.hasOfflineOperations = !operations.isEmpty
            }
            .store(in: &cancellables)
        
        // Check initial status
        updateConnectionStatus()
    }
    
    func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.performBackgroundSync()
            }
        }
    }
    
    func manualSync() async {
        guard !isManualSyncInProgress else { return }
        
        isManualSyncInProgress = true
        errorMessage = nil
        
        do {
            // Test connection
            connectionStatus = .connecting
            let isConnected = await testConnection()
            
            if isConnected {
                connectionStatus = .connected
                
                // Sync offline operations
                await offlineQueue.processQueue()
                
                // Download latest data
                await downloadLatestData()
                
                lastSyncTime = Date()
                errorMessage = nil
            } else {
                connectionStatus = .disconnected
                errorMessage = "Unable to connect to sync service"
            }
        } catch {
            connectionStatus = .error
            errorMessage = error.localizedDescription
        }
        
        isManualSyncInProgress = false
    }
    
    func resetSync() async {
        // Clear local cache
        await supabase.clearAllCachedData()
        
        // Clear offline queue
        offlineQueue.clearQueue()
        
        // Reset sync state
        lastSyncTime = nil
        errorMessage = nil
        
        // Trigger fresh sync
        await manualSync()
    }
    
    func exportData() async -> URL? {
        do {
            let exportData = SyncExportData(
                learningPatterns: try await supabase.getAllLearnedPatterns(),
                learningPreferences: try await supabase.getPreferences(),
                exportDate: Date(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(exportData)
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Transcriptly_Export_\(Date().formatted(.iso8601)).json")
            
            try data.write(to: tempURL)
            return tempURL
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            return nil
        }
    }
    
    func importData(from url: URL) async -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let importData = try decoder.decode(SyncExportData.self, from: data)
            
            // Import patterns
            for pattern in importData.learningPatterns {
                try await supabase.saveOrUpdatePattern(pattern)
            }
            
            // Import preferences
            for preference in importData.learningPreferences {
                try await supabase.saveOrUpdatePreference(preference)
            }
            
            lastSyncTime = Date()
            return true
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func updateConnectionStatus() {
        Task {
            if supabase.isAuthenticated {
                connectionStatus = await testConnection() ? .connected : .disconnected
            } else {
                connectionStatus = .offline
            }
        }
    }
    
    private func testConnection() async -> Bool {
        do {
            // Simple connection test using a lightweight query
            _ = try await supabase.client.from("learned_patterns")
                .select("id")
                .limit(1)
                .execute()
            return true
        } catch {
            print("Connection test failed: \(error)")
            return false
        }
    }
    
    private func performBackgroundSync() async {
        guard connectionStatus == .connected else { return }
        
        do {
            // Sync offline operations
            await offlineQueue.processQueue()
            
            // Update last sync time if successful
            if !hasOfflineOperations {
                lastSyncTime = Date()
            }
        } catch {
            // Log error but don't update UI for background sync failures
            print("Background sync failed: \(error)")
        }
    }
    
    private func downloadLatestData() async {
        do {
            // Download latest patterns
            _ = try await supabase.getActivePatterns()
            
            // Download latest preferences
            _ = try await supabase.getPreferences()
        } catch {
            print("Failed to download latest data: \(error)")
        }
    }
    
    deinit {
        // Timer cleanup is handled in stopMonitoring()
    }
}

// MARK: - Supporting Types

enum ConnectionStatus {
    case unknown, connecting, connected, disconnected, offline, error
    
    var statusText: String {
        switch self {
        case .unknown: return "Unknown"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .offline: return "Offline"
        case .error: return "Error"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .unknown: return .gray
        case .connecting: return .blue
        case .connected: return .green
        case .disconnected: return .orange
        case .offline: return .gray
        case .error: return .red
        }
    }
    
    var statusIcon: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .connecting: return "arrow.triangle.2.circlepath"
        case .connected: return "checkmark.circle.fill"
        case .disconnected: return "exclamationmark.triangle.fill"
        case .offline: return "wifi.slash"
        case .error: return "xmark.circle.fill"
        }
    }
}

struct SyncProgress {
    let operation: String
    let progress: Double
    let itemsProcessed: Int
    let totalItems: Int
}

struct SyncExportData: Codable {
    let learningPatterns: [LearnedPattern]
    let learningPreferences: [UserPreference]
    let exportDate: Date
    let appVersion: String
}