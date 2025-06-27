# Transcriptly Phase 3 - Learning System Project Brief

## Project Overview

**Phase 3 Goal**: Implement a text-based learning system that adapts to user preferences through post-transcription analysis, creating a personalized refinement experience that improves over time.

**Critical Constraint**: Learning operates ONLY on transcribed text, NEVER on audio recordings. This is a hard requirement based on previous failures.

## Core Learning Principle

The learning system analyzes the gap between:
1. **What the AI refined** (post-transcription)
2. **What the user actually wanted** (post-edit)

This happens through two mechanisms:
- **Edit Review**: Users refine AI output before pasting
- **A/B Testing**: Users choose between two AI refinements

## Key Features

### 1. Edit Review Window
- **Appears after transcription + AI refinement**
- **Shows refined text in editable form**
- **User edits represent learning data**
- **First 10 transcriptions**: Always appears
- **After that**: Random appearance (1 in 5)
- **Includes diff view** showing AI changes
- **2-minute auto-submit timer** (only during inaction)
- **Skip option** available

### 2. A/B Testing System
- **For short transcriptions only** (<20 words)
- **First 50 short messages**: A/B testing appears
- **Shows two AI-refined versions**
- **User selects preferred option**
- **No editing, just selection**
- **Helps learn style preferences**

### 3. Hybrid Learning Engine
- **Pattern Matching**: Tracks specific corrections (e.g., "gonna" → "going to")
- **AI Preferences**: Builds profile of style preferences
- **Confidence Threshold**: Patterns need 3+ occurrences
- **Recency Weighting**: Recent edits matter more
- **Global Application**: Learned preferences apply across all refinement modes

### 4. Supabase Integration
- **Cloud storage for learning data**
- **User authentication (optional)**
- **Multi-device sync**
- **Real-time or batch sync options**
- **Works offline with local storage**

### 5. User Control
- **View learned patterns**
- **Delete specific patterns**
- **Reset all learning**
- **Pause learning temporarily**
- **Export learned data**
- **"Don't learn from this" option**

## Technical Architecture

### Data Flow
```
1. User speaks → Audio recorded
2. Audio → Transcribed to text (NO LEARNING HERE)
3. Text → AI refinement
4. Refined text → Review window
5. User edits → Learning system
6. Approved text → Pasted + Stored in database
```

### Storage Structure
- **Local**: SQLite for offline capability
- **Cloud**: Supabase for sync and backup
- **Schema**: Supports user preferences, patterns, and analytics

### Learning Application
- **Immediate**: Learned patterns apply right away
- **Contextual**: Extra weight to patterns from same refinement mode
- **Transparent**: Optional indicators when learning is applied

## Success Metrics

- **Learning Accuracy**: Reduces user edits over time
- **Performance**: No impact on transcription speed
- **Reliability**: Never affects audio transcription
- **Privacy**: Optional cloud sync, local-first
- **User Control**: Full transparency and control

## Risk Mitigation

### Critical Safeguards
1. **Complete isolation from audio pipeline**
2. **Learning service cannot access AudioService**
3. **Text-only data structures**
4. **Fail-safe: Learning can be disabled without affecting core functionality**

### Lessons from Previous Failure
- **Previous issue**: Learning system interfaced with audio processing
- **Result**: Cascading failures in transcription
- **Solution**: Hard boundary between audio and learning
- **Validation**: No audio-related imports in learning modules

## Development Principles

1. **Text-Only Learning**: No audio analysis whatsoever
2. **Post-Transcription Only**: Learning happens after text exists
3. **User Control**: Every learning action is user-initiated
4. **Gradual Rollout**: Edit review first, A/B testing second
5. **Fail-Safe Design**: Core app works if learning fails

## Phase 3 Deliverables

### Core Features
- ✅ Edit review window with full functionality
- ✅ A/B testing for short messages
- ✅ Pattern matching engine
- ✅ AI preference profiling
- ✅ Supabase integration with sync
- ✅ Learning analytics dashboard

### User Experience
- ✅ Seamless integration with existing flow
- ✅ Optional at every step
- ✅ Clear value from first use
- ✅ Privacy-respecting design

### Technical
- ✅ Isolated learning service
- ✅ Comprehensive test suite
- ✅ Performance benchmarks
- ✅ Documentation

## Timeline Estimate

- **Week 1-2**: Core infrastructure + Edit review window
- **Week 3**: A/B testing + Pattern matching
- **Week 4**: Supabase integration + Sync
- **Week 5**: Polish + Testing + Analytics

## The Most Important Rule

**Learning analyzes text, not audio.** Every line of code in the learning system should be auditable to ensure it never touches audio processing. This is the key to avoiding the cascading failures from before.