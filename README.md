# Transcriptly - macOS Voice Transcription App

## Overview
Transcriptly is a native macOS 26 application that captures speech via keyboard shortcuts, transcribes using Apple's Speech framework, applies AI refinement with Foundation Models, and pastes results into any application. Built with service isolation and Liquid Glass design principles.

## Current Status: Phase 2 Complete ✅
- **Version**: v0.6.0-phase2-complete
- **Phase**: Phase 2 Complete - Ready for Phase 3
- **Last Updated**: 2025-06-26

## Architecture Highlights
- **Service Isolation**: Each service (audio, transcription, AI) operates independently
- **Liquid Glass UI**: Apple HIG compliant with translucent materials
- **Defensive Programming**: Extensive resource cleanup and error handling
- **Dock-First Design**: Full macOS app with secondary menu bar access

## Core Features 
### Phase 1 Complete ✅
- Global keyboard shortcuts (⌘⌥V - changed from ⌘⇧V to avoid conflicts)
- Post-recording transcription using Apple's Speech framework
- Auto-paste to active application
- Basic recording interface

### Phase 2 Complete ✅
- **AI Refinement System**: Four modes (Raw, Clean-up, Email, Messaging) with Apple Foundation Models
- **Sidebar Navigation**: Home, Transcription, AI Providers, Learning, Settings sections
- **Capsule Mode**: Floating minimal recording interface with bidirectional navigation
- **User-Editable Prompts**: Character-counted prompt editing with reset functionality
- **Enhanced Shortcuts**: ⌘⌥1-4 for mode switching (changed from ⌘⇧1-4), Escape for cancel
- **Menu Bar Enhancements**: Animated waveform during recording
- **Completion Notifications**: User-configurable notifications with sound
- **Settings Management**: Notification preferences, history view, shortcuts display

### Keyboard Shortcuts
- **⌘⌥V**: Start/Stop Recording (changed from ⌘⇧V to avoid conflicts with system shortcuts)
- **⌘⌥1**: Raw Transcription Mode
- **⌘⌥2**: Clean-up Mode
- **⌘⌥3**: Email Mode
- **⌘⌥4**: Messaging Mode
- **Escape**: Cancel Recording (while recording)

**Note**: If keyboard shortcuts fail to register, check System Settings → Keyboard → Keyboard Shortcuts for conflicts

## Technical Requirements
- **macOS**: 26.0+ only (no backward compatibility)
- **Xcode**: 26.0 beta
- **Hardware**: Apple Silicon Mac
- **Frameworks**: SwiftUI, Speech, Foundation Models

## Development Phases
1. **Phase 0**: Project setup and structure ✅
2. **Phase 1**: Basic dock app with Liquid Glass UI ✅
3. **Phase 2**: AI refinement and UI restructuring ✅
4. **Phase 3**: Learning features and advanced AI
5. **Phase 4**: Polish and production readiness

## Key Lessons from Previous Attempt
- Service isolation prevents cascading failures
- Simple audio management (no device switching)
- All controls visible in main window (no complex preferences)
- Test after every single feature addition

## Quick Commands
```bash
# Build and run
open Transcriptly.xcodeproj

# Test commands (to be determined)
# npm run test (equivalent to be found)
```

## Development Guidelines
- Follow task list exactly - designed to avoid previous pitfalls
- Complete each phase fully before moving to next
- Test after every task using Critical Testing Protocol
- Stop immediately if any "Red Flags" appear

---

**Warning**: This is a v3 rebuild after a previous cascading failure. Methodical, phase-by-phase approach is critical for success.