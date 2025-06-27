# Voice Transcription App - Task List v3

## Project Configuration
- **App Name**: Transcriptly
- **Bundle ID**: com.yourname.transcriptly
- **Target Platform**: macOS 26.0+ ONLY
- **Development Environment**: Xcode 26.0 beta
- **UI Framework**: SwiftUI with AppKit integration
- **Design System**: Liquid Glass (Apple HIG compliant)

## Pre-Development Setup

### Task 0.1: Project Creation and Configuration
```bash
# Create new macOS app project in Xcode
# Select: macOS > App
# Interface: SwiftUI
# Language: Swift
# Bundle ID: com.yourname.transcriptly
# Minimum Deployment: macOS 26.0
```

### Task 0.2: Initial Git Setup
```bash
git init
git add .
git commit -m "Initial project setup"
git tag v0.0.1-initial
```

### Task 0.3: Create Base Folder Structure
```
Transcriptly/
├── App/
│   ├── TranscriptlyApp.swift
│   └── Info.plist
├── Models/
├── Views/
│   ├── MainWindow/
│   └── MenuBar/
├── Services/
├── Utilities/
└── Resources/
    └── Entitlements.plist
```

**Checkpoint 0**: 
- [ ] Project builds and runs
- [ ] Empty window appears
- [ ] Git repository initialized
- [ ] Tag: v0.0.2-structure

---

## Phase 1: Basic Dock App with Liquid Glass UI (Week 1)

### Task 1.1: Main Window Implementation
Create the main application window with proper Liquid Glass design:

```swift
// Views/MainWindow/MainWindowView.swift
// - Implement unified toolbar
// - Add NSVisualEffectView background
// - Set up proper margins (20pt)
// - Configure window size (400x500)
```

**Success Criteria**:
- Window appears in dock
- Proper translucent background
- Correct window controls
- Respects Light/Dark mode

### Task 1.2: Basic UI Layout
Implement the main interface structure WITHOUT functionality:

```swift
// Views/MainWindow/RecordingView.swift
// - Large record button (SF Symbol: mic.circle.fill)
// - Keyboard shortcut label (SF Mono)
// - Proper spacing and alignment

// Views/MainWindow/RefinementModeView.swift
// - Section header "Refinement Mode"
// - Four radio buttons (non-functional)
// - Proper grouping and spacing

// Views/MainWindow/OptionsView.swift
// - Two checkboxes (non-functional)
// - "Customize Shortcuts" button (non-functional)

// Views/MainWindow/StatusView.swift
// - Status text at bottom
// - Divider line above
```

**Success Criteria**:
- All UI elements visible
- Proper Liquid Glass styling
- Correct spacing (8pt/16pt)
- Native controls only

### Task 1.3: Menu Bar Integration
Add minimal menu bar support:

```swift
// Views/MenuBar/MenuBarController.swift
// - Menu bar icon (mic symbol)
// - Menu with three items:
//   - "Show Transcriptly" (opens main window)
//   - Divider
//   - "Quit"
```

**Success Criteria**:
- Menu bar icon appears
- Can show/hide main window
- Can quit app

**Phase 1 Checkpoint**:
- [ ] Beautiful, empty UI shell
- [ ] Dock and menu bar presence
- [ ] All controls visible but non-functional
- [ ] No crashes or console errors
- [ ] Git tag: v0.1.0-ui-shell

---

## Phase 2: Core Recording Functionality (Week 1-2)

### Task 2.1: Audio Permissions
Implement microphone permission handling:

```swift
// Services/PermissionsService.swift
// - Request microphone permission
// - Handle denial gracefully
// - Update UI based on permission status
```

**Success Criteria**:
- Permission dialog appears once
- App handles denial without crashing
- Status shows "Microphone access required" if denied

### Task 2.2: Basic Audio Recording
Implement simple recording to memory:

```swift
// Services/AudioService.swift
// - Use AVAudioRecorder
// - Record to memory buffer
// - No device selection (use default)
// - Start/stop methods only
```

**Success Criteria**:
- Can start recording
- Can stop recording
- No console errors
- Memory usage stable

### Task 2.3: Recording UI Integration
Connect recording to UI:

```swift
// Update Views/MainWindow/RecordingView.swift
// - Button starts/stops recording
// - Button changes appearance when recording
// - Status shows "Recording..." when active
// - Disable refinement options while recording
```

**Success Criteria**:
- Visual feedback during recording
- Can record multiple times
- UI properly enables/disables

### Task 2.4: Keyboard Shortcut (Basic)
Implement global keyboard shortcut:

```swift
// Services/ShortcutService.swift
// - Register Cmd+Shift+V globally
// - Toggle recording on shortcut
// - Show shortcut in UI
```

**Success Criteria**:
- Shortcut works from any app
- Recording toggles properly
- No conflicts with system shortcuts

**Phase 2 Checkpoint**:
- [ ] Can record audio via button or shortcut
- [ ] Clean start/stop with visual feedback
- [ ] Permissions handled properly
- [ ] 10 recordings in a row without issues
- [ ] Git tag: v0.2.0-recording

---

## Phase 3: Transcription Integration (Week 2)

### Task 3.1: Speech Framework Setup
Configure Apple Speech framework:

```swift
// Services/TranscriptionService.swift
// - Import Speech framework
// - Set up SpeechAnalyzer
// - Configure SpeechTranscriber
// - Request speech recognition permission
```

**Success Criteria**:
- Framework imports successfully
- Permissions requested properly
- No initialization errors

