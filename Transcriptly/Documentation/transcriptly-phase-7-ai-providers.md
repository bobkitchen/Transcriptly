# Transcriptly Phase 7 - AI Providers Integration

## Project Overview

**Phase 7 Goal**: Implement a comprehensive AI provider system that gives users control over transcription, refinement, and TTS services while maintaining Apple frameworks as the primary option with cloud providers as alternatives and backups.

**Key Principle**: Apple-first with intelligent fallback hierarchy - maintain current reliability while adding choice and capability for older macOS versions.

## Core Architecture

### Provider Categories
1. **Transcription Providers**
   - Apple Speech Framework (primary)
   - OpenAI gpt-4o-transcribe/gpt-4o-mini-transcribe 
   - Parakeet-MLX (local, Apple Silicon optimized)
   - Custom Provider endpoints

2. **Refinement Providers**
   - Apple Foundation Models (primary)
   - OpenAI GPT models
   - OpenRouter free models (Mistral, Llama variants)
   - Custom Provider endpoints

3. **TTS Providers (Foundation)**
   - Apple AVSpeechSynthesizer (primary)
   - OpenAI gpt-4o-mini-tts
   - MLX-Audio (local TTS)
   - Custom Provider endpoints

### Per-Feature Provider Selection
Users can independently select providers for:
- **Transcription Service**: Speech-to-text conversion
- **Refinement Service**: AI text enhancement  
- **TTS Service**: Text-to-speech for future document reading

## Technical Specifications

### API Integration Requirements

#### OpenAI Integration
- **Transcription**: gpt-4o-transcribe, gpt-4o-mini-transcribe endpoints
- **Refinement**: GPT-4o, GPT-4o-mini for text refinement
- **TTS**: gpt-4o-mini-tts for speech generation
- **Authentication**: API key stored in macOS Keychain
- **Rate Limiting**: Built into OpenAI API (no client-side throttling)
- **Fallback**: Auto-fallback to Apple frameworks on failure

#### OpenRouter Integration  
- **Primary Use**: Free refinement models for cost-conscious users
- **Supported Models**: Curated list of fast, free models
  - Mistral Small 3.1 (24B parameters, multimodal)
  - Llama 4 Scout (17B active, 512K context)
  - Various other free options under 1000 req/day limit
- **Authentication**: OpenRouter API key in Keychain
- **Cost Control**: Only free models selectable by default
- **Custom Endpoints**: Allow users to add paid models if desired

#### Parakeet-MLX Integration
- **Local Processing**: No API key required
- **Requirements**: Apple Silicon Mac, MLX framework
- **Installation**: Automatic via pip during first use
- **Performance**: Fast local transcription (RTF 3380+)
- **Language Support**: English only (current limitation)
- **Fallback**: Apple Speech Framework if MLX unavailable

### Provider Configuration UI

#### AI Providers Section Layout
```
AI Providers

┌─────────────────────────────────────────────────────────────┐
│ 🎯 Provider Selection                                       │
│                                                             │
│ Transcription Provider:    [Apple Speech Framework ▼]      │
│ Refinement Provider:       [Apple Foundation Models ▼]     │
│ TTS Provider:              [Apple AVSpeechSynthesizer ▼]   │
│                                                             │
│ ✅ Use intelligent fallback hierarchy                      │
│ ✅ Prefer local processing when available                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 🔑 OpenAI Configuration                                     │
│                                                             │
│ API Key: [••••••••••••••••••••••••••••] [Test Connection] │
│                                                             │
│ Transcription Model: [gpt-4o-mini-transcribe ▼]           │
│ Refinement Model:    [gpt-4o-mini ▼]                      │
│ TTS Model:          [gpt-4o-mini-tts ▼]                   │
│                                                             │
│ Usage: 127 requests this month                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 🌐 OpenRouter Configuration                                 │
│                                                             │
│ API Key: [••••••••••••••••••••••••••••] [Test Connection] │
│                                                             │
│ Refinement Model: [mistral/mistral-small-latest ▼]        │
│                                                             │
│ Usage: 45/1000 free requests today                         │
│ [Browse Free Models] [Add Custom Model]                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 🖥️ Local AI Configuration                                   │
│                                                             │
│ Parakeet-MLX: [✅ Available] [⚙️ Configure]                │
│ MLX Audio:    [⚙️ Install] [Configure]                     │
│                                                             │
│ Status: Ready for local transcription                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 🔧 Custom Providers                                         │
│                                                             │
│ [+ Add Custom Transcription Provider]                       │
│ [+ Add Custom Refinement Provider]                         │
│ [+ Add Custom TTS Provider]                                │
└─────────────────────────────────────────────────────────────┘
```

### Fallback Hierarchy System

#### Intelligent Provider Selection
1. **Primary Provider**: User's selected provider
2. **Secondary Provider**: Best available alternative
3. **Tertiary Provider**: Apple framework (always available)
4. **Error Handling**: Clear user notification and graceful degradation

#### Example Fallback Flows
```
Transcription Flow:
User Selection: OpenAI gpt-4o-transcribe
    ↓ (API error/timeout)
Fallback 1: Apple Speech Framework
    ↓ (permission denied)
Error: "Transcription unavailable - check microphone permissions"

Refinement Flow:
User Selection: OpenRouter Mistral
    ↓ (rate limit exceeded)
Fallback 1: OpenAI gpt-4o-mini (if configured)
    ↓ (API key invalid)
Fallback 2: Apple Foundation Models
    ↓ (macOS 15.5, not available)
Result: Raw transcription with notification
```

### Provider Integration Architecture

