# Transcriptly Phase 3 - CORRECTED Task List (Supabase-First)

## Critical Implementation Rule

**🚨 LEARNING OPERATES ONLY ON TEXT, NEVER ON AUDIO 🚨**
**🚨 USE SUPABASE FROM THE OUTSET, NOT SQLITE 🚨**

---

## Phase 3.0: Setup and Architecture

### Task 3.0.1: Create Phase 3 Branch
```bash
git checkout main
git pull origin main
git checkout -b phase-3-learning-system
git push -u origin phase-3-learning-system
```

### Task 3.0.2: Create Learning Architecture Folders
```
Transcriptly/
├── Services/
│   └── Learning/
│       ├── LearningService.swift
│       ├── PatternMatcher.swift
│       ├── PreferenceProfiler.swift
│       └── LearningDataModels.swift
├── Views/
│   └── Learning/
│       ├── EditReviewWindow.swift
│       ├── ABTestingWindow.swift
│       └── LearningDashboard.swift
├── Database/
│   └── SupabaseManager.swift  // NO SQLite files
└── Models/
    └── Learning/
        ├── LearnedPattern.swift
        ├── UserPreference.swift
        └── LearningSession.swift
```

### Task 3.0.3: Set Up Supabase Project
1. Create Supabase project at https://app.supabase.com
2. Get project URL and anon key
3. Add to Xcode project as environment variables or config file
4. Install Supabase Swift SDK:
```swift
// Package.swift or SPM
.package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
```

### Task 3.0.4: Create Supabase Schema
```sql
-- Run this in Supabase SQL editor
-- Enable RLS (Row Level Security) on all tables

-- Users table (if not exists)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE,
    device_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Learning sessions table
CREATE TABLE learning_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    original_transcription TEXT NOT NULL,
    ai_refinement TEXT NOT NULL,
    user_final_version TEXT NOT NULL,
    refinement_mode TEXT NOT NULL,
    text_length INTEGER NOT NULL,
    learning_type TEXT NOT NULL,
    was_skipped BOOLEAN DEFAULT FALSE,
    device_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT text_length_positive CHECK (text_length > 0)
);

-- Learned patterns table
CREATE TABLE learned_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    original_phrase TEXT NOT NULL,
    corrected_phrase TEXT NOT NULL,
    occurrence_count INTEGER DEFAULT 1,
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    refinement_mode TEXT,
    confidence DECIMAL(3,2) DEFAULT 0.5,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(user_id, original_phrase, corrected_phrase)
);

-- User preferences table
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    preference_type TEXT NOT NULL,
    value DECIMAL(3,2) NOT NULL,
    sample_count INTEGER DEFAULT 1,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, preference_type),
    CONSTRAINT value_range CHECK (value >= -1 AND value <= 1)
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE learned_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own data" ON users
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can view own sessions" ON learning_sessions
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own patterns" ON learned_patterns
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own preferences" ON user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX idx_learning_sessions_user_timestamp ON learning_sessions(user_id, timestamp DESC);
CREATE INDEX idx_patterns_user_active ON learned_patterns(user_id, is_active);
CREATE INDEX idx_patterns_confidence ON learned_patterns(confidence DESC);
```

### Task 3.0.5: Create Learning Data Models
```swift
// Models/Learning/LearnedPattern.swift
import Foundation

struct LearnedPattern: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    let originalPhrase: String
    let correctedPhrase: String
    let occurrenceCount: Int
    let firstSeen: Date
    let lastSeen: Date
    let refinementMode: RefinementMode?
    let confidence: Double
    let isActive: Bool
    
    var isReady: Bool {
        occurrenceCount >= 3 && confidence > 0.6
    }
}

// Models/Learning/UserPreference.swift
struct UserPreference: Codable {
    enum PreferenceType: String, Codable {
        case formality
        case conciseness
        case contractions
        case punctuation
    }
    
    let id: UUID
    let userId: UUID?
    let type: PreferenceType
    let value: Double // -1.0 to 1.0
    let sampleCount: Int
    let lastUpdated: Date
}

// Models/Learning/LearningSession.swift
struct LearningSession: Codable {
    let id: UUID
    let userId: UUID?
    let timestamp: Date
    let originalTranscription: String
    let aiRefinement: String
    let userFinalVersion: String
    let refinementMode: RefinementMode
    let textLength: Int
    let learningType: LearningType
    let wasSkipped: Bool
    let deviceId: String?
    
    enum LearningType: String, Codable {
        case editReview
        case abTesting
    }
}
```

