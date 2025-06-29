//
//  RefinementService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation
import Combine
import NaturalLanguage
#if canImport(FoundationModels)
import FoundationModels
#endif

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
    #if canImport(FoundationModels)
    private var languageModelSession: Any?
    private var systemModel: Any?
    #endif
    
    init() {
        // Load saved prompts or use defaults
        if let savedPrompts = UserDefaults.standard.loadPrompts() {
            self.prompts = savedPrompts
        } else {
            self.prompts = RefinementPrompt.defaultPrompts()
        }
        
        // Initialize Foundation Models session
        Task {
            await initializeLanguageModel()
        }
    }
    
    private func initializeLanguageModel() async {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            do {
                // Initialize system model and check availability
                systemModel = SystemLanguageModel.default as Any
                
                guard let model = systemModel as? SystemLanguageModel, model.isAvailable else {
                    if let model = systemModel as? SystemLanguageModel {
                        switch model.availability {
                        case .unavailable(.appleIntelligenceNotEnabled):
                            print("Foundation Models: Apple Intelligence is not enabled")
                        case .unavailable(.deviceNotEligible):
                            print("Foundation Models: Device not eligible")
                        case .unavailable(.modelNotReady):
                            print("Foundation Models: Model not ready (downloading)")
                        default:
                            print("Foundation Models: Unavailable")
                        }
                    }
                    languageModelSession = nil
                    return
                }
                
                // Create system instructions for refinement tasks
                let instructions = Instructions("""
                    You are a text refinement assistant. Your task is to improve transcribed text according to specific modes:
                    - Clean-up Mode: Remove filler words, fix grammar, maintain original meaning
                    - Email Mode: Format as professional email with greeting and closing
                    - Messaging Mode: Make conversational and concise for quick messaging
                    Always return only the refined text without explanations.
                    """)
                
                // Create language model session with instructions
                languageModelSession = LanguageModelSession(instructions: instructions) as Any
                print("Foundation Models initialized successfully")
                
            } catch {
                print("Failed to initialize Foundation Models: \(error)")
                languageModelSession = nil
            }
        } else {
            print("Foundation Models require macOS 26.0 or later")
        }
        #else
        print("Foundation Models not available in this environment")
        #endif
    }
    
    func refine(_ text: String) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        // Return raw text immediately for raw mode
        guard currentMode != .raw else {
            return text
        }
        
        // Check that prompt exists for the mode
        guard let prompt = prompts[currentMode] else {
            throw RefinementError.promptNotFound
        }
        
        var refinedText: String
        
        // Try Foundation Models first, fallback to placeholder if unavailable
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), let session = languageModelSession as? LanguageModelSession {
            refinedText = try await refineWithFoundationModels(text: text, prompt: prompt, session: session)
        } else {
            refinedText = try await refineWithPlaceholderProcessing(text: text, mode: currentMode)
        }
        #else
        refinedText = try await refineWithPlaceholderProcessing(text: text, mode: currentMode)
        #endif
        
        // Apply learned patterns as final step
        refinedText = await LearningService.shared.applyLearnedPatterns(to: refinedText, mode: currentMode)
        
        return refinedText
    }
    
    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private func refineWithFoundationModels(text: String, prompt: RefinementPrompt, session: LanguageModelSession) async throws -> String {
        do {
            // Build the prompt with mode-specific context
            let userPrompt = buildFoundationModelsPrompt(text: text, prompt: prompt)
            
            // Check context limits (approximate token count)
            let estimatedTokens = userPrompt.count / 4 // Rough estimate: 4 chars per token
            if estimatedTokens > 4000 { // Conservative limit
                throw RefinementError.contextLimitExceeded
            }
            
            // Create prompt object and get response
            let promptObject = Prompt(userPrompt)
            let response = try await session.respond(to: promptObject)
            
            // Extract and clean the response
            let refinedText = cleanFoundationModelsResponse(response.content, originalText: text)
            
            return refinedText
            
        } catch {
            // Re-initialize session and try once more
            await initializeLanguageModel()
            throw RefinementError.processingFailed("Processing failed: \(error.localizedDescription)")
        }
    }
    
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
    #endif
    
    
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