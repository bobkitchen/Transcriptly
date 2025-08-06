# Transcriptly Phase 2 - Detailed Task List

## Pre-Phase 2 Setup

### Task 2.0.1: Create Phase 2 Branch
```bash
git checkout -b phase-2-refinement-and-ui
git push -u origin phase-2-refinement-and-ui
```

### Task 2.0.2: Update Documentation
```markdown
# Update CLAUDE.md with:
- Phase 2 start date
- Current app state summary
- Known issues from Phase 1
- Phase 2 objectives

# Update README.md with:
- Phase 2 features being added
- Current version (0.6.0-dev)
```

### Task 2.0.3: Create New File Structure
```
Transcriptly/
├── Views/
│   ├── Sidebar/
│   │   └── SidebarView.swift
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Transcription/
│   │   ├── TranscriptionView.swift
│   │   └── RefinementPromptsView.swift
│   ├── AIProviders/
│   │   └── AIProvidersView.swift
│   ├── Learning/
│   │   ├── LearningView.swift
│   │   ├── ReviewWindow.swift
│   │   └── ABTestingWindow.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Capsule/
│       ├── CapsuleWindow.swift
│       └── CapsuleController.swift
├── Models/
│   ├── RefinementMode.swift
│   └── RefinementPrompt.swift
```

**Checkpoint 2.0**:
- [ ] Branch created and pushed
- [ ] Documentation updated
- [ ] File structure created
- [ ] Git commit: "Setup Phase 2 structure"

---

## Phase 2.1: Refinement Models with Foundation Models

### Task 2.1.1: Create Refinement Models and Prompts
```swift
// Models/RefinementMode.swift
enum RefinementMode: String, CaseIterable, Codable {
    case raw = "Raw Transcription"
    case cleanup = "Clean-up Mode"
    case email = "Email Mode"
    case messaging = "Messaging Mode"
    
    var icon: String {
        switch self {
        case .raw: return "doc.plaintext"
        case .cleanup: return "sparkles"
        case .email: return "envelope"
        case .messaging: return "message"
        }
    }
    
    var shortcutNumber: Int {
        switch self {
        case .raw: return 1
        case .cleanup: return 2
        case .email: return 3
        case .messaging: return 4
        }
    }
}

// Models/RefinementPrompt.swift
struct RefinementPrompt: Codable {
    let mode: RefinementMode
    var userPrompt: String
    let defaultPrompt: String
    let maxCharacters: Int = 500
    
    static func defaultPrompts() -> [RefinementMode: RefinementPrompt] {
        // Temporary prompts - will be replaced with user's prompts
        return [
            .cleanup: RefinementPrompt(
                mode: .cleanup,
                userPrompt: "Remove filler words like 'um', 'uh', 'you know'. Fix grammar and punctuation. Keep the original meaning and tone.",
                defaultPrompt: "Remove filler words like 'um', 'uh', 'you know'. Fix grammar and punctuation. Keep the original meaning and tone."
            ),
            .email: RefinementPrompt(
                mode: .email,
                userPrompt: "Format as a professional email. Add appropriate greeting and closing. Organize into clear paragraphs.",
                defaultPrompt: "Format as a professional email. Add appropriate greeting and closing. Organize into clear paragraphs."
            ),
            .messaging: RefinementPrompt(
                mode: .messaging,
                userPrompt: "Make the text concise and casual. Remove unnecessary words. Keep it friendly and conversational.",
                defaultPrompt: "Make the text concise and casual. Remove unnecessary words. Keep it friendly and conversational."
            )
        ]
    }
}
```

### Task 2.1.2: Create Refinement Service
```swift
// Services/RefinementService.swift
import Foundation
// Import FoundationModels when available

@MainActor
class RefinementService: ObservableObject {
    @Published var isProcessing = false
    @Published var currentMode: RefinementMode = .cleanup
    @Published var prompts: [RefinementMode: RefinementPrompt]
    
    init() {
        // Load saved prompts or use defaults
        if let savedPrompts = UserDefaults.standard.loadPrompts() {
            self.prompts = savedPrompts
        } else {
            self.prompts = RefinementPrompt.defaultPrompts()
        }
    }
    
    func refine(_ text: String) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        switch currentMode {
        case .raw:
            return text
        case .cleanup, .email, .messaging:
            // TODO: Implement Foundation Models call
            // For now, return with placeholder processing
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            return "Refined: \(text)" // Placeholder
        }
    }
    
    func updatePrompt(for mode: RefinementMode, prompt: String) {
        prompts[mode]?.userPrompt = prompt
        savePrompts()
    }
    
    func resetPrompt(for mode: RefinementMode) {
        prompts[mode]?.userPrompt = prompts[mode]?.defaultPrompt ?? ""
        savePrompts()
    }
    
    private func savePrompts() {
        UserDefaults.standard.savePrompts(prompts)
    }
}

// Add UserDefaults extension for prompt storage
extension UserDefaults {
    private let promptsKey = "refinementPrompts"
    
    func savePrompts(_ prompts: [RefinementMode: RefinementPrompt]) {
        if let encoded = try? JSONEncoder().encode(prompts) {
            set(encoded, forKey: promptsKey)
        }
    }
    
    func loadPrompts() -> [RefinementMode: RefinementPrompt]? {
        guard let data = data(forKey: promptsKey),
              let decoded = try? JSONDecoder().decode([RefinementMode: RefinementPrompt].self, from: data) else {
            return nil
        }
        return decoded
    }
}
```

