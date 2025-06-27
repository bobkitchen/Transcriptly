//
//  LearningView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//  Updated by Claude Code on 6/27/25 for Phase 3.
//

import SwiftUI

struct LearningView: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var learnedPatterns: [LearnedPattern] = []
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Learning")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if supabaseManager.isSyncing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Syncing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Authentication Status
            HStack {
                Image(systemName: supabaseManager.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(supabaseManager.isAuthenticated ? .green : .orange)
                
                Text(supabaseManager.isAuthenticated ? "Signed in to cloud" : "Sign in to sync across devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !supabaseManager.isAuthenticated {
                    Button("Sign In") {
                        // TODO: Implement auth UI
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            // Learned Patterns Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Learned Patterns")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Refresh") {
                        loadPatterns()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading patterns...")
                            .foregroundColor(.secondary)
                    }
                } else if learnedPatterns.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "brain")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No patterns learned yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("As you use Transcriptly, it will learn from your corrections and preferences to improve accuracy.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(learnedPatterns) { pattern in
                                PatternRowView(pattern: pattern)
                            }
                        }
                    }
                }
            }
            
            if let error = error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Dismiss") {
                        self.error = nil
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear {
            loadPatterns()
        }
    }
    
    private func loadPatterns() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let patterns = try await supabaseManager.getActivePatterns()
                await MainActor.run {
                    self.learnedPatterns = patterns
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load patterns: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

struct PatternRowView: View {
    let pattern: LearnedPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(pattern.originalPhrase)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(pattern.correctedPhrase)
                    .font(.body)
                    .foregroundColor(.blue)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(pattern.occurrenceCount)x")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(pattern.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(pattern.confidence > 0.8 ? .green : .orange)
                }
            }
            
            if let mode = pattern.refinementMode {
                Text("Mode: \(mode.rawValue)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    LearningView()
}