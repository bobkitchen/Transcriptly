# Transcriptly App Detection & Assignment System - Project Brief

## Overview

**Goal**: Implement automatic app detection with manual override capabilities to intelligently select refinement modes based on the active application, with full user control and learning integration.

**Key Principle**: Smart defaults with complete user control - the system should be helpful but never get in the way.

## Core Features

### 1. Automatic App Detection
- **Trigger**: Detects active app when recording begins (not when shortcut pressed)
- **Method**: Use NSWorkspace.shared.frontmostApplication with bundle identifier fallback
- **Built-in Defaults**: Ships with sensible app→mode mappings
- **Confidence System**: Only auto-switch when confidence threshold met (configurable)
- **Learning Integration**: Works with existing Phase 3 learning system

### 2. Manual App Assignment
- **UI Integration**: Uses existing "Apps ▼" button in mode cards
- **App Selection**: Opens native app picker (NSOpenPanel filtered for applications)
- **Multiple Assignment**: Users can assign multiple apps to same mode
- **Override System**: Manual assignments always take precedence over auto-detection
- **Global Disable**: Option to turn off auto-detection entirely

### 3. User Interface Enhancements
- **Top Bar Indicator**: Shows "AppName → Mode" when auto-detection occurs
- **Mode Confirmation**: Existing capsule and main window UI sufficient for feedback
- **Quick Override**: Existing mode dropdown overrides auto-selection for current session
- **Settings Integration**: Full app management in existing Transcription section

### 4. Learning System Integration
- **App-Specific Learning**: Patterns learned separately per app context
- **A/B Testing Context**: A/B tests consider app context for better refinements
- **Preference Learning**: System learns user preferences per app over time
- **Supabase Sync**: All app assignments sync across devices

## Technical Architecture

### Data Models
```swift
// New model for app assignments
struct AppAssignment: Codable {
    let appBundleId: String
    let appName: String
    let assignedMode: RefinementMode
    let isUserOverride: Bool // vs built-in default
    let createdAt: Date
}

// Enhanced user preference with app context
struct UserPreference: Codable {
    // ... existing fields
    let appContext: String? // Bundle ID for app-specific preferences
}

// Enhanced learned pattern with app context
struct LearnedPattern: Codable {
    // ... existing fields
    let appContext: String? // Bundle ID for app-specific patterns
}
```

### Service Architecture
```swift
// New service for app detection
AppDetectionService {
    - detectActiveApp() -> AppInfo?
    - getAssignedMode(for: AppInfo) -> RefinementMode?
    - hasUserOverride(for: AppInfo) -> Bool
    - getConfidence(for: AppInfo) -> Double
}

// Enhanced learning service
LearningService {
    - processWithAppContext(app: AppInfo, ...)
    - getAppSpecificPatterns(for: AppInfo) -> [LearnedPattern]
    - learnAppPreference(app: AppInfo, mode: RefinementMode)
}
```

### Built-in Defaults
```swift
// Ships with these default assignments
let defaultAppAssignments = [
    "com.apple.mail": .email,
    "com.microsoft.Outlook": .email,
    "com.apple.MobileSMS": .messaging,
    "com.tinyspeck.slackmacgap": .messaging,
    "com.hnc.Discord": .messaging,
    "com.apple.TextEdit": .cleanup,
    "com.microsoft.Word": .cleanup,
    "com.apple.Notes": .cleanup
    // ... more defaults
]
```

## User Experience Flow

### Recording Flow with Auto-Detection
1. User presses ⌘⇧V (or clicks record)
2. Recording begins → System detects active app
3. System checks for user assignment → Falls back to built-in → Falls back to current mode
4. Top bar shows "Mail.app → Email Mode" if auto-switched
5. User can still override via dropdown
6. Transcription proceeds with selected mode

### Manual Assignment Flow
1. User goes to Transcription section
2. Clicks "Apps ▼" button on desired mode card
3. App picker opens (filtered to .app bundles)
4. User selects app → Assignment saved
5. Assignment syncs to Supabase
6. Future recordings in that app auto-select the mode

### Override and Control Flow
1. Auto-detection can be disabled in Settings
2. Dropdown override works for current session only
3. Manual assignments are permanent until changed
4. Users can remove assignments (reverting to defaults)

## Implementation Phases

### Phase A: Core App Detection (Week 1)
- App detection service
- Basic auto-mode switching
- Top bar indicator
- Built-in defaults

### Phase B: Manual Assignment UI (Week 1-2)
- App picker integration
- Assignment management
- Supabase schema updates
- Settings toggle

### Phase C: Learning Integration (Week 2)
- App-specific pattern learning
- Enhanced A/B testing
- Preference profiling per app
- Data migration

### Phase D: Polish & Edge Cases (Week 2-3)
- Confidence tuning
- Error handling
- Performance optimization
- Comprehensive testing

## Success Metrics

### Functionality
- Auto-detection works reliably for common apps
- Manual assignments save and sync correctly
- Override system works seamlessly
- Learning improves with app context

### User Experience
- Clear feedback when auto-switching occurs
- Easy app assignment workflow
- No disruption to existing users
- Improved refinement accuracy over time

### Technical
- No performance impact on recording
- Reliable app detection (>95% accuracy)
- Proper error handling for edge cases
- Clean integration with existing architecture

## Edge Cases & Considerations

### Technical Edge Cases
- **App not found**: Graceful fallback to current mode
- **Multiple instances**: Handle apps with multiple windows
- **System apps**: Special handling for Finder, System Preferences, etc.
- **Terminal/IDEs**: May want cleanup mode for code
- **Browser tabs**: Cannot detect specific websites

### User Experience Edge Cases
- **First-time users**: Should see helpful defaults immediately
- **Power users**: Should be able to disable auto-detection
- **App updates**: Handle when app bundle IDs change
- **Cross-device**: Assignments should sync but not be disruptive

## Privacy & Performance

### Privacy Considerations
- Only detect app name and bundle ID (no content access)
- No screen recording or window content analysis
- User data synced securely through Supabase
- Clear user control over all data

### Performance Requirements
- App detection must not delay recording start
- Assignment lookup should be <50ms
- No impact on transcription performance
- Minimal memory footprint

## Integration Points

### Existing Systems
- **RefinementService**: Enhanced to consider app context
- **LearningService**: Extended for app-specific learning
- **Supabase**: New tables for app assignments
- **UI Components**: Mode cards get app picker integration

### Future Extensibility
- **Custom modes**: Framework supports user-created modes
- **App categories**: Could group similar apps
- **Time-based rules**: Could consider time of day
- **Workflow integration**: Could integrate with Shortcuts.app

## Risk Mitigation

### Technical Risks
- **App detection failure**: Always have fallback mode
- **Performance impact**: Async detection with caching
- **Privacy concerns**: Minimal data collection, clear user control

### User Experience Risks
- **Confusion**: Clear indicators and easy override
- **Over-automation**: Comprehensive disable options
- **Data loss**: Proper backup and sync validation

## Development Guidelines

### Architecture Principles
1. **Fail-safe design**: App detection failure never breaks recording
2. **User control**: Every automatic decision can be overridden
3. **Performance first**: Detection happens async, never blocks UI
4. **Privacy by design**: Minimal data collection, maximum user control

### Testing Requirements
1. **Cross-app testing**: Test with 20+ common macOS apps
2. **Edge case validation**: Test app switching during recording
3. **Performance benchmarking**: Ensure no recording delays
4. **User acceptance testing**: Validate workflow with real users

This system will make Transcriptly significantly more intelligent while maintaining the user control and reliability that are core to the app's design philosophy.