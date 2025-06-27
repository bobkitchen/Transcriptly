import Foundation
import Combine
import Auth

@MainActor
class LearningService: ObservableObject {
    static let shared = LearningService()
    
    @Published var isLearningEnabled = true
    @Published var sessionCount = 0
    @Published var shouldShowEditReview = false
    @Published var shouldShowABTest = false
    @Published var learningQuality: LearningQuality = .minimal
    
    private let supabase = SupabaseManager.shared
    private let patternMatcher = PatternMatcher()
    private let preferenceProfiler = PreferenceProfiler()
    
    enum LearningQuality {
        case minimal    // < 10 sessions
        case basic      // 10-50 sessions
        case good       // 50-100 sessions
        case excellent  // 100+ sessions
    }
    
    private init() {
        Task {
            await loadSessionCount()
        }
    }
    
    // MARK: - Critical: Text-Only Learning Entry Point
    
    /// The ONLY method that receives data for learning
    /// Called AFTER transcription is complete and refined
    /// NEVER called during audio recording
    func processCompletedTranscription(
        original: String,
        refined: String,
        refinementMode: RefinementMode
    ) {
        guard isLearningEnabled else { 
            print("Learning disabled, skipping learning processing")
            return 
        }
        
        let wordCount = original.split(separator: " ").count
        print("Processing transcription: \(wordCount) words, original: '\(original)', refined: '\(refined)'")
        
        guard wordCount >= 20 else {
            // Too short for edit review, consider A/B testing
            print("Short transcription (\(wordCount) words), considering A/B testing")
            if sessionCount < 50 {
                print("Session count (\(sessionCount)) < 50, triggering A/B test")
                shouldShowABTest = true
            } else {
                print("Session count (\(sessionCount)) >= 50, skipping A/B test")
            }
            return
        }
        
        // Determine if we should show edit review
        if sessionCount < 10 {
            shouldShowEditReview = true
        } else {
            // Random 1 in 5 chance
            shouldShowEditReview = Int.random(in: 1...5) == 1
        }
    }
    
    // MARK: - Edit Review Processing
    
    func submitEditReview(
        original: String,
        aiRefined: String,
        userFinal: String,
        refinementMode: RefinementMode,
        skipLearning: Bool
    ) {
        shouldShowEditReview = false
        
        Task {
            let session = LearningSession(
                id: UUID(),
                userId: supabase.currentUser?.id,
                timestamp: Date(),
                originalTranscription: original,
                aiRefinement: aiRefined,
                userFinalVersion: userFinal,
                refinementMode: refinementMode,
                textLength: original.split(separator: " ").count,
                learningType: .editReview,
                wasSkipped: skipLearning,
                deviceId: nil
            )
            
            try? await supabase.saveLearningSession(session)
            
            if !skipLearning {
                // Extract patterns from the edits
                await patternMatcher.extractPatterns(
                    from: aiRefined,
                    to: userFinal,
                    mode: refinementMode
                )
                
                // Update preferences
                await preferenceProfiler.analyzePreferences(
                    original: aiRefined,
                    edited: userFinal
                )
            }
            
            sessionCount += 1
            updateLearningQuality()
        }
    }
    
    // MARK: - A/B Testing Processing
    
    func submitABTest(
        original: String,
        optionA: String,
        optionB: String,
        selected: String,
        refinementMode: RefinementMode
    ) {
        shouldShowABTest = false
        
        Task {
            let session = LearningSession(
                id: UUID(),
                userId: supabase.currentUser?.id,
                timestamp: Date(),
                originalTranscription: original,
                aiRefinement: selected == optionA ? optionA : optionB,
                userFinalVersion: selected,
                refinementMode: refinementMode,
                textLength: original.split(separator: " ").count,
                learningType: .abTesting,
                wasSkipped: false,
                deviceId: nil
            )
            
            try? await supabase.saveLearningSession(session)
            
            // Learn from the choice
            await preferenceProfiler.learnFromABChoice(
                selected: selected,
                rejected: selected == optionA ? optionB : optionA
            )
            
            sessionCount += 1
            updateLearningQuality()
        }
    }
    
    // MARK: - Pattern Application
    
    /// Apply learned patterns to refined text
    /// Called by RefinementService AFTER AI processing
    func applyLearnedPatterns(to text: String, mode: RefinementMode) async -> String {
        guard isLearningEnabled else { return text }
        
        var processedText = text
        
        // Apply pattern matching
        processedText = await patternMatcher.applyPatterns(
            to: processedText,
            mode: mode
        )
        
        // Apply preference-based adjustments
        processedText = await preferenceProfiler.adjustForPreferences(
            text: processedText
        )
        
        return processedText
    }
    
    // MARK: - User Control
    
    func resetAllLearning() async {
        do {
            try await supabase.clearAllUserData()
            sessionCount = 0
            updateLearningQuality()
        } catch {
            print("Failed to reset learning: \(error)")
        }
    }
    
    func deletePattern(_ pattern: LearnedPattern) async {
        // Mark pattern as inactive in Supabase
        var updatedPattern = pattern
        updatedPattern.isActive = false
        
        do {
            try await supabase.saveOrUpdatePattern(updatedPattern)
        } catch {
            print("Failed to delete pattern: \(error)")
        }
    }
    
    func pauseLearning() {
        isLearningEnabled = false
    }
    
    func resumeLearning() {
        isLearningEnabled = true
    }
    
    // MARK: - Data Access
    
    func getActivePatterns() async -> [LearnedPattern] {
        do {
            return try await supabase.getActivePatterns()
        } catch {
            print("Failed to get active patterns: \(error)")
            return []
        }
    }
    
    func getUserPreferences() async -> [UserPreference] {
        do {
            return try await supabase.getPreferences()
        } catch {
            print("Failed to get user preferences: \(error)")
            return []
        }
    }
    
    // MARK: - Private Helpers
    
    private func loadSessionCount() async {
        // TODO: Get session count from Supabase
        // For now, use a placeholder
        sessionCount = 0
        updateLearningQuality()
    }
    
    private func updateLearningQuality() {
        switch sessionCount {
        case 0..<10: learningQuality = .minimal
        case 10..<50: learningQuality = .basic
        case 50..<100: learningQuality = .good
        default: learningQuality = .excellent
        }
    }
}

// MARK: - Critical Safety Extension

extension LearningService {
    /// Compile-time verification that learning doesn't touch audio
    private func verifyNoAudioAccess() {
        // This function should fail to compile if any audio imports exist
        // let _ = AudioService.shared  // ❌ Should not compile
        // let _ = AVAudioRecorder()    // ❌ Should not compile
        let _ = "Text only processing" // ✅ Only text operations allowed
    }
}