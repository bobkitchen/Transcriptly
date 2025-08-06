//
//  HistoryView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var historyService = TranscriptionHistoryService.shared
    @State private var searchText = ""
    @State private var selectedMode: RefinementMode?
    @State private var showExportDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Transcription History")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Export button
                Button("Export") {
                    showExportDialog = true
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
            
            Divider()
            
            // Search and filters
            VStack(spacing: DesignSystem.spacingMedium) {
                HStack {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondaryText)
                        TextField("Search transcriptions...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, DesignSystem.spacingMedium)
                    .padding(.vertical, DesignSystem.spacingSmall)
                    .background(Color.secondaryBackground)
                    .cornerRadius(DesignSystem.cornerRadiusSmall)
                    
                    // Mode filter
                    Picker("Mode", selection: $selectedMode) {
                        Text("All Modes").tag(nil as RefinementMode?)
                        ForEach(RefinementMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode as RefinementMode?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 140)
                }
                
                // Statistics
                if !historyService.transcriptions.isEmpty {
                    HistoryStatsView(statistics: historyService.statistics)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, DesignSystem.spacingMedium)
            
            Divider()
            
            // History list
            if historyService.isLoading {
                VStack {
                    ProgressView("Loading history...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredTranscriptions.isEmpty {
                VStack(spacing: DesignSystem.spacingMedium) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.tertiaryText)
                    
                    Text(historyService.transcriptions.isEmpty ? "No transcriptions yet" : "No results found")
                        .font(.title3)
                        .foregroundColor(.secondaryText)
                    
                    if !searchText.isEmpty {
                        Button("Clear Search") {
                            searchText = ""
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.spacingMedium) {
                        ForEach(filteredTranscriptions) { transcription in
                            TranscriptionCard(transcription: transcription)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 700, height: 500)
        .background(Color.primaryBackground)
        .fileExporter(
            isPresented: $showExportDialog,
            document: TranscriptionExportDocument(transcriptions: filteredTranscriptions),
            contentType: .json,
            defaultFilename: "transcription-history"
        ) { result in
            switch result {
            case .success(let url):
                print("Exported transcriptions to: \(url)")
            case .failure(let error):
                print("Export failed: \(error)")
            }
        }
    }
    
    private var filteredTranscriptions: [TranscriptionRecord] {
        return historyService.getTranscriptions(
            mode: selectedMode,
            searchText: searchText.isEmpty ? nil : searchText
        )
    }
}

// MARK: - Supporting Views

struct HistoryStatsView: View {
    let statistics: TranscriptionStatistics
    
    var body: some View {
        HStack(spacing: DesignSystem.spacingLarge) {
            StatItem(title: "Total", value: "\(statistics.totalCount)")
            StatItem(title: "Today", value: "\(statistics.todayCount)")
            StatItem(title: "This Week", value: "\(statistics.weekCount)")
            StatItem(title: "Avg Words", value: "\(statistics.averageWordCount)")
            
            if statistics.totalDuration > 0 {
                StatItem(title: "Total Time", value: formatDuration(statistics.totalDuration))
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.spacingMedium)
        .padding(.vertical, DesignSystem.spacingSmall)
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(DesignSystem.cornerRadiusSmall)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
    }
}

// MARK: - Export Document

import UniformTypeIdentifiers

struct TranscriptionExportDocument: FileDocument {
    nonisolated(unsafe) static var readableContentTypes: [UTType] = [.json]
    
    let transcriptions: [TranscriptionRecord]
    
    init(transcriptions: [TranscriptionRecord]) {
        self.transcriptions = transcriptions
    }
    
    init(configuration: ReadConfiguration) throws {
        // For import functionality (not currently used)
        transcriptions = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(transcriptions)
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    HistoryView()
}