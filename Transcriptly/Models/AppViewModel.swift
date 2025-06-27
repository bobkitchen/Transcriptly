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
import UserNotifications

final class AppViewModel: ObservableObject {
    @Published var currentStatus: AppStatus = .ready
    @Published var isRecording = false
    @Published var transcribedText: String = ""
    @Published var isTranscribing = false
    @Published var errorMessage: String? = nil
    @Published var selectedSidebarSection: SidebarSection = .home
    
    // Learning window states
    @Published var showEditReview = false
    @Published var showABTesting = false
    
    // Current transcription data for learning
    @Published var currentOriginalTranscription = ""
    @Published var currentAIRefinement = ""
    @Published var currentABOptionA = ""
    @Published var currentABOptionB = ""
    
    private let permissionsService = PermissionsService()
    private let audioService = AudioService()
    private let keyboardShortcutService = KeyboardShortcutService()
    private let transcriptionService = TranscriptionService()
    private let pasteService = PasteService()
    @Published var refinementService = RefinementService()
    @Published var capsuleController = CapsuleController()
    private let learningService = LearningService.shared
    
    init() {
        // Initialize status based on permissions
        updateStatusBasedOnPermissions()
        
        // Set up capsule controller reference
        capsuleController.setViewModel(self)
        
        // Request notification permissions
        requestNotificationPermissions()
        
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
        
        // Set up keyboard shortcut handlers
        keyboardShortcutService.onShortcutPressed = { [weak self] in
            Task { @MainActor in
                await self?.handleKeyboardShortcut()
            }
        }
        
        keyboardShortcutService.onModeChangePressed = { [weak self] mode in
            Task { @MainActor in
                self?.handleModeChange(mode)
            }
        }
        
        keyboardShortcutService.onCancelPressed = { [weak self] in
            Task { @MainActor in
                await self?.handleCancel()
            }
        }
        
        // Observe learning service state
        learningService.$shouldShowEditReview
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShow in
                if shouldShow {
                    self?.showEditReviewWindow()
                }
            }
            .store(in: &cancellables)
        
