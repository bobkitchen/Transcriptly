# Transcriptly Phase 4 Fixes - Detailed Task List

## Phase 4F.0: Setup and Assessment

### Task 4F.0.1: Create Fixes Branch
```bash
git checkout main
git pull origin main
git checkout -b phase-4-fixes
git push -u origin phase-4-fixes
```

### Task 4F.0.2: Audit Current State
Document exactly what's working vs. broken:
- ✅ Working: Basic navigation, recording, transcription, mode selection
- ❌ Broken: Capsule button, edit buttons, apps buttons, fake data
- ⚠️ Incomplete: Learning view, Settings view design consistency

### Task 4F.0.3: Prioritize Fixes
1. **P0 (Critical)**: Layout hierarchy and non-functional buttons
2. **P1 (High)**: Complete design system rollout
3. **P2 (Medium)**: Real data integration and empty states

---

## Phase 4F.1: Layout Hierarchy Fix

### Task 4F.1.1: Redesign Top Bar as Subtle Header
```swift
// Update Components/TopBar.swift
struct TopBar: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var showCapsuleMode: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Minimal app title - smaller, more subtle
            Text("Transcriptly")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.tertiaryText)
            
            Spacer()
            
            // Quick mode indicator (read-only)
            Text(viewModel.currentMode.displayName)
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            
            // Record button (smaller, more subtle)
            CompactRecordButton(
                isRecording: viewModel.isRecording,
                recordingTime: viewModel.recordingTime,
                action: viewModel.toggleRecording
            )
            
            // Capsule mode button (functional)
            Button(action: { showCapsuleMode = true }) {
                Image(systemName: "capsule")
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
            }
            .buttonStyle(.plain)
            .help("Enter Capsule Mode")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)  // Reduced from 12
        .background(.regularMaterial)
        .overlay(
            Divider()
                .background(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }
}

// New compact record button
struct CompactRecordButton: View {
    let isRecording: Bool
    let recordingTime: TimeInterval
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 16))
                    .symbolRenderingMode(.hierarchical)
                
                if isRecording {
                    Text(timeString(from: recordingTime))
                        .font(.system(.caption2, design: .monospaced))
                        .frame(width: 36)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: isRecording ? [.red, .red.opacity(0.8)] : [.accentColor, .accentColor.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
```

### Task 4F.1.2: Enhance Sidebar Visual Priority
```swift
// Update Views/Sidebar/SidebarView.swift
struct SidebarView: View {
    @Binding var selectedSection: SidebarSection
    @State private var hoveredSection: SidebarSection?
    
    var body: some View {
        VStack(spacing: 0) {
            // Sidebar header with more prominence
            HStack {
                Text("Navigation")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.tertiaryText)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Navigation items with better spacing
            VStack(spacing: 2) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    SidebarItem(
                        section: section,
                        isSelected: selectedSection == section,
                        isHovered: hoveredSection == section,
                        isEnabled: section.isEnabled
                    )
                    .onTapGesture {
                        if section.isEnabled {
                            selectedSection = section
                        }
                    }
                    .onHover { hovering in
                        hoveredSection = hovering ? section : nil
                    }
                }
            }
            .padding(.horizontal, 12)
            
            Spacer()
        }
        .frame(width: 220)  // Slightly wider for better presence
        .background(.thickMaterial)  // More prominent material
        .overlay(
            // Subtle right border
            Rectangle()
                .frame(width: 0.5)
                .foregroundColor(.white.opacity(0.1)),
            alignment: .trailing
        )
    }
}
```

