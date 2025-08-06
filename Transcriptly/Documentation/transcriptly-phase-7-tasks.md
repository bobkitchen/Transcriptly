# Transcriptly Phase 7 - AI Providers Integration - Task List

## Phase 7.0: Setup and Architecture

### Task 7.0.1: Create Phase 7 Branch
```bash
git checkout main
git pull origin main
git checkout -b phase-7-ai-providers
git push -u origin phase-7-ai-providers
```

### Task 7.0.2: Create AI Providers File Structure
```
Transcriptly/
├── Services/
│   └── AIProviders/
│       ├── AIProviderManager.swift
│       ├── ProviderTypes.swift
│       └── Providers/
│           ├── AppleProvider.swift
│           ├── OpenAIProvider.swift
│           └── OpenRouterProvider.swift
├── Views/
│   └── AIProviders/
│       ├── AIProvidersView.swift
│       └── ProviderConfigCard.swift
└── Models/
    └── AIProviders/
        └── ProviderModels.swift
```

### Task 7.0.3: Update Supabase Schema
```sql
-- Add to Supabase SQL editor
CREATE TABLE provider_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    transcription_provider TEXT DEFAULT 'apple',
    refinement_provider TEXT DEFAULT 'apple',
    use_fallback_hierarchy BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE POLICY "Users can manage own provider preferences" ON provider_preferences
    FOR ALL USING (auth.uid() = user_id);
```

**Checkpoint 7.0**:
- [ ] Branch created and file structure ready
- [ ] Supabase schema updated successfully
- [ ] Git commit: "Setup AI providers architecture"

---

## Phase 7.1: Core Provider Infrastructure

### Task 7.1.1: Create Provider Types and Protocols
```swift
// Services/AIProviders/ProviderTypes.swift
enum ProviderType: String, CaseIterable, Codable {
    case apple, openai, openrouter
    
    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .openai: return "OpenAI" 
        case .openrouter: return "OpenRouter"
        }
    }
    
    var requiresAPIKey: Bool {
        switch self {
        case .apple: return false
        case .openai, .openrouter: return true
        }
    }
}

enum AIService: String, CaseIterable {
    case transcription, refinement
    
    var displayName: String {
        switch self {
        case .transcription: return "Transcription"
        case .refinement: return "Refinement"
        }
    }
}

protocol AIProvider {
    var type: ProviderType { get }
    var isAvailable: Bool { get }
    var isConfigured: Bool { get }
    
    func testConnection() async -> Result<Bool, Error>
    func configure(apiKey: String?) async throws
}

protocol TranscriptionProvider: AIProvider {
    func transcribe(audio: Data) async -> Result<String, Error>
}

protocol RefinementProvider: AIProvider {
    func refine(text: String, mode: RefinementMode) async -> Result<String, Error>
}
```

### Task 7.1.2: Create Provider Models
```swift
// Models/AIProviders/ProviderModels.swift
struct ProviderPreferences: Codable {
    var transcriptionProvider: ProviderType = .apple
    var refinementProvider: ProviderType = .apple
    var useFallbackHierarchy: Bool = true
    
    static let `default` = ProviderPreferences()
}

enum ProviderError: Error, LocalizedError {
    case apiKeyMissing
    case apiKeyInvalid
    case serviceUnavailable
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing: return "API key required"
        case .apiKeyInvalid: return "Invalid API key"
        case .serviceUnavailable: return "Service unavailable"
        case .rateLimitExceeded: return "Rate limit exceeded"
        }
    }
}
```

**Test Protocol 7.1**:
1. Verify all enums and protocols compile
2. Test provider type validations
3. Check error handling completeness

**Checkpoint 7.1**:
- [ ] Core types and protocols defined
- [ ] Models compile without errors
- [ ] Provider infrastructure ready
- [ ] Git commit: "Core provider infrastructure"

---

## Phase 7.2: Apple Provider Implementation

