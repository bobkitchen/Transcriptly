# Voice Transcription App - Product Development Brief v3

## Project Overview

**App Name**: Transcriptly

**Goal**: Build a native macOS 26 application that captures speech via customizable keyboard shortcuts, transcribes using Apple's SpeechAnalyzer and SpeechTranscriber, applies AI refinement with Apple Foundation Models, and pastes into the active window. Architecture designed for future iOS expansion.

**Target Audience**: General productivity users who need fast, accurate dictation for emails, documents, and other long-form content.

**Core Differentiator**: Leveraging macOS 26's cutting-edge Speech framework and on-device Foundation Models for superior transcription accuracy and AI-powered refinement, all while maintaining complete privacy.

## Lessons Learned from Previous Development

### What Went Wrong
1. **Cascading Failures**: Adding audio device switching and learning features corrupted previously working code
2. **Hidden Dependencies**: Features that seemed isolated affected the entire system
3. **Settings Window Complexity**: Too much functionality hidden in preferences
4. **Menu Bar Limitations**: Difficult to interact with app when only in menu bar
5. **Audio Device Management**: AirPods Max switching caused framework-level issues

### What Worked Well
1. **AI Refinement Models**: Email and clean-up modes with sophisticated prompts
2. **Sequential Feature Development**: Building features one at a time
3. **Foundation Models Integration**: Grammar and flow refinement was effective
4. **Core Transcription**: When working, the transcription was accurate and fast

## Development Environment

- **macOS Version**: 26.0 Developer Preview ONLY (no backwards compatibility)
- **Xcode Version**: 26.0 beta (17A5241e)
- **Hardware**: Apple Silicon Mac
- **Apple Developer Program**: Yes (required for entitlements)
- **Bundle ID**: com.yourname.transcriptly

## Architectural Principles (Based on Lessons Learned)

### 1. **Dock-First Design**
- Full macOS application with dock icon (primary interface)
- Menu bar icon for quick access only (secondary)
- All controls visible in main window
- No complex settings window

### 2. **Service Isolation**
- Each service (transcription, AI, audio) in completely separate classes
- No shared singletons between services
- Clear initialization/deinitialization paths
- Explicit resource cleanup after each operation

### 3. **Defensive Programming**
- Always reset audio session before recording
- Force cleanup after each recording
- No persistent audio configuration between sessions
- Extensive logging for debugging

### 4. **Feature Protection**
- Feature flags for major functionality
- Ability to disable features without removing code
- State reset capability ("Reset All" function)
- Clear separation between core and enhancement features

## MVP Requirements (Revised)

### Core Features - Phase 1

1. **Main Application Window**
   - Lives in dock like a standard Mac app
   - Always accessible, can minimize or close
   - Contains ALL app controls (no separate settings)
   - Clean, single-window interface

2. **Recording Interface**
   - Large, prominent record button
   - Recording status indicator
   - Keyboard shortcut display (Cmd+Shift+V default)
   - Visual feedback during recording
   - Post-recording transcription (no real-time display)

3. **AI Refinement Modes** (Proven from Previous Build)
   - **Email Mode**: Sophisticated email cleanup and formatting
   - **Clean-up Mode**: Grammar, filler word removal, formatting
   - **Professional Tone**: Business communication enhancement
   - **Raw**: No AI processing
   - Mode selection via radio buttons in main window

4. **Essential Options**
   - Customizable keyboard shortcuts
   - Auto-paste toggle
   - Preview window toggle
   - All visible in main window

5. **Menu Bar Integration**
   - Minimal menu bar icon
   - Quick start/stop recording
   - Show main window
   - Quit application

6. **System Integration**
   - Paste refined text at cursor location
   - Works across all macOS applications
   - Handles secure input fields appropriately

### Explicitly Excluded from MVP
- Real-time transcription display
- Audio device switching
- Learning/personalization system
- Backwards compatibility (macOS 26 only)
- Multiple windows or complex preferences
- OpenAI Whisper (Phase 2)

## Technical Architecture

### UI Structure
```
MainWindow (Dock App)
├── RecordingView
│   ├── Record Button
│   ├── Status Display
│   └── Shortcut Info
├── RefinementModeView
│   ├── Email Mode
│   ├── Clean-up Mode
│   ├── Professional Mode
│   └── Raw Mode
├── OptionsView
│   ├── Keyboard Shortcuts
│   ├── Auto-paste Toggle
│   └── Preview Toggle
└── StatusView
    ├── Processing Indicator
    └── Last Result Info

MenuBarController (Minimal)
├── Quick Record/Stop
├── Show Main Window
└── Quit
```

### Service Architecture
```
Services/
├── TranscriptionService (SpeechAnalyzer + SpeechTranscriber)
├── RefinementService (Foundation Models)
├── AudioService (Simple recording, no device switching)
├── PasteService (System integration)
└── ShortcutService (Keyboard management)
```

### Key Technical Decisions
- **No Real-time Display**: Simplifies implementation, barely affects UX
- **Single Audio Device**: Use system default only
- **Post-Recording Processing**: Optimize for fastest transcription after recording ends
- **Stateless Services**: Each recording is independent

