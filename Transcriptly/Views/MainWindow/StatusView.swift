//
//  StatusView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import SwiftUI

struct StatusView: View {
    @State private var currentStatus: AppStatus = .ready
    
    var body: some View {
        VStack(spacing: 0) {
            // Divider line above status
            Divider()
            
            // Status bar area
            HStack {
                Text("Status: \(currentStatus.displayText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                
                // Optional status indicator
                if currentStatus != .ready {
                    Image(systemName: currentStatus.iconName)
                        .font(.caption)
                        .foregroundColor(currentStatus.color)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
}

enum AppStatus: Equatable {
    case ready
    case recording
    case transcribing
    case refining
    case complete
    case error(String)
    
    var displayText: String {
        switch self {
        case .ready:
            return "Ready"
        case .recording:
            return "Recording..."
        case .transcribing:
            return "Transcribing..."
        case .refining:
            return "Refining..."
        case .complete:
            return "Complete"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var iconName: String {
        switch self {
        case .ready, .complete:
            return "checkmark.circle.fill"
        case .recording:
            return "mic.fill"
        case .transcribing, .refining:
            return "gearshape.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .ready, .complete:
            return .green
        case .recording:
            return .red
        case .transcribing, .refining:
            return .blue
        case .error:
            return .red
        }
    }
}

#Preview {
    StatusView()
}