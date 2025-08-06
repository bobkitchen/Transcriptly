# Sprint Brief: Home Page UI Redesign

## Overview
Fix the overlapping dropzone issue and redesign the home page with proper spacing, a single universal dropzone, and a record button, while maintaining Apple HIG and Liquid Glass compliance.

## Design Requirements
- One prominent record button for voice dictation
- One universal dropzone that accepts any file type
- Proper vertical spacing throughout (following Apple HIG guidelines)
- Keep welcome message and stats at top
- Keep productivity metrics at bottom
- Liquid Glass visual effects (blur, transparency, shadows)
- Smart file type detection with appropriate routing

## Task List

### Task 1: Remove Existing Dropzone Implementation
**Priority: High**
```
1.1 Remove all existing dropzone components from HomeView
1.2 Remove the overlapping universal dropzone that was added
1.3 Clean up any related state variables and handlers
1.4 Remove the three action cards (Record Dictation, Read Documents, Transcribe Media)
```

### Task 2: Design New Layout Structure
**Priority: High**
```
2.1 Create new layout with proper spacing:
    - Welcome section: 24pt padding top
    - Stats line: 12pt below welcome
    - Main action area: 48pt margin top
    - Productivity section: 48pt margin from main content
    - Bottom padding: 32pt

2.2 Define responsive constraints for different window sizes
2.3 Ensure minimum heights are respected
```

### Task 3: Implement Record Button
**Priority: High**
```
3.1 Create large, prominent record button (suggested: 80x80pt)
3.2 Apply Liquid Glass styling:
    - Semi-transparent background with blur
    - Subtle shadow (0 4px 12px rgba(0,0,0,0.1))
    - Hover state with scale animation
    - Active state with depth effect

3.3 Position centrally in the main action area
3.4 Add microphone icon with proper SF Symbol
3.5 Include "Start Recording" label below icon
3.6 Connect to existing recording functionality
```

### Task 4: Implement Universal Dropzone
**Priority: High**
```
4.1 Create dropzone component:
    - Dashed border (2pt, 8pt dash pattern)
    - Border color: secondary label color at 30% opacity
    - Background: ultra thin material
    - Corner radius: 16pt
    - Min height: 200pt
    - Padding: 32pt

4.2 Add dropzone content:
    - Download arrow icon (SF Symbol: arrow.down.circle)
    - Primary text: "Drop any file here"
    - Secondary text: "Documents, audio, and video files supported"
    - Text should use semantic colors

4.3 Implement drag states:
    - Hover: Border color brightens, slight scale (1.02)
    - Active drag: Background highlights, border pulses

4.4 Add file type detection:
    - Text files (.txt, .docx, .pdf, etc.) → Read Aloud
    - Audio files (.mp3, .wav, .m4a, etc.) → File Transcription
    - Video files (.mp4, .mov, .avi, etc.) → File Transcription
```

### Task 5: Implement File Processing Feedback
**Priority: Medium**
```
5.1 Create processing overlay:
    - Semi-transparent backdrop
    - Centered progress indicator
    - File type icon
    - "Processing [filename]..." text

5.2 Add transition animations:
    - Fade in overlay (0.2s)
    - Scale up file icon (spring animation)
    - Smooth redirect after processing

5.3 Error handling:
    - Unsupported file type alert
    - File too large warning
    - Network error messages
```

### Task 6: Polish Visual Design
**Priority: Medium**
```
6.1 Apply consistent Liquid Glass effects:
    - All interactive elements use .regularMaterial
    - Consistent shadow depths
    - Proper vibrancy for text on glass

6.2 Refine spacing:
    - Use spacing variables from design system
    - Ensure optical balance
    - Test with different content lengths

6.3 Add subtle animations:
    - Gentle float animation for dropzone
    - Micro-interactions on hover
    - Spring animations for state changes
```

### Task 7: Update Routing Logic
**Priority: High**
```
7.1 Consolidate file handling:
    - Single file processor function
    - Route based on file extension
    - Pass file data to appropriate view

7.2 Update navigation:
    - Programmatic navigation to Read Aloud
    - Programmatic navigation to File Transcription
    - Maintain navigation stack properly
```

### Task 8: Testing and Refinement
**Priority: Low**
```
8.1 Test file dropping:
    - Multiple file types
    - Invalid files
    - Large files
    - Multiple files at once

8.2 Visual testing:
    - Light and dark mode
    - Different window sizes
    - Reduced transparency mode
    - High contrast mode

8.3 Performance testing:
    - File processing speed
    - Animation smoothness
    - Memory usage with large files
```

## Implementation Notes

### Spacing Guidelines (Apple HIG)
- Compact spacing: 8pt
- Regular spacing: 16pt  
- Relaxed spacing: 24pt
- Generous spacing: 32-48pt

### Component Hierarchy
```
HomeView
├── Welcome Section
│   ├── Welcome text (28pt, semibold)
│   └── Stats line (15pt, secondary)
├── Main Action Area
│   ├── Record Button
│   └── Universal Dropzone
└── Productivity Section
    └── Metrics Grid
```

### File Type Mappings
```swift
let documentExtensions = ["txt", "rtf", "doc", "docx", "pdf", "md"]
let audioExtensions = ["mp3", "wav", "m4a", "aac", "flac", "ogg"]
let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm", "m4v"]
```

## Success Criteria
- [ ] No overlapping UI elements
- [ ] Proper spacing throughout (no squashed elements)
- [ ] Single, functional universal dropzone
- [ ] Prominent record button
- [ ] Smooth file type detection and routing
- [ ] Maintains Liquid Glass aesthetic
- [ ] Passes accessibility tests
- [ ] Works in both light and dark mode