### Task 2.1.3: Update Main ViewModel
```swift
// Update ViewModels/MainViewModel.swift
// Add:
@Published var refinementService = RefinementService()

// Update the transcription completion to include refinement:
private func processTranscription(_ text: String) async {
    do {
        let refinedText = try await refinementService.refine(text)
        // Continue with paste operation
    } catch {
        // Handle error
    }
}
```

### Task 2.1.4: Create Refinement UI in Current Window
```swift
// Temporarily add to existing MainWindowView.swift
// Add refinement mode selection that updates:
Picker("Refinement Mode", selection: $viewModel.refinementService.currentMode) {
    ForEach(RefinementMode.allCases, id: \.self) { mode in
        Label(mode.rawValue, systemImage: mode.icon)
            .tag(mode)
    }
}
.pickerStyle(RadioGroupPickerStyle())

// Add processing indicator:
if viewModel.refinementService.isProcessing {
    HStack {
        ProgressView()
            .scaleEffect(0.8)
        Text("Refining...")
            .font(.caption)
    }
}
```

**Test Protocol 2.1**:
1. Record and transcribe text
2. Verify refinement mode selection works
3. Check processing indicator appears
4. Confirm different modes selected
5. Test prompt persistence between launches

**Checkpoint 2.1**:
- [ ] Refinement models created
- [ ] Service processes text (placeholder)
- [ ] UI shows processing state
- [ ] Mode selection works
- [ ] Clean-up is default mode
- [ ] Git commit: "Add refinement models and service"

---

## Phase 2.2: Sidebar Navigation UI

### Task 2.2.1: Create Sidebar View
```swift
// Views/Sidebar/SidebarView.swift
import SwiftUI

struct SidebarView: View {
    @Binding var selectedSection: SidebarSection
    @State private var isCollapsed = false
    
    enum SidebarSection: String, CaseIterable {
        case home = "Home"
        case transcription = "Transcription"
        case aiProviders = "AI Providers"
        case learning = "Learning"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .transcription: return "text.quote"
            case .aiProviders: return "cpu"
            case .learning: return "brain"
            case .settings: return "gearshape.fill"
            }
        }
        
        var isEnabled: Bool {
            switch self {
            case .home, .transcription, .settings: return true
            case .aiProviders, .learning: return false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapse button
            HStack {
                Button(action: { isCollapsed.toggle() }) {
                    Image(systemName: "sidebar.left")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
                
                if !isCollapsed {
                    Spacer()
                }
            }
            
            Divider()
            
            // Sidebar items
            VStack(spacing: 4) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    SidebarItemView(
                        section: section,
                        isSelected: selectedSection == section,
                        isCollapsed: isCollapsed
                    )
                    .onTapGesture {
                        if section.isEnabled {
                            selectedSection = section
                        }
                    }
                }
            }
            .padding(8)
            
            Spacer()
        }
        .frame(width: isCollapsed ? 60 : 200)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct SidebarItemView: View {
    let section: SidebarView.SidebarSection
    let isSelected: Bool
    let isCollapsed: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.icon)
                .frame(width: 20)
                .foregroundColor(section.isEnabled ? 
                    (isSelected ? .accentColor : .primary) : .secondary)
            
            if !isCollapsed {
                Text(section.rawValue)
                    .foregroundColor(section.isEnabled ? .primary : .secondary)
                
                Spacer()
                
                if !section.isEnabled {
                    Text("Soon")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected && section.isEnabled ? 
                    Color.accentColor.opacity(0.15) : Color.clear)
        )
        .opacity(section.isEnabled ? 1.0 : 0.6)
    }
}
```

