//
//  NSAttributedString+Highlighting.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//

import Foundation
import AppKit

extension NSAttributedString {
    
    /// Creates an attributed string with sentence-level highlighting capabilities
    /// - Parameters:
    ///   - text: The full text content
    ///   - sentences: Array of sentence ranges to enable highlighting
    ///   - baseFont: Base font for the text
    ///   - baseColor: Base text color
    /// - Returns: Attributed string ready for highlighting
    static func createHighlightableText(
        _ text: String,
        sentences: [NSRange],
        baseFont: NSFont = .systemFont(ofSize: 16),
        baseColor: NSColor = .labelColor
    ) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        
        // Apply base styling
        attributedString.addAttributes([
            .font: baseFont,
            .foregroundColor: baseColor,
            .paragraphStyle: createReadingParagraphStyle()
        ], range: NSRange(location: 0, length: text.count))
        
        // Mark sentence boundaries for highlighting
        for (index, range) in sentences.enumerated() {
            attributedString.addAttribute(
                .init("SentenceIndex"),
                value: index,
                range: range
            )
        }
        
        return attributedString
    }
    
    /// Highlights a specific sentence in the attributed string
    /// - Parameters:
    ///   - sentenceIndex: Index of the sentence to highlight
    ///   - highlightColor: Background color for highlighting
    ///   - textColor: Text color for highlighted sentence
    /// - Returns: New attributed string with highlighting applied
    func highlightSentence(
        at sentenceIndex: Int,
        highlightColor: NSColor = .systemYellow.withAlphaComponent(0.3),
        textColor: NSColor = .labelColor
    ) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        
        // Remove previous highlights from mutable string
        let fullRangeForClear = NSRange(location: 0, length: mutableString.length)
        mutableString.removeAttribute(.backgroundColor, range: fullRangeForClear)
        mutableString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRangeForClear)
        
        // Find the range for the specified sentence
        let fullRange = NSRange(location: 0, length: mutableString.length)
        mutableString.enumerateAttribute(.init("SentenceIndex"), in: fullRange) { value, range, _ in
            if let index = value as? Int, index == sentenceIndex {
                // Apply highlighting
                mutableString.addAttributes([
                    .backgroundColor: highlightColor,
                    .foregroundColor: textColor
                ], range: range)
            }
        }
        
        return mutableString
    }
    
    /// Removes all highlighting from the attributed string
    /// - Returns: New attributed string without highlighting
    func removeHighlighting() -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        let fullRange = NSRange(location: 0, length: mutableString.length)
        mutableString.removeAttribute(.backgroundColor, range: fullRange)
        mutableString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
        return mutableString
    }
    
    /// Gets the range of a specific sentence
    /// - Parameter sentenceIndex: Index of the sentence
    /// - Returns: Range of the sentence, or nil if not found
    func rangeOfSentence(at sentenceIndex: Int) -> NSRange? {
        let fullRange = NSRange(location: 0, length: self.length)
        var sentenceRange: NSRange?
        
        self.enumerateAttribute(.init("SentenceIndex"), in: fullRange) { value, range, stop in
            if let index = value as? Int, index == sentenceIndex {
                sentenceRange = range
                stop.pointee = true
            }
        }
        
        return sentenceRange
    }
    
    /// Gets all sentence ranges in the attributed string
    /// - Returns: Array of sentence ranges with their indices
    func allSentenceRanges() -> [(index: Int, range: NSRange)] {
        var sentences: [(index: Int, range: NSRange)] = []
        let fullRange = NSRange(location: 0, length: self.length)
        
        self.enumerateAttribute(.init("SentenceIndex"), in: fullRange) { value, range, _ in
            if let index = value as? Int {
                sentences.append((index: index, range: range))
            }
        }
        
        return sentences.sorted { $0.index < $1.index }
    }
    
    private static func createReadingParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 12
        paragraphStyle.alignment = .left
        return paragraphStyle
    }
}

extension NSMutableAttributedString {
    
    /// Removes highlighting from the mutable attributed string
    func removeHighlighting() {
        let fullRange = NSRange(location: 0, length: self.length)
        self.removeAttribute(.backgroundColor, range: fullRange)
        
        // Reset text color to base color
        self.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
    }
    
    /// Applies smooth highlighting animation-ready attributes
    /// - Parameters:
    ///   - sentenceIndex: Index of sentence to highlight
    ///   - animationDuration: Duration for highlight animation
    func prepareForHighlighting(at sentenceIndex: Int, animationDuration: TimeInterval = 0.3) {
        guard let range = rangeOfSentence(at: sentenceIndex) else { return }
        
        // Add animation-ready attributes
        self.addAttributes([
            .init("HighlightAnimation"): animationDuration,
            .init("ReadingFocus"): true
        ], range: range)
    }
}

// MARK: - String Processing Helpers

extension String {
    
    /// Splits text into sentences with their ranges
    /// - Returns: Array of sentence ranges in the original string
    func sentenceRanges() -> [NSRange] {
        var ranges: [NSRange] = []
        let nsString = self as NSString
        
        // Use NSString's sentence enumeration
        nsString.enumerateSubstrings(
            in: NSRange(location: 0, length: nsString.length),
            options: [.bySentences, .localized]
        ) { sentence, range, _, _ in
            if let _ = sentence, range.length > 0 {
                ranges.append(range)
            }
        }
        
        // Fallback: split by sentence-ending punctuation if enumeration fails
        if ranges.isEmpty {
            ranges = fallbackSentenceRanges()
        }
        
        return ranges
    }
    
    private func fallbackSentenceRanges() -> [NSRange] {
        var ranges: [NSRange] = []
        let nsString = self as NSString
        
        do {
            let regex = try NSRegularExpression(
                pattern: "[.!?]+\\s*",
                options: [.caseInsensitive]
            )
            
            let matches = regex.matches(
                in: self,
                options: [],
                range: NSRange(location: 0, length: nsString.length)
            )
            
            var currentLocation = 0
            
            for match in matches {
                let sentenceLength = match.range.location + match.range.length - currentLocation
                if sentenceLength > 0 {
                    ranges.append(NSRange(location: currentLocation, length: sentenceLength))
                    currentLocation = match.range.location + match.range.length
                }
            }
            
            // Add remaining text as final sentence
            if currentLocation < nsString.length {
                ranges.append(NSRange(
                    location: currentLocation,
                    length: nsString.length - currentLocation
                ))
            }
            
        } catch {
            // Final fallback: treat entire text as one sentence
            ranges = [NSRange(location: 0, length: nsString.length)]
        }
        
        return ranges
    }
}