### Task 7.2.1: Create Apple Provider
```swift
// Services/AIProviders/Providers/AppleProvider.swift
import Speech
import Foundation

@MainActor
class AppleProvider: ObservableObject {
    static let shared = AppleProvider()
    
    @Published var isConfigured = true // Always configured
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    private init() {}
}

extension AppleProvider: AIProvider {
    var type: ProviderType { .apple }
    
    var isAvailable: Bool {
        speechRecognizer?.isAvailable == true
    }
    
    func testConnection() async -> Result<Bool, Error> {
        let status = SFSpeechRecognizer.authorizationStatus()
        return status == .authorized ? .success(true) : .failure(ProviderError.serviceUnavailable)
    }
    
    func configure(apiKey: String?) async throws {
        // Apple provider doesn't need configuration
    }
}

extension AppleProvider: TranscriptionProvider {
    func transcribe(audio: Data) async -> Result<String, Error> {
        // Implementation using existing Speech framework code
        // (Reuse from existing TranscriptionService)
        return .success("Placeholder transcription")
    }
}

extension AppleProvider: RefinementProvider {
    func refine(text: String, mode: RefinementMode) async -> Result<String, Error> {
        // Implementation using existing Foundation Models code  
        // (Reuse from existing RefinementService)
        return .success("Placeholder refinement")
    }
}
```

**Test Protocol 7.2**:
1. Test Apple provider initialization
2. Verify Speech Recognition availability check
3. Test placeholder transcription and refinement

**Checkpoint 7.2**:
- [ ] Apple provider implemented
- [ ] Conforms to all required protocols
- [ ] Integration points identified
- [ ] Git commit: "Apple provider implementation"

---

## Phase 7.3: OpenAI Provider Implementation

### Task 7.3.1: Create API Key Manager
```swift
// Services/AIProviders/APIKeyManager.swift
import Security

class APIKeyManager {
    static let shared = APIKeyManager()
    private let serviceName = "com.yourname.transcriptly"
    
    func storeAPIKey(_ key: String, for provider: ProviderType) throws {
        let account = "\(provider.rawValue)_api_key"
        let data = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw ProviderError.apiKeyInvalid
        }
    }
    
    func getAPIKey(for provider: ProviderType) throws -> String? {
        let account = "\(provider.rawValue)_api_key"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
}
```

### Task 7.3.2: Create OpenAI Provider
```swift
// Services/AIProviders/Providers/OpenAIProvider.swift
import Foundation

@MainActor
class OpenAIProvider: ObservableObject {
    static let shared = OpenAIProvider()
    
    @Published var isConfigured = false
    
    private var apiKey: String?
    private let baseURL = "https://api.openai.com/v1"
    
    init() {
        loadAPIKey()
    }
    
    private func loadAPIKey() {
        apiKey = try? APIKeyManager.shared.getAPIKey(for: .openai)
        isConfigured = apiKey != nil
    }
}

extension OpenAIProvider: AIProvider {
    var type: ProviderType { .openai }
    
    var isAvailable: Bool {
        isConfigured
    }
    
    func testConnection() async -> Result<Bool, Error> {
        guard let apiKey = apiKey else {
            return .failure(ProviderError.apiKeyMissing)
        }
        
        // Simple API test call
        var request = URLRequest(url: URL(string: "\(baseURL)/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            return httpResponse?.statusCode == 200 ? .success(true) : .failure(ProviderError.apiKeyInvalid)
        } catch {
            return .failure(error)
        }
    }
    
    func configure(apiKey: String?) async throws {
        guard let apiKey = apiKey else {
            throw ProviderError.apiKeyMissing
        }
        
        try APIKeyManager.shared.storeAPIKey(apiKey, for: .openai)
        self.apiKey = apiKey
        isConfigured = true
    }
}

extension OpenAIProvider: TranscriptionProvider {
    func transcribe(audio: Data) async -> Result<String, Error> {
        // Placeholder - implement OpenAI Whisper API call
        return .success("OpenAI transcription placeholder")
    }
}

extension OpenAIProvider: RefinementProvider {
    func refine(text: String, mode: RefinementMode) async -> Result<String, Error> {
        // Placeholder - implement OpenAI Chat API call
        return .success("OpenAI refinement: \(text)")
    }
}
```

**Test Protocol 7.3**:
1. Test API key storage/retrieval
2. Test OpenAI connection with valid/invalid keys
3. Verify placeholder implementations work

**Checkpoint 7.3**:
- [ ] API key management working
- [ ] OpenAI provider implemented
- [ ] Connection testing functional
- [ ] Git commit: "OpenAI provider implementation"

---

## Phase 7.4: Provider Manager and Integration

