# Transcriptly Capsule Interface Overhaul - Detailed Task List

## Phase C.0: Setup and Architecture

### Task C.0.1: Create Capsule Overhaul Branch
```bash
git checkout main
git pull origin main
git checkout -b capsule-overhaul
git push -u origin capsule-overhaul
```

### Task C.0.2: Create New Capsule Architecture
```
Transcriptly/
├── Views/
│   └── Capsule/
│       ├── FloatingCapsuleController.swift
│       ├── MinimalCapsuleView.swift
│       ├── ExpandedCapsuleView.swift
│       ├── CapsuleWaveform.swift
│       └── ScreenPositioning.swift
└── Services/
    └── CapsuleWindowManager.swift
```

### Task C.0.3: Document Design Specifications
```swift
// Create CapsuleDesignSystem.swift
struct CapsuleDesignSystem {
    // Sizes
    static let minimalSize = CGSize(width: 60, height: 20)
    static let expandedSize = CGSize(width: 150, height: 40)
    
    // Positioning
    static let topMargin: CGFloat = 20
    
    // Animation
    static let expandDuration: TimeInterval = 0.25
    static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.8)
    
    // Visual
    static let waveformHeight: CGFloat = 20
    static let borderOpacity: Double = 0.8
}
```

**Checkpoint C.0**:
- [ ] Branch created and architecture planned
- [ ] File structure created
- [ ] Design system constants defined
- [ ] Git commit: "Setup capsule overhaul architecture"

---

## Phase C.1: Screen Positioning and Notch Detection

### Task C.1.1: Implement Screen Detection
```swift
// Services/ScreenPositioning.swift
import AppKit
import Foundation

class ScreenPositioning: ObservableObject {
    @Published var capsulePosition: CGPoint = .zero
    
    func calculateCapsulePosition() -> CGPoint {
        guard let screen = NSScreen.main else {
            return CGPoint(x: 400, y: 100) // Fallback
        }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        // Calculate top safe area (accounts for notch)
        let topSafeArea = screenFrame.maxY - visibleFrame.maxY
        let menuBarHeight: CGFloat = 24 // Standard menu bar height
        
        // Position below the lower of: menu bar or notch
        let topOffset = max(menuBarHeight, topSafeArea) + CapsuleDesignSystem.topMargin
        
        // Center horizontally
        let x = screenFrame.midX - (CapsuleDesignSystem.minimalSize.width / 2)
        let y = screenFrame.maxY - topOffset - CapsuleDesignSystem.minimalSize.height
        
        return CGPoint(x: x, y: y)
    }
    
    func updatePosition() {
        capsulePosition = calculateCapsulePosition()
    }
    
    // Monitor for screen changes
    func startMonitoring() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePosition()
        }
    }
}
```

### Task C.1.2: Create Floating Window Controller
```swift
// Views/Capsule/FloatingCapsuleController.swift
import AppKit
import SwiftUI

class FloatingCapsuleController: NSWindowController {
    private let viewModel: MainViewModel
    private let screenPositioning = ScreenPositioning()
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        
        // Create floating window
        let window = NSWindow(
            contentRect: NSRect(
                origin: .zero,
                size: CapsuleDesignSystem.minimalSize
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        setupWindow()
        setupContentView()
        positionWindow()
        
        screenPositioning.startMonitoring()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupWindow() {
        guard let window = window else { return }
        
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
    }
    
    private func setupContentView() {
        guard let window = window else { return }
        
        let capsuleView = CapsuleContainerView(
            viewModel: viewModel,
            onExpand: { [weak self] in
                self?.expandCapsule()
            },
            onCollapse: { [weak self] in
                self?.collapseCapsule()
            },
            onClose: { [weak self] in
                self?.closeCapsule()
            }
        )
        
        window.contentView = NSHostingView(rootView: capsuleView)
    }
    
    private func positionWindow() {
        guard let window = window else { return }
        
        let position = screenPositioning.calculateCapsulePosition()
        window.setFrameOrigin(position)
    }
    
    func expandCapsule() {
        guard let window = window else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = CapsuleDesignSystem.expandDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            let newSize = CapsuleDesignSystem.expandedSize
            let currentOrigin = window.frame.origin
            
            // Adjust position to keep centered during expansion
            let xOffset = (CapsuleDesignSystem.expandedSize.width - CapsuleDesignSystem.minimalSize.width) / 2
            let newOrigin = CGPoint(x: currentOrigin.x - xOffset, y: currentOrigin.y)
            
            window.animator().setFrame(
                NSRect(origin: newOrigin, size: newSize),
                display: true
            )
        }
    }
    
    func collapseCapsule() {
        guard let window = window else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = CapsuleDesignSystem.expandDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            let newSize = CapsuleDesignSystem.minimalSize
            let currentOrigin = window.frame.origin
            
            // Adjust position to keep centered during collapse
            let xOffset = (CapsuleDesignSystem.expandedSize.width - CapsuleDesignSystem.minimalSize.width) / 2
            let newOrigin = CGPoint(x: currentOrigin.x + xOffset, y: currentOrigin.y)
            
            window.animator().setFrame(
                NSRect(origin: newOrigin, size: newSize),
                display: true
            )
        }
    }
    
    private func closeCapsule() {
        window?.close()
        // Signal to main app that capsule closed
        NotificationCenter.default.post(name: .capsuleClosed, object: nil)
    }
}

extension Notification.Name {
    static let capsuleClosed = Notification.Name("capsuleClosed")
}
```

