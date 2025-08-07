import Foundation

@MainActor
class PatternMatcher {
    private let supabase = SupabaseManager.shared
    
    func extractPatterns(from original: String, to edited: String, mode: RefinementMode) async {
        // Use diff algorithm to find changes
        let changes = findChanges(between: original, and: edited)
        
        for change in changes {
            if change.isSignificant {
                let pattern = LearnedPattern(
                    id: UUID(),
                    userId: supabase.currentUser?.id,
                    originalPhrase: change.original,
                    correctedPhrase: change.edited,
                    occurrenceCount: 1,
                    firstSeen: Date(),
                    lastSeen: Date(),
                    refinementMode: mode,
                    confidence: 0.3,
                    isActive: true
                )
                
                do {
                    try await supabase.saveOrUpdatePattern(pattern)
                } catch {
                    print("Failed to save pattern: \(error)")
                }
            }
        }
    }
    
    func applyPatterns(to text: String, mode: RefinementMode) async -> String {
        var result = text
        
        do {
            let activePatterns = try await supabase.getActivePatterns()
            
            // Apply patterns with highest confidence first
            for pattern in activePatterns where pattern.isReady {
                // Give extra weight to patterns from same mode
                let modeBonus = pattern.refinementMode == mode ? 0.1 : 0.0
                let effectiveConfidence = min(1.0, pattern.confidence + modeBonus)
                
                if effectiveConfidence > 0.6 {
                    result = result.replacingOccurrences(
                        of: pattern.originalPhrase,
                        with: pattern.correctedPhrase,
                        options: [.caseInsensitive, .diacriticInsensitive]
                    )
                }
            }
        } catch {
            print("Failed to apply patterns: \(error)")
        }
        
        return result
    }
    
    private func findChanges(between original: String, and edited: String) -> [TextChange] {
        let originalWords = original.split(separator: " ").map(String.init)
        let editedWords = edited.split(separator: " ").map(String.init)
        
        var changes: [TextChange] = []
        
        // Find word-level replacements
        let minLength = min(originalWords.count, editedWords.count)
        
        for i in 0..<minLength {
            if originalWords[i] != editedWords[i] {
                // Check for phrase patterns (1-3 words)
                for length in 1...min(3, originalWords.count - i, editedWords.count - i) {
                    let originalPhrase = originalWords[i..<(i + length)].joined(separator: " ")
                    let editedPhrase = editedWords[i..<(i + length)].joined(separator: " ")
                    
                    if originalPhrase != editedPhrase {
                        changes.append(TextChange(
                            original: originalPhrase,
                            edited: editedPhrase
                        ))
                    }
                }
            }
        }
        
        // Handle additions and deletions
        if originalWords.count != editedWords.count {
            // Find longer phrases that were replaced
            if let longestCommonSubsequence = findLongestCommonSubsequence(originalWords, editedWords) {
                // Extract changes based on LCS
            }
        }
        
        return changes.filter { $0.isSignificant }
    }
    
    private func findLongestCommonSubsequence(_ a: [String], _ b: [String]) -> [(Int, Int)]? {
        // Simplified LCS for pattern detection
        // Real implementation would be more sophisticated
        return nil
    }
}

struct TextChange {
    let original: String
    let edited: String
    
    var isSignificant: Bool {
        // Ignore single character changes, punctuation only, etc.
        return original.count > 2 && 
               edited.count > 2 && 
               original.lowercased() != edited.lowercased() &&
               !isOnlyPunctuation(original) &&
               !isOnlyPunctuation(edited)
    }
    
    private func isOnlyPunctuation(_ text: String) -> Bool {
        return text.allSatisfy { char in
            char.isPunctuation || char.isWhitespace
        }
    }
}