        learningService.$shouldShowABTest
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShow in
                if shouldShow {
                    self?.showABTestingWindow()
                }
            }
            .store(in: &cancellables)
    }
    
    var cancellables = Set<AnyCancellable>()
    
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
        
        // Update keyboard service recording state
        keyboardShortcutService.setRecordingState(recording)
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
                // Process transcription with refinement
                Task {
                    await processTranscription(text)
                }
            } else {
                self.transcribedText = ""
                self.errorMessage = "Transcription failed. Please try recording again."
            }
        }
    }
    
    private func processTranscription(_ text: String) async {
        do {
            let refinedText = try await refinementService.refine(text)
            await MainActor.run {
                self.transcribedText = refinedText
            }
            
            // Create learning session and check if learning windows should appear
            await createLearningSession(
                originalTranscription: text,
                aiRefinement: refinedText,
                userFinalVersion: refinedText, // For now, same as AI refinement
                wasSkipped: false
            )
            
            // Wait a moment for learning service to update its state
            try? await Task.sleep(for: .milliseconds(100))
            
            // Check if learning windows will appear - if so, don't auto-paste
            await MainActor.run {
                if !learningService.shouldShowEditReview && !learningService.shouldShowABTest {
                    // No learning windows - proceed with normal flow
                    completeTranscriptionWithText(refinedText)
                }
                // If learning windows should appear, they will be shown by the observers
                // and completion will happen when user finishes the learning interaction
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Refinement failed: \(error.localizedDescription)"
                self.transcribedText = text // Fall back to original text
            }
            
            // Create learning session for failed refinement
            await createLearningSession(
                originalTranscription: text,
                aiRefinement: "", // Failed to refine
                userFinalVersion: text, // Fallback to original
                wasSkipped: true
            )
            
            // For failed refinement, proceed with fallback text immediately
            await MainActor.run {
                completeTranscriptionWithText(text)
            }
        }
    }
    
    private func createLearningSession(
        originalTranscription: String,
        aiRefinement: String,
        userFinalVersion: String,
        wasSkipped: Bool
    ) async {
        // Store current transcription data for learning windows
        await MainActor.run {
            self.currentOriginalTranscription = originalTranscription
            self.currentAIRefinement = aiRefinement
            
            learningService.processCompletedTranscription(
                original: originalTranscription,
                refined: aiRefinement,
                refinementMode: refinementService.currentMode
            )
        }
        print("Learning session processed successfully")
    }
    
    // MARK: - Learning Window Management
    
    private func showEditReviewWindow() {
        showEditReview = true
    }
    
    private func showABTestingWindow() {
        // Generate two different refinement options for A/B testing
        generateABOptions()
        showABTesting = true
    }
    
    private func generateABOptions() {
        // For now, create simple variations
        // In a real implementation, this would use different AI parameters
        let baseText = currentAIRefinement
        
        // Option A: Current refinement
        currentABOptionA = baseText
        
        // Option B: Slight variation (more formal/less formal)
        currentABOptionB = createVariation(of: baseText)
    }
    
    private func createVariation(of text: String) -> String {
        // Simple variation: toggle contractions
        var variation = text
        
        // Expand contractions for a more formal variant
        let contractions = [
            "don't": "do not",
            "won't": "will not",
            "can't": "cannot",
            "I'm": "I am",
            "you're": "you are",
            "it's": "it is",
            "we're": "we are",
            "they're": "they are"
        ]
        
        for (contraction, expansion) in contractions {
            variation = variation.replacingOccurrences(of: contraction, with: expansion, options: .caseInsensitive)
        }
        
        return variation
    }
    
    func handleEditReviewComplete(finalText: String, wasSkipped: Bool) {
        showEditReview = false
        
        // Submit to learning service
        learningService.submitEditReview(
            original: currentOriginalTranscription,
            aiRefined: currentAIRefinement,
            userFinal: finalText,
            refinementMode: refinementService.currentMode,
            skipLearning: wasSkipped
        )
        
        // Use the final text for pasting
        completeTranscriptionWithText(finalText)
    }
    
    func handleABTestComplete(selectedOption: String) {
        showABTesting = false
        
        // Submit A/B test result to learning service
        learningService.submitABTest(
            original: currentOriginalTranscription,
            optionA: currentABOptionA,
            optionB: currentABOptionB,
            selected: selectedOption,
            refinementMode: refinementService.currentMode
        )
        
        // Use the selected option for pasting
        completeTranscriptionWithText(selectedOption)
    }
    
    private func completeTranscriptionWithText(_ text: String) {
        Task {
            // Update the transcribed text
            await MainActor.run {
                self.transcribedText = text
            }
            
            // Copy to clipboard
            await MainActor.run {
                self.pasteService.copyTextToClipboard(text)
            }
            
            // Paste automatically
            let pasteSuccess = await pasteService.pasteAtCursorLocation()
            
            await MainActor.run {
                if !pasteSuccess {
                    self.errorMessage = "Text copied to clipboard but failed to paste automatically"
                }
                // Show completion notification
                self.showCompletionNotification()
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
    
    private func handleModeChange(_ mode: RefinementMode) {
        refinementService.currentMode = mode
        showModeChangeNotification(mode)
    }
    
    private func showModeChangeNotification(_ mode: RefinementMode) {
        // Show brief visual feedback for mode change
        // This could be implemented as a temporary overlay or menu bar update
        print("Mode changed to: \(mode.rawValue)")
    }
    
    private func handleCancel() async {
        guard isRecording else { return }
        await audioService.cancelRecording()
        await MainActor.run {
            currentStatus = .ready
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Failed to request notification permissions: \(error)")
            }
        }
    }
    
    private func showCompletionNotification() {
        // Check user preferences
        let showNotifications = UserDefaults.standard.bool(forKey: "showNotifications")
        let playCompletionSound = UserDefaults.standard.bool(forKey: "playCompletionSound")
        
        if showNotifications {
            let content = UNMutableNotificationContent()
            content.title = "Transcription Complete"
            content.body = "Text has been copied to clipboard"
            
            if playCompletionSound {
                content.sound = .default
            }
            
            let request = UNNotificationRequest(
                identifier: "transcription-complete-\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil // Show immediately
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to show notification: \(error)")
                }
            }
        }
    }
}