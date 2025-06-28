# Claude Code Prompt - Transcriptly Phase 4 Fixes

## Context
You are working on Transcriptly, a macOS voice transcription app. Phase 4 (UI overhaul) has been completed but has several critical issues that need immediate fixes. The app currently works for basic transcription but has layout problems and non-functional UI elements.

## Current State Analysis
From the screenshots and documentation, these issues exist:

1. **Layout Hierarchy Problem**: Top bar competes with sidebar for visual priority, creating awkward top-left spacing
2. **Non-functional Buttons**: Capsule button in top bar doesn't work, Edit/Apps buttons in transcription view don't work  
3. **Incomplete Design System**: Learning and Settings views still use old design instead of Liquid Glass
4. **Mock Data Display**: Home screen shows fake transcription history instead of real user data

## Your Task
Implement Phase 4 Fixes following the detailed task list in `transcriptly-phase-4-fixes-tasks.md`. Focus on these priorities:

### P0 (Critical) - Fix Immediately:
1. **Redesign layout hierarchy** - Make sidebar visually primary, top bar subtle
2. **Wire capsule button** - Connect to actual capsule mode functionality  
3. **Implement edit prompt functionality** - Make Edit buttons open working prompt editor
4. **Connect Apps buttons** - Add placeholder functionality or disable with explanation

### P1 (High) - Complete Next:
5. **Apply Liquid Glass to Learning view** - Use same design system as other views
6. **Apply Liquid Glass to Settings view** - Consistent materials and spacing
7. **Create real data models** - Replace mock transcription data

### P2 (Medium) - Polish:
8. **Integrate real data flow** - Connect transcription pipeline to data storage
9. **Add proper empty states** - Show appropriate messages when no data exists
10. **Final testing and polish** - Ensure all interactions work smoothly

## Key Design Principles to Follow

### Sidebar-First Layout:
- Sidebar should have visual prominence with `.thickMaterial` background
- Top bar should be subtle header with `.regularMaterial` and smaller height
- Remove awkward spacing by giving sidebar proper priority
- Maintain essential controls (record button, mode indicator, capsule button) in top bar

### Functional Completeness:
- Every button that appears must work or be clearly disabled
- Edit buttons must open actual prompt editing sheets
- Capsule button must launch working capsule mode
- All hover states must lead to actual actions

### Design Consistency:
- Use the same `liquidGlassBackground()` modifier throughout
- Apply consistent spacing: 20pt margins, 16pt between sections, 8pt between related elements
- Use semantic colors: `.primaryText`, `.secondaryText`, `.tertiaryText`
- Maintain spring animations: `.spring(response: 0.4, dampingFraction: 0.8)`

## Critical Implementation Notes

### For Layout Fixes:
- Reduce top bar height and visual weight
- Increase sidebar width slightly (220pt) and use stronger material
- Ensure sidebar navigation feels like primary interface element
- Keep top bar functional but visually secondary

### For Button Functionality:
- Create `EditPromptSheet` component for prompt editing
- Wire capsule button to launch actual `CapsuleMode` view
- Add default prompts to `RefinementMode` enum
- Implement proper save/load for user prompts via UserDefaults

### For Data Integration:
- Create `TranscriptionRecord` model for real data
- Add `recentTranscriptions` array to `MainViewModel`
- Replace all hardcoded stats with calculated values from real data
- Implement proper empty states when no transcriptions exist

### For Design System Completion:
- Apply `SettingsCard` component pattern to Learning and Settings views
- Use consistent icon and color schemes
- Ensure all views use same background and spacing patterns
- Maintain accessibility with proper focus states

## Testing Requirements

After each major change:
1. **Build and run** - Verify no compilation errors
2. **Test basic flow** - Record → transcribe → paste still works
3. **Test new functionality** - Click every button to ensure it works
4. **Visual verification** - Check layout hierarchy looks correct
5. **Data persistence** - Restart app to verify settings/data persist

## Files to Focus On

### Primary Files to Modify:
- `Views/MainWindow/MainWindowView.swift` - Layout hierarchy fixes
- `Views/Sidebar/SidebarView.swift` - Enhanced visual prominence  
- `Components/TopBar.swift` - Redesign as subtle header
- `Views/Transcription/TranscriptionView.swift` - Wire edit buttons
- `Views/Learning/LearningView.swift` - Apply Liquid Glass design
- `Views/Settings/SettingsView.swift` - Apply Liquid Glass design
- `Views/Home/HomeView.swift` - Real data integration
- `Models/TranscriptionRecord.swift` - New data model (create)

### New Files to Create:
- `Views/Transcription/EditPromptSheet.swift` - Prompt editing interface
- `Views/Capsule/CapsuleMode.swift` - Working capsule mode
- `Models/TranscriptionRecord.swift` - Real data model

## Success Criteria

When complete, the app should have:
- ✅ Clear visual hierarchy with sidebar as primary navigation
- ✅ All interactive elements functional (no broken buttons)  
- ✅ Consistent Liquid Glass design across all views
- ✅ Real user data or appropriate empty states
- ✅ Smooth, predictable interactions throughout
- ✅ No awkward spacing or layout issues

## Important Reminders

- **Don't break existing functionality** - Core transcription must keep working
- **Test frequently** - Build and test after each major change
- **Follow the task list order** - P0 issues first, then P1, then P2
- **Maintain code quality** - Use proper SwiftUI patterns and clean architecture
- **Document any blockers** - If you can't implement something, explain why

The goal is to transform the current partially-working UI into a polished, fully-functional experience that feels like a professional macOS application.