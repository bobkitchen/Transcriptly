//
//  ProviderModels.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 7: AI Providers Integration - Provider Models
//

import Foundation

struct ProviderPreferences: Codable {
    var transcriptionProvider: ProviderType = .apple
    var refinementProvider: ProviderType = .apple
    var textToSpeechProvider: ProviderType = .apple
    var useFallbackHierarchy: Bool = true
    
    // Model selections per provider
    var openaiTranscriptionModel: String = "gpt-4o-mini-transcribe"
    var openaiRefinementModel: String = "gpt-4o-mini"
    var openrouterRefinementModel: String = "mistralai/mistral-7b-instruct:free"
    
    // TTS voice selections per provider
    var googleCloudTTSVoice: String = "en-US-Wavenet-A"
    var elevenLabsTTSVoice: String = "rachel"
    var openaiTTSVoice: String? = "alloy"
    var elevenLabsTTSModel: String? = "eleven_multilingual_v2"
    var appleTTSVoice: String? = "com.apple.voice.compact.en-US.Samantha"
    
    static let `default` = ProviderPreferences()
}

// Available models for each provider
struct OpenAIModels {
    static let transcriptionModels = [
        "gpt-4o-mini-transcribe": "GPT-4o Mini Transcribe",
        "gpt-4o-transcribe": "GPT-4o Transcribe"
    ]
    
    static let refinementModels = [
        "gpt-4o-mini": "GPT-4o Mini",
        "gpt-4o": "GPT-4o",
        "gpt-3.5-turbo": "GPT-3.5 Turbo"
    ]
    
    static let ttsVoices = [
        "alloy": "Alloy (Neutral)",
        "echo": "Echo (Male)",
        "fable": "Fable (British Male)",
        "onyx": "Onyx (Male Deep)",
        "nova": "Nova (Female)",
        "shimmer": "Shimmer (Female)"
    ]
}

struct GoogleCloudModels {
    static let ttsVoices = [
        // US English Voices
        "en-US-Wavenet-A": "US - WaveNet A (Female)",
        "en-US-Wavenet-B": "US - WaveNet B (Male)", 
        "en-US-Wavenet-C": "US - WaveNet C (Female)",
        "en-US-Wavenet-D": "US - WaveNet D (Male)",
        "en-US-Wavenet-E": "US - WaveNet E (Female)",
        "en-US-Wavenet-F": "US - WaveNet F (Female)",
        "en-US-Wavenet-G": "US - WaveNet G (Female)",
        "en-US-Wavenet-H": "US - WaveNet H (Female)",
        "en-US-Wavenet-I": "US - WaveNet I (Male)",
        "en-US-Wavenet-J": "US - WaveNet J (Male)",
        
        // UK English Voices (Premium WaveNet)
        "en-GB-Wavenet-A": "UK - WaveNet A (Female)",
        "en-GB-Wavenet-B": "UK - WaveNet B (Male)",
        "en-GB-Wavenet-C": "UK - WaveNet C (Female)", 
        "en-GB-Wavenet-D": "UK - WaveNet D (Male)",
        "en-GB-Wavenet-F": "UK - WaveNet F (Female)",
        
        // UK English Voices (Neural2)
        "en-GB-Neural2-A": "UK - Neural2 A (Female)",
        "en-GB-Neural2-B": "UK - Neural2 B (Male)",
        "en-GB-Neural2-C": "UK - Neural2 C (Female)",
        "en-GB-Neural2-D": "UK - Neural2 D (Male)",
        "en-GB-Neural2-F": "UK - Neural2 F (Female)",
        
        // Australian English
        "en-AU-Wavenet-A": "AU - WaveNet A (Female)",
        "en-AU-Wavenet-B": "AU - WaveNet B (Male)",
        "en-AU-Wavenet-C": "AU - WaveNet C (Female)",
        "en-AU-Wavenet-D": "AU - WaveNet D (Male)",
        
        // Indian English
        "en-IN-Wavenet-A": "IN - WaveNet A (Female)",
        "en-IN-Wavenet-B": "IN - WaveNet B (Male)",
        "en-IN-Wavenet-C": "IN - WaveNet C (Male)",
        "en-IN-Wavenet-D": "IN - WaveNet D (Female)",
        
        // Standard voices (lower quality but cheaper)
        "en-US-Standard-A": "US - Standard A (Female)",
        "en-US-Standard-B": "US - Standard B (Male)",
        "en-GB-Standard-A": "UK - Standard A (Female)",
        "en-GB-Standard-B": "UK - Standard B (Male)",
        "en-GB-Standard-C": "UK - Standard C (Female)",
        "en-GB-Standard-D": "UK - Standard D (Male)",
        "en-GB-Standard-F": "UK - Standard F (Female)",
        "en-AU-Standard-A": "AU - Standard A (Female)",
        "en-AU-Standard-B": "AU - Standard B (Male)"
    ]
}

