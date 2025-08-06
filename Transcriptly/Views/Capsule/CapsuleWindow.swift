//
//  CapsuleWindow.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI
import AppKit
import Combine

class CapsuleWindowController: NSWindowController {
    convenience init(viewModel: AppViewModel) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 80),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.init(window: window)
        
        let capsuleView = CapsuleView(viewModel: viewModel)
        window.contentView = NSHostingView(rootView: capsuleView)
        
        // Position at top center
        positionAtTopCenter()
    }
    
    private func positionAtTopCenter() {
        guard let window = window,
              let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        
        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.maxY - windowFrame.height - 20
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

struct CapsuleView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var elapsedTime: TimeInterval = 0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Record button
            Button(action: { 
                Task {
                    if viewModel.isRecording {
                        _ = await viewModel.stopRecording()
                    } else {
                        _ = await viewModel.startRecording()
                    }
                }
            }) {
                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(viewModel.isRecording ? .red : .white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Waveform placeholder
            if viewModel.isRecording {
                WaveformView()
                    .frame(width: 100, height: 40)
            }
            
            // Time and mode
            VStack(alignment: .leading, spacing: 2) {
                if viewModel.isRecording {
                    Text(formatTime(elapsedTime))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Text(viewModel.currentRefinementMode.rawValue)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Expand button
            Button(action: expandToMainWindow) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(40)
        )
        .onReceive(timer) { _ in
            if viewModel.isRecording {
                elapsedTime += 0.1
            } else {
                elapsedTime = 0
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func expandToMainWindow() {
        viewModel.capsuleController.exitCapsuleMode()
    }
}

// Placeholder waveform
struct WaveformView: View {
    @State private var animationValues: [CGFloat] = Array(repeating: 0.3, count: 20)
    @State private var animationTimer: Timer?
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 3, height: max(10, animationValues[index] * 30))
                    .animation(.easeInOut(duration: 0.3).repeatForever(), value: animationValues[index])
            }
        }
        .onAppear {
            startWaveformAnimation()
        }
        .onDisappear {
            stopWaveformAnimation()
        }
    }
    
    private func startWaveformAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                for index in 0..<animationValues.count {
                    animationValues[index] = CGFloat.random(in: 0.3...1.0)
                }
            }
        }
    }
    
    private func stopWaveformAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

#Preview {
    CapsuleView(viewModel: AppViewModel())
        .padding()
}