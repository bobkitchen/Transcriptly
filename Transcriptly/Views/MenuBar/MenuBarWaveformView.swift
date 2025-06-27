//
//  MenuBarWaveformView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import AppKit

class MenuBarWaveformView: NSView {
    private var animationTimer: Timer?
    private var barHeights: [CGFloat] = []
    private let barCount = 8
    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 1
    private var isIdleState = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBars()
    }
    
    private func setupBars() {
        // Initialize bar heights with a static waveform pattern for idle state
        barHeights = [0.4, 0.7, 0.9, 0.6, 0.8, 0.5, 0.7, 0.3]
    }
    
    func setIdleState(_ idle: Bool) {
        isIdleState = idle
        if idle {
            setupBars() // Reset to static pattern
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Set bar color - dimmer for idle, brighter for recording
        let color = isIdleState ? 
            NSColor.controlAccentColor.withAlphaComponent(0.6) : 
            NSColor.controlAccentColor
        context.setFillColor(color.cgColor)
        
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        let startX = (bounds.width - totalWidth) / 2
        
        for (index, height) in barHeights.enumerated() {
            let x = startX + CGFloat(index) * (barWidth + barSpacing)
            let barHeight = bounds.height * height
            let y = (bounds.height - barHeight) / 2
            
            let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            context.fillEllipse(in: barRect) // Use ellipse for rounded bars
        }
    }
    
    func startAnimating() {
        stopAnimating()
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateBarHeights()
        }
    }
    
    func stopAnimating() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateBarHeights() {
        // Generate random heights for each bar to simulate waveform
        for index in 0..<barHeights.count {
            barHeights[index] = CGFloat.random(in: 0.3...1.0)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.needsDisplay = true
        }
    }
    
    deinit {
        stopAnimating()
    }
}