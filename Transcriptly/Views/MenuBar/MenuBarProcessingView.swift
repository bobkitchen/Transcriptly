//
//  MenuBarProcessingView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/27/25.
//

import AppKit

class MenuBarProcessingView: NSView {
    private var animationTimer: Timer?
    private var rotationAngle: CGFloat = 0
    private let dotCount = 3
    private var pulseMagnitudes: [CGFloat] = []
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAnimation()
    }
    
    private func setupAnimation() {
        // Initialize pulse magnitudes for brain-like pulsing dots
        pulseMagnitudes = Array(repeating: 0.5, count: dotCount)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Set color for processing state
        context.setFillColor(NSColor.systemOrange.cgColor)
        
        let centerX = bounds.width / 2
        let centerY = bounds.height / 2
        let spacing: CGFloat = 8
        
        // Draw three pulsing dots in a row (brain-like thinking indicator)
        for i in 0..<dotCount {
            let x = centerX + CGFloat(i - 1) * spacing
            let baseRadius: CGFloat = 3
            let pulseRadius = baseRadius * (0.7 + 0.6 * pulseMagnitudes[i])
            
            let dotRect = CGRect(
                x: x - pulseRadius,
                y: centerY - pulseRadius,
                width: pulseRadius * 2,
                height: pulseRadius * 2
            )
            
            context.fillEllipse(in: dotRect)
        }
    }
    
    func startAnimating() {
        stopAnimating()
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    func stopAnimating() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateAnimation() {
        // Create a wave-like pulsing effect across the dots
        let time = Date().timeIntervalSince1970
        
        for i in 0..<dotCount {
            let phase = CGFloat(i) * 0.8 // Offset each dot
            let pulse = sin(CGFloat(time * 3) + phase) * 0.5 + 0.5 // Smooth sine wave
            pulseMagnitudes[i] = pulse
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.needsDisplay = true
        }
    }
    
    deinit {
        stopAnimating()
    }
}