**Test Protocol C.1**:
1. Launch capsule on different screen configurations
2. Test with MacBook (notch) vs external monitor (no notch)
3. Verify positioning stays centered after screen changes
4. Test window level (should float above other apps)
5. Verify smooth expand/collapse animations

**Checkpoint C.1**:
- [ ] Capsule positions correctly below menu bar/notch
- [ ] Handles multiple screen scenarios
- [ ] Smooth expand/collapse animations
- [ ] Window stays above other apps
- [ ] Git commit: "Implement capsule positioning and window management"

---

## Phase C.2: Minimal and Expanded States

### Task C.2.1: Create Minimal Capsule View
```swift
// Views/Capsule/MinimalCapsuleView.swift
import SwiftUI

struct MinimalCapsuleView: View {
    @State private var isHovered = false
    let onHover: (Bool) -> Void
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        Color.gray.opacity(CapsuleDesignSystem.borderOpacity),
                        lineWidth: 1
                    )
            )
            .frame(
                width: CapsuleDesignSystem.minimalSize.width,
                height: CapsuleDesignSystem.minimalSize.height
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(CapsuleDesignSystem.springAnimation, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
                onHover(hovering)
            }
    }
}
```

### Task C.2.2: Create Expanded Capsule View
```swift
// Views/Capsule/ExpandedCapsuleView.swift
import SwiftUI

struct ExpandedCapsuleView: View {
    @ObservedObject var viewModel: MainViewModel
    let onHover: (Bool) -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Record button (left)
            Button(action: { viewModel.toggleRecording() }) {
                Circle()
                    .fill(recordButtonColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: recordButtonIcon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
            .buttonStyle(.plain)
            .help(viewModel.isRecording ? "Stop Recording" : "Start Recording")
            
            Spacer()
            
            // Center content area
            VStack(spacing: 2) {
                // Waveform
                if viewModel.isRecording {
                    CapsuleWaveform()
                        .frame(height: CapsuleDesignSystem.waveformHeight)
                } else {
                    CapsuleWaveformIdle()
                        .frame(height: CapsuleDesignSystem.waveformHeight)
                }
                
                // Current mode name
                Text(viewModel.currentMode.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Expand button (right)
            Button(action: onClose) {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.8))
                    )
            }
            .buttonStyle(.plain)
            .help("Return to Main Window")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(
            width: CapsuleDesignSystem.expandedSize.width,
            height: CapsuleDesignSystem.expandedSize.height
        )
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            Color.gray.opacity(CapsuleDesignSystem.borderOpacity),
                            lineWidth: 1
                        )
                )
        )
        .onHover { hovering in
            onHover(hovering)
        }
    }
    
    private var recordButtonColor: Color {
        if viewModel.isRecording {
            return .red
        } else {
            return Color.red.opacity(0.8)
        }
    }
    
    private var recordButtonIcon: String {
        viewModel.isRecording ? "stop.fill" : "mic.fill"
    }
}
```

### Task C.2.3: Create Waveform Components
```swift
// Views/Capsule/CapsuleWaveform.swift
import SwiftUI

struct CapsuleWaveform: View {
    @State private var amplitudes = Array(repeating: 0.3, count: 8)
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.9))
                    .frame(
                        width: 2,
                        height: CGFloat(amplitudes[index] * Double(CapsuleDesignSystem.waveformHeight))
                    )
                    .animation(.easeInOut(duration: 0.3), value: amplitudes[index])
            }
        }
        .onReceive(timer) { _ in
            // Animate random bars
            for i in 0..<amplitudes.count {
                if Bool.random() {
                    amplitudes[i] = Double.random(in: 0.2...1.0)
                }
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
    }
}

struct CapsuleWaveformIdle: View {
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.4))
                    .frame(
                        width: 2,
                        height: CGFloat(CapsuleDesignSystem.waveformHeight * 0.3)
                    )
            }
        }
    }
}
```