### Task 4F.1.3: Adjust Main Window Layout
```swift
// Update MainWindowView.swift
struct MainWindowView: View {
    @StateObject var viewModel = MainViewModel()
    @State private var selectedSection: SidebarSection = .home
    @State private var showCapsuleMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Smaller, more subtle top bar
            TopBar(
                viewModel: viewModel,
                showCapsuleMode: $showCapsuleMode
            )
            
            // Main content with sidebar getting visual priority
            HStack(spacing: 0) {
                // Prominent sidebar
                SidebarView(selectedSection: $selectedSection)
                
                // Main content area
                MainContentView(
                    selectedSection: $selectedSection,
                    viewModel: viewModel
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 920, minHeight: 640)  // Adjusted for new layout
        .sheet(isPresented: $showCapsuleMode) {
            CapsuleMode(viewModel: viewModel)
        }
    }
}
```

**Test Protocol 4F.1**:
1. Verify sidebar feels like primary navigation
2. Check top bar is subtle but functional
3. Test capsule button launches capsule mode
4. Ensure record button works in compact form
5. Verify layout proportions feel balanced

**Checkpoint 4F.1**:
- [ ] Sidebar has visual priority
- [ ] Top bar is subtle but functional
- [ ] Capsule button works
- [ ] Layout feels balanced
- [ ] Git commit: "Fix layout hierarchy - sidebar first"

---

## Phase 4F.2: Wire Non-Functional Buttons

### Task 4F.2.1: Implement Edit Prompt Functionality
```swift
// Update Views/Transcription/TranscriptionView.swift
struct TranscriptionView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showEditPrompt = false
    @State private var editingMode: RefinementMode?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("AI Refinement Modes")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                VStack(spacing: 12) {
                    ForEach(RefinementMode.allCases, id: \.self) { mode in
                        ModeCard(
                            mode: mode,
                            selectedMode: $viewModel.currentMode,
                            stats: viewModel.modeStatistics[mode],
                            onEdit: {
                                editingMode = mode
                                showEditPrompt = true
                            },
                            onAppsConfig: mode != .raw ? {
                                showAppConfigSheet(for: mode)
                            } : nil
                        )
                    }
                }
            }
            .padding(20)
        }
        .background(Color.primaryBackground)
        .sheet(isPresented: $showEditPrompt) {
            if let mode = editingMode {
                EditPromptSheet(
                    mode: mode,
                    currentPrompt: viewModel.refinementService.prompts[mode]?.userPrompt ?? "",
                    onSave: { newPrompt in
                        viewModel.refinementService.updatePrompt(for: mode, prompt: newPrompt)
                        showEditPrompt = false
                    },
                    onCancel: {
                        showEditPrompt = false
                    }
                )
            }
        }
    }
    
    private func showAppConfigSheet(for mode: RefinementMode) {
        // TODO: Implement in future phase
        print("App configuration for \(mode.displayName) - Coming Soon")
    }
}

// Create the actual edit prompt sheet
struct EditPromptSheet: View {
    let mode: RefinementMode
    @State private var promptText: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    init(mode: RefinementMode, currentPrompt: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.mode = mode
        self._promptText = State(initialValue: currentPrompt)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit \(mode.displayName) Prompt")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Customize how AI refines your transcriptions in this mode")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
            }
            
            // Text editor
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Instructions:")
                    .font(.system(size: 14, weight: .medium))
                
                TextEditor(text: $promptText)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(Color.tertiaryBackground)
                    .cornerRadius(8)
                    .frame(height: 120)
                
                HStack {
                    Text("\(promptText.count)/500")
                        .font(.system(size: 12))
                        .foregroundColor(promptText.count > 500 ? .red : .tertiaryText)
                    
                    Spacer()
                    
                    Button("Reset to Default") {
                        promptText = mode.defaultPrompt
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 12))
                }
            }
            
            // Footer buttons
            HStack {
                Spacer()
                
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                
                Button("Save Changes") {
                    onSave(promptText)
                }
                .buttonStyle(.borderedProminent)
                .disabled(promptText.isEmpty || promptText.count > 500)
            }
        }
        .padding(24)
        .frame(width: 480, height: 320)
        .background(.regularMaterial)
    }
}
```

