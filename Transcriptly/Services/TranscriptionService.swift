//
//  TranscriptionService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import Foundation
import Speech
import AVFoundation
import Combine

final class TranscriptionService: ObservableObject {
    @Published var isTranscribing = false
    @Published var transcriptionError: String?
    
    private var speechRecognizer: SFSpeechRecognizer?
    
    init() {
        setupSpeechFramework()
    }
    
    private func setupSpeechFramework() {
        // Set up speech recognizer for the device's locale
        speechRecognizer = SFSpeechRecognizer()
        
        // Check if speech recognition is available
        guard speechRecognizer?.isAvailable == true else {
            transcriptionError = "Speech recognition is not available on this device"
            return
        }
    }
    
    func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.main.async {
                    switch authStatus {
                    case .authorized:
                        continuation.resume(returning: true)
                    case .denied, .restricted, .notDetermined:
                        self.transcriptionError = "Speech recognition permission denied"
                        continuation.resume(returning: false)
                    @unknown default:
                        self.transcriptionError = "Unknown speech recognition authorization status"
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    var hasSpeechPermission: Bool {
        return SFSpeechRecognizer.authorizationStatus() == .authorized
    }
    
    var speechPermissionStatus: SFSpeechRecognizerAuthorizationStatus {
        return SFSpeechRecognizer.authorizationStatus()
    }
    
    func transcribeAudioFile(at url: URL) async -> String? {
        await MainActor.run {
            isTranscribing = true
            transcriptionError = nil
        }
        
        defer {
            Task { @MainActor in
                isTranscribing = false
            }
        }
        
        // Use direct Apple Speech Recognition to avoid circular dependencies
        guard speechRecognizer?.isAvailable == true else {
            await MainActor.run {
                transcriptionError = "Speech recognition not available"
            }
            return nil
        }
        
        guard hasSpeechPermission else {
            await MainActor.run {
                transcriptionError = "Speech recognition permission required"
            }
            return nil
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = true // For privacy
        
        return await withCheckedContinuation { continuation in
            speechRecognizer?.recognitionTask(with: request) { result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.transcriptionError = "Transcription failed: \(error.localizedDescription)"
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    if let result = result, result.isFinal {
                        let transcribedText = result.bestTranscription.formattedString
                        continuation.resume(returning: transcribedText)
                    } else if result == nil {
                        self.transcriptionError = "No transcription result"
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
}