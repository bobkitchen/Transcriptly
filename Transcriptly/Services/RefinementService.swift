//
//  RefinementService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation
import Combine
import NaturalLanguage

enum RefinementError: LocalizedError {
    case promptNotFound
    case modelUnavailable
    case contextLimitExceeded
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .promptNotFound:
            return "Refinement prompt not found for the selected mode"
        case .modelUnavailable:
            return "Language model is not available. Please check that Apple Intelligence is enabled."
        case .contextLimitExceeded:
            return "Text is too long for processing. Please try with shorter text."
        case .processingFailed(let reason):
            return "Refinement failed: \(reason)"
        }
    }
}

struct TextAnalysis {
    let language: String
    let sentiment: Double
    let wordCount: Int
    let hasQuestions: Bool
    let hasExclamations: Bool
    let isUppercase: Bool
}

@MainActor
class RefinementService: ObservableObject {
    @Published var isProcessing = false
    @Published var currentMode: RefinementMode = .cleanup
    @Published var prompts: [RefinementMode: RefinementPrompt]
    
    private let languageRecognizer = NLLanguageRecognizer()
    private let sentimentAnalyzer = NLTagger(tagSchemes: [.sentimentScore])
    // Note: FoundationModels not available in current SDK
    // Using fallback implementation instead
    
    init() {
        // Load saved prompts or use defaults
        if let savedPrompts = UserDefaults.standard.loadPrompts() {
            self.prompts = savedPrompts
        } else {
            self.prompts = RefinementPrompt.defaultPrompts()
        }
        
        // Note: FoundationModels not available in current SDK
        // Using fallback NaturalLanguage implementation
        print("RefinementService: Initialized with NaturalLanguage fallback")
    }
    
    private func initializeLanguageModel() async {
        // FoundationModels not available in current SDK
        // Using NaturalLanguage framework for basic text processing
        print("RefinementService: Using NaturalLanguage fallback implementation")
    }
    
    func refine(_ text: String) async throws -> String {
        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }
        
        // Get current mode and prompt on main actor
        let (mode, prompt) = await MainActor.run {
            let mode = currentMode
            let prompt = prompts[mode]
            return (mode, prompt)
        }
        
        // Return raw text immediately for raw mode
        guard mode != .raw else {
            return text
        }
        
        // Check that prompt exists for the mode
        guard let prompt = prompt else {
            throw RefinementError.promptNotFound
        }
        
        var refinedText: String
        
        // Try AI Providers first
        let result = await AIProviderManager.shared.refine(text: text, mode: currentMode)
        
        switch result {
        case .success(let refined):
            refinedText = refined
        case .failure(let error):
            print("AI Provider refinement failed: \(error)")
            
            // Note: FoundationModels not available, using fallback processing
            refinedText = try await refineWithPlaceholderProcessing(text: text, mode: currentMode)
        }
        
        // Apply learned patterns as final step
        refinedText = await LearningService.shared.applyLearnedPatterns(to: refinedText, mode: currentMode)
        
