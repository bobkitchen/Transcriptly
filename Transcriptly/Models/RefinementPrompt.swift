//
//  RefinementPrompt.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation

struct RefinementPrompt: Codable {
    let mode: RefinementMode
    var userPrompt: String
    let defaultPrompt: String
    let maxCharacters: Int = 2000
    
    static func defaultPrompts() -> [RefinementMode: RefinementPrompt] {
        // Create prompts for ALL modes, including raw
        return [
            .raw: RefinementPrompt(
                mode: .raw,
                userPrompt: "",  // Raw mode has no AI processing
                defaultPrompt: ""
            ),
            .cleanup: RefinementPrompt(
                mode: .cleanup,
                userPrompt: "Remove filler words like 'um', 'uh', 'you know'. Fix grammar and punctuation. Keep the original meaning and tone.",
                defaultPrompt: "Remove filler words like 'um', 'uh', 'you know'. Fix grammar and punctuation. Keep the original meaning and tone."
            ),
            .email: RefinementPrompt(
                mode: .email,
                userPrompt: "Format as a professional email. Add appropriate greeting and closing. Organize into clear paragraphs.",
                defaultPrompt: "Format as a professional email. Add appropriate greeting and closing. Organize into clear paragraphs."
            ),
            .messaging: RefinementPrompt(
                mode: .messaging,
                userPrompt: "Make the text concise and casual. Remove unnecessary words. Keep it friendly and conversational.",
                defaultPrompt: "Make the text concise and casual. Remove unnecessary words. Keep it friendly and conversational."
            )
        ]
    }
}