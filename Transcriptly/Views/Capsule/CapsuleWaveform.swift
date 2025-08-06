//
//  CapsuleWaveform.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  Capsule Interface Overhaul - Animated Waveform Components
//

import SwiftUI

/// Animated waveform for recording state
struct CapsuleWaveform: View {
    @State private var amplitudes = Array(repeating: 0.3, count: 6) // Fewer bars
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 1) { // Tighter spacing
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color.white.opacity(CapsuleDesignSystem.waveformActiveOpacity))
                    .frame(
                        width: 1.5, // Thinner bars
                        height: max(2, CGFloat(amplitudes[index] * 14)) // Scale to fit smaller height
                    )
                    .animation(.easeInOut(duration: 0.3), value: amplitudes[index])
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    for i in 0..<amplitudes.count {
                        if Bool.random() {
                            amplitudes[i] = Double.random(in: 0.2...1.0)
                        }
                    }
                }
            }
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

/// Static waveform for idle state
struct CapsuleWaveformIdle: View {
    var body: some View {
        HStack(spacing: 1) { // Tighter spacing
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color.white.opacity(CapsuleDesignSystem.waveformIdleOpacity))
                    .frame(
                        width: 1.5, // Thinner bars
                        height: 4 // Fixed small height for idle state
                    )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Animated Waveform")
            .foregroundColor(.white)
        CapsuleWaveform()
            .frame(height: CapsuleDesignSystem.waveformHeight)
        
        Text("Idle Waveform")
            .foregroundColor(.white)
        CapsuleWaveformIdle()
            .frame(height: CapsuleDesignSystem.waveformHeight)
    }
    .padding()
    .background(.black)
    .cornerRadius(12)
}