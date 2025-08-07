import Foundation

@MainActor
class PreferenceProfiler {
    private let supabase = SupabaseManager.shared
    private var preferences: [UserPreference.PreferenceType: Double] = [:]
    private var sampleCounts: [UserPreference.PreferenceType: Int] = [:]
    
    init() {
        Task {
            await loadPreferences()
        }
    }
    
    // MARK: - Learning from User Edits
    
    func analyzePreferences(original: String, edited: String) async {
        // Analyze formality
        let formalityDelta = assessFormality(edited) - assessFormality(original)
        await updatePreference(.formality, delta: formalityDelta)
        
        // Analyze conciseness
        let concisenessDelta = assessConciseness(original, edited)
        await updatePreference(.conciseness, delta: concisenessDelta)
        
        // Analyze contractions
        let contractionDelta = assessContractions(edited) - assessContractions(original)
        await updatePreference(.contractions, delta: contractionDelta)
        
        // Analyze punctuation
        let punctuationDelta = assessPunctuation(edited) - assessPunctuation(original)
        await updatePreference(.punctuation, delta: punctuationDelta)
        
        await savePreferences()
    }
    
    func learnFromABChoice(selected: String, rejected: String) async {
        // Compare characteristics of selected vs rejected (smaller weight for A/B)
        let formalityDiff = assessFormality(selected) - assessFormality(rejected)
        await updatePreference(.formality, delta: formalityDiff * 0.5)
        
        let concisenessDiff = assessConciseness(rejected, selected)
        await updatePreference(.conciseness, delta: concisenessDiff * 0.5)
        
        let contractionDiff = assessContractions(selected) - assessContractions(rejected)
        await updatePreference(.contractions, delta: contractionDiff * 0.5)
        
        await savePreferences()
    }
    
    // MARK: - Applying Preferences
    
    func adjustForPreferences(text: String) async -> String {
        var result = text
        
        // Apply formality preferences
        if let formalityPref = preferences[.formality] {
            if formalityPref > 0.5 {
                result = applyFormalAdjustments(result)
            } else if formalityPref < -0.5 {
                result = applyCasualAdjustments(result)
            }
        }
        
        // Apply conciseness preferences
        if let concisenessPref = preferences[.conciseness] {
            if concisenessPref > 0.5 {
                result = applyConciseAdjustments(result)
            }
        }
        
        // Apply contraction preferences
        if let contractionPref = preferences[.contractions] {
            if contractionPref > 0.5 {
                result = applyContractions(result)
            } else if contractionPref < -0.5 {
                result = removeContractions(result)
            }
        }
        
        return result
    }
    
    // MARK: - Assessment Methods
    
    private func assessFormality(_ text: String) -> Double {
        let formalIndicators = ["therefore", "furthermore", "however", "nevertheless", "consequently", "accordingly"]
        let casualIndicators = ["gonna", "wanna", "yeah", "ok", "cool", "awesome"]
        
        let words = text.lowercased().split(separator: " ").map(String.init)
        let totalWords = Double(words.count)
        
        guard totalWords > 0 else { return 0.0 }
        
        let formalCount = Double(words.filter { formalIndicators.contains($0) }.count)
        let casualCount = Double(words.filter { casualIndicators.contains($0) }.count)
        
        return (formalCount - casualCount) / totalWords
    }
    
    private func assessConciseness(_ original: String, _ edited: String) -> Double {
        let originalWordCount = Double(original.split(separator: " ").count)
        let editedWordCount = Double(edited.split(separator: " ").count)
        
        guard originalWordCount > 0 else { return 0.0 }
        
        // Positive if user made text more concise
        return (originalWordCount - editedWordCount) / originalWordCount
    }
    
    private func assessContractions(_ text: String) -> Double {
        let contractions = ["don't", "won't", "can't", "shouldn't", "wouldn't", "couldn't", "haven't", "hasn't", "isn't", "aren't", "wasn't", "weren't", "I'm", "you're", "he's", "she's", "it's", "we're", "they're", "I've", "you've", "we've", "they've", "I'll", "you'll", "he'll", "she'll", "it'll", "we'll", "they'll"]
        
        let words = text.lowercased().split(separator: " ").map(String.init)
        let totalWords = Double(words.count)
        
        guard totalWords > 0 else { return 0.0 }
        
        let contractionCount = Double(words.filter { word in
            contractions.contains(where: { $0.lowercased() == word })
        }.count)
        
        return contractionCount / totalWords
    }
    
