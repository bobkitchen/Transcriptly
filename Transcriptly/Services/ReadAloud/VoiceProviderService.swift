//
//  VoiceProviderService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//

import Foundation
import AVFoundation
import Combine

private struct SpeechOperation {
    let id = UUID()
    let text: String
    let sentenceIndex: Int
    let characterOffset: Int
    let completion: (Bool) -> Void
    let createdAt = Date()
}

@MainActor
final class VoiceProviderService: NSObject, ObservableObject {
    @Published var availableVoices: [VoiceProvider] = []
    @Published var selectedVoice: VoiceProvider?
    @Published var voicePreferences = VoicePreferences()
    @Published var isLoading = false
    @Published var lastError: String?
    
    // Speech synthesis - Single instance best practice
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    
    // Operation management
    private var currentOperation: SpeechOperation?
    private var operationQueue: [SpeechOperation] = []
    
    // Audio playback for cloud TTS
    private var currentAudioPlayer: AVAudioPlayer?
    private var audioPlaybackTask: Task<Void, Never>?
    
    // Enhanced speech tracking
    private var currentSentenceIndex: Int = 0
    private var currentCharacterOffset: Int = 0
    @Published var speakingProgress: Double = 0.0
    
    // AI Provider Manager integration
    private let aiProviderManager = AIProviderManager.shared
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
        loadAvailableVoices()
        loadVoicePreferences()
    }
    
    // MARK: - Voice Management
    
    func loadAvailableVoices() {
        isLoading = true
        
        Task {
            var voices: [VoiceProvider] = []
            
            // Load Apple voices (always available)
            voices.append(contentsOf: VoiceProvider.availableAppleVoices())
            
            // Load cloud voices if providers are configured
            if aiProviderManager.providers[.googleCloud]?.isConfigured == true {
                voices.append(contentsOf: await loadGoogleCloudVoices())
            }
            
            if aiProviderManager.providers[.elevenLabs]?.isConfigured == true {
                voices.append(contentsOf: await loadElevenLabsVoices())
            }
            
            await MainActor.run {
                self.availableVoices = voices
                
                // Set default voice if none selected
                if selectedVoice == nil {
                    self.selectedVoice = voices.first { $0.type == .apple && $0.gender == .female }
                        ?? voices.first
                }
                
                self.isLoading = false
            }
        }
    }
    
    private func loadGoogleCloudVoices() async -> [VoiceProvider] {
        // This would fetch voices from Google Cloud TTS API
        // For now, return placeholder voices
        return [
            VoiceProvider(
                id: "google-en-us-wavenet-a",
                type: .googleCloud,
                name: "WaveNet-A",
                displayName: "WaveNet-A (US Female)",
                gender: .female,
                language: "English",
                languageCode: "en-US",
                isAvailable: true,
                quality: .premium,
                previewURL: nil,
                avVoice: nil,
                providerVoiceId: "en-US-Wavenet-A",
                modelType: "wavenet"
            ),
            VoiceProvider(
                id: "google-en-us-wavenet-b",
                type: .googleCloud,
                name: "WaveNet-B",
                displayName: "WaveNet-B (US Male)",
                gender: .male,
                language: "English",
                languageCode: "en-US",
                isAvailable: true,
                quality: .premium,
                previewURL: nil,
                avVoice: nil,
                providerVoiceId: "en-US-Wavenet-B",
                modelType: "wavenet"
            )
        ]
    }
    
    private func loadElevenLabsVoices() async -> [VoiceProvider] {
        // This would fetch voices from ElevenLabs API
        // For now, return placeholder voices
        return [
            VoiceProvider(
                id: "elevenlabs-rachel",
                type: .elevenLabs,
                name: "Rachel",
                displayName: "Rachel (Premium Female)",
                gender: .female,
                language: "English",
                languageCode: "en-US",
                isAvailable: true,
                quality: .premium,
                previewURL: nil,
                avVoice: nil,
                providerVoiceId: "21m00Tcm4TlvDq8ikWAM",
                modelType: "eleven_monolingual_v1"
            ),
            VoiceProvider(
                id: "elevenlabs-adam",
                type: .elevenLabs,
                name: "Adam",
                displayName: "Adam (Premium Male)",
                gender: .male,
                language: "English",
                languageCode: "en-US",
                isAvailable: true,
                quality: .premium,
                previewURL: nil,
                avVoice: nil,
                providerVoiceId: "pNInz6obpgDQGcFmaJgB",
                modelType: "eleven_monolingual_v1"
            )
        ]
    }
    
    func selectVoice(_ voice: VoiceProvider) {
        selectedVoice = voice
        voicePreferences.selectedVoiceId = voice.id
        voicePreferences.preferredProvider = voice.type
        saveVoicePreferences()
    }
    
    // MARK: - Speech Synthesis
    
    /// Speaks a specific sentence with tracking information
    func speakSentence(text: String, sentenceIndex: Int, characterOffset: Int, completion: @escaping (Bool) -> Void) async {
        // Create new operation
        let operation = SpeechOperation(
            text: text,
            sentenceIndex: sentenceIndex,
            characterOffset: characterOffset,
            completion: completion
        )
        
        // Cancel any existing operation
        if let current = currentOperation {
            print("🔄 Canceling previous speech operation: \(current.id)")
            speechSynthesizer.stopSpeaking(at: .immediate)
            currentAudioPlayer?.stop()
            audioPlaybackTask?.cancel()
            
            // Complete the cancelled operation without setting error
            current.completion(false)
        }
        
        // Set as current operation
        currentOperation = operation
        currentSentenceIndex = sentenceIndex
        currentCharacterOffset = characterOffset
        speakingProgress = 0.0
        
        print("🔄 Starting speech operation: \(operation.id) for sentence \(sentenceIndex)")
        print("🔄 Current operation set to: \(operation.id)")
        
        // Execute the operation
        await executeSpeechOperation(operation)
    }
    
    private func executeSpeechOperation(_ operation: SpeechOperation) async {
        // Ensure this is still the current operation
        guard currentOperation?.id == operation.id else {
            print("🔄 Operation \(operation.id) no longer current, skipping")
            return
        }
        
        // Use the selected TTS provider from AI Providers
        let selectedProvider = aiProviderManager.preferences.textToSpeechProvider
        
        switch selectedProvider {
        case .apple:
            let appleVoice = availableVoices.first { $0.type == .apple } ?? availableVoices.first
            if let voice = appleVoice {
                await speakWithApple(text: operation.text, voice: voice, operation: operation)
            } else {
                lastError = "No Apple voice available"
                completeOperation(operation, success: false)
            }
        case .googleCloud:
            let voiceId = aiProviderManager.preferences.googleCloudTTSVoice
            let googleVoice = availableVoices.first { $0.type == .googleCloud && $0.providerVoiceId == voiceId }
                ?? availableVoices.first { $0.type == .googleCloud }
            if let voice = googleVoice {
                await speakWithGoogleCloud(text: operation.text, voice: voice)
            } else {
                lastError = "No Google Cloud voice available"
                completeOperation(operation, success: false)
            }
        case .elevenLabs:
            let voiceId = aiProviderManager.preferences.elevenLabsTTSVoice
            let elevenlabsVoice = availableVoices.first { $0.type == .elevenLabs && $0.name.lowercased() == voiceId }
                ?? availableVoices.first { $0.type == .elevenLabs }
            if let voice = elevenlabsVoice {
                await speakWithElevenLabs(text: operation.text, voice: voice)
            } else {
                lastError = "No ElevenLabs voice available"
                completeOperation(operation, success: false)
            }
        case .openai, .openrouter:
            let appleVoice = availableVoices.first { $0.type == .apple } ?? availableVoices.first
            if let voice = appleVoice {
                await speakWithApple(text: operation.text, voice: voice, operation: operation)
            } else {
                lastError = "No voice available"
                completeOperation(operation, success: false)
            }
        }
    }
    
    private func completeOperation(_ operation: SpeechOperation, success: Bool) {
        guard currentOperation?.id == operation.id else {
            print("🔄 Operation \(operation.id) already replaced, not completing")
            return
        }
        
        print("🔄 Completing operation \(operation.id) with success: \(success)")
        currentOperation = nil
        operation.completion(success)
    }
    
    func speak(text: String, completion: @escaping (Bool) -> Void) async {
        await speakSentence(text: text, sentenceIndex: 0, characterOffset: 0, completion: completion)
    }
    
    private func speakWithApple(text: String, voice: VoiceProvider, operation: SpeechOperation) async {
        guard let avVoiceId = voice.avVoice,
              let avVoice = AVSpeechSynthesisVoice(identifier: avVoiceId) else {
            lastError = "Apple voice not available"
            completeOperation(operation, success: false)
            return
        }
        
        // Ensure this is still the current operation
        guard currentOperation?.id == operation.id else {
            print("🔄 Operation \(operation.id) no longer current during Apple speech setup")
            return
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = avVoice
        utterance.rate = voicePreferences.speechRate
        utterance.pitchMultiplier = voicePreferences.pitch
        utterance.volume = voicePreferences.volume
        
        currentUtterance = utterance
        speechSynthesizer.speak(utterance)
    }
    
    private func speakWithGoogleCloud(text: String, voice: VoiceProvider) async {
        guard let provider = aiProviderManager.providers[.googleCloud] as? GoogleCloudProvider,
              provider.isConfigured,
              let operation = currentOperation else {
            lastError = "Google Cloud TTS not configured"
            if let operation = currentOperation {
                completeOperation(operation, success: false)
            }
            return
        }
        
        // Use AI Provider Manager to synthesize speech
        let result = await aiProviderManager.synthesizeSpeech(text: text)
        
        switch result {
        case .success(let audioData):
            // Play the audio data
            await playAudioData(audioData, operation: operation)
        case .failure(let error):
            lastError = "Google Cloud TTS failed: \(error.localizedDescription)"
            completeOperation(operation, success: false)
        }
    }
    
    private func speakWithElevenLabs(text: String, voice: VoiceProvider) async {
        guard let provider = aiProviderManager.providers[.elevenLabs] as? ElevenLabsProvider,
              provider.isConfigured,
              let operation = currentOperation else {
            lastError = "ElevenLabs TTS not configured"
            if let operation = currentOperation {
                completeOperation(operation, success: false)
            }
            return
        }
        
        // Use AI Provider Manager to synthesize speech
        let result = await aiProviderManager.synthesizeSpeech(text: text)
        
        switch result {
        case .success(let audioData):
            // Play the audio data
            await playAudioData(audioData, operation: operation)
        case .failure(let error):
            lastError = "ElevenLabs TTS failed: \(error.localizedDescription)"
            completeOperation(operation, success: false)
        }
    }
    
    func stopSpeaking() {
        print("🔄 Stopping all speech operations")
        
        // Clear current operation but don't call completion - let the delegate handle it
        if let operation = currentOperation {
            print("🔄 Clearing current operation: \(operation.id)")
            currentOperation = nil
        }
        
        // Stop Apple speech synthesizer (for built-in voices)
        speechSynthesizer.stopSpeaking(at: .immediate)
        currentUtterance = nil
        
        // Stop audio player for cloud TTS (Google Cloud, ElevenLabs)
        currentAudioPlayer?.stop()
        currentAudioPlayer = nil
        
        // Cancel any ongoing audio playback task to prevent orphaned players
        audioPlaybackTask?.cancel()
        audioPlaybackTask = nil
    }
    
    func pauseSpeaking() {
        speechSynthesizer.pauseSpeaking(at: .word)
        currentAudioPlayer?.pause()
    }
    
    func resumeSpeaking() {
        speechSynthesizer.continueSpeaking()
        currentAudioPlayer?.play()
    }
    
    var isSpeaking: Bool {
        return speechSynthesizer.isSpeaking || currentAudioPlayer?.isPlaying == true
    }
    
    var isPaused: Bool {
        return speechSynthesizer.isPaused || (currentAudioPlayer != nil && currentAudioPlayer?.isPlaying == false)
    }
    
    // MARK: - Voice Preferences
    
    private func loadVoicePreferences() {
        if let data = UserDefaults.standard.data(forKey: "VoicePreferences"),
           let preferences = try? JSONDecoder().decode(VoicePreferences.self, from: data) {
            voicePreferences = preferences
        }
    }
    
    private func saveVoicePreferences() {
        if let data = try? JSONEncoder().encode(voicePreferences) {
            UserDefaults.standard.set(data, forKey: "VoicePreferences")
        }
    }
    
    func updateSpeechRate(_ rate: Float) {
        voicePreferences.speechRate = max(0.5, min(2.0, rate))
        saveVoicePreferences()
    }
    
    func setPlaybackRate(_ rate: Float) {
        let clampedRate = max(0.5, min(2.5, rate))
        
        // Update preferences
        voicePreferences.speechRate = clampedRate
        saveVoicePreferences()
        
        // For cloud TTS (Google Cloud, ElevenLabs), we need to modify the audio player rate
        if let audioPlayer = currentAudioPlayer {
            print("🎚️ VoiceProviderService: Applying rate \(clampedRate)x to audio player (cloud TTS)")
            audioPlayer.rate = clampedRate
            audioPlayer.enableRate = true // Enable rate changes for audio player
        }
        
        // For Apple voices, the rate will be applied to new utterances via voicePreferences.speechRate
        if currentUtterance != nil {
            print("🎚️ VoiceProviderService: Rate change will apply to next utterance (Apple TTS)")
        }
        
        print("🎚️ VoiceProviderService: Set playback rate to \(clampedRate)x")
    }
    
    func updatePitch(_ pitch: Float) {
        voicePreferences.pitch = max(0.8, min(1.2, pitch))
        saveVoicePreferences()
    }
    
    func updateVolume(_ volume: Float) {
        voicePreferences.volume = max(0.0, min(1.0, volume))
        saveVoicePreferences()
    }
    
    // MARK: - Audio Playback
    
    private func playAudioData(_ audioData: Data, operation: SpeechOperation) async {
        // Stop any existing audio playback first
        currentAudioPlayer?.stop()
        audioPlaybackTask?.cancel()
        
        audioPlaybackTask = Task {
            do {
                // Ensure this is still the current operation
                guard currentOperation?.id == operation.id else {
                    print("🔄 Audio playback cancelled - operation no longer current")
                    return
                }
                
                // Create a temporary file for the audio data
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mp3")
                
                try audioData.write(to: tempURL)
                
                // Use AVAudioPlayer to play the audio
                let audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
                currentAudioPlayer = audioPlayer
                
                // Enable rate changes and apply current speech rate
                audioPlayer.enableRate = true
                audioPlayer.rate = voicePreferences.speechRate
                print("🎚️ VoiceProviderService: Created audio player with rate \(voicePreferences.speechRate)x")
                
                audioPlayer.play()
                
                // Wait for playback to complete
                while audioPlayer.isPlaying && !Task.isCancelled {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
                
                // Clean up temporary file
                try? FileManager.default.removeItem(at: tempURL)
                
                // Complete the operation if task wasn't cancelled and operation is still current
                if !Task.isCancelled && currentOperation?.id == operation.id {
                    await MainActor.run {
                        self.completeOperation(operation, success: true)
                        currentAudioPlayer = nil
                    }
                }
                
            } catch {
                await MainActor.run {
                    lastError = "Audio playback failed: \(error.localizedDescription)"
                    if currentOperation?.id == operation.id {
                        self.completeOperation(operation, success: false)
                    }
                    currentAudioPlayer = nil
                }
            }
        }
        
        await audioPlaybackTask?.value
    }
    
    // MARK: - Voice Filtering
    
    func voices(for provider: VoiceProviderType) -> [VoiceProvider] {
        return availableVoices.filter { $0.type == provider }
    }
    
    func voices(for gender: VoiceGender) -> [VoiceProvider] {
        return availableVoices.filter { $0.gender == gender }
    }
    
    func voices(for language: String) -> [VoiceProvider] {
        return availableVoices.filter { $0.languageCode.hasPrefix(language) }
    }
    
    // MARK: - Voice Preview
    
    func previewVoice(_ voice: VoiceProvider) async {
        let previewText = "Hello, this is a preview of the \(voice.displayName) voice."
        
        let previousVoice = selectedVoice
        selectedVoice = voice
        
        await speak(text: previewText) { _ in
            // Restore previous voice selection after preview
            Task { @MainActor in
                self.selectedVoice = previousVoice
            }
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceProviderService: @preconcurrency AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard let operation = currentOperation else {
            print("🔄 Speech finished but no current operation")
            return
        }
        
        currentUtterance = nil
        print("🔄 Speech finished successfully for operation: \(operation.id)")
        completeOperation(operation, success: true)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        currentUtterance = nil
        print("🔄 Speech cancelled (intentional stop)")
        
        // Don't call any completion handlers for cancellations
        // Cancellations are intentional and should not trigger error states
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // Calculate speaking progress
        let totalLength = utterance.speechString.count
        if totalLength > 0 {
            speakingProgress = Double(characterRange.location + characterRange.length) / Double(totalLength)
        }
        
        // Post notification with detailed information
        NotificationCenter.default.post(
            name: .speechRangeChanged,
            object: self,
            userInfo: [
                "range": characterRange,
                "utterance": utterance,
                "sentenceIndex": currentSentenceIndex,
                "globalCharacterOffset": currentCharacterOffset + characterRange.location,
                "progress": speakingProgress
            ]
        )
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let speechRangeChanged = Notification.Name("speechRangeChanged")
}