### Task 3.2: Basic Transcription
Implement post-recording transcription:

```swift
// Update Services/TranscriptionService.swift
// - Transcribe audio buffer after recording stops
// - Return transcribed text
// - Handle errors gracefully
// - Show "Transcribing..." in status
```

**Success Criteria**:
- Transcription completes successfully
- Accurate text output
- Errors shown in status
- No memory leaks

### Task 3.3: Clipboard Integration
Add paste functionality:

```swift
// Services/PasteService.swift
// - Copy transcribed text to clipboard
// - Implement paste at cursor location
// - Handle secure input fields
```

**Success Criteria**:
- Text appears in clipboard
- Can paste into any app
- Secure fields handled gracefully

### Task 3.4: Complete Flow Integration
Connect full record → transcribe → paste flow:

```swift
// Update RecordingView to orchestrate:
// 1. Stop recording
// 2. Show "Transcribing..." status
// 3. Transcribe audio
// 4. Show "Complete" status
// 5. Auto-paste if enabled
```

**Success Criteria**:
- Full flow works end-to-end
- Status updates at each step
- Less than 2 seconds total
- Works repeatedly

**Phase 3 Checkpoint**:
- [ ] Complete transcription flow working
- [ ] Accurate transcription
- [ ] Auto-paste functioning
- [ ] 20 transcriptions without failure
- [ ] Memory usage stable
- [ ] Git tag: v0.3.0-transcription

---

## Phase 4: AI Refinement (Week 2-3)

### Task 4.1: Foundation Models Setup
Integrate Apple's Foundation Models:

```swift
// Services/RefinementService.swift
// - Import Foundation Models framework
// - Create refinement service
// - Set up error handling
// - Add timeout handling
```

**Success Criteria**:
- Framework loads properly
- Service initializes
- Graceful error handling

### Task 4.2: Refinement Modes Implementation
Implement all four refinement modes:

```swift
// Services/RefinementService.swift
// Add methods for each mode:
// - refineEmail(text: String) -> String
// - refineCleanup(text: String) -> String
// - refineProfessional(text: String) -> String
// - refineRaw(text: String) -> String (passthrough)

// Use the proven prompts from previous build
```

**Success Criteria**:
- Each mode produces different output
- Email mode formats properly
- Clean-up removes fillers
- Professional enhances tone
- Raw passes through unchanged

### Task 4.3: UI Mode Selection
Make refinement mode selection functional:

```swift
// Update RefinementModeView.swift
// - Radio buttons update app state
// - Selected mode persists
// - Connect to refinement service
```

**Success Criteria**:
- Can select different modes
- Selection persists between launches
- Selected mode is used for refinement

### Task 4.4: Complete AI Integration
Update full flow with refinement:

```swift
// Update flow to:
// 1. Record
// 2. Transcribe
// 3. Refine (based on selected mode)
// 4. Paste refined text
// Show status for each step
```

**Success Criteria**:
- Refinement adds <1 second
- Each mode works correctly
- Status shows refinement step
- No failures in 50 operations

**Phase 4 Checkpoint**:
- [ ] All refinement modes working
- [ ] Fast processing (<3 seconds total)
- [ ] Mode selection functional
- [ ] Stable through extended use
- [ ] Git tag: v0.4.0-ai-refinement

---

## Phase 5: Polish and Options (Week 3)

### Task 5.1: Options Implementation
Make options functional:

```swift
// Update OptionsView.swift
// - Auto-paste checkbox works
// - Preview window checkbox works
// - Settings persist between launches
```

### Task 5.2: Keyboard Shortcut Customization
Implement shortcut editor:

```swift
// Views/ShortcutCustomizationView.swift
// - Sheet for editing shortcuts
// - Detect conflicts
// - Save custom shortcuts
```

### Task 5.3: Preview Window
Add floating preview window:

```swift
// Views/PreviewWindow.swift
// - Translucent floating window
// - Shows final result (not real-time)
// - Can be toggled on/off
```

### Task 5.4: Polish and Error Handling
Final polish pass:
- Improve error messages
- Add sound effects for completion
- Smooth all animations
- Complete accessibility support

**Phase 5 Checkpoint**:
- [ ] All options functional
- [ ] Custom shortcuts working
- [ ] Preview window toggles properly
- [ ] Polished user experience
- [ ] Git tag: v0.5.0-mvp-complete

---

## Critical Testing Protocol

After EACH task:
1. **Clean build and run**
2. **Test all previous features still work**
3. **Check memory usage in Activity Monitor**
4. **Look for console errors/warnings**
5. **Quit and restart app 5 times**
6. **Commit and tag if successful**

## Architecture Safeguards

### Service Isolation Rules
- No service should import another service
- All communication through protocols
- Each service has init/deinit logging
- Services are stateless where possible

### Resource Management
- Every start() has a stop()
- Every allocation has a deallocation
- Log all resource lifecycle events
- Audio session reset before each recording

### State Management
- Single source of truth (MainViewModel)
- No hidden state in services
- All preferences in UserDefaults
- "Reset All Settings" always available

## Red Flags to Stop Development

If ANY of these occur, STOP and debug:
- A working feature breaks when adding new code
- Memory usage grows with each operation
- Console shows unexpected errors
- Audio recording fails intermittently
- Services retain references after use

## Success Metrics

- **Stability**: 100 operations without restart
- **Performance**: <2 seconds record to paste
- **Memory**: Flat memory usage over time
- **Reliability**: No cascading failures
- **Polish**: Feels like Apple built it