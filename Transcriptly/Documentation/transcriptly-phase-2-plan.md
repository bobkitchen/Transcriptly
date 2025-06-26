# Transcriptly Phase 2 - Feature Plan and Task List

## Overview
This document outlines the next phase of Transcriptly development, building upon the working MVP to add refinement models, UI restructuring, and foundation for future learning capabilities.

## Key Features to Implement

### 1. Refinement Models with Apple Foundation Models
- **Four modes**: Raw, Clean-up, Email, Messaging
- **User-editable prompts** for each mode (except Raw)
- **Default prompt templates** with reset capability
- **Clean-up Mode as default** on app launch
- **Visual processing indicator** during refinement

### 2. Keyboard Shortcuts
- **Fix current implementation** for Start/Stop (⌘⇧V)
- **Escape key** for cancel (fixed, not customizable)
- **Mode switching shortcuts**: ⌘1, ⌘2, ⌘3, ⌘4
- **Shortcut recorder** in Settings section
- **Conflict detection** with system shortcuts

### 3. UI Restructuring with Sidebar Navigation

#### Main Window Structure:
```
┌─────────────────────────────────────────────┐
│ ☰ │  Transcriptly                   [─][□][×]│
├───┼─────────────────────────────────────────┤
│ 🏠 │                                         │
│ 📝 │        Main Landing Area                │
│ 🤖 │                                         │
│ 🧠 │    [Record Button] → [Capsule Mode]    │
│ ⚙️ │                                         │
│   │         Usage Statistics                │
│   │                                         │
└───┴─────────────────────────────────────────┘
```

#### Sidebar Sections:
1. **Home** (🏠) - Landing page with record button and stats
2. **Transcription** (📝) - Refinement modes and prompts
3. **AI Providers** (🤖) - Local/Cloud API settings (grayed out for now)
4. **Learning** (🧠) - Future learning features (grayed out for now)
5. **Settings** (⚙️) - Account, History, About, Help

### 4. Capsule Mode UI
- **Activated via button** on landing page
- **Small, semi-transparent** window
- **Top-center default position** (draggable)
- **Shows**: Record button, waveform, elapsed time, current mode
- **Stays on top** of other windows
- **Expand button** to return to main window

### 5. Learning Infrastructure (UI Only)
- **Review Window** for post-refinement editing
- **A/B Testing Interface** for comparing refinements
- **Toggle in Learning section** (non-functional but visible)
- **Account system planning** in Settings

### 6. Additional Improvements
- **Menu bar waveform** animation during recording
- **Completion notification** with optional chime
- **Auto-update checking**
- **Status bar** at bottom of main window
- **Resizable main window**
- **Collapsible sidebar**

## Detailed Task List

### Phase 2.1: Refinement Models Implementation

#### Task 2.1.1: Foundation Models Integration
```swift
// Services/RefinementService.swift
// - Import Foundation Models framework
// - Create refinement service with error handling
// - Implement timeout handling (30 seconds max)
// - Add processing state management
```

#### Task 2.1.2: Refinement Mode Implementation
```swift
// Services/RefinementService.swift
// Implement four refinement methods:
// - refineCleanup(): Remove fillers, fix grammar
// - refineEmail(): Format for professional email
// - refineMessaging(): Make concise and casual
// - refineRaw(): Pass through unchanged

// Models/RefinementMode.swift
// - Enum with four modes
// - Default prompts for each mode
// - User prompt storage
```

#### Task 2.1.3: Prompt Management UI
```swift
// Views/Transcription/RefinementPromptsView.swift
// - Text editor for each mode's prompt
// - Character counter (e.g., "245/500")
// - "Reset to Default" button per prompt
// - Save prompts to UserDefaults
```

#### Task 2.1.4: Processing Feedback
```swift
// Update MainWindow to show:
// - "Refining..." status during processing
// - Mode indicator in status bar
// - Error messages if refinement fails
```

**Checkpoint 2.1**:
- [ ] All four modes produce different outputs
- [ ] Prompts are editable and persist
- [ ] Clean-up mode is default
- [ ] Processing completes in <2 seconds

### Phase 2.2: UI Restructuring

#### Task 2.2.1: Sidebar Navigation Implementation
```swift
// Views/Sidebar/SidebarView.swift
// - Create collapsible sidebar
// - Five sections with icons + labels
// - Highlight active section
// - Collapse to icons-only mode

// Views/MainContentView.swift
// - Switch content based on sidebar selection
// - Maintain state during section changes
```

#### Task 2.2.2: Home/Landing View
```swift
// Views/Home/HomeView.swift
// - Large record button (center)
// - "Enter Capsule Mode" button
// - Usage statistics display
// - Clean, minimal design
```