### Task 4F.2.2: Add Default Prompts to RefinementMode
```swift
// Update Models/RefinementMode.swift
extension RefinementMode {
    var defaultPrompt: String {
        switch self {
        case .raw:
            return ""
        case .cleanup:
            return "Remove filler words (um, uh, like, you know), fix grammar and punctuation, and improve sentence structure while preserving the original meaning and tone."
        case .email:
            return "Format as a professional email with appropriate greeting, clear paragraphs, proper salutation, and business-appropriate tone. Add subject line suggestions if the content warrants it."
        case .messaging:
            return "Make the text concise and conversational. Remove unnecessary words, use casual tone, and format for quick messaging platforms. Keep it friendly but brief."
        }
    }
    
    var description: String {
        switch self {
        case .raw:
            return "No AI processing - exactly what you said"
        case .cleanup:
            return "Removes filler words and fixes grammar"
        case .email:
            return "Professional formatting with greetings and signatures"
        case .messaging:
            return "Concise and casual for quick messages"
        }
    }
}
```

### Task 4F.2.3: Fix Capsule Mode Connection
```swift
// Create Views/Capsule/CapsuleMode.swift
import SwiftUI

struct CapsuleMode: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    @State private var windowPosition = CGPoint(x: 0, y: 0)
    
    var body: some View {
        HStack(spacing: 16) {
            // Record button
            Button(action: { viewModel.toggleRecording() }) {
                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(viewModel.isRecording ? .red : .white)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            
            // Waveform visualization (when recording)
            if viewModel.isRecording {
                CapsuleWaveform()
                    .frame(width: 80, height: 32)
            }
            
            // Info display
            VStack(alignment: .leading, spacing: 2) {
                if viewModel.isRecording {
                    Text(timeString(from: viewModel.recordingTime))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                } else {
                    Text("Ready to Record")
                        .font(.system(.caption))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text(viewModel.currentMode.displayName)
                    .font(.system(.caption2))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Expand button
            Button(action: {
                dismiss()
                // Bring main window to front
                NSApp.activate(ignoringOtherApps: true)
            }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help("Return to Main Window")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
        .frame(width: 280, height: 56)
        .onAppear {
            positionCapsule()
        }
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func positionCapsule() {
        // Position at top center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 140  // Half of capsule width
            let y = screenFrame.maxY - 80   // From top of screen
            windowPosition = CGPoint(x: x, y: y)
        }
    }
}

struct CapsuleWaveform: View {
    @State private var animationValues = Array(repeating: 0.3, count: 12)
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 3, height: CGFloat(animationValues[index] * 24 + 4))
                    .animation(.easeInOut(duration: 0.3), value: animationValues[index])
            }
        }
        .onReceive(timer) { _ in
            // Animate random bars
            for i in 0..<animationValues.count {
                if Bool.random() {
                    animationValues[i] = Double.random(in: 0.2...1.0)
                }
            }
        }
    }
}
```

**Test Protocol 4F.2**:
1. Click Edit button on any mode card
2. Verify prompt editor opens with current prompt
3. Edit prompt and save - verify it persists
4. Test Reset to Default button
5. Test capsule mode launch and return
6. Verify all buttons provide visual feedback

**Checkpoint 4F.2**:
- [ ] Edit buttons open functional prompt editor
- [ ] Prompt changes save and persist
- [ ] Capsule mode launches and works
- [ ] All interactive elements functional
- [ ] Git commit: "Wire all non-functional buttons"

---

## Phase 4F.3: Complete Design System Rollout

