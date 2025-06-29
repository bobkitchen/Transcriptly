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
import AppKit
import ObjectiveC


final class AppViewModel: ObservableObject {
    @Published var currentStatus: AppStatus = .ready
    @Published var isRecording = false
    @Published var transcribedText: String = ""
    @Published var isTranscribing = false
    @Published var errorMessage: String? = nil
    @Published var selectedSidebarSection: SidebarSection = .home
    
    // Learning window controllers
    private var editReviewWindow: NSWindow?
    private var abTestingWindow: NSWindow?
    
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
    private let historyService = TranscriptionHistoryService.shared
    private let appDetectionService = AppDetectionService.shared
    private let aiProviderManager = AIProviderManager.shared
    
    // App detection state
    @Published var detectedApp: AppInfo?
    @Published var autoSelectedMode: RefinementMode?
    @Published var showModeDetectionIndicator = false
    
    // Recording metadata for history
    private var recordingStartTime: Date?
    
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
                print("⌨️ Recording shortcut triggered")
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
        
        // Note: Removed Combine observers for learning service flags to prevent race conditions
        // Learning window presentation is now handled directly in processTranscription
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
        print("🎤 startRecording() called")
        
        guard permissionsService.hasPermission else { 
            print("❌ No microphone permission")
            await MainActor.run {
                errorMessage = "Microphone permission required"
            }
            return false 
        }
        
        await MainActor.run {
            errorMessage = nil
            currentStatus = .recording
            recordingStartTime = Date()
        }
        
        print("🎤 Starting audio service...")
        let success = await audioService.startRecording()
        
        if !success {
            print("❌ Audio service failed to start")
            await MainActor.run {
                currentStatus = .ready
                errorMessage = "Failed to start recording. Please check your microphone."
            }
            return false
        }
        
        print("✅ Recording started successfully")
        