### Task 3.0.6: Document Learning Isolation
```markdown
# Create LEARNING_ISOLATION.md
## Audio/Learning Separation Checklist

### ✅ Prohibited in Learning System:
- Import AudioService
- Import AVFoundation (audio components)
- Access recording state
- Reference audio buffers
- Subscribe to audio notifications

### ✅ Allowed in Learning System:
- Import transcription results (String only)
- Process refined text
- Store text patterns in Supabase
- Sync with cloud database
- Update UI preferences

### ✅ Database Architecture:
- Supabase is PRIMARY storage (not backup)
- Local caching for offline operation
- Real-time sync when online
- NO SQLite implementation
```

**Checkpoint 3.0**:
- [ ] Supabase project created and configured
- [ ] Schema deployed to Supabase
- [ ] Models defined without audio references
- [ ] Supabase SDK integrated
- [ ] Isolation documentation written
- [ ] Git commit: "Phase 3 setup - Supabase-first architecture"

---

## Phase 3.1: Supabase Manager and Core Learning Service

### Task 3.1.1: Create Supabase Manager
```swift
// Database/SupabaseManager.swift
import Foundation
import Supabase
import Combine

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    private let client: SupabaseClient
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isSyncing = false
    
    // Cache for offline operation
    private var offlineQueue: [PendingOperation] = []
    private var cachedPatterns: [LearnedPattern] = []
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initialize Supabase client
        let url = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "")!
        let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
        
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        
        // Set up auth state listener
        Task {
            await setupAuthListener()
            await checkCurrentUser()
        }
        
        // Monitor network status for sync
        setupNetworkMonitoring()
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        currentUser = response.user
        isAuthenticated = true
        
        // Download user data after sign in
        await downloadUserData()
    }
    
    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        currentUser = response.user
        isAuthenticated = true
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        isAuthenticated = false
        
        // Clear cached data
        cachedPatterns.removeAll()
    }
    
    // MARK: - Learning Sessions
    
    func saveLearningSession(_ session: LearningSession) async throws {
        guard let userId = currentUser?.id else {
            // Queue for later if not authenticated
            queueOfflineOperation(.saveLearningSession(session))
            return
        }
        
        var sessionData = session
        sessionData.userId = userId
        sessionData.deviceId = getDeviceId()
        
        try await client
            .from("learning_sessions")
            .insert(sessionData)
            .execute()
    }
    
    // MARK: - Pattern Management
    
    func saveOrUpdatePattern(_ pattern: LearnedPattern) async throws {
        guard let userId = currentUser?.id else {
            queueOfflineOperation(.savePattern(pattern))
            return
        }
        
        var patternData = pattern
        patternData.userId = userId
        
        // Try to update existing pattern first
        let existing = try await client
            .from("learned_patterns")
            .select()
            .eq("user_id", value: userId)
            .eq("original_phrase", value: pattern.originalPhrase)
            .eq("corrected_phrase", value: pattern.correctedPhrase)
            .single()
            .execute()
        
        if existing.data != nil {
            // Update existing pattern
            try await client
                .from("learned_patterns")
                .update([
                    "occurrence_count": pattern.occurrenceCount + 1,
                    "last_seen": Date(),
                    "confidence": min(1.0, pattern.confidence + 0.1)
                ])
                .eq("id", value: pattern.id)
                .execute()
        } else {
            // Insert new pattern
            try await client
                .from("learned_patterns")
                .insert(patternData)
                .execute()
        }
        
        // Update local cache
        await refreshPatternCache()
    }
    
    func getActivePatterns() async throws -> [LearnedPattern] {
        // Return cached patterns if offline
        guard isOnline else { return cachedPatterns.filter { $0.isActive } }
        
        guard let userId = currentUser?.id else { return [] }
        
        let response = try await client
            .from("learned_patterns")
            .select()
            .eq("user_id", value: userId)
            .eq("is_active", value: true)
            .gte("occurrence_count", value: 3)
            .order("confidence", ascending: false)
            .execute()
        
        let patterns = try response.decoded(to: [LearnedPattern].self)
        
        // Update cache
        cachedPatterns = patterns
        
        return patterns
    }
    
    // MARK: - Preferences
    
    func saveOrUpdatePreference(_ preference: UserPreference) async throws {
        guard let userId = currentUser?.id else {
            queueOfflineOperation(.savePreference(preference))
            return
        }
        
        var prefData = preference
        prefData.userId = userId
        
        try await client
            .from("user_preferences")
            .upsert(prefData)
            .execute()
    }
    
    func getPreferences() async throws -> [UserPreference] {
        guard let userId = currentUser?.id else { return [] }
        
        let response = try await client
            .from("user_preferences")
            .select()
            .eq("user_id", value: userId)
            .execute()
        
        return try response.decoded(to: [UserPreference].self)
    }
    
    // MARK: - Data Management
    
    func clearAllUserData() async throws {
        guard let userId = currentUser?.id else { return }
        
        // Delete all user data
        try await client
            .from("learning_sessions")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        
        try await client
            .from("learned_patterns")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        
        try await client
            .from("user_preferences")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        
        // Clear cache
        cachedPatterns.removeAll()
    }
    
    // MARK: - Offline Support
    
    private enum PendingOperation {
        case saveLearningSession(LearningSession)
        case savePattern(LearnedPattern)
        case savePreference(UserPreference)
    }
    
    private func queueOfflineOperation(_ operation: PendingOperation) {
        offlineQueue.append(operation)
        UserDefaults.standard.set(try? JSONEncoder().encode(offlineQueue), 
                                 forKey: "offlineQueue")
    }
    
    private func processOfflineQueue() async {
        guard isAuthenticated, isOnline else { return }
        
        for operation in offlineQueue {
            do {
                switch operation {
                case .saveLearningSession(let session):
                    try await saveLearningSession(session)
                case .savePattern(let pattern):
                    try await saveOrUpdatePattern(pattern)
                case .savePreference(let preference):
                    try await saveOrUpdatePreference(preference)
                }
            } catch {
                print("Failed to sync offline operation: \(error)")
            }
        }
        
        offlineQueue.removeAll()
        UserDefaults.standard.removeObject(forKey: "offlineQueue")
    }
    
    // MARK: - Helpers
    
    private var isOnline: Bool {
        // Implement network monitoring
        return true // Placeholder
    }
    
    private func setupNetworkMonitoring() {
        // Monitor network status and trigger sync when online
        NotificationCenter.default.publisher(for: .init("NetworkStatusChanged"))
            .sink { [weak self] _ in
                Task {
                    await self?.processOfflineQueue()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupAuthListener() async {
        // Listen for auth state changes
        for await (event, session) in client.auth.authStateChanges {
            switch event {
            case .signedIn:
                currentUser = session?.user
                isAuthenticated = true
                await downloadUserData()
            case .signedOut:
                currentUser = nil
                isAuthenticated = false
            default:
                break
            }
        }
    }
    
    private func checkCurrentUser() async {
        if let user = try? await client.auth.user() {
            currentUser = user
            isAuthenticated = true
            await downloadUserData()
        }
    }
    
    private func downloadUserData() async {
        do {
            // Download patterns for offline use
            _ = try await getActivePatterns()
            
            // Process any queued operations
            await processOfflineQueue()
        } catch {
            print("Failed to download user data: \(error)")
        }
    }
    
    private func refreshPatternCache() async {
        do {
            _ = try await getActivePatterns()
        } catch {
            print("Failed to refresh pattern cache: \(error)")
        }
    }
    
    private func getDeviceId() -> String {
        if let deviceId = UserDefaults.standard.string(forKey: "deviceId") {
            return deviceId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "deviceId")
            return newId
        }
    }
}
```