### Task 4F.3.1: Redesign Learning View
```swift
// Update Views/Learning/LearningView.swift
struct LearningView: View {
    @ObservedObject var learningService = LearningService.shared
    @State private var showResetConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Learning")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Text("Transcriptly learns from your corrections to improve accuracy over time")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }
                
                // Status card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20))
                            .foregroundColor(.accentColor)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("Learning Status")
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                        Toggle("", isOn: $learningService.isLearningEnabled)
                            .toggleStyle(SwitchToggleStyle())
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Sessions: \(learningService.sessionCount)")
                                .font(.system(size: 14))
                            
                            Text("•")
                                .foregroundColor(.tertiaryText)
                            
                            Text(learningQualityText)
                                .font(.system(size: 14))
                                .foregroundColor(learningQualityColor)
                        }
                        
                        if !learningService.isLearningEnabled {
                            Text("Learning is paused. Enable to continue improving accuracy.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondaryText)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(20)
                .liquidGlassBackground(cornerRadius: 12)
                
                // Learned patterns section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Learned Patterns")
                            .font(.system(size: 18, weight: .medium))
                        
                        Spacer()
                        
                        Button("Refresh") {
                            // Refresh patterns
                        }
                        .font(.system(size: 12))
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                    
                    if learningService.sessionCount == 0 {
                        VStack(spacing: 12) {
                            Image(systemName: "brain")
                                .font(.system(size: 48))
                                .foregroundColor(.tertiaryText)
                                .symbolRenderingMode(.hierarchical)
                            
                            Text("No patterns learned yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondaryText)
                            
                            Text("As you use Transcriptly, it will learn from your corrections and preferences to improve accuracy.")
                                .font(.system(size: 14))
                                .foregroundColor(.tertiaryText)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 300)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Future: Show actual learned patterns
                        Text("Pattern list will appear here")
                            .foregroundColor(.tertiaryText)
                            .italic()
                    }
                }
                .padding(20)
                .liquidGlassBackground(cornerRadius: 12)
                
                // Controls section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Learning Controls")
                        .font(.system(size: 18, weight: .medium))
                    
                    VStack(spacing: 12) {
                        Button("Reset All Learning Data") {
                            showResetConfirmation = true
                        }
                        .buttonStyle(DestructiveButtonStyle())
                        .disabled(learningService.sessionCount == 0)
                        
                        if learningService.sessionCount == 0 {
                            Text("No learning data to reset")
                                .font(.system(size: 12))
                                .foregroundColor(.tertiaryText)
                        }
                    }
                }
                .padding(20)
                .liquidGlassBackground(cornerRadius: 12)
            }
            .padding(20)
        }
        .background(Color.primaryBackground)
        .confirmationDialog(
            "Reset All Learning Data",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset All Data", role: .destructive) {
                Task {
                    await learningService.resetAllLearning()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all learned patterns and preferences. This action cannot be undone.")
        }
    }
    
    private var learningQualityText: String {
        switch learningService.learningQuality {
        case .minimal: return "Getting Started"
        case .basic: return "Learning Basics"
        case .good: return "Good Progress"
        case .excellent: return "Highly Trained"
        }
    }
    
    private var learningQualityColor: Color {
        switch learningService.learningQuality {
        case .minimal: return .orange
        case .basic: return .yellow
        case .good: return .blue
        case .excellent: return .green
        }
    }
}

// Add button styles
struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.red.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}
```