#### Service Structure
```
Services/
├── AIProviders/
│   ├── AIProviderManager.swift
│   ├── ProviderTypes.swift
│   └── Providers/
│       ├── OpenAIProvider.swift
│       ├── OpenRouterProvider.swift
│       ├── ParakeetMLXProvider.swift
│       ├── AppleProvider.swift
│       └── CustomProvider.swift
├── Configuration/
│   ├── ProviderConfigManager.swift
│   ├── APIKeyManager.swift
│   └── ModelSelector.swift
└── Fallback/
    ├── FallbackManager.swift
    └── ProviderHealthChecker.swift
```

#### Provider Protocol
```swift
protocol AIProvider {
    var name: String { get }
    var supportedServices: [AIService] { get }
    var isAvailable: Bool { get }
    var requiresAPIKey: Bool { get }
    
    func testConnection() async -> Result<Bool, ProviderError>
    func transcribe(audio: Data) async -> Result<String, ProviderError>
    func refine(text: String, mode: RefinementMode) async -> Result<String, ProviderError>
    func synthesizeSpeech(text: String) async -> Result<Data, ProviderError>
}

enum AIService {
    case transcription
    case refinement
    case textToSpeech
}
```

## Detailed Implementation Tasks

### Phase 7.1: Provider Infrastructure
- Create provider protocol and base classes
- Implement API key management with Keychain
- Build provider health checking system
- Create fallback management logic

### Phase 7.2: OpenAI Integration
- Implement OpenAI provider with latest models
- Add transcription (gpt-4o-transcribe) support
- Add refinement (GPT-4o) support  
- Add TTS foundation (gpt-4o-mini-tts)
- Implement usage tracking

### Phase 7.3: OpenRouter Integration
- Implement OpenRouter provider
- Create free model catalog and selection
- Add custom model support
- Implement rate limit tracking

### Phase 7.4: Parakeet-MLX Integration
- Create MLX installation manager
- Implement Parakeet-MLX provider
- Add local transcription support
- Handle MLX framework dependencies

### Phase 7.5: UI Implementation
- Build AI Providers settings section
- Create provider configuration forms
- Implement model selection dropdowns
- Add connection testing UI

### Phase 7.6: TTS Foundation
- Create TTS provider interface
- Implement Apple AVSpeechSynthesizer integration
- Add OpenAI TTS support
- Build MLX-Audio foundation for future

### Phase 7.7: Integration and Testing
- Update transcription/refinement services
- Implement provider selection logic
- Add fallback testing
- Performance optimization

## Provider-Specific Details

### OpenAI Provider Configuration
```swift
struct OpenAIConfig {
    var apiKey: String
    var transcriptionModel: OpenAITranscriptionModel = .gpt4oMiniTranscribe
    var refinementModel: OpenAIRefinementModel = .gpt4oMini
    var ttsModel: OpenAITTSModel = .gpt4oMiniTTS
    var baseURL: String = "https://api.openai.com/v1"
    
    enum OpenAITranscriptionModel: String, CaseIterable {
        case gpt4oTranscribe = "gpt-4o-transcribe"
        case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"
        case whisper1 = "whisper-1"
    }
}
```

### OpenRouter Free Models
- **mistral/mistral-small-latest**: Fast, 24B parameters
- **meta-llama/llama-4-scout**: 17B active parameters, 512K context
- **meta-llama/llama-4-maverick**: 17B active, 256K context
- **openrouter/optimus-alpha**: General purpose assistant
- **Additional curated free models**: Based on performance/speed testing

### Parakeet-MLX Requirements
- **System Requirements**: Apple Silicon Mac, macOS 13+
- **Dependencies**: MLX framework, ffmpeg
- **Installation**: Automatic pip install: `pip install parakeet-mlx`
- **Model Download**: Automatic from HuggingFace: `mlx-community/parakeet-tdt-0.6b-v2`
- **Performance**: RTF 3380+ on Apple Silicon

## Success Metrics

### Functionality Requirements
- Provider switching works seamlessly
- Fallback hierarchy prevents failures
- API key management is secure
- Model selection persists correctly
- Usage tracking accurate

### Performance Requirements
- Provider switching adds <200ms delay
- Fallback triggers within 5 seconds
- Local providers faster than API providers
- Memory usage stable across providers

### User Experience Requirements
- Clear provider status indicators
- Helpful error messages for failures
- Easy API key configuration
- Obvious connection testing
- Transparent fallback notifications

## Security Considerations

### API Key Storage
- All API keys stored in macOS Keychain
- Keys encrypted at rest
- No keys in UserDefaults or plaintext
- Secure key retrieval for API calls

### Network Security
- HTTPS only for all API communications
- Certificate pinning for major providers
- Request/response validation
- Timeout handling for all network calls

## Backward Compatibility

### macOS 15.5 Support
- Apple Foundation Models unavailable
- OpenAI/OpenRouter as primary refinement
- Parakeet-MLX available for transcription
- Graceful degradation messaging

### Future Expansion
- Plugin architecture for new providers
- Custom provider templates
- Community provider sharing
- Advanced routing rules

## Development Guidelines

### Critical Constraints
- No real-time streaming (learned from previous failures)
- Service isolation maintained
- Apple frameworks remain primary choice
- Fallback must be bulletproof
- No performance degradation when using Apple providers

### Testing Requirements
- Test with/without API keys
- Test provider unavailability scenarios
- Test fallback hierarchy completely
- Test on macOS 15.5 and 26.0
- Test with slow network conditions

## Implementation Timeline

**Week 1**: Provider infrastructure and OpenAI integration
**Week 2**: OpenRouter and Parakeet-MLX integration  
**Week 3**: UI implementation and provider selection
**Week 4**: TTS foundation and testing
**Week 5**: Integration, fallback testing, and polish

## Ready for Implementation

This specification provides the foundation for building a robust, user-controlled AI provider system that enhances Transcriptly's capabilities while maintaining reliability and performance.