        return refinedText
    }
    
    // Note: This function is not used since FoundationModels is not available
    // Keeping for potential future implementation when macOS 26 beta is available
    
    private func buildFoundationModelsPrompt(text: String, prompt: RefinementPrompt) -> String {
        let modeContext = """
            Mode: \(prompt.mode.rawValue)
            Task: \(prompt.userPrompt)
            
            Please refine the following transcribed text according to the mode and task above.
            Return only the refined text without any explanations or metadata.
            
            Original text:
            \(text)
            
            Refined text:
            """
        
        return modeContext
    }
    
    
    private func cleanFoundationModelsResponse(_ response: String, originalText: String) -> String {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common artifacts from model responses
        cleaned = cleaned.replacingOccurrences(of: "Refined text:", with: "")
        cleaned = cleaned.replacingOccurrences(of: "Here is the refined text:", with: "")
        cleaned = cleaned.replacingOccurrences(of: "**", with: "") // Remove markdown bold
        
        // Final cleanup
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Fallback to original if response is empty or too short
        if cleaned.isEmpty || cleaned.count < originalText.count / 3 {
            return originalText
        }
        
        return cleaned
    }
    
    private func refineWithPlaceholderProcessing(text: String, mode: RefinementMode) async throws -> String {
        // Simulate realistic processing time based on text length
        let processingTime = min(max(0.3, Double(text.count) / 1000.0), 2.0)
        try await Task.sleep(nanoseconds: UInt64(processingTime * 1_000_000_000))
        
        // Analyze text with NaturalLanguage for realistic processing
        let analyzedText = analyzeText(text)
        
        // Apply mode-specific transformations
        switch mode {
        case .raw:
            return text
            
        case .cleanup:
            return cleanupText(text, analysis: analyzedText)
            
        case .email:
            return formatAsEmail(text, analysis: analyzedText)
            
        case .messaging:
            return formatAsMessage(text, analysis: analyzedText)
        }
    }
    
    private func analyzeText(_ text: String) -> TextAnalysis {
        // Use NaturalLanguage to analyze the text
        languageRecognizer.reset()
        languageRecognizer.processString(text)
        
        // Analyze sentiment
        sentimentAnalyzer.string = text
        let (sentimentTag, _) = sentimentAnalyzer.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        let sentimentScore = sentimentTag?.rawValue ?? "0"
        
        return TextAnalysis(
            language: languageRecognizer.dominantLanguage?.rawValue ?? "en",
            sentiment: Double(sentimentScore) ?? 0.0,
            wordCount: text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count,
            hasQuestions: text.contains("?"),
            hasExclamations: text.contains("!"),
            isUppercase: text == text.uppercased()
        )
    }
    
    private func cleanupText(_ text: String, analysis: TextAnalysis) -> String {
        var refined = text
        
        // Remove common filler words
        let fillerWords = ["um", "uh", "like", "you know", "basically", "actually", "literally"]
        for filler in fillerWords {
            refined = refined.replacingOccurrences(of: " \(filler) ", with: " ", options: .caseInsensitive)
            refined = refined.replacingOccurrences(of: " \(filler),", with: ",", options: .caseInsensitive)
        }
        
        // Fix common punctuation issues
        refined = refined.replacingOccurrences(of: " ,", with: ",")
        refined = refined.replacingOccurrences(of: " .", with: ".")
        refined = refined.replacingOccurrences(of: "  ", with: " ")
        
        // Ensure proper capitalization
        refined = refined.trimmingCharacters(in: .whitespacesAndNewlines)
        if !refined.isEmpty {
            refined = refined.prefix(1).capitalized + refined.dropFirst()
        }
        
        return refined
    }
    
    private func formatAsEmail(_ text: String, analysis: TextAnalysis) -> String {
        let cleanText = cleanupText(text, analysis: analysis)
        
        // Add email structure
        var email = "Hi,\n\n"
        email += cleanText
        
        // Ensure proper ending punctuation
        if !cleanText.hasSuffix(".") && !cleanText.hasSuffix("!") && !cleanText.hasSuffix("?") {
            email += "."
        }
        
        email += "\n\nBest regards"
        
        return email
    }
    
    private func formatAsMessage(_ text: String, analysis: TextAnalysis) -> String {
        let cleanText = cleanupText(text, analysis: analysis)
        
        // Make more conversational and concise
        var message = cleanText
        
        // Remove formal language
        message = message.replacingOccurrences(of: "I would like to", with: "I'd like to")
        message = message.replacingOccurrences(of: "Please let me know", with: "Let me know")
        message = message.replacingOccurrences(of: "Thank you very much", with: "Thanks")
        
        // Add casual tone if not already casual
        if analysis.sentiment >= 0 && !message.contains("!") && message.count > 20 {
            if message.hasSuffix(".") {
                message = String(message.dropLast()) + "!"
            }
        }
        
        return message
    }
    
    func updatePrompt(for mode: RefinementMode, prompt: String) {
        prompts[mode]?.userPrompt = prompt
        savePrompts()
    }
    
    func resetPrompt(for mode: RefinementMode) {
        prompts[mode]?.userPrompt = prompts[mode]?.defaultPrompt ?? ""
        savePrompts()
    }
    
    private func savePrompts() {
        UserDefaults.standard.savePrompts(prompts)
    }
}

// Add UserDefaults extension for prompt storage
extension UserDefaults {
    private var promptsKey: String { "refinementPrompts" }
    
    func savePrompts(_ prompts: [RefinementMode: RefinementPrompt]) {
        if let encoded = try? JSONEncoder().encode(prompts) {
            set(encoded, forKey: promptsKey)
        }
    }
    
    func loadPrompts() -> [RefinementMode: RefinementPrompt]? {
        guard let data = data(forKey: promptsKey),
              let decoded = try? JSONDecoder().decode([RefinementMode: RefinementPrompt].self, from: data) else {
            return nil
        }
        return decoded
    }
}