### Task 4F.3.2: Redesign Settings View
```swift
// Update Views/Settings/SettingsView.swift
struct SettingsView: View {
    @AppStorage("playCompletionSound") private var playCompletionSound = true
    @AppStorage("showNotifications") private var showNotifications = true
    @State private var showingHistory = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Settings")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                // Account section
                SettingsCard(
                    title: "Account",
                    icon: "person.circle",
                    accentColor: .blue
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Sign in to sync your preferences")
                                .font(.system(size: 14))
                                .foregroundColor(.secondaryText)
                            
                            Spacer()
                            
                            Button("Sign In") {
                                // TODO: Implement in Phase 3
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(true)
                        }
                        
                        Text("Account features coming soon")
                            .font(.system(size: 12))
                            .foregroundColor(.tertiaryText)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                // Notifications section
                SettingsCard(
                    title: "Notifications",
                    icon: "bell",
                    accentColor: .green
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Play sound on completion", isOn: $playCompletionSound)
                            .toggleStyle(SwitchToggleStyle())
                        
                        Toggle("Show notifications", isOn: $showNotifications)
                            .toggleStyle(SwitchToggleStyle())
                    }
                }
                
                // History section
                SettingsCard(
                    title: "History",
                    icon: "clock.arrow.circlepath",
                    accentColor: .purple
                ) {
                    HStack {
                        Text("View transcription history")
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)
                        
                        Spacer()
                        
                        Button("View History") {
                            showingHistory = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // Keyboard shortcuts section
                SettingsCard(
                    title: "Keyboard Shortcuts",
                    icon: "keyboard",
                    accentColor: .orange
                ) {
                    VStack(spacing: 8) {
                        ShortcutRow(title: "Start/Stop Recording", shortcut: "⌘⇧V")
                        Divider().background(Color.white.opacity(0.1))
                        ShortcutRow(title: "Raw Transcription", shortcut: "⌘1")
                        ShortcutRow(title: "Clean-up Mode", shortcut: "⌘2")
                        ShortcutRow(title: "Email Mode", shortcut: "⌘3")
                        ShortcutRow(title: "Messaging Mode", shortcut: "⌘4")
                    }
                }
                
                // About section
                SettingsCard(
                    title: "About",
                    icon: "info.circle",
                    accentColor: .gray
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Transcriptly")
                                .font(.system(size: 16, weight: .medium))
                            
                            Spacer()
                            
                            Text("Version 1.0.0")
                                .font(.system(size: 14))
                                .foregroundColor(.secondaryText)
                        }
                        
                        HStack(spacing: 16) {
                            Link("Help", destination: URL(string: "https://transcriptly.app/help")!)
                                .foregroundColor(.accentColor)
                            
                            Link("Privacy Policy", destination: URL(string: "https://transcriptly.app/privacy")!)
                                .foregroundColor(.accentColor)
                        }
                        .font(.system(size: 14))
                    }
                }
            }
            .padding(20)
        }
        .background(Color.primaryBackground)
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
    }
}

// Reusable settings card component
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(accentColor)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryText)
            }
            
            content
        }
        .padding(20)
        .liquidGlassBackground(cornerRadius: 12)
    }
}

struct ShortcutRow: View {
    let title: String
    let shortcut: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.primaryText)
            
            Spacer()
            
            Text(shortcut)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.tertiaryBackground)
                .cornerRadius(4)
        }
    }
}
```

**Test Protocol 4F.3**:
1. Navigate to Learning view - verify new design
2. Toggle learning on/off - verify it works
3. Navigate to Settings view - verify new design  
4. Toggle notification settings - verify they persist
5. Verify all cards use consistent Liquid Glass styling

**Checkpoint 4F.3**:
- [ ] Learning view uses Liquid Glass design
- [ ] Settings view uses Liquid Glass design
- [ ] All interactive elements work
- [ ] Design consistency across all views
- [ ] Git commit: "Complete Liquid Glass rollout"

---

## Phase 4F.4: Fix Real Data Integration