### Task 7.4.1: Create Provider Manager
```swift
// Services/AIProviders/AIProviderManager.swift
import Foundation

@MainActor
class AIProviderManager: ObservableObject {
    static let shared = AIProviderManager()
    
    @Published var preferences = ProviderPreferences.default
    
    private let providers: [ProviderType: any AIProvider] = [
        .apple: AppleProvider.shared,
        .openai: OpenAIProvider.shared,
        .openrouter: OpenRouterProvider.shared
    ]
    
    init() {
        loadPreferences()
    }
    
    func getProvider(for service: AIService) -> (any AIProvider)? {
        let preferredType: ProviderType
        
        switch service {
        case .transcription:
            preferredType = preferences.transcriptionProvider
        case .refinement:
            preferredType = preferences.refinementProvider
        }
        
        // Try preferred provider
        if let provider = providers[preferredType], provider.isAvailable {
            return provider
        }
        
        // Fallback to Apple if enabled
        if preferences.useFallbackHierarchy, let appleProvider = providers[.apple], appleProvider.isAvailable {
            return appleProvider
        }
        
        return nil
    }
    
    func transcribe(audio: Data) async -> Result<String, Error> {
        guard let provider = getProvider(for: .transcription) as? any TranscriptionProvider else {
            return .failure(ProviderError.serviceUnavailable)
        }
        
        return await provider.transcribe(audio: audio)
    }
    
    func refine(text: String, mode: RefinementMode) async -> Result<String, Error> {
        guard let provider = getProvider(for: .refinement) as? any RefinementProvider else {
            return .failure(ProviderError.serviceUnavailable)
        }
        
        return await provider.refine(text: text, mode: mode)
    }
    
    private func loadPreferences() {
        // Load from UserDefaults for now
        // TODO: Load from Supabase in future task
    }
    
    func updatePreferences(_ newPreferences: ProviderPreferences) {
        preferences = newPreferences
        // TODO: Save to Supabase in future task
    }
}
```

### Task 7.4.2: Update Main Services Integration
```swift
// Update TranscriptionService.swift to use provider manager
extension TranscriptionService {
    func transcribeWithProviders(audioData: Data) async -> Result<String, TranscriptionError> {
        let result = await AIProviderManager.shared.transcribe(audio: audioData)
        
        switch result {
        case .success(let text):
            return .success(text)
        case .failure(let error):
            return .failure(.transcriptionFailed(error.localizedDescription))
        }
    }
}

// Update RefinementService.swift to use provider manager  
extension RefinementService {
    func refineWithProviders(text: String, mode: RefinementMode) async -> Result<String, RefinementError> {
        let result = await AIProviderManager.shared.refine(text: text, mode: mode)
        
        switch result {
        case .success(let refinedText):
            return .success(refinedText)
        case .failure(let error):
            return .failure(.refinementFailed(error.localizedDescription))
        }
    }
}
```

**Test Protocol 7.4**:
1. Test provider selection logic
2. Test fallback to Apple provider
3. Test integration with existing services
4. Verify transcription/refinement flow works

**Checkpoint 7.4**:
- [ ] Provider manager implemented
- [ ] Fallback logic working
- [ ] Service integration complete
- [ ] Git commit: "Provider manager and integration"

---

## Phase 7.5: AI Providers UI

### Task 7.5.1: Update AI Providers View
```swift
// Views/AIProviders/AIProvidersView.swift
import SwiftUI

struct AIProvidersView: View {
    @ObservedObject private var providerManager = AIProviderManager.shared
    @State private var showingAPIKeySheet = false
    @State private var selectedProvider: ProviderType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AI Providers")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            // Provider Selection
            GroupBox("Provider Selection") {
                VStack(spacing: 12) {
                    ServiceProviderRow(
                        title: "Transcription",
                        selection: $providerManager.preferences.transcriptionProvider
                    )
                    
                    ServiceProviderRow(
                        title: "Refinement", 
                        selection: $providerManager.preferences.refinementProvider
                    )
                    
                    Toggle("Use fallback hierarchy", isOn: $providerManager.preferences.useFallbackHierarchy)
                }
            }
            
            // Provider Configurations
            ForEach(ProviderType.allCases, id: \.self) { providerType in
                ProviderConfigCard(
                    providerType: providerType,
                    onConfigureAPIKey: {
                        selectedProvider = providerType
                        showingAPIKeySheet = true
                    }
                )
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingAPIKeySheet) {
            if let provider = selectedProvider {
                APIKeyConfigView(providerType: provider)
            }
        }
    }
}

struct ServiceProviderRow: View {
    let title: String
    @Binding var selection: ProviderType
    
    var body: some View {
        HStack {
            Text(title)
                .frame(width: 100, alignment: .leading)
            
            Picker("Provider", selection: $selection) {
                ForEach(ProviderType.allCases, id: \.self) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .pickerStyle(.menu)
        }
    }
}
```

