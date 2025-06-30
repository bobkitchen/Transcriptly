//
//  HapticFeedback.swift
//  Transcriptly
//
//  Created by Claude Code on 6/30/25.
//  Utilities - Haptic Feedback Helper
//

import AppKit

struct HapticFeedback {
    
    static func impact() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
    
    static func selection() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
    
    static func success() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
    
    static func error() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
}