//
//  CapsuleDesignSystem.swift
//  Transcriptly
//
//  Created by Claude Code on 8/6/25.
//

import Foundation
import CoreGraphics

import SwiftUI

struct CapsuleDesignSystem {
    static let windowWidth: CGFloat = 320
    static let windowHeight: CGFloat = 180
    static let cornerRadius: CGFloat = 20
    static let padding: CGFloat = 20
    static let buttonSize: CGFloat = 60
    static let modeIndicatorHeight: CGFloat = 24
    static let waveformHeight: CGFloat = 40
    static let minimalSize = CGSize(width: 280, height: 140)
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let expandDuration: TimeInterval = 0.3
}