        // Do app detection after recording starts successfully
        Task {
            print("🔍 Starting app detection...")
            // Add small delay to ensure app focus has switched
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms delay
            
            let (app, recommendedMode) = await appDetectionService.detectAndRecommendMode()
            
            // Debug output for app detection issues
            if let app = app {
                print("🔍 Detected: \(app.displayName) → \(recommendedMode?.displayName ?? "No mode")")
            } else if appDetectionService.isAutoDetectionEnabled {
                print("🔍 No app detected (auto-detection enabled)")
            } else {
                print("🔍 App detection is disabled")
            }
            
            await MainActor.run {
                // Store detected app
                detectedApp = app
                
                // Apply mode recommendation if available
                if let mode = recommendedMode {
                    autoSelectedMode = mode
                    refinementService.currentMode = mode
                    showModeDetectionIndicator = true
                    
                    // Hide indicator after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showModeDetectionIndicator = false
                    }
                } else {
                    autoSelectedMode = nil
                }
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
        // Check if speech recognition permission is needed for Apple provider fallback
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
        
        // Load audio data for AI providers
        guard let audioData = try? Data(contentsOf: url) else {
            await MainActor.run {
                self.errorMessage = "Failed to load audio file"
            }
            return
        }
        
        // Use AI Provider Manager for transcription
        let result = await aiProviderManager.transcribe(audio: audioData)
        
        await MainActor.run {
            switch result {
            case .success(let text):
                if !text.isEmpty {
                    // Process transcription with refinement
                    Task {
                        await processTranscription(text)
                    }
                } else {
                    self.transcribedText = ""
                    self.errorMessage = "Transcription returned empty text"
                }
            case .failure(let error):
                self.transcribedText = ""
                self.errorMessage = "Transcription failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func processTranscription(_ text: String) async {
        // Use AI Provider Manager for refinement
        let result = await aiProviderManager.refine(text: text, mode: refinementService.currentMode)
        
        await MainActor.run {
            switch result {
            case .success(let refinedText):
                self.transcribedText = refinedText
            case .failure(let error):
                // Fall back to original text if refinement fails
                self.transcribedText = text
                print("Refinement failed, using original text: \(error.localizedDescription)")
            }
        }
        
        let finalText = await MainActor.run { self.transcribedText }
        
        // Create learning session and check if learning windows should appear
        await createLearningSession(
            originalTranscription: text,
            aiRefinement: finalText,
            userFinalVersion: finalText, // For now, same as AI refinement
            wasSkipped: false
        )
        
        // Learning windows are now handled directly in createLearningSession
        // Wait a moment to allow the UI to update, then check if we need to auto-complete
        try? await Task.sleep(for: .milliseconds(200))
        
        await MainActor.run {
            let hasEditWindow = editReviewWindow != nil
            let hasABWindow = abTestingWindow != nil
            print("Post-learning check: editReviewWindow = \(hasEditWindow), abTestingWindow = \(hasABWindow)")
            if !hasEditWindow && !hasABWindow {
                // No learning windows - proceed with normal flow
                print("No learning windows shown, proceeding with auto-completion")
                completeTranscriptionWithText(finalText)
            } else {
                print("Learning window shown, waiting for user interaction")
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
            print("Stored learning data - Original: '\(originalTranscription)', AI: '\(aiRefinement)'")
        }
        
        // Check if learning should be triggered - call learning service for decision
        let shouldShowLearning = await MainActor.run {
            return learningService.shouldTriggerLearning(
                original: originalTranscription,
                refined: aiRefinement,
                refinementMode: refinementService.currentMode
            )
        }
        
        // Directly control window presentation based on learning decision
        await MainActor.run {
            switch shouldShowLearning {
            case .editReview:
                print("Directly showing Edit Review window")
                self.showEditReviewWindow()
            case .abTesting:
                print("Directly showing A/B Testing window")
                self.generateABOptions()
                self.showABTestingWindow()
            case .none:
                print("No learning window needed")
                break
            }
        }
        
        print("Learning session processed successfully")
    }
    
    // MARK: - Learning Window Management
    // Note: Learning windows are now proper NSWindows to work with capsule mode
    
    private func showEditReviewWindow() {
        // Close any existing edit review window
        editReviewWindow?.close()
        
        let contentView = EditReviewWindow(
            originalTranscription: currentOriginalTranscription,
            aiRefinement: currentAIRefinement,
            refinementMode: refinementService.currentMode
        ) { [weak self] finalText, wasSkipped in
            Task { @MainActor in
                self?.handleEditReviewComplete(finalText: finalText, wasSkipped: wasSkipped)
            }
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Review & Improve Transcription"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        
        // CRITICAL: Prevent autorelease pool crash when window closes
        window.isReleasedWhenClosed = false
        
        // Store reference and set up cleanup
        editReviewWindow = window
        
        // Set up window delegate to clean up when closed (saves original SwiftUI delegate)
        let delegate = LearningWindowDelegate(window: window) { [weak self] in
            self?.cleanupEditReviewWindow()
        }
        window.delegate = delegate
        
        // Keep strong reference to delegate to prevent deallocation
        objc_setAssociatedObject(window, "editReviewDelegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        print("Edit Review window created and shown")
    }
    
    private func showABTestingWindow() {
        // Close any existing A/B testing window
        abTestingWindow?.close()
        
        let contentView = ABTestingWindow(
            originalTranscription: currentOriginalTranscription,
            optionA: currentABOptionA,
            optionB: currentABOptionB,
            refinementMode: refinementService.currentMode
        ) { [weak self] selectedOption in
            Task { @MainActor in
                self?.handleABTestComplete(selectedOption: selectedOption)
            }
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Choose Your Preference"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        
        // CRITICAL: Prevent autorelease pool crash when window closes
        window.isReleasedWhenClosed = false
        
        // Store reference and set up cleanup
        abTestingWindow = window
        
        // Set up window delegate to clean up when closed (saves original SwiftUI delegate)
        let delegate = LearningWindowDelegate(window: window) { [weak self] in
            self?.cleanupABTestingWindow()
        }
        window.delegate = delegate
        
        // Keep strong reference to delegate to prevent deallocation
        objc_setAssociatedObject(window, "abTestingDelegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        print("A/B Testing window created and shown")
    }
    
    // MARK: - Safe Window Cleanup
    
    private func cleanupEditReviewWindow() {
        guard let window = editReviewWindow else { return }
        
        // Clear associated objects - delegate restoration happens in windowWillClose
        objc_setAssociatedObject(window, "editReviewDelegate", nil, .OBJC_ASSOCIATION_ASSIGN)
        
        // Close and clear reference
        if window.isVisible {
            window.close()
        }
        editReviewWindow = nil
        
        print("Edit Review window cleaned up safely")
    }
    
    private func cleanupABTestingWindow() {
        guard let window = abTestingWindow else { return }
        
        // Clear associated objects - delegate restoration happens in windowWillClose
        objc_setAssociatedObject(window, "abTestingDelegate", nil, .OBJC_ASSOCIATION_ASSIGN)
        
        // Close and clear reference
        if window.isVisible {
            window.close()
        }
        abTestingWindow = nil
        
        print("A/B Testing window cleaned up safely")
    }
    
    private func generateABOptions() {
        // For now, create simple variations
        // In a real implementation, this would use different AI parameters
        let baseText = currentAIRefinement.isEmpty ? currentOriginalTranscription : currentAIRefinement
        
        print("Generating A/B options from base text: '\(baseText)'")
        
        // Option A: Current refinement (or original if refinement failed)
        currentABOptionA = baseText
        
        // Option B: Slight variation (more formal/less formal)
        currentABOptionB = createVariation(of: baseText)
        
        print("Option A: '\(currentABOptionA)'")
        print("Option B: '\(currentABOptionB)'")
    }
    
    private func createVariation(of text: String) -> String {
        guard !text.isEmpty else { return "Option B (no text)" }
        
        // Simple variation: toggle contractions and formality
        var variation = text
        var hasChanges = false
        
        // Expand contractions for a more formal variant
        let contractions = [
            "don't": "do not",
            "won't": "will not", 
            "can't": "cannot",
            "I'm": "I am",
            "you're": "you are",
            "it's": "it is",
            "we're": "we are", 
            "they're": "they are",
            "that's": "that is",
            "there's": "there is"
        ]
        
        for (contraction, expansion) in contractions {
            let newVariation = variation.replacingOccurrences(of: contraction, with: expansion, options: .caseInsensitive)
            if newVariation != variation {
                variation = newVariation
                hasChanges = true
            }
        }
        
        // If no contractions found, try other variations
        if !hasChanges {
            // Try making it more concise by removing filler words
            let fillerWords = ["really", "actually", "basically", "obviously", "clearly"]
            for filler in fillerWords {
                let pattern = "\\b\(filler)\\s+"
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let range = NSRange(location: 0, length: variation.utf16.count)
                    let newVariation = regex.stringByReplacingMatches(in: variation, options: [], range: range, withTemplate: "")
                    if newVariation != variation {
                        variation = newVariation.trimmingCharacters(in: .whitespaces)
                        hasChanges = true
                        break
                    }
                }
            }
        }
        
        // If still no changes, add a simple variation
        if !hasChanges {
            variation = text + " (refined)"
        }
        
        return variation
    }
    
    func handleEditReviewComplete(finalText: String, wasSkipped: Bool) {
        // Clean up window safely
        cleanupEditReviewWindow()
        
        // Submit to learning service
        learningService.submitEditReview(
            original: currentOriginalTranscription,
            aiRefined: currentAIRefinement,
            userFinal: finalText,
            refinementMode: refinementService.currentMode,
            skipLearning: wasSkipped
        )
        
        // Use the final text for pasting
        completeTranscriptionWithText(finalText, learningType: .editReview)
    }
    
    func handleABTestComplete(selectedOption: String) {
        // Clean up window safely
        cleanupABTestingWindow()
        
        // Submit A/B test result to learning service
        learningService.submitABTest(
            original: currentOriginalTranscription,
            optionA: currentABOptionA,
            optionB: currentABOptionB,
            selected: selectedOption,
            refinementMode: refinementService.currentMode
        )
        
        // Use the selected option for pasting
        completeTranscriptionWithText(selectedOption, learningType: .abTesting)
    }
    
    private func completeTranscriptionWithText(_ text: String, learningType: LearningType? = nil) {
        Task {
            // Calculate recording duration
            let duration: TimeInterval? = await MainActor.run {
                guard let startTime = recordingStartTime else { return nil }
                return Date().timeIntervalSince(startTime)
            }
            
            // Save transcription to history
            await MainActor.run {
                historyService.createAndSaveTranscription(
                    original: currentOriginalTranscription,
                    refined: currentAIRefinement,
                    final: text,
                    mode: refinementService.currentMode,
                    duration: duration,
                    wasLearningTriggered: learningType != nil,
                    learningType: learningType
                )
            }
            
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
                
                // Clear recording start time
                recordingStartTime = nil
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

// MARK: - Learning Window Delegate

class LearningWindowDelegate: NSObject, NSWindowDelegate {
    private var onClose: (() -> Void)?
    private weak var window: NSWindow?
    private weak var originalDelegate: NSWindowDelegate?
    
    init(window: NSWindow, onClose: @escaping () -> Void) {
        self.window = window
        self.onClose = onClose
        // Save the original SwiftUI delegate before overriding
        self.originalDelegate = window.delegate
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        // Restore original SwiftUI delegate for proper cleanup
        window?.delegate = originalDelegate
        
        // Call our cleanup once and clear to prevent double-calls
        let cleanup = onClose
        onClose = nil
        cleanup?()
    }
    
    deinit {
        onClose = nil
        originalDelegate = nil
    }
}