### Task 7.5.2: Create Provider Config Cards
```swift
// Views/AIProviders/ProviderConfigCard.swift
struct ProviderConfigCard: View {
    let providerType: ProviderType
    let onConfigureAPIKey: () -> Void
    
    @ObservedObject private var providerManager = AIProviderManager.shared
    @State private var connectionStatus: String = "Unknown"
    
    var body: some View {
        GroupBox(providerType.displayName) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status:")
                    Text(connectionStatus)
                        .foregroundColor(connectionStatus == "Connected" ? .green : .red)
                    
                    Spacer()
                    
                    if providerType.requiresAPIKey {
                        Button("Configure API Key") {
                            onConfigureAPIKey()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Button("Test Connection") {
                    testConnection()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private func testConnection() {
        guard let provider = providerManager.providers[providerType] else { return }
        
        Task {
            let result = await provider.testConnection()
            await MainActor.run {
                connectionStatus = result.isSuccess ? "Connected" : "Failed"
            }
        }
    }
}

struct APIKeyConfigView: View {
    let providerType: ProviderType
    @Environment(\.dismiss) var dismiss
    
    @State private var apiKey = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Configure \(providerType.displayName) API Key")
                .font(.headline)
            
            SecureField("API Key", text: $apiKey)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    saveAPIKey()
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty || isLoading)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
    
    private func saveAPIKey() {
        isLoading = true
        
        Task {
            do {
                let provider = AIProviderManager.shared.providers[providerType]
                try await provider?.configure(apiKey: apiKey)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                // Handle error
                print("Failed to configure API key: \(error)")
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
```

**Test Protocol 7.5**:
1. Test provider selection changes preferences
2. Test API key configuration flow
3. Test connection testing for each provider
4. Verify UI updates when provider status changes

**Checkpoint 7.5**:
- [ ] AI Providers view functional
- [ ] Provider selection working
- [ ] API key configuration working
- [ ] Connection testing working
- [ ] Git commit: "AI providers UI implementation"

---

## Phase 7.6: Final Integration and OpenRouter

### Task 7.6.1: Add OpenRouter Provider (Simplified)
```swift
// Services/AIProviders/Providers/OpenRouterProvider.swift
// Simple implementation focusing on free models only
@MainActor  
class OpenRouterProvider: ObservableObject {
    static let shared = OpenRouterProvider()
    @Published var isConfigured = false
    
    // Implementation similar to OpenAI but for OpenRouter free models
    // Focus on mistral/mistral-small-latest for refinement only
}
```

### Task 7.6.2: Update Main Transcription Flow
```swift
// Update MainViewModel to use provider system
func processTranscription() async {
    // Replace existing transcription/refinement with provider calls
    let transcriptionResult = await AIProviderManager.shared.transcribe(audio: audioData)
    // Handle result and continue with existing flow
}
```

### Task 7.6.3: Testing and Polish
- Test complete flow with all providers
- Verify fallback scenarios work
- Polish UI and error messages
- Update documentation

**Final Test Protocol**:
1. Test complete recording → transcription → refinement flow
2. Test provider fallbacks when primary unavailable
3. Test API key management security
4. Verify no regressions in existing features
5. Test with 20+ consecutive operations

**Phase 7 Final Checkpoint**:
- [ ] All providers working (Apple, OpenAI, OpenRouter)
- [ ] Fallback system functional
- [ ] UI integration complete
- [ ] No regressions in existing features
- [ ] Performance acceptable
- [ ] Git commit: "Complete AI providers integration"
- [ ] Tag: v1.1.0-ai-providers-complete

---

## Critical Notes

- **Keep Apple as Primary**: Maintain current reliability while adding choice
- **Focus on Essentials**: Only transcription and refinement providers for now
- **Test After Each Task**: Prevent cascading failures
- **Reuse Existing Code**: Integrate with current transcription/refinement services
- **Security First**: API keys in Keychain, not UserDefaults

## Success Metrics

- Provider switching works seamlessly
- Fallback prevents any service failures  
- API key storage is secure
- UI is intuitive and follows Liquid Glass design
- No performance impact on core functionality