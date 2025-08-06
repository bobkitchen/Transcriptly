//
//  RefinementPrompt.swift
//  Transcriptly
//
//  Created by Claude Code on 8/6/25.
//

import Foundation

struct RefinementPrompt: Codable, Identifiable {
    let id = UUID()
    let mode: RefinementMode
    var prompt: String
    
    static let defaults: [RefinementMode: String] = [
        .raw: "",
        .cleanup: "Clean up this transcription by removing filler words, fixing grammar, and improving clarity while maintaining the original meaning.",
        .email: "Transform this transcription into a professional email format with proper greeting, body, and closing.",
        .messaging: "Convert this transcription into a casual message format suitable for instant messaging or text."
    ]
    
    static func getDefault(for mode: RefinementMode) -> String {
        return defaults[mode] ?? ""
    }
}