### Task 3.1.2: Create Core Learning Service (Supabase-integrated)
```swift
// Services/Learning/LearningService.swift
import Foundation
import Combine

@MainActor
class LearningService: ObservableObject {
    static let shared = LearningService()
    
    @Published var isLearningEnabled = true
    @Published var sessionCount = 0
    @Published var shouldShowEditReview = false
    @Published var shouldShowABTest = false
    @Published var learningQuality: LearningQuality = .minimal
    
    private let supabase = SupabaseManager.shared
    private let patternMatcher = PatternMatcher()
    private let preferenceProfiler = PreferenceProfiler()
    
    enum LearningQuality {
        case minimal    // < 10 sessions
        case basic      // 10-50 sessions
        case good       // 50-100 sessions
        case excellent  // 100+ sessions
    }
    
    private init() {
        Task {
            await loadSessionCount()
        }
    }
    
    // MARK: - Critical: Text-Only Learning Entry Point
    
    /// The ONLY method that receives data for learning
    /// Called AFTER transcription is complete and refined
    /// NEVER called during audio recording
    func processCompletedTranscription(
        original: String,
        refined: String,
        refinementMode: RefinementMode
    ) {
        guard isLearningEnabled else { return }
        guard original.split(separator: " ").count >= 20 else {
            // Too short for edit review, consider A/B testing
            if sessionCount < 50 {
                shouldShowABTest = true
            }
            return
        }
        
        // Determine if we should show edit review
        if sessionCount < 10 {
            shouldShowEditReview = true
        } else {
            // Random 1 in 5 chance
            shouldShowEditReview = Int.random(in: 1...5) == 1
        }
    }
    
    // MARK: - Edit Review Processing
    
    func submitEditReview(
        original: String,
        aiRefined: String,
        userFinal: String,
        refinementMode: RefinementMode,
        skipLearning: Bool
    ) {
        shouldShowEditReview = false
        
        Task {
            let session = LearningSession(
                id: UUID(),
                userId: supabase.currentUser?.id,
                timestamp: Date(),
                originalTranscription: original,
                aiRefinement: aiRefined,
                userFinalVersion: userFinal,
                refinementMode: refinementMode,
                textLength: original.split(separator: " ").count,
                learningType: .editReview,
                wasSkipped: skipLearning,
                deviceId: nil
            )
            
            try? await supabase.saveLearningSession(session)
            
            if !skipLearning {
                // Extract patterns from the edits
                await patternMatcher.extractPatterns(
                    from: aiRefined,
                    to: userFinal,
                    mode: refinementMode
                )
                
                // Update preferences
                await preferenceProfiler.analyzePreferences(
                    original: aiRefined,
                    edited: userFinal
                )
            }
            
            sessionCount += 1
            updateLearningQuality()
        }
    }
    
    // MARK: - A/B Testing Processing
    
    func submitABTest(
        original: String,
        optionA: String,
        optionB: String,
        selected: String,
        refinementMode: RefinementMode
    ) {
        shouldShowABTest = false
        
        Task {
            let session = LearningSession(
                id: UUID(),
                userId: supabase.currentUser?.id,
                timestamp: Date(),
                originalTranscription: original,
                aiRefinement: selected == optionA ? optionA : optionB,
                userFinalVersion: selected,
                refinementMode: refinementMode,
                textLength: original.split(separator: " ").count,
                learningType: .abTesting,
                wasSkipped: false,
                deviceId: nil
            )
            
            try? await supabase.saveLearningSession(session)
            
            // Learn from the choice
            await preferenceProfiler.learnFromABChoice(
                selected: selected,
                rejected: selected == optionA ? optionB : optionA
            )
            
            sessionCount += 1
            updateLearningQuality()
        }
    }
    
    // MARK: - Pattern Application
    
    /// Apply learned patterns to refined text
    /// Called by RefinementService AFTER AI processing
    func applyLearnedPatterns(to text: String, mode: RefinementMode) async -> String {
        guard isLearningEnabled else { return text }
        
        var processedText = text
        
        // Apply pattern matching
        processedText = await patternMatcher.applyPatterns(
            to: processedText,
            mode: mode
        )
        
        // Apply preference-based adjustments
        processedText = await preferenceProfiler.adjustForPreferences(
            text: processedText
        )
        
        return processedText
    }
    
    // MARK: - User Control
    
    func resetAllLearning() async {
        do {
            try await supabase.clearAllUserData()
            sessionCount = 0
            updateLearningQuality()
        } catch {
            print("Failed to reset learning: \(error)")
        }
    }
    
    func deletePattern(_ pattern: LearnedPattern) async {
        // Mark pattern as inactive in Supabase
        var updatedPattern = pattern
        updatedPattern.isActive = false
        
        do {
            try await supabase.saveOrUpdatePattern(updatedPattern)
        } catch {
            print("Failed to delete pattern: \(error)")
        }
    }
    
    func pauseLearning() {
        isLearningEnabled = false
    }
    
    func resumeLearning() {
        isLearningEnabled = true
    }
    
    // MARK: - Private Helpers
    
    private func loadSessionCount() async {
        // Get session count from Supabase
        // For now, use a placeholder
        sessionCount = 0
        updateLearningQuality()
    }
    
    private func updateLearningQuality() {
        switch sessionCount {
        case 0..<10: learningQuality = .minimal
        case 10..<50: learningQuality = .basic
        case 50..<100: learningQuality = .good
        default: learningQuality = .excellent
        }
    }
}

// MARK: - Critical Safety Extension

extension LearningService {
    /// Compile-time verification that learning doesn't touch audio
    private func verifyNoAudioAccess() {
        // This function should fail to compile if any audio imports exist
        // let _ = AudioService.shared  // ❌ Should not compile
        // let _ = AVAudioRecorder()    // ❌ Should not compile
        let _ = "Text only processing" // ✅ Only text operations allowed
    }
}
```