    private func assessPunctuation(_ text: String) -> Double {
        let heavyPunctuation = "!?;:—"
        let punctuationCount = Double(text.filter { heavyPunctuation.contains($0) }.count)
        let wordCount = Double(text.split(separator: " ").count)
        
        guard wordCount > 0 else { return 0.0 }
        
        return punctuationCount / wordCount
    }
    
    // MARK: - Adjustment Applications
    
    private func applyFormalAdjustments(_ text: String) -> String {
        var result = text
        
        // Replace casual phrases with formal ones
        let formalizations = [
            "gonna": "going to",
            "wanna": "want to",
            "gotta": "have to",
            "yeah": "yes",
            "ok": "very well"
        ]
        
        for (casual, formal) in formalizations {
            result = result.replacingOccurrences(of: casual, with: formal, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func applyCasualAdjustments(_ text: String) -> String {
        var result = text
        
        // Replace formal phrases with casual ones
        let casualizations = [
            "going to": "gonna",
            "want to": "wanna",
            "have to": "gotta",
            "very well": "ok"
        ]
        
        for (formal, casual) in casualizations {
            result = result.replacingOccurrences(of: formal, with: casual, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func applyConciseAdjustments(_ text: String) -> String {
        var result = text
        
        // Remove filler phrases
        let fillerPhrases = [
            "I think that",
            "I believe that",
            "it seems like",
            "in my opinion",
            "I would say that",
            "you know"
        ]
        
        for filler in fillerPhrases {
            result = result.replacingOccurrences(of: filler, with: "", options: .caseInsensitive)
        }
        
        // Clean up double spaces
        result = result.replacingOccurrences(of: "  ", with: " ")
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    private func applyContractions(_ text: String) -> String {
        var result = text
        
        let contractionMap = [
            "do not": "don't",
            "will not": "won't",
            "cannot": "can't",
            "should not": "shouldn't",
            "would not": "wouldn't",
            "could not": "couldn't",
            "have not": "haven't",
            "has not": "hasn't",
            "is not": "isn't",
            "are not": "aren't",
            "was not": "wasn't",
            "were not": "weren't",
            "I am": "I'm",
            "you are": "you're",
            "he is": "he's",
            "she is": "she's",
            "it is": "it's",
            "we are": "we're",
            "they are": "they're"
        ]
        
        for (full, contraction) in contractionMap {
            result = result.replacingOccurrences(of: full, with: contraction, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func removeContractions(_ text: String) -> String {
        var result = text
        
        let expansionMap = [
            "don't": "do not",
            "won't": "will not",
            "can't": "cannot",
            "shouldn't": "should not",
            "wouldn't": "would not",
            "couldn't": "could not",
            "haven't": "have not",
            "hasn't": "has not",
            "isn't": "is not",
            "aren't": "are not",
            "wasn't": "was not",
            "weren't": "were not",
            "I'm": "I am",
            "you're": "you are",
            "he's": "he is",
            "she's": "she is",
            "it's": "it is",
            "we're": "we are",
            "they're": "they are"
        ]
        
        for (contraction, expansion) in expansionMap {
            result = result.replacingOccurrences(of: contraction, with: expansion, options: .caseInsensitive)
        }
        
        return result
    }
    
    // MARK: - Preference Management
    
    private func updatePreference(_ type: UserPreference.PreferenceType, delta: Double) async {
        let currentValue = preferences[type] ?? 0.0
        let currentSamples = sampleCounts[type] ?? 0
        
        // Weighted average with recency bias
        let weight = min(0.3, 1.0 / Double(currentSamples + 1))
        let newValue = currentValue * (1 - weight) + delta * weight
        
        // Clamp to valid range
        preferences[type] = max(-1.0, min(1.0, newValue))
        sampleCounts[type] = currentSamples + 1
    }
    
    private func loadPreferences() async {
        do {
            let userPreferences = try await supabase.getPreferences()
            
            for preference in userPreferences {
                preferences[preference.type] = preference.value
                sampleCounts[preference.type] = preference.sampleCount
            }
        } catch {
            print("Failed to load preferences: \(error)")
        }
    }
    
    private func savePreferences() async {
        for (type, value) in preferences {
            let sampleCount = sampleCounts[type] ?? 1
            let preference = UserPreference(
                id: UUID(),
                userId: supabase.currentUser?.id,
                type: type,
                value: value,
                sampleCount: sampleCount,
                lastUpdated: Date()
            )
            
            do {
                try await supabase.saveOrUpdatePreference(preference)
            } catch {
                print("Failed to save preference: \(error)")
            }
        }
    }
}