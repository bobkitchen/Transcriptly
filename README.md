# Transcriptly - macOS Voice Transcription App

## Overview
Transcriptly is a native macOS 26 application that captures speech via keyboard shortcuts, transcribes using Apple's Speech framework, applies AI refinement with Foundation Models, and pastes results into any application. Built with service isolation and Liquid Glass design principles.

## Current Status: Pre-Development Setup
- **Version**: v0.0.1-initial
- **Phase**: Phase 0 - Project Setup
- **Last Updated**: 2025-06-25

## Architecture Highlights
- **Service Isolation**: Each service (audio, transcription, AI) operates independently
- **Liquid Glass UI**: Apple HIG compliant with translucent materials
- **Defensive Programming**: Extensive resource cleanup and error handling
- **Dock-First Design**: Full macOS app with secondary menu bar access

## Core Features (Planned)
- Global keyboard shortcuts (Cmd+Shift+V default)
- Post-recording transcription using Apple's Speech framework
- AI refinement modes: Email, Clean-up, Professional, Raw
- Auto-paste to active application
- Minimal menu bar integration

## Technical Requirements
- **macOS**: 26.0+ only (no backward compatibility)
- **Xcode**: 26.0 beta
- **Hardware**: Apple Silicon Mac
- **Frameworks**: SwiftUI, Speech, Foundation Models

## Development Phases
1. **Phase 0**: Project setup and structure *(Current)*
2. **Phase 1**: Basic dock app with Liquid Glass UI
3. **Phase 2**: Core recording functionality
4. **Phase 3**: Transcription integration
5. **Phase 4**: AI refinement
6. **Phase 5**: Polish and options

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