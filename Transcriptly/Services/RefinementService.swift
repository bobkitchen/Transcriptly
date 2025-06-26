//
//  RefinementService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation
import Combine
// Import FoundationModels when available

@MainActor
class RefinementService: ObservableObject {
    @Published var isProcessing = false
    @Published var currentMode: RefinementMode = .cleanup
    @Published var prompts: [RefinementMode: RefinementPrompt]
    
    init() {
        // Load saved prompts or use defaults
        if let savedPrompts = UserDefaults.standard.loadPrompts() {
            self.prompts = savedPrompts
        } else {
            self.prompts = RefinementPrompt.defaultPrompts()
        }
    }
    
    func refine(_ text: String) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        switch currentMode {
        case .raw:
            return text
        case .cleanup, .email, .messaging:
            // TODO: Implement Foundation Models call
            // For now, return with placeholder processing
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            return "Refined: \(text)" // Placeholder
        }
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