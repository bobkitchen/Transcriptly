# Transcriptly UI Overhaul - Complete Design Specification

## Overview

This document outlines a comprehensive UI overhaul for Transcriptly to achieve a premium, modern macOS application that fully embraces Liquid Glass design principles and Apple's Human Interface Guidelines.

## Design Principles

### Liquid Glass Requirements
1. **Translucent Materials**: Use NSVisualEffectView throughout
2. **Depth and Layering**: Subtle shadows and elevation changes
3. **Smooth Animations**: Spring dynamics for all transitions
4. **Vibrancy**: Proper use of vibrancy for text and UI elements
5. **Semantic Colors**: Use system colors that adapt to appearance

### Typography & Spacing
- **Font Scale**: Use SF Pro Display with proper weight hierarchy
- **Margins**: 20pt standard margins
- **Spacing**: 16pt between major sections, 8pt between related elements
- **Line Height**: 1.5x for body text, 1.2x for UI text

## Major Layout Changes

### 1. Persistent Top Bar

**Layout:**
```
┌─────────────────────────────────────────────────────────────────┐
│  Transcriptly              [◐] [Clean-up ▼] [🎙 Record]         │
└─────────────────────────────────────────────────────────────────┘
```

**Components:**
- **App Title**: SF Pro Display, 14pt, secondary color
- **Capsule Button [◐]**: 
  - Minimal icon with tooltip "Enter Capsule Mode"
  - Subtle hover state
  - Located left of mode dropdown
- **Mode Dropdown**:
  - Shows current refinement mode
  - Updates when mode selected in cards
  - Smooth menu animation
- **Record Button**:
  - Always visible in top-right
  - Three states: Default, Recording (with timer), Processing
  - Gradient background with subtle shadow
  - Pulse animation when recording

**Visual Specifications:**
- Height: 52pt
- Background: NSVisualEffectView with .headerView material
- Bottom border: 0.5pt translucent separator

### 2. Sidebar Redesign

**Visual Updates:**
- Material: NSVisualEffectView with .sidebar material
- Width: 200pt (collapsible to 68pt)
- Translucent background with backdrop blur

**Item Design:**
```
┌─────────────────────┐
│ 🏠 Home             │  <- Selected state
├─────────────────────┤
│ 📝 Transcription    │
├─────────────────────┤
│ 🤖 AI Providers     │  [Soon]
├─────────────────────┤
│ 🧠 Learning         │
├─────────────────────┤
│ ⚙️ Settings         │
└─────────────────────┘
```

**Selection State:**
- Subtle gradient background
- 6pt rounded corners
- Smooth spring animation
- Accent color tint

**"Soon" Badge:**
- Translucent background
- 10pt SF Pro, medium weight
- Vibrancy effect
- Fade in on hover

### 3. Home Screen Transformation

**New Dashboard Layout:**

```
Welcome back

┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  📊 Today       │ │  📈 This Week   │ │  🎯 Efficiency  │
│                 │ │                 │ │                 │
│  1,234 words    │ │  8,456 words    │ │  87% refined    │
│  12 sessions    │ │  45 min saved   │ │  23 patterns    │
└─────────────────┘ └─────────────────┘ └─────────────────┘

Recent Transcriptions
┌────────────────────────────────────────────────────────────┐
│ 10:32 AM - Email to Sarah (234 words)          [View]    │
│ 09:45 AM - Meeting notes (567 words)           [View]    │
│ Yesterday - Project update (1,023 words)       [View]    │
└────────────────────────────────────────────────────────────┘

Quick Actions
[Enter Capsule Mode]  [View All History]  [Export Today's Work]
```

**Card Specifications:**
- Background: NSVisualEffectView with .contentBackground material
- Shadow: 0 2pt 8pt rgba(0,0,0,0.1)
- Border radius: 10pt
- Hover: Lift with increased shadow
- Content padding: 16pt

**Number Animations:**
- Smooth counter animation when values update
- Spring dynamics for emphasis
- Fade transition for rapid updates

### 4. Transcription View - Unified Mode Cards