### Task C.2.4: Create Container View with State Management
```swift
// Views/Capsule/CapsuleContainerView.swift
import SwiftUI

struct CapsuleContainerView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isExpanded = false
    @State private var isHovered = false
    
    let onExpand: () -> Void
    let onCollapse: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        Group {
            if isExpanded {
                ExpandedCapsuleView(
                    viewModel: viewModel,
                    onHover: handleHover,
                    onClose: onClose
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            } else {
                MinimalCapsuleView(
                    onHover: handleHover
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .animation(CapsuleDesignSystem.springAnimation, value: isExpanded)
        .onChange(of: isExpanded) { newValue in
            if newValue {
                onExpand()
            } else {
                onCollapse()
            }
        }
        .onChange(of: viewModel.isRecording) { isRecording in
            // Keep expanded while recording
            if isRecording {
                if !isExpanded {
                    isExpanded = true
                }
            }
        }
    }
    
    private func handleHover(_ hovering: Bool) {
        isHovered = hovering
        
        // Expand on hover, collapse on leave (unless recording)
        if hovering {
            isExpanded = true
        } else if !viewModel.isRecording {
            isExpanded = false
        }
    }
}
```

**Test Protocol C.2**:
1. Hover over minimal capsule - should expand immediately
2. Move cursor away - should collapse (unless recording)
3. Start recording - capsule should stay expanded
4. Test record button changes appearance when recording
5. Verify waveform animates only when recording
6. Test expand button closes capsule

**Checkpoint C.2**:
- [ ] Minimal state appears correctly
- [ ] Hover triggers immediate expansion
- [ ] Expanded state shows all components
- [ ] Recording keeps capsule expanded
- [ ] Waveform animates during recording
- [ ] Git commit: "Implement capsule states and interactions"

---

## Phase C.3: Integration and Polish

### Task C.3.1: Integrate with Main App
```swift
// Update MainWindowView.swift to include capsule management
class CapsuleWindowManager: ObservableObject {
    private var capsuleController: FloatingCapsuleController?
    private let viewModel: MainViewModel
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        
        // Listen for capsule close notifications
        NotificationCenter.default.addObserver(
            forName: .capsuleClosed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.capsuleController = nil
        }
    }
    
    func showCapsule() {
        guard capsuleController == nil else { return }
        
        capsuleController = FloatingCapsuleController(viewModel: viewModel)
        capsuleController?.showWindow(nil)
    }
    
    func hideCapsule() {
        capsuleController?.close()
        capsuleController = nil
    }
    
    var isCapsuleVisible: Bool {
        capsuleController != nil
    }
}

// Update MainWindowView.swift
struct MainWindowView: View {
    @StateObject var viewModel = MainViewModel()
    @StateObject private var capsuleManager: CapsuleWindowManager
    @State private var selectedSection: SidebarSection = .home
    
    init() {
        let vm = MainViewModel()
        self._viewModel = StateObject(wrappedValue: vm)
        self._capsuleManager = StateObject(wrappedValue: CapsuleWindowManager(viewModel: vm))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TopBar(
                viewModel: viewModel,
                showCapsuleMode: capsuleManager.showCapsule
            )
            
            HStack(spacing: 0) {
                SidebarView(selectedSection: $selectedSection)
                
                Divider()
                
                MainContentView(
                    selectedSection: $selectedSection,
                    viewModel: viewModel
                )
            }
        }
        .frame(minWidth: 920, minHeight: 640)
        .onReceive(NotificationCenter.default.publisher(for: .capsuleClosed)) { _ in
            // Bring main window to front when capsule closes
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
```

### Task C.3.2: Update Top Bar Integration
```swift
// Update Components/TopBar.swift
struct TopBar: View {
    @ObservedObject var viewModel: MainViewModel
    let showCapsuleMode: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Text("Transcriptly")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.tertiaryText)
            
            Spacer()
            
            Text(viewModel.currentMode.displayName)
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            
            CompactRecordButton(
                isRecording: viewModel.isRecording,
                recordingTime: viewModel.recordingTime,
                action: viewModel.toggleRecording
            )
            
            Button(action: showCapsuleMode) {
                Image(systemName: "capsule")
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
            }
            .buttonStyle(.plain)
            .help("Enter Capsule Mode")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .overlay(
            Divider()
                .background(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }
}
```