### Task 4F.4.1: Create Real Data Models
```swift
// Create Models/TranscriptionRecord.swift
import Foundation

struct TranscriptionRecord: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let originalText: String
    let refinedText: String
    let mode: RefinementMode
    let wordCount: Int
    let duration: TimeInterval
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var title: String {
        // Create smart title from first few words
        let words = refinedText.components(separatedBy: .whitespaces)
        let firstWords = Array(words.prefix(6)).joined(separator: " ")
        return firstWords.count > 40 ? String(firstWords.prefix(40)) + "..." : firstWords
    }
}

// Add to MainViewModel.swift
extension MainViewModel {
    @Published var recentTranscriptions: [TranscriptionRecord] = []
    @Published var todayStats: DailyStats = DailyStats.empty
    @Published var weekStats: WeeklyStats = WeeklyStats.empty
    
    private func saveTranscription(_ original: String, refined: String, mode: RefinementMode, duration: TimeInterval) {
        let record = TranscriptionRecord(
            timestamp: Date(),
            originalText: original,
            refinedText: refined,
            mode: mode,
            wordCount: refined.components(separatedBy: .whitespaces).count,
            duration: duration
        )
        
        recentTranscriptions.insert(record, at: 0)
        // Keep only last 10
        if recentTranscriptions.count > 10 {
            recentTranscriptions = Array(recentTranscriptions.prefix(10))
        }
        
        // Update stats
        updateStats()
        
        // Persist to UserDefaults
        saveToUserDefaults()
    }
    
    private func updateStats() {
        let today = Calendar.current.startOfDay(for: Date())
        let todayRecords = recentTranscriptions.filter { 
            Calendar.current.isDate($0.timestamp, inSameDayAs: today)
        }
        
        todayStats = DailyStats(
            transcriptionCount: todayRecords.count,
            totalWords: todayRecords.reduce(0) { $0 + $1.wordCount },
            timeSaved: todayRecords.reduce(0) { $0 + ($1.duration * 3) } // Estimate 3x typing speed
        )
        
        // Calculate week stats similarly
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekRecords = recentTranscriptions.filter { $0.timestamp >= weekAgo }
        
        weekStats = WeeklyStats(
            transcriptionCount: weekRecords.count,
            totalWords: weekRecords.reduce(0) { $0 + $1.wordCount },
            timeSaved: weekRecords.reduce(0) { $0 + ($1.duration * 3) }
        )
    }
    
    private func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(recentTranscriptions) {
            UserDefaults.standard.set(data, forKey: "recentTranscriptions")
        }
    }
    
    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "recentTranscriptions"),
           let records = try? JSONDecoder().decode([TranscriptionRecord].self, from: data) {
            recentTranscriptions = records
            updateStats()
        }
    }
}

struct DailyStats {
    let transcriptionCount: Int
    let totalWords: Int
    let timeSaved: TimeInterval // in seconds
    
    static let empty = DailyStats(transcriptionCount: 0, totalWords: 0, timeSaved: 0)
    
    var timeSavedFormatted: String {
        let minutes = Int(timeSaved) / 60
        return "\(minutes) min"
    }
}

struct WeeklyStats {
    let transcriptionCount: Int
    let totalWords: Int
    let timeSaved: TimeInterval
    
    static let empty = WeeklyStats(transcriptionCount: 0, totalWords: 0, timeSaved: 0)
    
    var timeSavedFormatted: String {
        let minutes = Int(timeSaved) / 60
        return "\(minutes) min"
    }
}
```

