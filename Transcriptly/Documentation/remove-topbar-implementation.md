# Remove Top Bar - Implementation Plan

## Overview
Transform Transcriptly to match Apple's current design pattern by removing the separate top bar and integrating controls directly into content areas, exactly like the Tasks app.

## Current vs Target Architecture

### **Current (Non-Apple Pattern):**
```
┌─────────────────────────────────────────────┐
│ Transcriptly    [Mode] [Record] [Float]     │ ← Remove this entire bar
├─────────────────────────────────────────────┤
│ Sidebar │ Content Area                      │
└─────────────────────────────────────────────┘
```

### **Target (Apple Pattern):**
```
┌─────────────────────────────────────────────┐
│ [System Window Controls Only]               │
│ Sidebar │ Welcome back    [Mode] [Record]   │ ← Controls in content
│         │                        [Float]   │
│         │ [Content]                        │
└─────────────────────────────────────────────┘
```

---

## Step-by-Step Implementation

### Step 1: Remove Top Bar from MainWindowView

**File**: `MainWindowView.swift`

```swift
// BEFORE (Current):
struct MainWindowView: View {
    var body: some View {
        VStack(spacing: 0) {
            TopBar(...)              // ❌ Remove this
            
            ZStack(alignment: .topLeading) {
                FullWidthContentView(...)
                FloatingSidebar(...)
            }
        }
    }
}

// AFTER (Apple Pattern):
struct MainWindowView: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Full-height content (no top bar)
            FullWidthContentView(
                selectedSection: $selectedSection,
                viewModel: viewModel
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Floating sidebar
            FloatingSidebar(selectedSection: $selectedSection)
                .padding(.leading, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
        }
        .frame(minWidth: 920, minHeight: 640)
    }
}
```

### Step 2: Create Content Header Component

**Create File**: `Components/ContentHeader.swift`

```swift
import SwiftUI

struct ContentHeader: View {
    @ObservedObject var viewModel: MainViewModel
    let title: String
    let showModeControls: Bool
    let showFloatButton: Bool
    let onFloat: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Content title
            Text(title)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Spacer()
            
            // Control group
            HStack(spacing: 12) {
                if showModeControls {
                    // Mode selector (compact version)
                    ModeSelector(currentMode: $viewModel.currentMode)
                    
                    // Record button (prominent)
                    RecordButton(
                        isRecording: viewModel.isRecording,
                        recordingTime: viewModel.recordingTime,
                        action: viewModel.toggleRecording
                    )
                }
                
                if showFloatButton {
                    // Float button (subtle)
                    FloatButton(action: onFloat)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial.opacity(0.3)) // Very subtle background
    }
}

// Compact mode selector for content headers
struct ModeSelector: View {
    @Binding var currentMode: RefinementMode
    
    var body: some View {
        Menu {
            ForEach(RefinementMode.allCases, id: \.self) { mode in
                Button(action: { 
                    currentMode = mode
                    HapticFeedback.selection()
                }) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.displayName)
                                .font(.system(size: 14, weight: .medium))
                            Text(mode.description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: mode.icon)
                            .foregroundColor(mode.accentColor)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: currentMode.icon)
                    .font(.system(size: 13))
                    .foregroundColor(currentMode.accentColor)
                
                Text(currentMode.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.tertiaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
        .menuStyle(.borderlessButton)
        .help("Switch refinement mode")
    }
}

// Compact record button for content headers
struct RecordButton: View {
    let isRecording: Bool
    let recordingTime: TimeInterval
    let action: () -> Void
    
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 16))
                    .symbolRenderingMode(.hierarchical)
                
                if isRecording {
                    Text(timeString(from: recordingTime))
                        .font(.system(.caption, design: .monospaced))
                        .frame(width: 40)
                } else {
                    Text("Record")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: isRecording ? [.red, .red.opacity(0.8)] : [.accentColor, .accentColor.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(16)
            .shadow(
                color: isRecording ? .red.opacity(0.3) : .accentColor.opacity(0.3), 
                radius: 6, 
                y: 2
            )
            .scaleEffect(pulseAnimation && isRecording ? 1.05 : 1.0)
            .animation(
                isRecording ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : .default,
                value: pulseAnimation
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Subtle float button for content headers
struct FloatButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "pip.enter")
                    .font(.system(size: 11))
                Text("Float")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? Color.white.opacity(0.1) : Color.clear)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .help("Enter floating recording mode")
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
```

### Step 3: Update HomeView with Integrated Header

**File**: `Views/Home/HomeView.swift`

