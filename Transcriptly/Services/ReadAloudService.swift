//
//  ReadAloudService.swift
//  Transcriptly
//
//  Created by Claude Code on 8/6/25.
//

import Foundation
import AVFoundation
import Combine

@MainActor
class ReadAloudService: ObservableObject {
    @Published var isReading = false
    @Published var currentDocument: String?
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    @Published var selectedVoiceIdentifier: String?
    @Published var speechRate: Float = 0.5
    @Published var pitch: Float = 1.0
    
    private let synthesizer = AVSpeechSynthesizer()
    
    init() {
        loadAvailableVoices()
    }
    
    private func loadAvailableVoices() {
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
        if let defaultVoice = AVSpeechSynthesisVoice(language: "en-US") {
            selectedVoiceIdentifier = defaultVoice.identifier
        }
    }
    
    func startReading(_ text: String) {
        guard !text.isEmpty else { return }
        
        stopReading()
        
        let utterance = AVSpeechUtterance(string: text)
        
        if let voiceID = selectedVoiceIdentifier,
           let voice = availableVoices.first(where: { $0.identifier == voiceID }) {
            utterance.voice = voice
        }
        
        utterance.rate = speechRate
        utterance.pitchMultiplier = pitch
        
        currentDocument = text
        isReading = true
        synthesizer.speak(utterance)
    }
    
    func stopReading() {
        synthesizer.stopSpeaking(at: .immediate)
        isReading = false
    }
    
    func pauseReading() {
        synthesizer.pauseSpeaking(at: .immediate)
    }
    
    func resumeReading() {
        synthesizer.continueSpeaking()
    }
}