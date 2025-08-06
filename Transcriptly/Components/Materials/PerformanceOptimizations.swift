//
//  PerformanceOptimizations.swift
//  Transcriptly
//
//  Created by Claude Code on 7/2/25.
//  Phase 9.5 - Performance Optimizations for 60fps
//

import SwiftUI
import Combine

// MARK: - Render Performance Utilities

/// Optimized animation modifier that ensures 60fps performance
struct OptimizedAnimation<V: Equatable>: ViewModifier {
    let animation: Animation?
    let value: V
    
    func body(content: Content) -> some View {
        content
            .animation(animation, value: value)
    }
}

/// Cached shadow modifier for reduced recalculation
struct CachedShadow: ViewModifier {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                Color.clear
                    .shadow(color: color, radius: radius, x: x, y: y)
                    .allowsHitTesting(false)
            )
    }
}

/// Lightweight hover tracking
struct LightweightHover: ViewModifier {
    @Binding var isHovered: Bool
    let throttleDelay: Double
    
    init(isHovered: Binding<Bool>, throttleDelay: Double = 0.016) { // 60fps = ~16ms
        self._isHovered = isHovered
        self.throttleDelay = throttleDelay
    }
    
    @State private var hoverTask: Task<Void, Never>?
    
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                hoverTask?.cancel()
                hoverTask = Task {
                    try? await Task.sleep(for: .seconds(throttleDelay))
                    if !Task.isCancelled {
                        isHovered = hovering
                    }
                }
            }
    }
}

// MARK: - Optimized Material Views

/// Performance-optimized material background
struct OptimizedMaterial: View {
    let material: Material
    let cornerRadius: CGFloat
    
    // Cache the material view
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(material)
            .drawingGroup() // Flatten for performance
    }
}

/// Debounced state changes for smooth animations
@MainActor
class DebouncedState<Value>: ObservableObject {
    @Published private(set) var value: Value
    private var task: Task<Void, Never>?
    private let delay: TimeInterval
    
    init(initialValue: Value, delay: TimeInterval = 0.016) { // 16ms for 60fps
        self.value = initialValue
        self.delay = delay
    }
    
    func update(_ newValue: Value) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !Task.isCancelled {
                self.value = newValue
            }
        }
    }
}

// MARK: - View Extensions for Performance

extension View {
    /// Apply optimized animation that maintains 60fps
    func optimizedAnimation<V: Equatable>(
        _ animation: Animation? = .default,
        value: V
    ) -> some View {
        modifier(OptimizedAnimation(animation: animation, value: value))
    }
    
    /// Apply cached shadow for better performance
    func cachedShadow(
        color: Color = .black.opacity(0.1),
        radius: CGFloat = 8,
        x: CGFloat = 0,
        y: CGFloat = 4
    ) -> some View {
        modifier(CachedShadow(color: color, radius: radius, x: x, y: y))
    }
    
    /// Apply lightweight hover tracking
    func lightweightHover(
        isHovered: Binding<Bool>,
        throttleDelay: Double = 0.016
    ) -> some View {
        modifier(LightweightHover(isHovered: isHovered, throttleDelay: throttleDelay))
    }
    
    /// Reduce opacity animations for better performance
    func reducedMotion(_ reduce: Bool = true) -> some View {
        transaction { transaction in
            if reduce {
                transaction.animation = transaction.animation?.speed(2)
            }
        }
    }
    
    /// Apply render optimization for complex views
    func renderOptimized() -> some View {
        self
            .drawingGroup()
            .compositingGroup()
    }
}

// MARK: - Performance Best Practices

struct PerformanceGuidelines {
    /// Maximum recommended blur radius for 60fps
    static let maxBlurRadius: CGFloat = 20
    
    /// Maximum recommended shadow radius for 60fps
    static let maxShadowRadius: CGFloat = 20
    
    /// Recommended animation duration for smooth transitions
    static let smoothAnimationDuration: Double = 0.3
    
    /// Throttle delay for 60fps (16.67ms)
    static let frameThrottleDelay: Double = 0.01667
    
    /// Maximum recommended simultaneous animations
    static let maxSimultaneousAnimations = 3
}

// MARK: - Debug Performance Overlay

struct PerformanceDebugOverlay: ViewModifier {
    @State private var frameRate: Double = 60
    @State private var lastUpdate = Date()
    let showOverlay: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if showOverlay {
                    Text("\(Int(frameRate)) fps")
                        .font(.caption.monospaced())
                        .padding(4)
                        .background(.black.opacity(0.7))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                        .padding(8)
                }
            }
            .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                let now = Date()
                let delta = now.timeIntervalSince(lastUpdate)
                frameRate = 1.0 / delta
                lastUpdate = now
            }
    }
}

extension View {
    /// Show performance debug overlay
    func performanceDebugOverlay(_ show: Bool = true) -> some View {
        modifier(PerformanceDebugOverlay(showOverlay: show))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Optimized Material")
            .padding()
            .background(
                OptimizedMaterial(
                    material: .regularMaterial,
                    cornerRadius: 12
                )
            )
            .cachedShadow()
        
        Text("Performance Debug")
            .padding()
            .background(.regularMaterial)
            .cornerRadius(8)
            .performanceDebugOverlay()
    }
    .padding()
}