```swift
struct HomeView: View {
    @ObservedObject var viewModel: MainViewModel
    let onFloat: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Integrated header (replaces top bar)
            ContentHeader(
                viewModel: viewModel,
                title: "Welcome back",
                showModeControls: true,
                showFloatButton: true,
                onFloat: onFloat
            )
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Stats cards
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
                    
                    // Recent transcriptions section
                    if !viewModel.recentTranscriptions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Transcriptions")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                Button("View All") {
                                    // Action
                                }
                                .foregroundColor(.accentColor)
                                .font(.system(size: 14))
                            }
                            
                            VStack(spacing: 8) {
                                ForEach(Array(viewModel.recentTranscriptions.prefix(5))) { transcription in
                                    TranscriptionCard(transcription: transcription)
                                }
                            }
                        }
                    }
                    
                    // Quick actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        HStack(spacing: 12) {
                            QuickActionButton(
                                title: "View All History",
                                icon: "clock.arrow.circlepath",
                                action: { /* action */ }
                            )
                            .disabled(viewModel.recentTranscriptions.isEmpty)
                            
                            QuickActionButton(
                                title: "Export Data",
                                icon: "square.and.arrow.up",
                                action: { /* action */ }
                            )
                            .disabled(viewModel.recentTranscriptions.isEmpty)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .adjustForFloatingSidebar()
        .background(Color.primaryBackground)
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number == 0 { return "0" }
        if number < 1000 { return "\(number)" }
        return String(format: "%.1fK", Double(number) / 1000.0)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }
}
```

### Step 4: Update TranscriptionView with Integrated Header

**File**: `Views/Transcription/TranscriptionView.swift`

```swift
struct TranscriptionView: View {
    @ObservedObject var viewModel: MainViewModel
    let onFloat: () -> Void
    @State private var showEditPrompt = false
    @State private var editingMode: RefinementMode?
    
    var body: some View {
        VStack(spacing: 0) {
            // Integrated header
            ContentHeader(
                viewModel: viewModel,
                title: "AI Refinement Modes",
                showModeControls: true,
                showFloatButton: true,
                onFloat: onFloat
            )
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
                                    // Future: Show apps configuration
                                } : nil
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .adjustForFloatingSidebar()
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
}
```

### Step 5: Update Other Views with Simple Headers

**Files**: `LearningView.swift`, `SettingsView.swift`, `AIProvidersView.swift`

```swift
// For views that don't need recording controls
struct LearningView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Simple header (no controls)
            HStack {
                Text("Learning")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.regularMaterial.opacity(0.3))
            
            // Existing content
            ScrollView {
                // ... existing learning content
            }
        }
        .adjustForFloatingSidebar()
        .background(Color.primaryBackground)
    }
}

// Similar pattern for SettingsView and AIProvidersView
```

### Step 6: Update FullWidthContentView to Pass onFloat

**File**: `Views/Layout/FullWidthContentView.swift`

```swift
struct FullWidthContentView: View {
    @Binding var selectedSection: SidebarSection
    @ObservedObject var viewModel: MainViewModel
    let onFloat: () -> Void  // Add this parameter
    
    var body: some View {
        Group {
            switch selectedSection {
            case .home:
                HomeView(viewModel: viewModel, onFloat: onFloat)
            case .transcription:
                TranscriptionView(viewModel: viewModel, onFloat: onFloat)
            case .aiProviders:
                AIProvidersView()
            case .learning:
                LearningView()
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
    }
}
```

### Step 7: Update MainWindowView Integration

**File**: `MainWindowView.swift` (Complete)

```swift
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
        ZStack(alignment: .topLeading) {
            // Full-height content (no top bar)
            FullWidthContentView(
                selectedSection: $selectedSection,
                viewModel: viewModel,
                onFloat: capsuleManager.showCapsule
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Floating sidebar
            FloatingSidebar(selectedSection: $selectedSection)
                .padding(.leading, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
        }
        .frame(minWidth: 920, minHeight: 640)
    }
}
```

---

## Visual Result

### **Before (Current):**
```
┌─────────────────────────────────────────────┐
│ Transcriptly    [Mode] [Record] [Float]     │ ← Separate chrome
├─────────────────────────────────────────────┤
│ Sidebar │ Welcome back                      │
│         │ [Content]                         │
└─────────────────────────────────────────────┘
```

### **After (Apple Pattern):**
```
┌─────────────────────────────────────────────┐
│ Sidebar │ Welcome back    [Mode] [Record]   │ ← Integrated
│         │                        [Float]   │
│         │ [Content]                         │
│         │                                   │
└─────────────────────────────────────────────┘
```

## Benefits of This Approach

1. **True Apple Compliance** - Matches Tasks, Notes, and other native apps exactly
2. **More Content Space** - Eliminates redundant UI chrome
3. **Contextual Controls** - Recording controls appear where they're relevant
4. **Cleaner Interface** - Less visual noise, more focus on content
5. **Better Scalability** - Easy to customize controls per view

## Testing Protocol

1. **Visual Verification** - Compare side-by-side with Apple Tasks app
2. **Functional Testing** - All controls work in their new locations
3. **Navigation Testing** - Switching between views maintains consistency
4. **Responsive Testing** - Layout works on different screen sizes

This implementation will make Transcriptly feel **identical** to Apple's current design language!