### Task 2.2.2: Create Main Content Router
```swift
// Views/MainContentView.swift
import SwiftUI

struct MainContentView: View {
    @Binding var selectedSection: SidebarView.SidebarSection
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        Group {
            switch selectedSection {
            case .home:
                HomeView(viewModel: viewModel)
            case .transcription:
                TranscriptionView(viewModel: viewModel)
            case .aiProviders:
                AIProvidersView()
            case .learning:
                LearningView()
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

### Task 2.2.3: Create Home View
```swift
// Views/Home/HomeView.swift
import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showCapsuleMode = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Title
            Text("Transcriptly")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            // Main Record Button
            Button(action: { viewModel.toggleRecording() }) {
                VStack(spacing: 16) {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(viewModel.isRecording ? .red : .accentColor)
                    
                    Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                        .font(.title2)
                    
                    Text("⌘⇧V")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Capsule Mode Button
            Button("Enter Capsule Mode") {
                showCapsuleMode = true
                // TODO: Implement capsule mode
            }
            .buttonStyle(.bordered)
            
            // Statistics
            VStack(spacing: 8) {
                HStack(spacing: 40) {
                    StatisticView(title: "Words Today", value: "1,234")
                    StatisticView(title: "Time Saved", value: "45 min")
                }
            }
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

### Task 2.2.4: Move Current UI to Transcription View
```swift
// Views/Transcription/TranscriptionView.swift
// Move existing recording UI here
// Add refinement mode selection
// Add prompt editing (initially hidden)
```

### Task 2.2.5: Create Placeholder Views
```swift
// Views/AIProviders/AIProvidersView.swift
struct AIProvidersView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cpu")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("AI Providers")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Cloud-based transcription and refinement options coming soon")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// Views/Learning/LearningView.swift
struct LearningView: View {
    @State private var isLearningEnabled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Learning")
                .font(.title)
                .fontWeight(.semibold)
            
            HStack {
                Toggle("Enable Learning", isOn: $isLearningEnabled)
                    .disabled(true)
                
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text("Learning features will help improve transcription accuracy based on your corrections and preferences.")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
```

### Task 2.2.6: Update Main Window
```swift
// Update MainWindowView.swift
struct MainWindowView: View {
    @StateObject var viewModel = MainViewModel()
    @State private var selectedSection: SidebarView.SidebarSection = .home
    
    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedSection: $selectedSection)
            
            Divider()
            
            MainContentView(
                selectedSection: $selectedSection,
                viewModel: viewModel
            )
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
```

**Test Protocol 2.2**:
1. Launch app and verify sidebar appears
2. Click each section and verify navigation
3. Test sidebar collapse/expand
4. Verify disabled sections show "Soon"
5. Check recording still works from Home

**Checkpoint 2.2**:
- [ ] Sidebar navigation functional
- [ ] All sections load correctly
- [ ] Recording works from new UI
- [ ] Disabled sections clearly marked
- [ ] Git commit: "Add sidebar navigation"

---

## Phase 2.3: Keyboard Shortcuts Fix

### Task 2.3.1: Fix Recording Shortcut
```swift
// Update Services/ShortcutService.swift
// Ensure ⌘⇧V works reliably from any app
// Add proper cleanup on app termination
```

### Task 2.3.2: Add Mode Switching Shortcuts
```swift
// Update ShortcutService.swift
private func registerModeShortcuts() {
    for mode in RefinementMode.allCases {
        registerShortcut(
            keyCode: kVK_ANSI_1 + mode.shortcutNumber - 1,
            modifiers: .command
        ) { [weak self] in
            self?.refinementService.currentMode = mode
        }
    }
}

// Add visual feedback when mode changes
private func showModeChangeNotification(_ mode: RefinementMode) {
    // Show brief overlay or update menu bar
}
```

### Task 2.3.3: Add Escape for Cancel
```swift
// Update recording logic to handle Escape
// Only active during recording
// Should discard current recording
```

**Test Protocol 2.3**:
1. Test ⌘⇧V from different apps
2. Test ⌘1-4 switches modes
3. Verify mode change feedback
4. Test Escape cancels recording
5. Verify no conflicts with system

**Checkpoint 2.3**:
- [ ] Recording shortcut works reliably
- [ ] Mode switching works (⌘1-4)
- [ ] Escape cancels recording
- [ ] Visual feedback for mode changes
- [ ] Git commit: "Fix keyboard shortcuts"

---

## Phase 2.4: Refinement Prompts UI

### Task 2.4.1: Create Prompt Editing View
```swift
// Views/Transcription/RefinementPromptsView.swift
struct RefinementPromptsView: View {
    @ObservedObject var refinementService: RefinementService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Refinement Prompts")
                .font(.headline)
            
            ForEach([RefinementMode.cleanup, .email, .messaging], id: \.self) { mode in
                PromptEditorView(
                    mode: mode,
                    prompt: Binding(
                        get: { refinementService.prompts[mode]?.userPrompt ?? "" },
                        set: { refinementService.updatePrompt(for: mode, prompt: $0) }
                    ),
                    onReset: {
                        refinementService.resetPrompt(for: mode)
                    }
                )
            }
        }
        .padding()
    }
}

struct PromptEditorView: View {
    let mode: RefinementMode
    @Binding var prompt: String
    let onReset: () -> Void
    @State private var characterCount: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(mode.rawValue, systemImage: mode.icon)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Reset to Default", action: onReset)
                    .buttonStyle(.plain)
                    .font(.caption)
            }
            
            TextEditor(text: $prompt)
                .font(.system(.body, design: .monospaced))
                .frame(height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: prompt) { newValue in
                    characterCount = newValue.count
                }
            
            Text("\(characterCount)/500")
                .font(.caption)
                .foregroundColor(characterCount > 500 ? .red : .secondary)
        }
    }
}
```

### Task 2.4.2: Integrate Prompts into Transcription View
```swift
// Update TranscriptionView to include:
// - Collapsible section for prompts
// - Only visible when non-raw mode selected
// - Smooth animation on expand/collapse
```

**Test Protocol 2.4**:
1. Edit each prompt and verify it saves
2. Test character counter
3. Reset prompts and verify defaults
4. Restart app and check persistence
5. Switch modes and verify correct prompts

**Checkpoint 2.4**:
- [ ] Prompt editing UI complete
- [ ] Character counting works
- [ ] Reset functionality works
- [ ] Prompts persist between launches
- [ ] Git commit: "Add refinement prompts UI"

---

## Phase 2.5: Settings Section

### Task 2.5.1: Create Settings View
```swift
// Views/Settings/SettingsView.swift
struct SettingsView: View {
    @AppStorage("playCompletionSound") private var playCompletionSound = true
    @AppStorage("showNotifications") private var showNotifications = true
    @State private var showingHistory = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Account Section (Placeholder)
            GroupBox("Account") {
                HStack {
                    Text("Sign in to sync your preferences")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Sign In") {
                        // TODO: Implement in Phase 3
                    }
                    .disabled(true)
                }
                .padding(.vertical, 4)
            }
            
            // Notifications
            GroupBox("Notifications") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Play sound on completion", isOn: $playCompletionSound)
                    Toggle("Show notifications", isOn: $showNotifications)
                }
                .padding(.vertical, 4)
            }
            
            // History
            GroupBox("History") {
                HStack {
                    Text("View transcription history")
                    Spacer()
                    Button("View History") {
                        showingHistory = true
                    }
                }
                .padding(.vertical, 4)
            }
            
            // About
            GroupBox("About") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcriptly")
                        .font(.headline)
                    Text("Version 0.6.0")
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Button("Help") {
                            NSWorkspace.shared.open(URL(string: "https://transcriptly.app/help")!)
                        }
                        .buttonStyle(.link)
                        
                        Button("Privacy Policy") {
                            NSWorkspace.shared.open(URL(string: "https://transcriptly.app/privacy")!)
                        }
                        .buttonStyle(.link)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
    }
}
```

### Task 2.5.2: Create History View
```swift
// Views/Settings/HistoryView.swift
struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    // TODO: Load actual history
    
    var body: some View {
        VStack {
            HStack {
                Text("Transcription History")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            // Placeholder for history list
            List {
                Text("History will appear here")
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 600, height: 400)
    }
}
```

### Task 2.5.3: Update Keyboard Shortcuts UI
```swift
// Add to SettingsView:
GroupBox("Keyboard Shortcuts") {
    VStack(alignment: .leading, spacing: 12) {
        ShortcutRow(
            title: "Start/Stop Recording",
            shortcut: "⌘⇧V",
            isEditable: false // Phase 3
        )
        
        ForEach(RefinementMode.allCases, id: \.self) { mode in
            ShortcutRow(
                title: mode.rawValue,
                shortcut: "⌘\(mode.shortcutNumber)",
                isEditable: false
            )
        }
    }
    .padding(.vertical, 4)
}

struct ShortcutRow: View {
    let title: String
    let shortcut: String
    let isEditable: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}
```

**Test Protocol 2.5**:
1. Toggle notification settings
2. Verify settings persist
3. Test history view opens
4. Check all links work
5. Verify shortcuts display

**Checkpoint 2.5**:
- [ ] Settings view complete
- [ ] Preferences save correctly
- [ ] History view opens
- [ ] All sections display properly
- [ ] Git commit: "Add settings section"

---

## Phase 2.6: Capsule Mode (Foundation)

### Task 2.6.1: Create Capsule Window
```swift
// Views/Capsule/CapsuleWindow.swift
import SwiftUI
import AppKit

class CapsuleWindowController: NSWindowController {
    convenience init() {
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
        
        let capsuleView = CapsuleView()
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
    @ObservedObject var viewModel = MainViewModel.shared // Make shared instance
    @State private var elapsedTime: TimeInterval = 0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 16) {
            // Record button
            Button(action: { viewModel.toggleRecording() }) {
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
                
                Text(viewModel.refinementService.currentMode.rawValue)
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
        // TODO: Show main window and close capsule
    }
}

// Placeholder waveform
struct WaveformView: View {
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<20) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 3, height: CGFloat.random(in: 10...30))
            }
        }
    }
}
```

### Task 2.6.2: Add Visual Effect View
```swift
// Views/Helpers/VisualEffectView.swift
import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
```

### Task 2.6.3: Wire Capsule Mode Toggle
```swift
// Update HomeView to show/hide capsule:
// - Create capsule window controller
// - Hide main window when entering capsule
// - Show main window when expanding
```

**Test Protocol 2.6**:
1. Enter capsule mode from home
2. Verify capsule appears at top center
3. Test recording from capsule
4. Verify time display updates
5. Test expand back to main window

**Checkpoint 2.6**:
- [ ] Capsule window appears correctly
- [ ] Recording works from capsule
- [ ] Time display updates
- [ ] Mode indicator shows
- [ ] Git commit: "Add capsule mode foundation"

---

## Phase 2.7: Menu Bar Improvements

### Task 2.7.1: Add Waveform Animation
```swift
// Update MenuBarController.swift
// Add animated waveform when recording
// Use simple bars that animate height
// Only visible during active recording
```

### Task 2.7.2: Add Completion Notification
```swift
// Add to transcription completion:
private func showCompletionNotification() {
    if UserDefaults.standard.bool(forKey: "showNotifications") {
        let notification = NSUserNotification()
        notification.title = "Transcription Complete"
        notification.informativeText = "Text has been pasted"
        notification.soundName = UserDefaults.standard.bool(forKey: "playCompletionSound") ? 
            NSUserNotificationDefaultSoundName : nil
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}
```

**Test Protocol 2.7**:
1. Start recording and check menu bar
2. Verify waveform animates
3. Complete transcription
4. Check notification appears
5. Test sound on/off setting

**Checkpoint 2.7**:
- [ ] Menu bar shows recording state
- [ ] Waveform animates properly
- [ ] Notifications work
- [ ] Sound preference respected
- [ ] Git commit: "Enhance menu bar feedback"

---

## Phase 2.8: Final Integration

### Task 2.8.1: Connect All Services
- Ensure RefinementService is properly integrated
- Verify all shortcuts work together
- Test complete flow with all features

### Task 2.8.2: Polish and Bug Fixes
- Fix any UI inconsistencies
- Ensure all animations are smooth
- Verify memory usage is stable
- Check for console warnings

### Task 2.8.3: Update Documentation
```markdown
# Update CLAUDE.md with:
- All Phase 2 features implemented
- Any issues encountered
- Performance observations
- Next phase recommendations

# Update README.md with:
- New features list
- Updated screenshots
- Version bump to 0.6.0
```

**Final Test Protocol**:
1. Complete 20 transcriptions with refinement
2. Test all refinement modes
3. Use all keyboard shortcuts
4. Enter/exit capsule mode 10 times
5. Verify settings all work
6. Check memory usage over time

**Phase 2 Final Checkpoint**:
- [ ] All features integrated
- [ ] No regressions from Phase 1
- [ ] Performance acceptable
- [ ] Documentation updated
- [ ] Git commit: "Complete Phase 2"
- [ ] Tag: v0.6.0-phase2-complete

---

## Critical Reminders

1. **Test after EVERY task** - Don't skip testing
2. **Commit working code frequently** - Small, focused commits
3. **Watch for memory leaks** - Monitor Activity Monitor
4. **Keep services isolated** - No service should import another
5. **Update CLAUDE.md** - Document all decisions and issues
6. **If something breaks** - Stop and debug before continuing

## Success Criteria

- Refinement works with all four modes
- UI feels native and polished
- Keyboard shortcuts are reliable
- Capsule mode is smooth
- No performance degradation
- Ready for Phase 3 (learning features)