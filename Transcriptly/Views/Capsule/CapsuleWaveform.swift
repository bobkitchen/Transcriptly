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
    @State private var amplitudes = Array(repeating: 0.3, count: CapsuleDesignSystem.waveformBarCount)
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: CapsuleDesignSystem.waveformBarSpacing) {
            ForEach(0..<CapsuleDesignSystem.waveformBarCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(CapsuleDesignSystem.waveformActiveOpacity))
                    .frame(
                        width: CapsuleDesignSystem.waveformBarWidth,
                        height: CGFloat(amplitudes[index] * Double(CapsuleDesignSystem.waveformHeight))
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
            withAnimation(.easeInOut(duration: 0.3)) {
                for i in 0..<amplitudes.count {
                    if Bool.random() {
                        amplitudes[i] = Double.random(in: 0.2...1.0)
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
        HStack(spacing: CapsuleDesignSystem.waveformBarSpacing) {
            ForEach(0..<CapsuleDesignSystem.waveformBarCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(CapsuleDesignSystem.waveformIdleOpacity))
                    .frame(
                        width: CapsuleDesignSystem.waveformBarWidth,
                        height: CGFloat(CapsuleDesignSystem.waveformHeight * 0.3)
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