## Development Phases

### Phase 1: Core Application (Weeks 1-3)
- Dock application with main window
- Basic recording with SpeechAnalyzer/SpeechTranscriber
- All four refinement modes (proven to work)
- Keyboard shortcuts
- Auto-paste functionality

### Phase 2: Enhancement (Week 4)
- Preview window (showing final result)
- Performance optimization
- Extended testing
- Polish and refinement

### Phase 3: Fallback System (Week 5)
- OpenAI Whisper integration
- User toggle in main window
- Only after Apple stack is proven stable

### Phase 4: Future Features (Post-MVP)
- Transcription history
- Export options
- iOS companion app
- Advanced features (only with strict isolation)

## Success Metrics

- **Stability**: Zero cascading failures between features
- **Performance**: <2 seconds from stop recording to paste
- **Reliability**: 99.9% successful recordings
- **Accuracy**: >97% using Apple SpeechTranscriber
- **AI Speed**: <1 second for refinement
- **Memory**: Stable for 30+ minute recordings

## Critical Development Guidelines

1. **Test After Every Feature**
   - All previous features must still work
   - Complete app restart testing
   - Memory leak detection
   - Resource cleanup verification

2. **Avoid These Patterns**
   - Complex audio device management
   - Hidden state in preferences
   - Persistent audio configurations
   - Features that modify global state

3. **Maintain These Practices**
   - Single window interface
   - Visible controls
   - Explicit resource management
   - Comprehensive logging

## Design Philosophy

- **Visible, Not Hidden**: All controls in main window
- **Stable, Not Clever**: Simple patterns over complex optimizations
- **Isolated, Not Integrated**: Services should not know about each other
- **Explicit, Not Implicit**: Clear resource management
- **Proven, Not Experimental**: Use what worked before
- **Liquid Glass First**: Adopt Apple's latest visual design language from the start

## UI/UX Requirements - Liquid Glass Design

### Visual Design Principles
Following Apple's Human Interface Guidelines and macOS 26 Liquid Glass design:

1. **Material Design**
   - Use NSVisualEffectView with .hudWindow material for floating elements
   - Implement proper vibrancy and translucency
   - Respect system appearance (Light/Dark/Auto)
   - Use system colors exclusively

2. **Window Design**
   - Unified toolbar with inline title
   - Proper content margins (20pt standard)
   - Rounded corners matching system radius
   - Seamless toolbar-to-content transition

3. **Typography**
   - SF Pro Display for UI elements
   - SF Mono for shortcuts and technical info
   - Dynamic Type support
   - Proper text hierarchy with system text styles

4. **Controls and Spacing**
   - Standard macOS control sizes
   - Consistent 20pt margins
   - 8pt spacing between related elements
   - 16pt spacing between sections
   - Native system controls only

5. **Animation and Feedback**
   - Smooth spring animations for state changes
   - Haptic feedback where appropriate
   - System-standard progress indicators
   - Subtle hover states

### Main Window Layout (HIG-Compliant)
```
┌─────────────────────────────────────────┐
│  Transcriptly                   [─][□][×]│  <- Unified toolbar
├─────────────────────────────────────────┤
│                                         │
│      [🎤 Start Recording]               │  <- Large, prominent call-to-action
│         Cmd+Shift+V                     │  <- SF Mono, secondary text
│                                         │
│  ─────────────────────────────────      │  <- Section divider
│                                         │
│  Refinement Mode                        │  <- Section header (SF Pro Display)
│  ○ Email Mode                           │  <- Radio button group
│  ○ Clean-up Mode                        │
│  ○ Professional                         │
│  ○ Raw Transcription                    │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Options                                │
│  ☑ Auto-paste after transcription       │  <- System checkboxes
│  ☑ Show preview window                  │
│                                         │
│  [Customize Shortcuts...]               │  <- Secondary button style
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Status: Ready                          │  <- Status bar area
└─────────────────────────────────────────┘
```

### Implementation Requirements
1. **Use SwiftUI with AppKit integration** where needed for system features
2. **Follow Apple's color system** - no custom colors
3. **Implement proper focus states** for keyboard navigation
4. **Support full accessibility** from day one
5. **Use system sound effects** for feedback

### Critical UI Guidelines
- **No custom UI components** - use system controls
- **Respect safe areas** and window margins
- **Support keyboard navigation** throughout
- **Implement proper resize behavior**
- **Follow platform conventions** strictly

This ensures the app feels native and premium from the first build, avoiding the need for UI overhauls later.

## The Most Important Lesson

The previous build proved that the core concept works. The transcription was accurate, the AI refinement was effective, and the user experience was good. The failure came from architectural issues, not from the fundamental approach. This rebuild focuses on a more robust architecture while preserving what worked well.

## Ready to Build

With these specifications and lessons learned, Claude Code can begin building a more stable, maintainable application that avoids the pitfalls of the previous attempt while preserving its successful features.