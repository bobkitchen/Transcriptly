# Transcriptly Capsule Interface Overhaul - Design Brief

## Vision Overview
Transform the capsule mode into a minimal, always-visible floating interface that expands on hover to reveal full functionality. This creates an unobtrusive but instantly accessible recording interface.

## Design Specifications

### Minimal State (Default)
- **Size**: 60px wide × 20px tall (measured to outer edge)
- **Position**: Horizontally centered, 20px below menu bar OR notch (whichever is lower)
- **Appearance**: Semi-translucent center with dark gray outline
- **Material**: `.ultraThinMaterial` with `Color.gray.opacity(0.8)` border
- **Behavior**: Always visible, floats above all windows, fixed screen position

### Expanded State (On Hover)
- **Size**: 150px wide × 40px tall
- **Trigger**: Immediate expansion on hover (no delay)
- **Animation**: Smooth 0.2-0.3 second spring animation
- **Persistence**: Stays expanded while hovered OR while recording
- **Auto-collapse**: Returns to minimal when cursor leaves (except during recording)

### Expanded Interface Layout
```
┌─────────────────────────────────────────────┐
│  ●    ||||||||||||||||||||||||||||||||   ⤢  │
│       current mode name                     │
└─────────────────────────────────────────────┘
```

**Components:**
- **Left**: Red circular record button (changes appearance when recording)
- **Center**: Animated waveform (20px tall, half of capsule height)
- **Center-Bottom**: Current refinement mode name (10-11pt font, aligned to waveform edges)
- **Right**: Circular expand button with `arrow.up.left.and.arrow.down.right` icon

### Interaction Behaviors

#### Recording States
- **Idle**: Static waveform, normal record button
- **Recording**: Animated waveform, recording-state record button, capsule stays expanded
- **Processing**: Could show processing indicator (future enhancement)

#### User Actions
- **Hover**: Expands capsule (immediate)
- **Click Record Button**: Starts/stops recording (only the button is clickable)
- **Click Expand Button**: Closes capsule mode, returns to main window
- **Cursor Leave**: Auto-collapses to minimal (unless recording)

### Technical Requirements

#### Positioning Logic
- Detect screen with menu bar focus
- Account for MacBook notches in positioning calculation
- Maintain position across screen changes and app switching
- Always appear above other windows but below system modals

#### Window Management
- Use `NSWindow` with appropriate style masks for floating behavior
- Implement proper window level hierarchy
- Handle multi-monitor scenarios gracefully
- Respect system UI elements (menu bar, dock, notch)

#### Animation System
- Smooth spring-based expand/collapse animations
- Responsive hover state changes
- Fluid recording state transitions
- Optimized performance for always-visible interface

## User Experience Goals

### Minimal Intrusion
- Nearly invisible when not needed
- Doesn't interfere with normal workflow
- Quick access when required

### Instant Accessibility
- No clicking to access - just hover
- Visual feedback confirms functionality
- Clear recording state indication

### Elegant Interaction
- Smooth, delightful animations
- Predictable behavior patterns
- Seamless integration with macOS

## Implementation Priorities

### Phase 1: Core Functionality
1. Minimal capsule with proper positioning
2. Hover expansion/collapse
3. Basic recording button integration

### Phase 2: Polish & Animation
1. Smooth spring animations
2. Waveform visualization
3. Recording state management

### Phase 3: System Integration
1. Notch detection and positioning
2. Multi-monitor support
3. Window level management

## Success Metrics

- **Discoverability**: Users can easily find and access recording
- **Unobtrusiveness**: Doesn't interfere with normal Mac usage
- **Responsiveness**: Immediate hover response, smooth animations
- **Reliability**: Consistent positioning across system changes
- **Polish**: Feels like built-in macOS functionality

This capsule interface will provide the ultimate balance between accessibility and minimal intrusion, creating a premium recording experience that feels native to macOS.