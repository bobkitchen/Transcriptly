//
//  String+Chunking.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//

import Foundation

extension String {
    
    /// Chunks text into manageable pieces for text-to-speech processing
    /// - Parameters:
    ///   - maxChunkSize: Maximum size of each chunk in characters
    ///   - preferSentences: Whether to prefer sentence boundaries for chunking
    /// - Returns: Array of text chunks
    func chunkedForSpeech(maxChunkSize: Int = 5000, preferSentences: Bool = true) -> [String] {
        guard !self.isEmpty else { return [] }
        
        if self.count <= maxChunkSize {
            return [self]
        }
        
        if preferSentences {
            return sentenceBasedChunking(maxChunkSize: maxChunkSize)
        } else {
            return characterBasedChunking(maxChunkSize: maxChunkSize)
        }
    }
    
    /// Chunks text based on sentence boundaries
    private func sentenceBasedChunking(maxChunkSize: Int) -> [String] {
        let sentences = self.sentences()
        var chunks: [String] = []
        var currentChunk = ""
        
        for sentence in sentences {
            let potentialChunk = currentChunk.isEmpty ? sentence : currentChunk + " " + sentence
            
            if potentialChunk.count <= maxChunkSize {
                currentChunk = potentialChunk
            } else {
                // Current chunk is at capacity, start a new one
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                
                // If single sentence is too long, split it
                if sentence.count > maxChunkSize {
                    chunks.append(contentsOf: sentence.characterBasedChunking(maxChunkSize: maxChunkSize))
                    currentChunk = ""
                } else {
                    currentChunk = sentence
                }
            }
        }
        
        // Add remaining chunk
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return chunks.filter { !$0.isEmpty }
    }
    
    /// Chunks text based on character count, respecting word boundaries
    private func characterBasedChunking(maxChunkSize: Int) -> [String] {
        var chunks: [String] = []
        var currentIndex = self.startIndex
        
        while currentIndex < self.endIndex {
            let remainingText = String(self[currentIndex...])
            
            if remainingText.count <= maxChunkSize {
                chunks.append(remainingText)
                break
            }
            
            // Find the best breaking point within maxChunkSize
            let targetEndIndex = self.index(currentIndex, offsetBy: maxChunkSize, limitedBy: self.endIndex) ?? self.endIndex
            let chunk = String(self[currentIndex..<targetEndIndex])
            
            // Try to break at word boundary
            if let lastSpaceIndex = chunk.lastIndex(of: " ") {
                let wordBoundaryChunk = String(chunk[..<lastSpaceIndex])
                chunks.append(wordBoundaryChunk)
                currentIndex = self.index(after: self.index(currentIndex, offsetBy: wordBoundaryChunk.count))
            } else {
                // No word boundary found, break at character limit
                chunks.append(chunk)
                currentIndex = targetEndIndex
            }
        }
        
        return chunks.filter { !$0.isEmpty }
    }
    
    /// Splits text into individual sentences
    /// - Returns: Array of sentences
    func sentences() -> [String] {
        var sentences: [String] = []
        let nsString = self as NSString
        
        // Use NSString's sentence enumeration
        nsString.enumerateSubstrings(
            in: NSRange(location: 0, length: nsString.length),
            options: [.bySentences, .localized]
        ) { sentence, _, _, _ in
            if let sentence = sentence?.trimmingCharacters(in: .whitespacesAndNewlines),
               !sentence.isEmpty {
                sentences.append(sentence)
            }
        }
        
        // Fallback if enumeration fails
        if sentences.isEmpty {
            sentences = fallbackSentenceSplitting()
        }
        
        return sentences
    }
    
