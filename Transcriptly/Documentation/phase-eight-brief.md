# Transcriptly Phase Eight - Read Aloud Project Brief

## Project Overview

**Phase Eight Goal**: Transform Transcriptly into a comprehensive voice productivity suite by adding document reading capabilities alongside the existing voice transcription features. Implement AI-powered text-to-speech that can process and read PDFs, Word documents, and web content with intelligent highlighting and natural voice options.

## Core Feature: Read Aloud System

### Document Processing Capabilities
- **PDF Support**: Extract text content preserving readable structure
- **Microsoft Word (.docx)**: Parse document content and formatting
- **Web Content**: Extract main article content from URLs, filtering out navigation/ads
- **File Size Limit**: 50MB maximum per document
- **Processing**: Use Apple Foundation Models for text extraction and optimization

### Voice Technology Stack
- **Apple AVSpeechSynthesizer**: Built-in, free, local processing
- **Google Cloud TTS**: 1M chars/month free tier with WaveNet voices
- **ElevenLabs Integration**: Premium option for highest quality voices
- **Voice Selection**: Minimum 2 male and 2 female voice options per service
- **Speed Control**: 0.5x, 1x, 1.5x, 2x playback speeds

### Reading Experience
- **Separate Document Window**: Opens alongside main app for reading view
- **Sentence-Level Highlighting**: Visual indicator follows spoken content
- **Media Controls**: Play/pause, skip forward/back 15 seconds, speed adjustment
- **Position Memory**: Resume reading from last position
- **Click-to-Jump**: Click anywhere in document to start reading from that point
- **Mini Player**: Floating controls remain visible during reading

## UI/Navigation Changes

### Sidebar Restructure
1. **Home** (unchanged)
2. **Dictation** (renamed from "Transcription")
3. **Read Aloud** (new - primary focus of Phase Eight)
4. **AI Providers** (unchanged)
5. **Learning** (unchanged)
6. **Settings** (expanded with voice preferences)

### Read Aloud Tab Interface
- **Document Drop Zone**: Central area for dragging/dropping files
- **URL Input Field**: Separate input for web links
- **Document History**: List of previously processed documents
- **Voice Selection**: Dropdown with male/female voice options
- **Speed Control**: Visible speed adjustment slider
- **Processing Indicator**: Shows document parsing progress

## Technical Architecture

### Document Processing Pipeline
```
1. File Drop/URL Input → Document Parser
2. Content Extraction → Apple Foundation Models (text optimization)
3. Text Chunking → Sentence-level segmentation
4. Voice Generation → Selected TTS service
5. Playback Coordination → Highlighting sync
```

### New Services
- **DocumentProcessingService**: Handle PDF, DOCX, and web content extraction
- **ReadAloudService**: Coordinate TTS, playback, and highlighting
- **VoiceProviderService**: Abstract layer for different TTS services
- **DocumentHistoryService**: Track and manage processed documents

### Data Storage
- **Document History**: Local storage with Supabase sync for cross-device access
- **Reading Progress**: Position tracking per document
- **Voice Preferences**: User's preferred voice and speed settings
- **Processed Content**: Temporary local cache for performance

## User Experience Flow

### Primary Workflow
1. User opens "Read Aloud" tab
2. Drags PDF/DOCX file or pastes URL into drop zone
3. App processes document (shows progress indicator)
4. Document opens in separate window with processed text
5. User selects voice (male/female) and speed
6. Clicks play - audio begins with sentence highlighting
7. Mini player provides controls while user can work in other apps

### Advanced Features
- **Background Reading**: Continue reading while using other apps
- **Document Library**: Quick access to previously processed documents
- **Voice Switching**: Change voices mid-reading without losing position
- **Export Audio**: Option to save generated audio as MP3 (future phase)

## Integration with Existing Features

### Learning System Integration
- **Not Included**: Keep read-aloud separate from transcription learning
- **Future Consideration**: Voice preference learning in later phases

### App Detection Integration
- **Reading Context**: Track which app user switches to during reading
- **Pause Behavior**: Optionally pause reading when switching to work apps

## Implementation Priorities

### Phase 8.1: Core Infrastructure
- Document processing services (PDF, DOCX, web)
- Basic TTS integration with Apple voices
- Sidebar navigation updates
- Document drop zone UI

### Phase 8.2: Reading Experience
- Separate document window
- Sentence highlighting system
- Media controls and speed adjustment
- Position memory

### Phase 8.3: Voice Options
- Google Cloud TTS integration
- ElevenLabs premium integration
- Voice selection UI
- Settings preferences

### Phase 8.4: Polish & History
- Document history management
- Mini player controls
- Performance optimization
- Error handling

## Success Metrics

### Functionality
- Support for PDF, DOCX, and web content
- Accurate sentence-level highlighting synchronization
- Reliable voice playback with < 2 second start delay
- Position memory persists between app restarts

### User Experience
- Intuitive document drop workflow
- Responsive separate window reading experience
- Clear voice quality differences between free/premium options
- Seamless speed and voice switching

### Technical
- No performance impact on existing transcription features
- Stable memory usage during long document reading
- Proper cleanup when switching between documents
- Offline capability with Apple voices

## Future Phase Considerations

### Phase Nine Potential Features
- **Smart Content Filtering**: Skip footnotes, headers, page numbers
- **Multiple Voice Characters**: Different voices for different speakers in documents
- **Advanced Highlighting**: Word-level or paragraph-level options
- **Audio Export**: Save generated speech as audio files
- **EPUB Support**: Additional document format
- **Reading Analytics**: Track reading time, words per minute

## Risk Mitigation

### Service Isolation
- Read Aloud system completely independent from transcription pipeline
- No shared services that could affect existing functionality
- Separate error handling that won't crash main app

### Performance Safeguards
- Lazy loading of large documents
- Streaming TTS for long content
- Memory management for document caching
- Background processing with progress feedback

## Development Guidelines

1. **Maintain Service Isolation**: ReadAloudService must not import AudioService
2. **Test After Every Task**: Ensure existing features remain unaffected
3. **Progressive Enhancement**: Start with basic features, add polish iteratively
4. **User Choice**: Always provide free voice options alongside premium
5. **Accessibility**: Full VoiceOver support for reading controls

## The Key Innovation

Phase Eight transforms Transcriptly from a dictation tool into a comprehensive voice productivity suite. Users can now both **speak to create content** (dictation) and **listen to consume content** (read aloud), making it an essential tool for voice-first workflows and accessibility needs.