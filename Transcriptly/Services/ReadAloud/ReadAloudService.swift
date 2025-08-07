//
//  ReadAloudService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//

import Foundation
import Combine

@MainActor
final class ReadAloudService: ObservableObject {
    @Published var currentDocument: ProcessedDocument?
    @Published var currentSession: ReadingSession?
    @Published var sessionState: ReadingSessionState = .idle
    @Published var currentSentenceIndex: Int = 0
    @Published var progress: Double = 0.0
    @Published var lastError: String?
    @Published var playbackSpeed: Float = 1.0
    
    // Services
    private let documentProcessingService = DocumentProcessingService()
    private let voiceProviderService = VoiceProviderService()
    private let documentHistoryService = DocumentHistoryService()
    
    // Reading control
    private var readingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        setupNotifications()
    }
    
    private func setupBindings() {
        // Listen for voice service state changes
        voiceProviderService.$lastError
            .compactMap { $0 }
            .sink { [weak self] error in
                guard let self = self else { return }
                print("🔄 VoiceProvider error received: \(error), currentState=\(self.sessionState)")
                self.lastError = error
                // Only set error state if we're actively trying to play
                // Don't override intentional stops/pauses with error state
                if self.sessionState == .playing {
                    print("🔄 Setting error state from VoiceProvider binding")
                    self.sessionState = .error
                } else {
                    print("🔄 Not setting error state - not currently playing")
                }
            }
            .store(in: &cancellables)
        
        // Listen for document processing state
        documentProcessingService.$lastError
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.lastError = error
            }
            .store(in: &cancellables)
    }
    
    private func setupNotifications() {
        // Listen for speech range changes for highlighting
        NotificationCenter.default.publisher(for: .speechRangeChanged)
            .compactMap { $0.userInfo }
            .sink { [weak self] userInfo in
                guard let self = self else { return }
                
                // Extract progress information
                if let progress = userInfo["progress"] as? Double {
                    // Update fine-grained progress for current sentence
                    let sentenceProgress = self.progress + (progress / Double(self.currentDocument?.sentences.count ?? 1))
                    self.progress = min(1.0, sentenceProgress)
                }
                
                // Post notification for UI highlighting
                NotificationCenter.default.post(
                    name: .readAloudHighlightUpdate,
                    object: self,
                    userInfo: userInfo
                )
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Document Management
    
    func loadDocument(from url: URL) async {
        do {
            sessionState = .loading
            let document = try await documentProcessingService.processDocument(from: url)
            
            currentDocument = document
            currentSentenceIndex = 0
            progress = 0.0
            sessionState = .idle
            
            // Save to history
            await documentHistoryService.saveDocument(document)
            
        } catch {
            lastError = error.localizedDescription
            sessionState = .error
        }
    }
    
    func loadWebContent(from url: URL) async {
        do {
            sessionState = .loading
            let document = try await documentProcessingService.processWebContent(from: url)
            
            currentDocument = document
            currentSentenceIndex = 0
            progress = 0.0
            sessionState = .idle
            
            // Save to history
            await documentHistoryService.saveDocument(document)
            
        } catch {
            lastError = error.localizedDescription
            sessionState = .error
        }
    }
    
    func loadText(_ text: String, title: String = "Text Document") async {
        let document = await documentProcessingService.processText(text, title: title)
        
        currentDocument = document
        currentSentenceIndex = 0
        progress = 0.0
        sessionState = .idle
        
        // Save to history
        await documentHistoryService.saveDocument(document)
    }
    
    func loadProcessedDocument(_ document: ProcessedDocument) async {
        currentDocument = document
        currentSentenceIndex = 0
        progress = 0.0
        sessionState = .idle
        
        // Save to history
        await documentHistoryService.saveDocument(document)
        
        // Check for existing session to resume
        await checkForExistingSession(documentId: document.id)
    }
    
    private func checkForExistingSession(documentId: UUID) async {
        // Look for the most recent incomplete session for this document
        let sessions = documentHistoryService.getSessionsForDocument(documentId)
        if let lastSession = sessions.filter({ !$0.isCompleted }).last {
            // Resume from last position
            currentSession = lastSession
            currentSentenceIndex = lastSession.currentSentenceIndex
            progress = lastSession.progress
            
            // Notify UI about resumable session
            NotificationCenter.default.post(
                name: .readAloudSessionResumable,
                object: self,
                userInfo: ["session": lastSession]
            )
        }
    }
    
    // MARK: - Reading Control
    
    func startReading() async {
        print("🔄 StartReading: Called with state=\(sessionState)")
        
        guard let document = currentDocument else {
            print("🔄 StartReading: No document available")
            return
        }
        
        guard sessionState.canPlay else {
            print("🔄 StartReading: Cannot play in state=\(sessionState)")
            return
        }
        
        print("🔄 StartReading: Proceeding with start")
        
        // Create or resume session
        if currentSession == nil {
            currentSession = ReadingSession(
                documentId: document.id,
                voiceProvider: voiceProviderService.selectedVoice
            )
        }
        
        sessionState = .playing
        startProgressTimer()
        await readCurrentSentence()
    }
    
    func pauseReading() {
        guard sessionState.canPause else { return }
        
        voiceProviderService.pauseSpeaking()
        sessionState = .paused
        currentSession?.pause()
        stopReadingTimer()
    }
    
    func resumeReading() async {
        guard sessionState == .paused else { return }
        
        if voiceProviderService.isPaused {
            voiceProviderService.resumeSpeaking()
        } else {
            await readCurrentSentence()
        }
        
        sessionState = .playing
        currentSession?.resume()
    }
    
    func stopReading() {
        guard sessionState.canStop else { return }
        
        // Immediately stop the voice provider
        voiceProviderService.stopSpeaking()
        
        // Set state to stopped to prevent any pending operations
        sessionState = .stopped
        stopReadingTimer()
        
        // Update session
        if var session = currentSession {
            session.updateProgress(
                sentenceIndex: currentSentenceIndex,
                totalSentences: currentDocument?.sentences.count ?? 0
            )
            currentSession = session
        }
    }
    
    func seekToSentence(_ index: Int) async {
        guard let document = currentDocument,
              index >= 0 && index < document.sentences.count else { 
            print("🔄 SeekToSentence: Invalid document or index")
            return 
        }
        
        let wasPlaying = sessionState == .playing
        print("🔄 SeekToSentence: index=\(index), wasPlaying=\(wasPlaying), currentState=\(sessionState)")
        
        // Stop any current speech - the new operation system handles this cleanly
        voiceProviderService.stopSpeaking()
        
        // Set state appropriately
        if wasPlaying {
            sessionState = .stopped
            print("🔄 SeekToSentence: Set state to .stopped")
        } else {
            print("🔄 SeekToSentence: Keeping state as \(sessionState) (wasn't playing)")
        }
        
        stopReadingTimer()
        
        // Brief pause to ensure cleanup
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        currentSentenceIndex = index
        updateProgress()
        print("🔄 SeekToSentence: Updated to sentence \(index)")
        
        // Restart if we were playing before
        if wasPlaying {
            print("🔄 SeekToSentence: About to restart reading")
            await startReading()
        } else {
            print("🔄 SeekToSentence: Not restarting (wasn't playing)")
        }
    }
    
    func setPlaybackSpeed(_ speed: Float) async {
        print("🎚️ SetPlaybackSpeed: Setting speed to \(speed)x")
        
        // Clamp speed to reasonable bounds
        let clampedSpeed = max(0.5, min(2.5, speed))
        playbackSpeed = clampedSpeed
        
        // Apply speed to voice provider if currently speaking
        voiceProviderService.setPlaybackRate(clampedSpeed)
        
        // Update current session settings
        if var session = currentSession {
            session.playbackSettings.speechRate = clampedSpeed
            currentSession = session
        }
        
        print("🎚️ SetPlaybackSpeed: Speed set to \(clampedSpeed)x")
    }
    
    // MARK: - Private Reading Methods
    
    private func readCurrentSentence() async {
        print("🔄 ReadCurrentSentence: Called for sentence \(currentSentenceIndex), state=\(sessionState)")
        
        guard let document = currentDocument,
              currentSentenceIndex < document.sentences.count else {
            print("🔄 ReadCurrentSentence: No document or invalid index, completing")
            completeReading()
            return
        }
        
        // Don't start reading if we're not in playing state
        guard sessionState == .playing else {
            print("🔄 ReadCurrentSentence: Not in playing state (state=\(sessionState)), returning")
            return
        }
        
        print("🔄 ReadCurrentSentence: Proceeding to speak sentence \(currentSentenceIndex)")
        
        let sentence = document.sentences[currentSentenceIndex]
        
        // Calculate character offset for this sentence
        var characterOffset = 0
        if currentSentenceIndex > 0 {
            characterOffset = document.sentences[0..<currentSentenceIndex]
                .map { $0.text.count + 1 } // +1 for space between sentences
                .reduce(0, +)
        }
        
        // Use enhanced speak method with tracking
        await voiceProviderService.speakSentence(
            text: sentence.text,
            sentenceIndex: currentSentenceIndex,
            characterOffset: characterOffset
        ) { [weak self] success in
            Task { @MainActor in
                guard let self = self else { return }
                
                print("🔄 Speech completion: success=\(success), currentState=\(self.sessionState)")
                
                if success && self.sessionState == .playing {
                    await self.advanceToNextSentence()
                } else if !success && self.sessionState == .playing {
                    // Only set error if we're actively playing - if stopped/paused, the failure is intentional
                    print("🔄 Setting error state due to speech failure during playing")
                    self.sessionState = .error
                    self.lastError = "Speech synthesis failed"
                } else if !success {
                    print("🔄 Speech failed but state is \(self.sessionState) - treating as intentional cancellation")
                }
                // If !success but not .playing, it's intentional cancellation - do nothing
            }
        }
    }
    
    private func advanceToNextSentence() async {
        guard let document = currentDocument else { return }
        
        currentSentenceIndex += 1
        updateProgress()
        
        // Update session progress
        if var session = currentSession {
            session.updateProgress(
                sentenceIndex: currentSentenceIndex,
                totalSentences: document.sentences.count
            )
            currentSession = session
        }
        
        if currentSentenceIndex >= document.sentences.count {
            completeReading()
        } else if sessionState == .playing {
            // Continue reading next sentence
            await readCurrentSentence()
        }
    }
    
    private func completeReading() {
        sessionState = .completed
        stopReadingTimer()
        
        // Complete session
        if var session = currentSession {
            session.complete()
            currentSession = session
            
            // Save completed session
            Task {
                await documentHistoryService.saveSession(session)
            }
        }
    }
    
    private func updateProgress() {
        guard let document = currentDocument else { return }
        
        if document.sentences.isEmpty {
            progress = 0.0
        } else {
            progress = Double(currentSentenceIndex) / Double(document.sentences.count)
        }
    }
    
    private func stopReadingTimer() {
        readingTimer?.invalidate()
        readingTimer = nil
    }
    
    private func startProgressTimer() {
        stopReadingTimer()
        
        // Save progress every 5 seconds
        readingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.saveCurrentProgress()
            }
        }
    }
    
    private func saveCurrentProgress() async {
        guard let session = currentSession else { return }
        await documentHistoryService.saveSession(session)
    }
    
    // MARK: - Session Management
    
    func addBookmark(title: String, note: String? = nil) {
        guard var session = currentSession else { return }
        
        session.addBookmark(at: currentSentenceIndex, title: title, note: note)
        currentSession = session
    }
    
    func jumpToBookmark(_ bookmark: SessionBookmark) async {
        await seekToSentence(bookmark.sentenceIndex)
    }
    
    // MARK: - Settings
    
    func updatePlaybackSettings(_ settings: PlaybackSettings) {
        currentSession?.playbackSettings = settings
        
        // Update voice provider settings
        voiceProviderService.updateSpeechRate(settings.speechRate)
        voiceProviderService.updatePitch(settings.pitch)
        voiceProviderService.updateVolume(settings.volume)
    }
    
    // MARK: - Computed Properties
    
    var canLoadDocument: Bool {
        return sessionState == .idle || sessionState == .stopped || sessionState == .completed
    }
    
    var hasDocument: Bool {
        return currentDocument != nil
    }
    
    var currentSentence: DocumentSentence? {
        guard let document = currentDocument,
              currentSentenceIndex < document.sentences.count else { return nil }
        return document.sentences[currentSentenceIndex]
    }
    
    var totalSentences: Int {
        return currentDocument?.sentences.count ?? 0
    }
    
    var estimatedTimeRemaining: TimeInterval {
        guard let document = currentDocument,
              currentSentenceIndex < document.sentences.count else { return 0 }
        
        let remainingText = document.sentences[currentSentenceIndex...].map { $0.text }.joined(separator: " ")
        
        // Estimate based on speech rate and word count
        let wordsPerMinute = 150.0 * Double(voiceProviderService.voicePreferences.speechRate)
        return remainingText.estimatedReadingTime(wordsPerMinute: Int(wordsPerMinute))
    }
    
    // MARK: - Service Access
    
    var documentProcessing: DocumentProcessingService {
        return documentProcessingService
    }
    
    var voiceProvider: VoiceProviderService {
        return voiceProviderService
    }
    
    var documentHistory: DocumentHistoryService {
        return documentHistoryService
    }
    
    // MARK: - External Import Support
    
    /// Triggers an external file import request via notification
    /// This allows other parts of the app to request file imports in the Read Aloud view
    static func requestFileImport(fileURL: URL) {
        print("📄 ReadAloudService: Posting file import notification for: \(fileURL.path)")
        NotificationCenter.default.post(
            name: .readAloudImportFile,
            object: nil,
            userInfo: ["fileURL": fileURL]
        )
    }
    
    /// Triggers an external file import request via notification using file path
    /// This allows other parts of the app to request file imports in the Read Aloud view
    static func requestFileImport(filePath: String) {
        print("📄 ReadAloudService: Posting file import notification for path: \(filePath)")
        NotificationCenter.default.post(
            name: .readAloudImportFile,
            object: nil,
            userInfo: ["filePath": filePath]
        )
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let readAloudHighlightUpdate = Notification.Name("readAloudHighlightUpdate")
    static let readAloudSessionResumable = Notification.Name("readAloudSessionResumable")
    static let readAloudImportFile = Notification.Name("readAloudImportFile")
}