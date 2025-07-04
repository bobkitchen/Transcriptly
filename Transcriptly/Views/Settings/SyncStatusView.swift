//
//  SyncStatusView.swift
//  Transcriptly
//
//  Shows Supabase sync status and provides manual sync controls
//

import SwiftUI

struct SyncStatusView: View {
    @ObservedObject private var syncMonitor = SyncMonitor.shared
    @ObservedObject private var offlineQueue = OfflineQueue.shared
    @State private var showingExportPicker = false
    @State private var showingImportPicker = false
    @State private var exportURL: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
            // Connection Status
            connectionStatusSection
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Sync Controls
            syncControlsSection
            
            if !offlineQueue.pendingOperations.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Offline Queue
                offlineQueueSection
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Data Management
            dataManagementSection
        }
        .padding(DesignSystem.spacingLarge)
        .liquidGlassBackground(
            material: .ultraThinMaterial,
            cornerRadius: DesignSystem.cornerRadiusMedium
        )
        .fileExporter(
            isPresented: $showingExportPicker,
            document: exportURL.map { TextFileDocument(url: $0) },
            contentType: .json,
            defaultFilename: "Transcriptly_Export_\(Date().formatted(.iso8601)).json"
        ) { result in
            switch result {
            case .success:
                print("Export saved successfully")
            case .failure(let error):
                print("Export failed: \(error)")
            }
            exportURL = nil
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        _ = await syncMonitor.importData(from: url)
                    }
                }
            case .failure(let error):
                print("Import failed: \(error)")
            }
        }
    }
    
    private var connectionStatusSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            Text("Connection Status")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: syncMonitor.connectionStatus.statusIcon)
                    .foregroundColor(syncMonitor.connectionStatus.statusColor)
                    .font(.system(size: 20))
                
                Text(syncMonitor.connectionStatus.statusText)
                    .foregroundColor(.primary)
                    .font(.system(size: 14))
                
                Spacer()
                
                if let lastSync = syncMonitor.lastSyncTime {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Last sync")
                            .font(.caption2)
                            .foregroundColor(.secondaryText)
                        Text(lastSync.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            
            if let errorMessage = syncMonitor.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(DesignSystem.cornerRadiusSmall)
            }
        }
    }
    
    private var syncControlsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            Text("Sync Controls")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: DesignSystem.spacingMedium) {
                Button(action: {
                    Task {
                        await syncMonitor.manualSync()
                    }
                }) {
                    HStack {
                        if syncMonitor.isManualSyncInProgress {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text("Sync Now")
                    }
                }
                .disabled(syncMonitor.isManualSyncInProgress)
                .buttonStyle(.borderedProminent)
                
                Button("Reset Sync") {
                    Task {
                        await syncMonitor.resetSync()
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                if syncMonitor.hasOfflineOperations {
                    Label("\(offlineQueue.pendingOperations.count) pending", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    private var offlineQueueSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack {
                Text("Offline Queue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if offlineQueue.isProcessingQueue {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            VStack(spacing: DesignSystem.spacingSmall) {
                ForEach(offlineQueue.pendingOperations.prefix(5)) { operation in
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        
                        Text(operation.displayName)
                            .font(.caption)
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                        
                        Text(operation.statusText)
                            .font(.caption2)
                            .foregroundColor(.secondaryText)
                        
                        Button(action: {
                            Task {
                                await offlineQueue.retryOperation(operation.id)
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, 4)
                }
                
                if offlineQueue.pendingOperations.count > 5 {
                    Text("... and \(offlineQueue.pendingOperations.count - 5) more")
                        .font(.caption2)
                        .foregroundColor(.secondaryText)
                }
            }
            
            if !offlineQueue.pendingOperations.isEmpty {
                Button("Clear Queue") {
                    offlineQueue.clearQueue()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            Text("Data Management")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: DesignSystem.spacingMedium) {
                Button(action: {
                    Task {
                        if let url = await syncMonitor.exportData() {
                            exportURL = url
                            showingExportPicker = true
                        }
                    }
                }) {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    showingImportPicker = true
                }) {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
            }
            
            Text("Export your learning data for backup or import previous data")
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
    }
}

// Helper for file export
struct TextFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var text: String
    
    init(url: URL) {
        text = (try? String(contentsOf: url)) ?? ""
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}