**Layout Structure:**
```
AI Refinement Modes

┌─────────────────────────────────────────────────────────────┐
│ ○  Raw Transcription                                        │
│    No AI processing - exactly what you said                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ ●  Clean-up Mode                                   [Edit]   │
│    Removes filler words and fixes grammar                   │
│    ┗━ Used 127 times • Last edited 2 days ago              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ ○  Email Mode                              [Edit] [Apps ▼]  │
│    Professional formatting with greetings and signatures     │
│    ┗━ Auto-assigned: Mail, Outlook                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ ○  Messaging Mode                          [Edit] [Apps ▼]  │
│    Concise and casual for quick messages                    │
│    ┗━ Auto-assigned: Messages, Slack, Discord              │
└─────────────────────────────────────────────────────────────┘
```

**Card Behavior:**
- **Click anywhere**: Selects the mode
- **Hover**: Shows Edit and Apps buttons, subtle lift
- **Selected**: Accent border, stronger shadow, filled radio button

**Visual Specifications:**
- Height: 88pt per card
- Spacing: 12pt between cards
- Border radius: 8pt
- Padding: 16pt horizontal, 12pt vertical
- Background: NSColor.controlBackgroundColor with 0.8 opacity

**Button Styles:**
- Secondary style buttons
- Fade in/out on hover (0.2s)
- Edit: Opens modal sheet
- Apps: Dropdown menu (Phase 5)

### 5. Component Refinements

**Buttons:**
- Primary: Gradient fill, 4pt shadow, hover lift
- Secondary: Translucent background, subtle border
- All buttons: Spring animation on press

**Text Fields:**
- Inset appearance
- Subtle border on focus
- Smooth focus ring animation
- Proper Dark Mode support

**Radio Buttons/Checkboxes:**
- Larger hit targets (44pt minimum)
- Smooth state transitions
- Accent color when selected

**Empty States:**
- Refined illustrations (not just icons)
- Subtle animations
- Clear call-to-action buttons

### 6. Animation Specifications

**Timing:**
- Default duration: 0.3s
- Spring animations: damping 0.8, response 0.4
- Fade transitions: 0.2s
- Hover states: 0.15s

**Key Animations:**
- Sidebar selection: Spring slide
- Card selection: Radio fill + border fade
- Button hover: Fade + slight scale
- Recording pulse: 2s cycle, ease-in-out

### 7. Color System

**Backgrounds:**
- Primary: NSColor.windowBackgroundColor
- Secondary: NSColor.controlBackgroundColor
- Tertiary: NSColor.textBackgroundColor

**Text:**
- Primary: NSColor.labelColor
- Secondary: NSColor.secondaryLabelColor
- Tertiary: NSColor.tertiaryLabelColor

**Accents:**
- Use system accent color
- Apply with vibrancy where appropriate
- Subtle tints for backgrounds

## Implementation Priorities

### Phase 1: Foundation
1. Implement NSVisualEffectView throughout
2. Update color system to semantic colors
3. Add basic spring animations

### Phase 2: Layout Changes
1. Create persistent top bar with record button
2. Move capsule button to top bar
3. Transform home screen to dashboard

### Phase 3: Transcription Redesign
1. Implement unified mode cards
2. Add hover states and animations
3. Create edit prompt modal

### Phase 4: Polish
1. Refine all animations
2. Add subtle details (shadows, gradients)
3. Ensure Dark Mode perfection
4. Performance optimization

## Technical Requirements

### SwiftUI Implementation
```swift
// Use these modifiers throughout:
.background(.ultraThinMaterial)
.shadow(color: .black.opacity(0.1), radius: 8, y: 2)
.animation(.spring(response: 0.4, dampingFraction: 0.8))
```

### Required Frameworks
- SwiftUI materials and effects
- Combine for reactive updates
- Core Animation for custom transitions

## Success Metrics

1. **Visual Consistency**: Every element follows Liquid Glass principles
2. **Animation Performance**: 60fps throughout
3. **Accessibility**: Full VoiceOver and keyboard support
4. **User Delight**: Subtle details that surprise and please

## Future Considerations

- Mode reordering via drag and drop
- Custom mode creation
- Expanded statistics visualization
- Widget support for key stats

This overhaul will transform Transcriptly from a functional tool into a premium macOS application that users will be proud to use and recommend.