#### Task 2.2.3: Transcription Section
```swift
// Views/Transcription/TranscriptionView.swift
// - Move existing UI here
// - Add refinement mode selection
// - Add prompt editing interface
// - Keep recording controls
```

#### Task 2.2.4: Placeholder Sections
```swift
// Views/AIProviders/AIProvidersView.swift
// - "Coming Soon" interface
// - Grayed out options for future providers

// Views/Learning/LearningView.swift
// - Toggle switch (disabled)
// - Placeholder for future features
```

**Checkpoint 2.2**:
- [ ] Sidebar navigation works smoothly
- [ ] All sections load correctly
- [ ] UI maintains Liquid Glass design
- [ ] Sidebar collapses properly

### Phase 2.3: Capsule Mode

#### Task 2.3.1: Capsule Window Implementation
```swift
// Views/Capsule/CapsuleWindow.swift
// - Small, transparent window
// - Red record button
// - Animated waveform
// - Elapsed time display
// - Current mode indicator
```

#### Task 2.3.2: Capsule Behavior
```swift
// Controllers/CapsuleController.swift
// - Window stays on top
// - Draggable positioning
// - Return to top-center on reopen
// - Expand button functionality
```

#### Task 2.3.3: Mode Switching
```swift
// Implement keyboard shortcuts:
// - ⌘1: Raw mode
// - ⌘2: Clean-up mode
// - ⌘3: Email mode
// - ⌘4: Messaging mode
// Update capsule to show current mode
```

**Checkpoint 2.3**:
- [ ] Capsule mode activates/deactivates smoothly
- [ ] Recording works from capsule
- [ ] Mode switching updates display
- [ ] Window positioning works correctly

### Phase 2.4: Keyboard Shortcuts & Settings

#### Task 2.4.1: Fix Keyboard Shortcut Implementation
```swift
// Services/ShortcutService.swift
// - Fix current ⌘⇧V implementation
// - Add Escape for cancel
// - Implement mode switching shortcuts
// - Add conflict detection
```

#### Task 2.4.2: Settings Section
```swift
// Views/Settings/SettingsView.swift
// - Account/Login (placeholder)
// - Transcription History
// - Notification preferences (chime on/off)
// - Keyboard shortcuts customization
// - About/Help sections
```

#### Task 2.4.3: Menu Bar Improvements
```swift
// Update MenuBarController.swift
// - Animated waveform during recording
// - Visual feedback for active state
// - Smooth animations
```

**Checkpoint 2.4**:
- [ ] All shortcuts work reliably
- [ ] Settings save and persist
- [ ] Menu bar animates properly
- [ ] No shortcut conflicts

### Phase 2.5: Learning UI Foundation

#### Task 2.5.1: Review Window Interface
```swift
// Views/Learning/ReviewWindow.swift
// - Show original and refined text
// - Editable refined text field
// - "Submit" and "Skip" buttons
// - Clean, focused design
```

#### Task 2.5.2: A/B Testing Interface
```swift
// Views/Learning/ABTestingWindow.swift
// - Show two refinement options
// - Selection buttons
// - Skip option
// - Placeholder for future implementation
```

#### Task 2.5.3: Notifications
```swift
// Implement completion notifications:
// - System notification on completion
// - Optional chime sound
// - Preference to disable
```

**Checkpoint 2.5**:
- [ ] Review window displays correctly
- [ ] A/B interface is ready for future use
- [ ] Notifications work when app in background
- [ ] All UI elements follow Liquid Glass design

## Architecture Guidelines

### Service Isolation
- RefinementService independent of TranscriptionService
- No shared state between services
- Clear initialization/cleanup paths
- Comprehensive error handling

### State Management
- Single source of truth in ViewModels
- UserDefaults for all preferences
- No hidden state in services
- Clear data flow patterns

### Resource Management
- Explicit cleanup after each operation
- Memory monitoring during development
- Timeout handling for all async operations
- Proper error recovery

## Testing Requirements

After each task:
1. Test all previous features still work
2. Check memory usage remains flat
3. Verify no console errors
4. Test with 10+ consecutive operations
5. Ensure UI remains responsive

## Success Metrics

- Refinement adds <1 second to processing
- Mode switching is instant
- Capsule mode transitions smoothly
- All prompts save and restore correctly
- Learning UI ready for Phase 3 implementation
- Zero regressions from Phase 1

## Notes for Claude Code

1. **Prioritize stability** - Don't break existing functionality
2. **Test incrementally** - Verify each feature before moving on
3. **Log extensively** - Help diagnose any issues
4. **Follow Liquid Glass** - Maintain design consistency
5. **Update CLAUDE.md** - Document all decisions and changes

## Default Refinement Prompts

These will be provided separately before implementation of Task 2.1.2.