    private func fallbackSentenceSplitting() -> [String] {
        // Enhanced sentence detection with abbreviation handling
        let nsString = self as NSString
        var sentences: [String] = []
        var currentSentenceStart = 0
        
        // Common abbreviations that shouldn't end sentences
        let abbreviations = [
            "Dr.", "Mr.", "Mrs.", "Ms.", "Prof.", "Inc.", "Corp.", "Ltd.", "LLC",
            "vs.", "etc.", "e.g.", "i.e.", "a.m.", "p.m.", "U.S.", "U.K.",
            "St.", "Ave.", "Blvd.", "Rd.", "Jr.", "Sr.", "Ph.D.", "M.D."
        ]
        
        // Find potential sentence endings
        let sentencePattern = "[.!?]+"
        
        do {
            let regex = try NSRegularExpression(pattern: sentencePattern, options: [])
            let range = NSRange(location: 0, length: nsString.length)
            let matches = regex.matches(in: self, options: [], range: range)
            
            for match in matches {
                let endLocation = match.range.location + match.range.length
                
                // Check if this is likely a real sentence ending
                let beforePunctuation = NSRange(location: max(0, match.range.location - 10), 
                                              length: min(10, match.range.location))
                let beforeText = nsString.substring(with: beforePunctuation)
                
                // Skip if this appears to be an abbreviation
                let isAbbreviation = abbreviations.contains { abbrev in
                    beforeText.hasSuffix(abbrev)
                }
                
                if !isAbbreviation {
                    // Check if next character is uppercase (likely new sentence)
                    let nextCharLocation = endLocation
                    var isNewSentence = true
                    
                    if nextCharLocation < nsString.length {
                        let nextChar = nsString.character(at: nextCharLocation)
                        let nextString = String(Character(UnicodeScalar(nextChar)!))
                        
                        // Skip whitespace to find first non-whitespace character
                        var checkLocation = nextCharLocation
                        while checkLocation < nsString.length {
                            let checkChar = nsString.character(at: checkLocation)
                            let checkString = String(Character(UnicodeScalar(checkChar)!))
                            
                            if !checkString.trimmingCharacters(in: .whitespaces).isEmpty {
                                isNewSentence = checkString.uppercased() == checkString && checkString.lowercased() != checkString
                                break
                            }
                            checkLocation += 1
                        }
                    }
                    
                    if isNewSentence {
                        // This is a real sentence ending
                        let sentenceRange = NSRange(location: currentSentenceStart, 
                                                  length: endLocation - currentSentenceStart)
                        let sentence = nsString.substring(with: sentenceRange)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !sentence.isEmpty {
                            sentences.append(sentence)
                        }
                        
                        currentSentenceStart = endLocation
                    }
                }
            }
            
            // Add remaining text as final sentence
            if currentSentenceStart < nsString.length {
                let remaining = nsString.substring(from: currentSentenceStart)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !remaining.isEmpty {
                    sentences.append(remaining)
                }
            }
            
            // If no sentences found, return original text
            if sentences.isEmpty {
                return [self.trimmingCharacters(in: .whitespacesAndNewlines)]
            }
            
            return sentences
            
        } catch {
            // Final fallback: return original text as single sentence
            return [self.trimmingCharacters(in: .whitespacesAndNewlines)]
        }
    }
    
    /// Estimates optimal chunk size based on text-to-speech provider
    /// - Parameter provider: The voice provider being used
    /// - Returns: Recommended chunk size in characters
    static func recommendedChunkSize() -> Int {
        // Default chunk size for Apple's speech synthesis
        return 2000 // Apple's AVSpeechSynthesizer handles medium chunks well
    }
    
    /// Cleans text for better text-to-speech pronunciation
    /// - Returns: Cleaned text optimized for speech synthesis
    func cleanedForSpeech() -> String {
        var cleaned = self
        
        // Replace common abbreviations with full words
        let abbreviations: [String: String] = [
            "Dr.": "Doctor",
            "Mr.": "Mister",
            "Mrs.": "Missus",
            "Ms.": "Miss",
            "Prof.": "Professor",
            "etc.": "etcetera",
            "e.g.": "for example",
            "i.e.": "that is",
            "vs.": "versus",
            "Inc.": "Incorporated",
            "LLC": "Limited Liability Company",
            "Corp.": "Corporation",
            "Ltd.": "Limited"
        ]
        
        for (abbreviation, replacement) in abbreviations {
            cleaned = cleaned.replacingOccurrences(of: abbreviation, with: replacement)
        }
        
        // Handle numbers and dates more naturally
        // This is a simplified version - full implementation would use NSDataDetector
        cleaned = cleaned.replacingOccurrences(of: "1st", with: "first")
        cleaned = cleaned.replacingOccurrences(of: "2nd", with: "second")
        cleaned = cleaned.replacingOccurrences(of: "3rd", with: "third")
        
        // Handle common symbols
        cleaned = cleaned.replacingOccurrences(of: "&", with: "and")
        cleaned = cleaned.replacingOccurrences(of: "@", with: "at")
        cleaned = cleaned.replacingOccurrences(of: "%", with: "percent")
        cleaned = cleaned.replacingOccurrences(of: "$", with: "dollars")
        
        // Clean up extra whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    /// Estimates reading time for the text
    /// - Parameter wordsPerMinute: Average reading speed (default: 200 WPM)
    /// - Returns: Estimated reading time in seconds
    func estimatedReadingTime(wordsPerMinute: Int = 200) -> TimeInterval {
        let wordCount = self.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        
        let minutes = Double(wordCount) / Double(wordsPerMinute)
        return minutes * 60.0
    }
    
    /// Counts words in the text
    /// - Returns: Number of words
    nonisolated func wordCount() -> Int {
        return self.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }
    
    /// Counts sentences in the text
    /// - Returns: Number of sentences
    func sentenceCount() -> Int {
        return sentences().count
    }
}