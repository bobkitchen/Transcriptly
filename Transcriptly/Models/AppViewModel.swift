//
//  AppViewModel.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

final class AppViewModel: ObservableObject {
    @Published var currentStatus: AppStatus = .ready
    @Published var isRecording = false
    @Published var transcribedText: String = ""
    @Published var isTranscribing = false
    @Published var errorMessage: String? = nil
    
    private let permissionsService = PermissionsService()
    private let audioService = AudioService()
    private let keyboardShortcutService = KeyboardShortcutService()
    private let transcriptionService = TranscriptionService()
    private let pasteService = PasteService()
    
    init() {
        // Initialize status based on permissions
        updateStatusBasedOnPermissions()
        
        // Observe audio service recording state
        audioService.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
                self?.updateStatusForRecording(isRecording)
            }
            .store(in: &cancellables)
        
        // Observe transcription service state
        transcriptionService.$isTranscribing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isTranscribing in
                self?.isTranscribing = isTranscribing
                self?.updateStatusForTranscribing(isTranscribing)
            }
            .store(in: &cancellables)
        
        // Set up keyboard shortcut handler
        keyboardShortcutService.onShortcutPressed = { [weak self] in
            Task { @MainActor in
                await self?.handleKeyboardShortcut()
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateStatusBasedOnPermissions() {
        if permissionsService.hasPermission {
            currentStatus = .ready
        } else {
            currentStatus = .ready // Will show permission request when needed
        }
    }
    
    @MainActor
    func checkPermissions() async -> Bool {
        if permissionsService.hasPermission {
            return true
        }
        
        // Request permission
        let granted = await permissionsService.requestMicrophonePermission()
        updateStatusBasedOnPermissions()
        return granted
    }
    
    var statusText: String {
        if !permissionsService.hasPermission && permissionsService.microphonePermissionStatus == .denied {
            return "Microphone access required"
        }
        return currentStatus.displayText
    }
    
    var canRecord: Bool {
        // Allow button to be clicked if permissions are undetermined (so user can request permission)
        // or if permissions are granted and not currently recording
        return (permissionsService.hasPermission || permissionsService.microphonePermissionStatus == .undetermined) && !isRecording
    }
    
    private func updateStatusForRecording(_ recording: Bool) {
        if recording {
            currentStatus = .recording
        } else if !isTranscribing {
            currentStatus = .ready
        }
    }
    
    private func updateStatusForTranscribing(_ transcribing: Bool) {
        if transcribing {
            currentStatus = .transcribing
        } else if !isRecording {
            currentStatus = .ready
        }
    }
    
    func startRecording() async -> Bool {
        guard permissionsService.hasPermission else { 
            await MainActor.run {
                errorMessage = "Microphone permission required"
            }
            return false 
        }
        
        await MainActor.run {
            errorMessage = nil
            currentStatus = .recording
        }
        
        let success = await audioService.startRecording()
        
        if !success {
            await MainActor.run {
                currentStatus = .ready
                errorMessage = "Failed to start recording. Please check your microphone."
            }
        }
        
        return success
    }
    
    func stopRecording() async -> URL? {
        guard isRecording else { return nil }
        
        let recordingURL = await audioService.stopRecording()
        
        if let url = recordingURL {
            // Start transcription after recording completes
            await transcribeRecording(url: url)
        }
        
        return recordingURL
    }
    
    private func transcribeRecording(url: URL) async {
        // Check if speech recognition permission is needed
        let hasSpeechPermission = transcriptionService.hasSpeechPermission
        if !hasSpeechPermission {
            let granted = await transcriptionService.requestSpeechRecognitionPermission()
            if !granted {
                await MainActor.run {
                    errorMessage = "Speech recognition permission required for transcription"
                }
                return
            }
        }
        
        // Clear any previous errors
        await MainActor.run {
            errorMessage = nil
        }
        
        // Transcribe the audio file
        let transcribedText = await transcriptionService.transcribeAudioFile(at: url)
        
        await MainActor.run {
            if let text = transcribedText, !text.isEmpty {
                self.transcribedText = text
                // Automatically copy to clipboard
                self.pasteService.copyTextToClipboard(text)
            } else {
                self.transcribedText = ""
                self.errorMessage = "Transcription failed. Please try recording again."
            }
        }
    }
    
    func cancelRecording() async {
        guard isRecording else { return }
        
        await audioService.cancelRecording()
        currentStatus = .ready
    }
    
    @MainActor
    private func handleKeyboardShortcut() async {
        if isRecording {
            // Stop recording
            let recordingURL = await stopRecording()
            if recordingURL != nil {
                // Recording completed successfully
            }
        } else {
            // Check permissions and start recording
            let hasPermission = await checkPermissions()
            if hasPermission {
                _ = await startRecording()
            }
        }
    }
    
    func pasteTranscribedText() async -> Bool {
        return await pasteService.pasteAtCursorLocation()
    }
}