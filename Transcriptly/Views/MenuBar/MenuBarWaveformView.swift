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
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBars()
    }
    
    private func setupBars() {
        // Initialize bar heights
        barHeights = Array(repeating: 0.3, count: barCount)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Set bar color (white for menu bar)
        context.setFillColor(NSColor.controlAccentColor.cgColor)
        
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