### Task C.3.3: Add Performance Optimizations
```swift
// Add to CapsuleContainerView.swift
private struct CapsulePreferences {
    static let hoverDebounceTime: TimeInterval = 0.05
    static let animationDuration: TimeInterval = 0.25
    static let maxFrameRate: Double = 60
}

// Optimize waveform rendering
struct CapsuleWaveform: View {
    @State private var amplitudes = Array(repeating: 0.3, count: 8)
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.9))
                    .frame(
                        width: 2,
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
            for i in 0..<amplitudes.count {
                if Bool.random() {
                    amplitudes[i] = Double.random(in: 0.2...1.0)
                }
            }
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}
```

### Task C.3.4: Add Accessibility Support
```swift
// Add accessibility to all capsule components
extension ExpandedCapsuleView {
    var body: some View {
        // ... existing implementation ...
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Floating recording interface")
        .accessibilityHint("Hover to expand, click record button to start recording")
    }
}

extension MinimalCapsuleView {
    var body: some View {
        // ... existing implementation ...
        .accessibilityElement()
        .accessibilityLabel("Recording capsule - minimized")
        .accessibilityHint("Hover to expand recording interface")
        .accessibilityAddTraits(.isButton)
    }
}
```

**Test Protocol C.3**:
1. Launch capsule from top bar - verify it appears correctly
2. Test recording from both main window and capsule
3. Close capsule - verify main window comes to front
4. Test performance with multiple hover/expand cycles
5. Verify accessibility with VoiceOver
6. Test on different screen configurations

**Checkpoint C.3**:
- [ ] Capsule integrates smoothly with main app
- [ ] Performance is smooth during animations
- [ ] Accessibility features work correctly
- [ ] Multi-screen support functional
- [ ] Git commit: "Complete capsule integration and polish"

---

## Phase C.4: Final Testing and Edge Cases

### Task C.4.1: Edge Case Testing
1. **Multi-monitor scenarios**: Test capsule positioning across different monitor configurations
2. **Screen resolution changes**: Verify repositioning when resolution changes
3. **Full-screen apps**: Ensure capsule behavior with full-screen applications
4. **System sleep/wake**: Test capsule persistence across sleep cycles
5. **App termination**: Ensure clean capsule cleanup on app quit

### Task C.4.2: Performance Validation
1. **Memory usage**: Monitor for leaks during expand/collapse cycles
2. **CPU usage**: Verify waveform animation efficiency
3. **Frame rate**: Ensure 60fps during all animations
4. **Battery impact**: Test energy efficiency on MacBook

### Task C.4.3: User Experience Polish
1. **Animation timing**: Fine-tune expand/collapse feel
2. **Hover sensitivity**: Adjust hover areas for optimal UX
3. **Visual feedback**: Ensure all states are visually clear
4. **Error handling**: Graceful degradation if positioning fails

**Final Testing Protocol**:
1. Complete 50 hover expand/collapse cycles
2. Record 20 transcriptions via capsule interface
3. Test across 3 different screen configurations
4. Verify accessibility with VoiceOver enabled
5. Monitor memory usage over 30-minute session
6. Test with system sleep/wake cycle

**Phase C Final Checkpoint**:
- [ ] Minimal capsule (60×20px) positions correctly below menu bar/notch
- [ ] Immediate hover expansion to 150×40px
- [ ] Smooth spring animations (0.25s)
- [ ] Recording functionality integrated
- [ ] Waveform animates only when recording
- [ ] Auto-collapse (except during recording)
- [ ] Expand button returns to main window
- [ ] Performance optimized for always-visible interface
- [ ] Multi-screen support working
- [ ] Accessibility features complete
- [ ] Git commit: "Complete capsule interface overhaul"
- [ ] Tag: v1.1.0-capsule-complete

## Success Criteria

1. **Minimal Intrusion**: Nearly invisible when not needed
2. **Instant Access**: Immediate hover response and expansion
3. **Smooth Performance**: 60fps animations, no stuttering
4. **Reliable Positioning**: Correct placement across all Mac configurations
5. **Intuitive Interaction**: Predictable hover/expand/record behavior
6. **System Integration**: Feels like native macOS functionality

This capsule interface will provide the ultimate balance between accessibility and unobtrusiveness, creating a premium floating recording experience.