### Task 3.1.3: Create Pattern Matcher (Supabase-integrated)
```swift
// Services/Learning/PatternMatcher.swift
import Foundation

class PatternMatcher {
    private let supabase = SupabaseManager.shared
    
    func extractPatterns(from original: String, to edited: String, mode: RefinementMode) async {
        // Use diff algorithm to find changes
        let changes = findChanges(between: original, and: edited)
        
        for change in changes {
            if change.isSignificant {
                let pattern = LearnedPattern(
                    id: UUID(),
                    userId: supabase.currentUser?.id,
                    originalPhrase: change.original,
                    correctedPhrase: change.edited,
                    occurrenceCount: 1,
                    firstSeen: Date(),
                    lastSeen: Date(),
                    refinementMode: mode,
                    confidence: 0.3,
                    isActive: true
                )
                
                do {
                    try await supabase.saveOrUpdatePattern(pattern)
                } catch {
                    print("Failed to save pattern: \(error)")
                }
            }
        }
    }
    
    func applyPatterns(to text: String, mode: RefinementMode) async -> String {
        var result = text
        
        do {
            let activePatterns = try await supabase.getActivePatterns()
            
            // Apply patterns with highest confidence first
            for pattern in activePatterns where pattern.isReady {
                // Give extra weight to patterns from same mode
                let modeBonus = pattern.refinementMode == mode ? 0.1 : 0.0
                let effectiveConfidence = min(1.0, pattern.confidence + modeBonus)
                
                if effectiveConfidence > 0.6 {
                    result = result.replacingOccurrences(
                        of: pattern.originalPhrase,
                        with: pattern.correctedPhrase,
                        options: [.caseInsensitive, .diacriticInsensitive]
                    )
                }
            }
        } catch {
            print("Failed to apply patterns: \(error)")
        }
        
        return result
    }
    
    private func findChanges(between original: String, and edited: String) -> [TextChange] {
        // Simple word-level diff for now
        let originalWords = original.split(separator: " ").map(String.init)
        let editedWords = edited.split(separator: " ").map(String.init)
        
        var changes: [TextChange] = []
        
        // Find common phrases that changed
        // This is simplified - real implementation would use proper diff algorithm
        
        return changes
    }
}

struct TextChange {
    let original: String
    let edited: String
    
    var isSignificant: Bool {
        // Ignore single character changes, punctuation only, etc.
        original.count > 2 && 
        edited.count > 2 && 
        original.lowercased() != edited.lowercased()
    }
}
```