struct ElevenLabsModels {
    static let ttsVoices = [
        // American English
        "rachel": "Rachel (US Female)",
        "adam": "Adam (US Male)",
        "drew": "Drew (US Male - Young)",
        "clyde": "Clyde (US Male - Deep)",
        "paul": "Paul (US Male - News)",
        "domi": "Domi (US Female - Young)",
        "dave": "Dave (US Male - Conversational)",
        "fin": "Fin (US Male - Raspy)",
        "bella": "Bella (US Female - Soft)",
        "antoni": "Antoni (US Male - Narrative)",
        "elli": "Elli (US Female - Emotional)",
        "josh": "Josh (US Male - Deep)",
        "arnold": "Arnold (US Male - Crisp)",
        "sam": "Sam (US Male - Raspy)",
        
        // British English (RP - Received Pronunciation)
        "charlotte": "Charlotte (UK Female - RP)",
        "daniel": "Daniel (UK Male - RP)",
        "george": "George (UK Male - RP)",
        "freya": "Freya (UK Female - Young RP)",
        "lily": "Lily (UK Female - RP)",
        "harry": "Harry (UK Male - Mature RP)",
        "alice": "Alice (UK Female - Mature RP)",
        "charlie": "Charlie (UK Male - Young RP)",
        
        // British English (Regional)
        "jessica": "Jessica (UK Female - London)",
        "ryan": "Ryan (UK Male - Northern)",
        "olivia": "Olivia (UK Female - Midlands)",
        "thomas": "Thomas (UK Male - West Country)",
        
        // Australian English
        "matilda": "Matilda (AU Female)",
        "james": "James (AU Male)",
        
        // Irish English
        "patrick": "Patrick (Irish Male)",
        "aisling": "Aisling (Irish Female)",
        
        // Scottish English
        "callum": "Callum (Scottish Male)",
        "grace": "Grace (Scottish Female)",
        
        // New Zealand English
        "ethan": "Ethan (NZ Male)",
        
        // South African English
        "nicole": "Nicole (SA Female)",
        
        // Other accents available via voice cloning
        "giovanni": "Giovanni (English w/ Italian accent)",
        "glinda": "Glinda (English w/ subtle accent)"
    ]
}

struct AppleModels {
    static let ttsVoices = [
        // US English
        "com.apple.voice.compact.en-US.Samantha": "Samantha (US Female)",
        "com.apple.ttsbundle.siri_Nicky_en-US_compact": "Siri Nicky (US Female)",
        "com.apple.ttsbundle.siri_Aaron_en-US_compact": "Siri Aaron (US Male)",
        "com.apple.voice.enhanced.en-US.Ava": "Ava (US Female - Enhanced)",
        "com.apple.voice.premium.en-US.Zoe": "Zoe (US Female - Premium)",
        "com.apple.voice.premium.en-US.Allison": "Allison (US Female - Premium)",
        "com.apple.voice.premium.en-US.Susan": "Susan (US Female - Premium)",
        "com.apple.voice.premium.en-US.Tom": "Tom (US Male - Premium)",
        "com.apple.voice.enhanced.en-US.Nathan": "Nathan (US Male - Enhanced)",
        
        // UK English
        "com.apple.voice.compact.en-GB.Daniel": "Daniel (UK Male)",
        "com.apple.voice.compact.en-GB.Kate": "Kate (UK Female)",
        "com.apple.ttsbundle.siri_Martha_en-GB_compact": "Siri Martha (UK Female)",
        "com.apple.ttsbundle.siri_Arthur_en-GB_compact": "Siri Arthur (UK Male)",
        "com.apple.voice.enhanced.en-GB.Serena": "Serena (UK Female - Enhanced)",
        "com.apple.voice.premium.en-GB.Malcolm": "Malcolm (UK Male - Premium)",
        "com.apple.voice.premium.en-GB.Fiona": "Fiona (UK Female - Premium)",
        
        // Australian English  
        "com.apple.voice.compact.en-AU.Karen": "Karen (AU Female)",
        "com.apple.ttsbundle.siri_Catherine_en-AU_compact": "Siri Catherine (AU Female)",
        "com.apple.ttsbundle.siri_Gordon_en-AU_compact": "Siri Gordon (AU Male)",
        "com.apple.voice.enhanced.en-AU.Lee": "Lee (AU Male - Enhanced)",
        
        // Irish English
        "com.apple.voice.compact.en-IE.Moira": "Moira (Irish Female)",
        "com.apple.voice.enhanced.en-IE.Emily": "Emily (Irish Female - Enhanced)",
        
        // South African English
        "com.apple.voice.compact.en-ZA.Tessa": "Tessa (SA Female)",
        
        // Indian English
        "com.apple.voice.compact.en-IN.Rishi": "Rishi (Indian Male)",
        "com.apple.voice.enhanced.en-IN.Sangeeta": "Sangeeta (Indian Female - Enhanced)"
    ]
}

struct OpenRouterModels {
    static let freeRefinementModels = [
        "mistralai/mistral-7b-instruct:free": "Mistral 7B Instruct (Free)",
        "huggingfaceh4/zephyr-7b-beta:free": "Zephyr 7B Beta (Free)",
        "openchat/openchat-7b:free": "OpenChat 7B (Free)",
        "gryphe/mythomist-7b:free": "Mythomist 7B (Free)",
        "undi95/toppy-m-7b:free": "Toppy M 7B (Free)"
    ]
}