### Task 4F.4.2: Update Home View with Real Data
```swift
// Update Views/Home/HomeView.swift
struct HomeView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Welcome header
                Text("Welcome back")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                // Stats cards with real data
                HStack(spacing: 16) {
                    StatCard(
                        icon: "chart.bar.fill",
                        title: "Today",
                        value: formatNumber(viewModel.todayStats.totalWords),
                        subtitle: "words",
                        secondaryValue: "\(viewModel.todayStats.transcriptionCount) sessions"
                    )
                    
                    StatCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "This Week",
                        value: formatNumber(viewModel.weekStats.totalWords),
                        subtitle: "words",
                        secondaryValue: viewModel.weekStats.timeSavedFormatted + " saved"
                    )
                    
                    StatCard(
                        icon: "target",
                        title: "Current Mode",
                        value: viewModel.currentMode.displayName,
                        subtitle: "active",
                        secondaryValue: "⌘\(viewModel.currentMode.shortcutNumber)"
                    )
                }
                
                // Recent transcriptions
                if !viewModel.recentTranscriptions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Transcriptions")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(viewModel.recentTranscriptions.prefix(5))) { transcription in
                                TranscriptionCard(transcription: transcription)
                            }
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Text("Recent Transcriptions")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "mic.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.tertiaryText)
                                .symbolRenderingMode(.hierarchical)
                            
                            Text("No transcriptions yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondaryText)
                            
                            Text("Press ⌘⇧V or click Record to get started")
                                .font(.system(size: 14))
                                .foregroundColor(.tertiaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .liquidGlassBackground(cornerRadius: 12)
                    }
                }
                
                // Quick actions
                HStack(spacing: 12) {
                    SecondaryButton(
                        title: "View All History",
                        icon: "clock.arrow.circlepath"
                    ) {
                        // TODO: Open history view
                    }
                    .disabled(viewModel.recentTranscriptions.isEmpty)
                    
                    SecondaryButton(
                        title: "Export Data",
                        icon: "square.and.arrow.up"
                    ) {
                        // TODO: Export functionality
                    }
                    .disabled(viewModel.recentTranscriptions.isEmpty)
                }
            }
            .padding(20)
        }
        .background(Color.primaryBackground)
        .onAppear {
            viewModel.loadFromUserDefaults()
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number == 0 { return "0" }
        if number < 1000 { return "\(number)" }
        return String(format: "%.1fK", Double(number) / 1000.0)
    }
}

// Update StatCard to handle string values
struct StatCard: View {
    let icon: String
    let title: String
    let value: String  // Changed from Int
    let subtitle: String
    let secondaryValue: String
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                
                Text(secondaryValue)
                    .font(.system(size: 12))
                    .foregroundColor(.tertiaryText)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassBackground(cornerRadius: 12)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
```

### Task 4F.4.3: Connect Transcription Pipeline to Data Storage
```swift
// Update the transcription completion method in MainViewModel
private func handleTranscriptionComplete(_ originalText: String, refinedText: String) {
    let duration = recordingDuration
    
    // Save the transcription record
    saveTranscription(originalText, refined: refinedText, mode: currentMode, duration: duration)
    
    // Continue with existing paste logic
    if shouldAutoPaste {
        pasteToActiveApplication(refinedText)
    }
    
    // Show completion notification
    showCompletionNotification()
}
```

**Test Protocol 4F.4**:
1. Perform several transcriptions
2. Verify they appear in Recent Transcriptions
3. Check that stats update correctly
4. Restart app and verify data persists
5. Test empty state when no transcriptions exist

**Checkpoint 4F.4**:
- [ ] Home screen shows real transcription data
- [ ] Stats calculate correctly from real data  
- [ ] Empty states shown when appropriate
- [ ] Data persists between app launches
- [ ] Git commit: "Replace mock data with real data"

---

## Final Testing and Polish

### Task 4F.5.1: Comprehensive Testing
1. **Layout Tests**: Verify sidebar has visual priority in all views
2. **Functionality Tests**: Test every button and interactive element
3. **Data Flow Tests**: Complete transcription flow with data storage
4. **Design Consistency**: All views use Liquid Glass design system
5. **Performance Tests**: Smooth animations at 60fps

### Task 4F.5.2: Bug Fixes and Polish
- Fix any discovered issues
- Ensure consistent spacing and typography
- Verify Dark Mode works throughout
- Add missing hover states or animations

**Phase 4F Final Checkpoint**:
- [ ] Sidebar-first layout implemented
- [ ] All buttons functional
- [ ] Complete design system rollout
- [ ] Real data integration complete
- [ ] No mock data in production UI
- [ ] All views use Liquid Glass consistently
- [ ] Git commit: "Complete Phase 4 fixes"
- [ ] Tag: v1.0.0-phase4-fixes-complete

## Success Metrics

1. **Visual Hierarchy**: Sidebar clearly primary, top bar subtle
2. **Functional Completeness**: Every interactive element works
3. **Design Consistency**: Liquid Glass system used throughout
4. **Data Accuracy**: Real user data displayed appropriately
5. **User Experience**: Smooth, predictable, delightful interactions

This comprehensive fix will address all the identified issues while maintaining the good work from Phase 4.