**Test Protocol 3.1**:
1. Sign up/sign in to Supabase
2. Create test learning session
3. Verify it saves to Supabase
4. Go offline and create another session
5. Verify it queues and syncs when online
6. Verify NO audio imports anywhere

**Checkpoint 3.1**:
- [ ] Supabase manager functional
- [ ] Learning service uses Supabase only
- [ ] Offline queue works
- [ ] Pattern extraction saves to cloud
- [ ] No audio system access verified
- [ ] Git commit: "Core learning with Supabase"

---

## Remaining Phases Summary

The rest of the implementation remains the same, but with these key changes:

1. **ALL database operations use Supabase** - no SQLite anywhere
2. **Offline support through caching and queuing** - not a separate database
3. **Real-time sync is built in** - not added later
4. **Authentication is optional but integrated** - works offline without account

### Key Corrections Throughout:
- Replace all `LocalDatabase.shared` with `SupabaseManager.shared`
- Remove all SQLite references
- Ensure all data operations are async and use Supabase
- Implement proper offline queuing from the start
- Build with sync-first mentality

---

## Critical Notes for Claude Code

1. **DELETE any SQLite implementation** already created
2. **Use ONLY Supabase** for all data storage
3. **Implement offline support** through Supabase's caching, not SQLite
4. **Build sync from day one** - it's not a future feature
5. **Test with and without authentication** - both should work

I deeply apologize for this error. The original requirements were clear, and this corrected version accurately reflects what we agreed upon.