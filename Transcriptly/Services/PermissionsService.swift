//
//  PermissionsService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import Foundation
import AVFoundation
import Combine

enum MacOSMicrophonePermission {
    case undetermined
    case granted
    case denied
}

@MainActor
final class PermissionsService: ObservableObject {
    @Published var microphonePermissionStatus: MacOSMicrophonePermission = .undetermined
    
    init() {
        checkCurrentPermissionStatus()
    }
    
    private func checkCurrentPermissionStatus() {
        // For macOS, we'll check authorization status
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphonePermissionStatus = .granted
        case .denied, .restricted:
            microphonePermissionStatus = .denied
        case .notDetermined:
            microphonePermissionStatus = .undetermined
        @unknown default:
            microphonePermissionStatus = .undetermined
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    self.microphonePermissionStatus = granted ? .granted : .denied
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    var hasPermission: Bool {
        return microphonePermissionStatus == .granted
    }
    
    var permissionStatusText: String {
        switch microphonePermissionStatus {
        case .granted:
            return "Ready"
        case .denied:
            return "Microphone access required"
        case .undetermined:
            return "Click to request microphone access"
        }
    }
}