# Transcriptly Phase 3 - Detailed Task List

## Critical Implementation Rule

**🚨 LEARNING OPERATES ONLY ON TEXT, NEVER ON AUDIO 🚨**

Every task must be auditable to ensure:
- No imports from AudioService
- No access to audio buffers
- No references to recording state
- Learning begins AFTER transcription completes

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
│   ├── LocalDatabase.swift
│   └── SupabaseManager.swift
└── Models/
    └── Learning/
        ├── LearnedPattern.swift
        ├── UserPreference.swift
        └── LearningSession.swift
```

### Task 3.0.3: Create Learning Data Models
```swift
// Models/Learning/LearnedPattern.swift
import Foundation

struct LearnedPattern: Codable, Identifiable {
    let id: UUID
    let originalPhrase: String
    let correctedPhrase: String
    let occurrenceCount: Int
    let firstSeen: Date
    let lastSeen: Date
    let refinementMode: RefinementMode?
    let confidence: Double // 0.0 to 1.0
    
    var isActive: Bool {
        occurrenceCount >= 3 && confidence > 0.6
    }
}

// Models/Learning/UserPreference.swift
struct UserPreference: Codable {
    enum PreferenceType: String, Codable {
        case formality // formal vs casual
        case conciseness // verbose vs concise
        case contractions // use vs avoid
        case punctuation // heavy vs light
    }
    
    let id: UUID
    let type: PreferenceType
    let value: Double // -1.0 to 1.0 scale
    let sampleCount: Int
    let lastUpdated: Date
}

// Models/Learning/LearningSession.swift
struct LearningSession: Codable {
    let id: UUID
    let timestamp: Date
    let originalTranscription: String
    let aiRefinement: String
    let userFinalVersion: String
    let refinementMode: RefinementMode
    let textLength: Int
    let learningType: LearningType
    let wasSkipped: Bool
    
    enum LearningType: String, Codable {
        case editReview
        case abTesting
    }
}
```

### Task 3.0.4: Create Supabase Schema
```sql
-- Create this schema in Supabase dashboard
-- Users table (if not exists)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE,
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

-- Indexes for performance
CREATE INDEX idx_learning_sessions_user_timestamp ON learning_sessions(user_id, timestamp DESC);
CREATE INDEX idx_patterns_user_active ON learned_patterns(user_id, is_active);
CREATE INDEX idx_patterns_confidence ON learned_patterns(confidence DESC);
```

### Task 3.0.5: Document Learning Isolation
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
- Store text patterns
- Sync with cloud database
- Update UI preferences

### ✅ Audit Points:
1. No audio-related imports in Learning/ folder
2. LearningService only receives String data
3. Learning triggers AFTER paste operation
4. Complete isolation verified in tests
```

**Checkpoint 3.0**:
- [ ] Folder structure created
- [ ] Models defined without audio references
- [ ] Supabase schema created
- [ ] Isolation documentation written
- [ ] Git commit: "Phase 3 setup - text-only learning architecture"

---

## Phase 3.1: Local Database and Core Learning Service

### Task 3.1.1: Implement Local Database
```swift
// Database/LocalDatabase.swift
import Foundation
import SQLite3

class LocalDatabase {
    static let shared = LocalDatabase()
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
        // Setup SQLite database
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .applicationSupportDirectory, 
                                   in: .userDomainMask)
        let appSupportURL = urls[0].appendingPathComponent("Transcriptly")
        try? fileManager.createDirectory(at: appSupportURL, 
                                       withIntermediateDirectories: true)
        
        dbPath = appSupportURL.appendingPathComponent("learning.db").path
        openDatabase()
        createTables()
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }
    
    private func createTables() {
        let createSessionsTable = """
            CREATE TABLE IF NOT EXISTS learning_sessions (
                id TEXT PRIMARY KEY,
                timestamp REAL NOT NULL,
                original_transcription TEXT NOT NULL,
                ai_refinement TEXT NOT NULL,
                user_final_version TEXT NOT NULL,
                refinement_mode TEXT NOT NULL,
                text_length INTEGER NOT NULL,
                learning_type TEXT NOT NULL,
                was_skipped INTEGER DEFAULT 0,
                synced INTEGER DEFAULT 0
            );
        """
        
        let createPatternsTable = """
            CREATE TABLE IF NOT EXISTS learned_patterns (
                id TEXT PRIMARY KEY,
                original_phrase TEXT NOT NULL,
                corrected_phrase TEXT NOT NULL,
                occurrence_count INTEGER DEFAULT 1,
                first_seen REAL NOT NULL,
                last_seen REAL NOT NULL,
                refinement_mode TEXT,
                confidence REAL DEFAULT 0.5,
                is_active INTEGER DEFAULT 1,
                UNIQUE(original_phrase, corrected_phrase)
            );
        """
        
        let createPreferencesTable = """
            CREATE TABLE IF NOT EXISTS user_preferences (
                id TEXT PRIMARY KEY,
                preference_type TEXT NOT NULL UNIQUE,
                value REAL NOT NULL,
                sample_count INTEGER DEFAULT 1,
                last_updated REAL NOT NULL
            );
        """
        
        executeNonQuery(createSessionsTable)
        executeNonQuery(createPatternsTable)
        executeNonQuery(createPreferencesTable)
    }
    
    // MARK: - Learning Sessions
    
    func saveLearningSession(_ session: LearningSession) {
        let query = """
            INSERT INTO learning_sessions 
            (id, timestamp, original_transcription, ai_refinement, 
             user_final_version, refinement_mode, text_length, 
             learning_type, was_skipped)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, query, -1, &statement, nil)
        
        sqlite3_bind_text(statement, 1, session.id.uuidString, -1, nil)
        sqlite3_bind_double(statement, 2, session.timestamp.timeIntervalSince1970)
        sqlite3_bind_text(statement, 3, session.originalTranscription, -1, nil)
        sqlite3_bind_text(statement, 4, session.aiRefinement, -1, nil)
        sqlite3_bind_text(statement, 5, session.userFinalVersion, -1, nil)
        sqlite3_bind_text(statement, 6, session.refinementMode.rawValue, -1, nil)
        sqlite3_bind_int(statement, 7, Int32(session.textLength))
        sqlite3_bind_text(statement, 8, session.learningType.rawValue, -1, nil)
        sqlite3_bind_int(statement, 9, session.wasSkipped ? 1 : 0)
        
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }
    
    // MARK: - Pattern Management
    
    func saveOrUpdatePattern(_ pattern: LearnedPattern) {
        // First try to update existing pattern
        let updateQuery = """
            UPDATE learned_patterns 
            SET occurrence_count = occurrence_count + 1,
                last_seen = ?,
                confidence = MIN(1.0, confidence + 0.1)
            WHERE original_phrase = ? AND corrected_phrase = ?
        """
        
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil)
        
        sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
        sqlite3_bind_text(statement, 2, pattern.originalPhrase, -1, nil)
        sqlite3_bind_text(statement, 3, pattern.correctedPhrase, -1, nil)
        
        sqlite3_step(statement)
        let changes = sqlite3_changes(db)
        sqlite3_finalize(statement)
        
        // If no existing pattern, insert new
        if changes == 0 {
            let insertQuery = """
                INSERT INTO learned_patterns 
                (id, original_phrase, corrected_phrase, occurrence_count,
                 first_seen, last_seen, refinement_mode, confidence)
                VALUES (?, ?, ?, 1, ?, ?, ?, 0.3)
            """
            
            sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil)
            
            sqlite3_bind_text(statement, 1, UUID().uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, pattern.originalPhrase, -1, nil)
            sqlite3_bind_text(statement, 3, pattern.correctedPhrase, -1, nil)
            sqlite3_bind_double(statement, 4, Date().timeIntervalSince1970)
            sqlite3_bind_double(statement, 5, Date().timeIntervalSince1970)
            sqlite3_bind_text(statement, 6, pattern.refinementMode?.rawValue, -1, nil)
            
            sqlite3_step(statement)
            sqlite3_finalize(statement)
        }
    }
    
    func getActivePatterns() -> [LearnedPattern] {
        let query = """
            SELECT * FROM learned_patterns 
            WHERE is_active = 1 AND occurrence_count >= 3 
            ORDER BY confidence DESC, occurrence_count DESC
        """
        
        // Implementation continues...
        return []
    }
    
    private func executeNonQuery(_ query: String) {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(db, query, -1, &statement, nil)
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }
}
```

### Task 3.1.2: Create Core Learning Service
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
    
    private let database = LocalDatabase.shared
    private let patternMatcher = PatternMatcher()
    private let preferenceProfiler = PreferenceProfiler()
    private var supabaseManager: SupabaseManager?
    
    enum LearningQuality {
        case minimal    // < 10 sessions
        case basic      // 10-50 sessions
        case good       // 50-100 sessions
        case excellent  // 100+ sessions
    }
    
    private init() {
        loadSessionCount()
        setupSupabase()
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
        
        let session = LearningSession(
            id: UUID(),
            timestamp: Date(),
            originalTranscription: original,
            aiRefinement: aiRefined,
            userFinalVersion: userFinal,
            refinementMode: refinementMode,
            textLength: original.split(separator: " ").count,
            learningType: .editReview,
            wasSkipped: skipLearning
        )
        
        database.saveLearningSession(session)
        
        if !skipLearning {
            // Extract patterns from the edits
            patternMatcher.extractPatterns(
                from: aiRefined,
                to: userFinal,
                mode: refinementMode
            )
            
            // Update preferences
            preferenceProfiler.analyzePreferences(
                original: aiRefined,
                edited: userFinal
            )
        }
        
        sessionCount += 1
        updateLearningQuality()
        
        // Trigger sync if online
        Task {
            await supabaseManager?.syncPendingData()
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
        
        let session = LearningSession(
            id: UUID(),
            timestamp: Date(),
            originalTranscription: original,
            aiRefinement: selected == optionA ? optionA : optionB,
            userFinalVersion: selected,
            refinementMode: refinementMode,
            textLength: original.split(separator: " ").count,
            learningType: .abTesting,
            wasSkipped: false
        )
        
        database.saveLearningSession(session)
        
        // Learn from the choice
        preferenceProfiler.learnFromABChoice(
            selected: selected,
            rejected: selected == optionA ? optionB : optionA
        )
        
        sessionCount += 1
        updateLearningQuality()
    }
    
    // MARK: - Pattern Application
    
    /// Apply learned patterns to refined text
    /// Called by RefinementService AFTER AI processing
    func applyLearnedPatterns(to text: String, mode: RefinementMode) -> String {
        guard isLearningEnabled else { return text }
        
        var processedText = text
        
        // Apply pattern matching
        processedText = patternMatcher.applyPatterns(
            to: processedText,
            mode: mode
        )
        
        // Apply preference-based adjustments
        processedText = preferenceProfiler.adjustForPreferences(
            text: processedText
        )
        
        return processedText
    }
    
    // MARK: - User Control
    
    func resetAllLearning() {
        // Clear local database
        database.clearAllLearning()
        
        // Reset counters
        sessionCount = 0
        updateLearningQuality()
        
        // Clear cloud data
        Task {
            await supabaseManager?.clearUserData()
        }
    }
    
    func deletePattern(_ pattern: LearnedPattern) {
        database.deletePattern(pattern)
    }
    
    func pauseLearning() {
        isLearningEnabled = false
    }
    
    func resumeLearning() {
        isLearningEnabled = true
    }
    
    // MARK: - Private Helpers
    
    private func loadSessionCount() {
        sessionCount = database.getSessionCount()
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
    
    private func setupSupabase() {
        // Initialize Supabase if user is logged in
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            supabaseManager = SupabaseManager(userId: userId)
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

### Task 3.1.3: Create Pattern Matcher
```swift
// Services/Learning/PatternMatcher.swift
import Foundation

class PatternMatcher {
    private let database = LocalDatabase.shared
    private var activePatterns: [LearnedPattern] = []
    
    init() {
        loadActivePatterns()
    }
    
    func extractPatterns(from original: String, to edited: String, mode: RefinementMode) {
        // Use diff algorithm to find changes
        let changes = findChanges(between: original, and: edited)
        
        for change in changes {
            if change.isSignificant {
                let pattern = LearnedPattern(
                    id: UUID(),
                    originalPhrase: change.original,
                    correctedPhrase: change.edited,
                    occurrenceCount: 1,
                    firstSeen: Date(),
                    lastSeen: Date(),
                    refinementMode: mode,
                    confidence: 0.3
                )
                
                database.saveOrUpdatePattern(pattern)
            }
        }
        
        // Reload patterns after updates
        loadActivePatterns()
    }
    
    func applyPatterns(to text: String, mode: RefinementMode) -> String {
        var result = text
        
        // Apply patterns with highest confidence first
        for pattern in activePatterns where pattern.isActive {
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
        
        return result
    }
    
    private func loadActivePatterns() {
        activePatterns = database.getActivePatterns()
            .sorted { $0.confidence > $1.confidence }
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
1. Create test learning session
2. Verify it saves to local database
3. Extract patterns from sample edits
4. Apply patterns to new text
5. Verify NO audio imports anywhere

**Checkpoint 3.1**:
- [ ] Local database functional
- [ ] Learning service receives text only
- [ ] Pattern extraction works
- [ ] No audio system access verified
- [ ] Git commit: "Core learning service - text only"

---

## Phase 3.2: Edit Review Window

### Task 3.2.1: Create Edit Review Window
```swift
// Views/Learning/EditReviewWindow.swift
import SwiftUI
import AppKit

struct EditReviewWindow: View {
    let originalTranscription: String
    let aiRefinement: String
    let refinementMode: RefinementMode
    let onSubmit: (String, Bool) -> Void
    let onCancel: () -> Void
    
    @State private var editedText: String
    @State private var showDiffView = false
    @State private var dontLearnFromThis = false
    @State private var timeRemaining = 120 // 2 minutes
    @State private var isUserActive = false
    @State private var lastActivityTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(
        original: String,
        refined: String,
        mode: RefinementMode,
        onSubmit: @escaping (String, Bool) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.originalTranscription = original
        self.aiRefinement = refined
        self.refinementMode = mode
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self._editedText = State(initialValue: refined)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Review and Edit")
                    .font(.headline)
                
                Spacer()
                
                // Timer (only shows when inactive)
                if !isUserActive && timeRemaining < 120 {
                    Text("Auto-submit in \(timeRemaining)s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: { showDiffView.toggle() }) {
                    Label("Show Changes", systemImage: "doc.badge.ellipsis")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
            }
            .padding()
            
            Divider()
            
            // Main content
            if showDiffView {
                DiffView(original: aiRefinement, edited: editedText)
                    .padding()
            } else {
                TextEditor(text: $editedText)
                    .font(.system(.body))
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .onChange(of: editedText) { _ in
                        isUserActive = true
                        lastActivityTime = Date()
                        timeRemaining = 120 // Reset timer on activity
                    }
            }
            
            Divider()
            
            // Footer
            HStack {
                Toggle("Don't learn from this", isOn: $dontLearnFromThis)
                    .toggleStyle(.checkbox)
                
                Spacer()
                
                Button("Skip") {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Submit") {
                    onSubmit(editedText, dontLearnFromThis)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 600, height: 400)
        .onReceive(timer) { _ in
            // Check for user inactivity
            if Date().timeIntervalSince(lastActivityTime) > 2 {
                isUserActive = false
                
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    // Auto-submit
                    onSubmit(editedText, dontLearnFromThis)
                }
            }
        }
    }
}

struct DiffView: View {
    let original: String
    let edited: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("AI Refined:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(original)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
                
                Text("Your Edits:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(edited)
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
                
                // In production, implement proper diff highlighting
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// Window Controller
class EditReviewWindowController: NSWindowController {
    convenience init(
        original: String,
        refined: String,
        mode: RefinementMode,
        onSubmit: @escaping (String, Bool) -> Void,
        onCancel: @escaping () -> Void
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Edit Transcription"
        window.center()
        
        self.init(window: window)
        
        let contentView = EditReviewWindow(
            original: original,
            refined: refined,
            mode: mode,
            onSubmit: { text, skipLearning in
                onSubmit(text, skipLearning)
                window.close()
            },
            onCancel: {
                onCancel()
                window.close()
            }
        )
        
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }
}
```

### Task 3.2.2: Integrate Edit Review into Main Flow
```swift
// Update MainViewModel.swift
extension MainViewModel {
    func handleTranscriptionComplete(transcription: String, refined: String) {
        // Store for learning system
        self.lastTranscription = transcription
        self.lastRefinement = refined
        
        // Check if learning should show review
        LearningService.shared.processCompletedTranscription(
            original: transcription,
            refined: refined,
            refinementMode: refinementService.currentMode
        )
        
        if LearningService.shared.shouldShowEditReview {
            showEditReview(transcription: transcription, refined: refined)
        } else {
            // Normal flow - paste immediately
            pasteText(refined)
        }
    }
    
    private func showEditReview(transcription: String, refined: String) {
        let windowController = EditReviewWindowController(
            original: transcription,
            refined: refined,
            mode: refinementService.currentMode,
            onSubmit: { [weak self] editedText, skipLearning in
                guard let self = self else { return }
                
                // Submit to learning system
                LearningService.shared.submitEditReview(
                    original: transcription,
                    aiRefined: refined,
                    userFinal: editedText,
                    refinementMode: self.refinementService.currentMode,
                    skipLearning: skipLearning
                )
                
                // Paste the edited text
                self.pasteText(editedText)
            },
            onCancel: { [weak self] in
                // Just paste the original refined text
                self?.pasteText(refined)
            }
        )
        
        editReviewWindowController = windowController
    }
}
```

**Test Protocol 3.2**:
1. Trigger transcription over 20 words
2. Verify edit window appears (first 10 times)
3. Edit text and submit
4. Verify edited text is pasted
5. Check timer counts down only during inactivity

**Checkpoint 3.2**:
- [ ] Edit review window functional
- [ ] Timer resets on activity
- [ ] Diff view shows changes
- [ ] Submit/Skip both work
- [ ] Git commit: "Add edit review window"

---

## Phase 3.3: A/B Testing Implementation

### Task 3.3.1: Create A/B Testing Window
```swift
// Views/Learning/ABTestingWindow.swift
import SwiftUI
import AppKit

struct ABTestingWindow: View {
    let originalTranscription: String
    let optionA: String
    let optionB: String
    let onSelection: (String) -> Void
    
    @State private var hoveredOption: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Your Preferred Version")
                .font(.headline)
            
            Text("Original: \"\(originalTranscription)\"")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                OptionCard(
                    text: optionA,
                    label: "Option A",
                    isHovered: hoveredOption == "A",
                    action: { onSelection(optionA) }
                )
                .onHover { isHovered in
                    hoveredOption = isHovered ? "A" : nil
                }
                
                OptionCard(
                    text: optionB,
                    label: "Option B",
                    isHovered: hoveredOption == "B",
                    action: { onSelection(optionB) }
                )
                .onHover { isHovered in
                    hoveredOption = isHovered ? "B" : nil
                }
            }
            .padding()
            
            Text("Press A or B to select")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 600, height: 300)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
        // Keyboard shortcuts
        .onReceive(NotificationCenter.default.publisher(for: .init("SelectA"))) { _ in
            onSelection(optionA)
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("SelectB"))) { _ in
            onSelection(optionB)
        }
    }
}

struct OptionCard: View {
    let text: String
    let label: String
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHovered ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Window Controller for A/B Testing
class ABTestingWindowController: NSWindowController {
    convenience init(
        original: String,
        optionA: String,
        optionB: String,
        onSelection: @escaping (String) -> Void
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Choose Preferred Version"
        window.center()
        
        self.init(window: window)
        
        let contentView = ABTestingWindow(
            originalTranscription: original,
            optionA: optionA,
            optionB: optionB,
            onSelection: { selected in
                onSelection(selected)
                window.close()
            }
        )
        
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        
        // Add keyboard shortcuts
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.charactersIgnoringModifiers == "a" {
                NotificationCenter.default.post(name: .init("SelectA"), object: nil)
                return nil
            } else if event.charactersIgnoringModifiers == "b" {
                NotificationCenter.default.post(name: .init("SelectB"), object: nil)
                return nil
            }
            return event
        }
    }
}
```

### Task 3.3.2: Implement A/B Test Generation
```swift
// Update RefinementService.swift
extension RefinementService {
    func generateABOptions(_ text: String) async throws -> (String, String) {
        // Generate two variations using slightly different approaches
        
        // Option A: Standard refinement
        let optionA = try await refine(text)
        
        // Option B: Alternative approach (slightly different prompt)
        let alternativePrompt = prompts[currentMode]?.userPrompt
            .replacingOccurrences(of: "professional", with: "clear and direct")
            .replacingOccurrences(of: "casual", with: "conversational") ?? ""
        
        // Temporarily use alternative prompt
        let originalPrompt = prompts[currentMode]?.userPrompt ?? ""
        prompts[currentMode]?.userPrompt = alternativePrompt
        let optionB = try await refine(text)
        prompts[currentMode]?.userPrompt = originalPrompt
        
        return (optionA, optionB)
    }
}
```

### Task 3.3.3: Integrate A/B Testing into Flow
```swift
// Update MainViewModel.swift
extension MainViewModel {
    private func handleShortTranscription(transcription: String, refined: String) {
        if LearningService.shared.shouldShowABTest {
            Task {
                do {
                    let (optionA, optionB) = try await refinementService.generateABOptions(transcription)
                    
                    await MainActor.run {
                        showABTest(
                            original: transcription,
                            optionA: optionA,
                            optionB: optionB
                        )
                    }
                } catch {
                    // Fallback to normal flow
                    pasteText(refined)
                }
            }
        } else {
            pasteText(refined)
        }
    }
    
    private func showABTest(original: String, optionA: String, optionB: String) {
        let windowController = ABTestingWindowController(
            original: original,
            optionA: optionA,
            optionB: optionB,
            onSelection: { [weak self] selected in
                guard let self = self else { return }
                
                // Submit to learning system
                LearningService.shared.submitABTest(
                    original: original,
                    optionA: optionA,
                    optionB: optionB,
                    selected: selected,
                    refinementMode: self.refinementService.currentMode
                )
                
                // Paste selected text
                self.pasteText(selected)
            }
        )
        
        abTestWindowController = windowController
    }
}
```

**Test Protocol 3.3**:
1. Transcribe text under 20 words
2. Verify A/B test appears (first 50)
3. Test keyboard shortcuts A and B
4. Verify selection is pasted
5. Check learning captures choice

**Checkpoint 3.3**:
- [ ] A/B window displays two options
- [ ] Keyboard shortcuts work
- [ ] Selection is recorded
- [ ] No editing allowed
- [ ] Git commit: "Add A/B testing"

---

## Phase 3.4: Supabase Integration

### Task 3.4.1: Create Supabase Manager
```swift
// Database/SupabaseManager.swift
import Foundation
import Supabase

class SupabaseManager {
    private let client: SupabaseClient
    private let userId: String
    private var syncTimer: Timer?
    
    init(userId: String) {
        self.userId = userId
        
        // Initialize Supabase client
        let url = URL(string: "YOUR_SUPABASE_URL")!
        let key = "YOUR_SUPABASE_ANON_KEY"
        
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        
        // Start sync timer (every 30 seconds)
        startSyncTimer()
    }
    
    // MARK: - Session Sync
    
    func syncPendingData() async {
        await syncSessions()
        await syncPatterns()
        await syncPreferences()
    }
    
    private func syncSessions() async {
        do {
            // Get unsynced sessions from local DB
            let unsyncedSessions = LocalDatabase.shared.getUnsyncedSessions()
            
            for session in unsyncedSessions {
                let data: [String: Any] = [
                    "user_id": userId,
                    "timestamp": session.timestamp.timeIntervalSince1970,
                    "original_transcription": session.originalTranscription,
                    "ai_refinement": session.aiRefinement,
                    "user_final_version": session.userFinalVersion,
                    "refinement_mode": session.refinementMode.rawValue,
                    "text_length": session.textLength,
                    "learning_type": session.learningType.rawValue,
                    "was_skipped": session.wasSkipped,
                    "device_id": getDeviceId()
                ]
                
                try await client
                    .from("learning_sessions")
                    .insert(data)
                    .execute()
                
                // Mark as synced in local DB
                LocalDatabase.shared.markSessionSynced(session.id)
            }
        } catch {
            print("Sync error: \(error)")
        }
    }
    
    private func syncPatterns() async {
        do {
            // Get patterns from local DB
            let patterns = LocalDatabase.shared.getAllPatterns()
            
            for pattern in patterns {
                let data: [String: Any] = [
                    "user_id": userId,
                    "original_phrase": pattern.originalPhrase,
                    "corrected_phrase": pattern.correctedPhrase,
                    "occurrence_count": pattern.occurrenceCount,
                    "first_seen": pattern.firstSeen.timeIntervalSince1970,
                    "last_seen": pattern.lastSeen.timeIntervalSince1970,
                    "refinement_mode": pattern.refinementMode?.rawValue ?? "",
                    "confidence": pattern.confidence,
                    "is_active": pattern.isActive
                ]
                
                // Upsert pattern (update if exists, insert if not)
                try await client
                    .from("learned_patterns")
                    .upsert(data)
                    .execute()
            }
        } catch {
            print("Pattern sync error: \(error)")
        }
    }
    
    // MARK: - Download User Data
    
    func downloadUserData() async {
        await downloadPatterns()
        await downloadPreferences()
    }
    
    private func downloadPatterns() async {
        do {
            let response = try await client
                .from("learned_patterns")
                .select()
                .eq("user_id", value: userId)
                .execute()
            
            // Parse and save to local DB
            if let patterns = response.data as? [[String: Any]] {
                for patternData in patterns {
                    // Convert to LearnedPattern and save locally
                    // LocalDatabase.shared.savePattern(pattern)
                }
            }
        } catch {
            print("Download error: \(error)")
        }
    }
    
    // MARK: - Clear Data
    
    func clearUserData() async {
        do {
            // Delete all user data from cloud
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
        } catch {
            print("Clear data error: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await self.syncPendingData()
            }
        }
    }
    
    private func getDeviceId() -> String {
        // Get or create unique device ID
        if let deviceId = UserDefaults.standard.string(forKey: "deviceId") {
            return deviceId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "deviceId")
            return newId
        }
    }
    
    deinit {
        syncTimer?.invalidate()
    }
}
```

### Task 3.4.2: Add Authentication UI
```swift
// Views/Settings/AccountView.swift
import SwiftUI

struct AccountView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignedIn = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        GroupBox("Account") {
            if isSignedIn {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                        Text(email)
                        Spacer()
                    }
                    
                    Text("Your learning data is syncing across devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Sign Out") {
                        signOut()
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sign in to sync your preferences across devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Button("Sign In") {
                            Task { await signIn() }
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        
                        Button("Create Account") {
                            Task { await createAccount() }
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            checkAuthStatus()
        }
    }
    
    private func signIn() async {
        // Implement Supabase sign in
    }
    
    private func createAccount() async {
        // Implement Supabase sign up
    }
    
    private func signOut() {
        // Clear auth and stop sync
    }
    
    private func checkAuthStatus() {
        // Check if user is already signed in
    }
}
```

**Test Protocol 3.4**:
1. Create Supabase account (optional)
2. Test sign in flow
3. Verify data syncs to cloud
4. Sign out and verify local-only works
5. Test sync conflict resolution

**Checkpoint 3.4**:
- [ ] Supabase schema created
- [ ] Authentication works
- [ ] Data syncs when online
- [ ] Offline mode functional
- [ ] Git commit: "Add Supabase sync"

---

## Phase 3.5: Learning Dashboard

### Task 3.5.1: Create Learning Dashboard
```swift
// Views/Learning/LearningDashboard.swift
import SwiftUI

struct LearningDashboard: View {
    @ObservedObject var learningService = LearningService.shared
    @State private var learnedPatterns: [LearnedPattern] = []
    @State private var selectedPattern: LearnedPattern?
    @State private var showResetConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with toggle
            HStack {
                Text("Learning")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Toggle("Enable Learning", isOn: $learningService.isLearningEnabled)
            }
            
            // Learning Quality Indicator
            LearningQualityView(quality: learningService.learningQuality)
            
            // Statistics
            GroupBox("Learning Statistics") {
                HStack(spacing: 40) {
                    StatItem(
                        title: "Sessions",
                        value: "\(learningService.sessionCount)"
                    )
                    
                    StatItem(
                        title: "Patterns Learned",
                        value: "\(learnedPatterns.count)"
                    )
                    
                    StatItem(
                        title: "Accuracy",
                        value: "87%" // Calculate from actual data
                    )
                }
                .padding(.vertical, 8)
            }
            
            // Learned Patterns
            GroupBox("Learned Patterns") {
                if learnedPatterns.isEmpty {
                    Text("No patterns learned yet. Keep using Transcriptly!")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(learnedPatterns) { pattern in
                                PatternRow(
                                    pattern: pattern,
                                    isSelected: selectedPattern?.id == pattern.id
                                )
                                .onTapGesture {
                                    selectedPattern = pattern
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            // Actions
            HStack {
                Button("Export Learning Data") {
                    exportData()
                }
                
                Spacer()
                
                if selectedPattern != nil {
                    Button("Delete Pattern") {
                        deleteSelectedPattern()
                    }
                }
                
                Button("Reset All Learning") {
                    showResetConfirmation = true
                }
                .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadPatterns()
        }
        .alert("Reset All Learning?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                learningService.resetAllLearning()
                loadPatterns()
            }
        } message: {
            Text("This will delete all learned patterns and preferences. This action cannot be undone.")
        }
    }
    
    private func loadPatterns() {
        learnedPatterns = LocalDatabase.shared.getAllPatterns()
            .sorted { $0.occurrenceCount > $1.occurrenceCount }
    }
    
    private func deleteSelectedPattern() {
        if let pattern = selectedPattern {
            learningService.deletePattern(pattern)
            loadPatterns()
            selectedPattern = nil
        }
    }
    
    private func exportData() {
        // Export learning data to file
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "transcriptly-learning-data.json"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            // Export data to JSON
            do {
                let data = try JSONEncoder().encode(learnedPatterns)
                try data.write(to: url)
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
}

struct LearningQualityView: View {
    let quality: LearningService.LearningQuality
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.largeTitle)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text("Learning Quality: \(quality.description)")
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    var iconName: String {
        switch quality {
        case .minimal: return "brain"
        case .basic: return "brain"
        case .good: return "brain"
        case .excellent: return "brain"
        }
    }
    
    var color: Color {
        switch quality {
        case .minimal: return .gray
        case .basic: return .blue
        case .good: return .green
        case .excellent: return .purple
        }
    }
    
    var subtitle: String {
        switch quality {
        case .minimal: return "Just getting started"
        case .basic: return "Building your profile"
        case .good: return "Well-trained"
        case .excellent: return "Highly personalized"
        }
    }
}

struct PatternRow: View {
    let pattern: LearnedPattern
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\"\(pattern.originalPhrase)\" → \"\(pattern.correctedPhrase)\"")
                    .font(.system(.body, design: .monospaced))
                
                HStack {
                    Text("Used \(pattern.occurrenceCount) times")
                    Text("•")
                    Text("Confidence: \(Int(pattern.confidence * 100))%")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if pattern.isActive {
                Label("Active", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundColor(.green)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

### Task 3.5.2: Update Learning View
```swift
// Update existing LearningView to use dashboard
struct LearningView: View {
    var body: some View {
        LearningDashboard()
    }
}
```

**Test Protocol 3.5**:
1. View learning dashboard
2. Check statistics update
3. View learned patterns
4. Delete a pattern
5. Export and reset data

**Checkpoint 3.5**:
- [ ] Dashboard shows statistics
- [ ] Patterns display correctly
- [ ] Export functionality works
- [ ] Reset clears all data
- [ ] Git commit: "Add learning dashboard"

---

## Phase 3.6: Integration and Polish

### Task 3.6.1: Update RefinementService for Learning
```swift
// Update RefinementService.swift
extension RefinementService {
    func refineWithLearning(_ text: String) async throws -> String {
        // First, apply AI refinement
        let aiRefined = try await refine(text)
        
        // Then apply learned patterns
        let finalText = LearningService.shared.applyLearnedPatterns(
            to: aiRefined,
            mode: currentMode
        )
        
        return finalText
    }
}
```

### Task 3.6.2: Add Learning Indicators
```swift
// Update UI to show when learning is applied
struct LearningIndicator: View {
    let isActive: Bool
    
    var body: some View {
        if isActive {
            HStack(spacing: 4) {
                Image(systemName: "brain")
                    .font(.caption2)
                Text("Learning Active")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(4)
        }
    }
}
```

### Task 3.6.3: Create Preference Profiler
```swift
// Services/Learning/PreferenceProfiler.swift
import Foundation

class PreferenceProfiler {
    private var preferences: [UserPreference.PreferenceType: Double] = [:]
    
    func analyzePreferences(original: String, edited: String) {
        // Analyze formality
        let formalityDelta = assessFormality(edited) - assessFormality(original)
        updatePreference(.formality, delta: formalityDelta)
        
        // Analyze conciseness
        let concisenessDelta = assessConciseness(original, edited)
        updatePreference(.conciseness, delta: concisenessDelta)
        
        // Analyze contractions
        let contractionDelta = assessContractions(edited) - assessContractions(original)
        updatePreference(.contractions, delta: contractionDelta)
        
        // Save to database
        savePreferences()
    }
    
    func learnFromABChoice(selected: String, rejected: String) {
        // Compare characteristics of selected vs rejected
        let formalityDiff = assessFormality(selected) - assessFormality(rejected)
        updatePreference(.formality, delta: formalityDiff * 0.5) // Smaller weight for A/B
        
        let concisenessDiff = assessConciseness(rejected, selected)
        updatePreference(.conciseness, delta: concisenessDiff * 0.5)
    }
    
    func adjustForPreferences(text: String) -> String {
        var result = text
        
        // Apply formality preferences
        if let formalityPref = preferences[.formality] {
            if formalityPref > 0.5 {
                // Make more formal
                result = applyFormalAdjustments(result)
            } else if formalityPref < -0.5 {
                // Make more casual
                result = applyCasualAdjustments(result)
            }
        }
        
        // Apply conciseness preferences
        if let concisenessPref = preferences[.conciseness] {
            if concisenessPref > 0.5 {
                // Make more concise
                result = applyConciseAdjustments(result)
            }
        }
        
        return result
    }
    
    // MARK: - Assessment Methods
    
    private func assessFormality(_ text: String) -> Double {
        var score = 0.0
        
        // Check for formal indicators
        if text.contains("therefore") || text.contains("furthermore") { score += 0.2 }
        if text.contains("Mr.") || text.contains("Ms.") { score += 0.2 }
        if !text.contains("!") { score += 0.1 } // No exclamations
        
        // Check for casual indicators
        if text.contains("gonna") || text.contains("wanna") { score -= 0.3 }
        if text.contains("hey") || text.contains("yeah") { score -= 0.2 }
        
        return max(-1.0, min(1.0, score))
    }
    
    private func assessConciseness(_ original: String, _ edited: String) -> Double {
        let originalWords = original.split(separator: " ").count
        let editedWords = edited.split(separator: " ").count
        
        if originalWords == 0 { return 0 }
        
        let ratio = Double(editedWords) / Double(originalWords)
        
        // If edited is shorter, positive score for conciseness
        // If edited is longer, negative score
        return (1.0 - ratio).clamped(to: -1.0...1.0)
    }
    
    private func assessContractions(_ text: String) -> Double {
        let contractions = ["don't", "won't", "can't", "isn't", "aren't", 
                           "wasn't", "weren't", "haven't", "hasn't", "hadn't",
                           "wouldn't", "couldn't", "shouldn't", "I'm", "you're",
                           "we're", "they're", "it's", "that's", "what's"]
        
        var count = 0
        for contraction in contractions {
            count += text.components(separatedBy: contraction).count - 1
        }
        
        let words = text.split(separator: " ").count
        let ratio = Double(count) / Double(max(words, 1))
        
        return ratio * 10.0 // Scale up for sensitivity
    }
    
    // MARK: - Adjustment Methods
    
    private func applyFormalAdjustments(_ text: String) -> String {
        var result = text
        
        // Replace casual phrases with formal ones
        let replacements = [
            "thanks": "thank you",
            "yeah": "yes",
            "nope": "no",
            "gonna": "going to",
            "wanna": "want to",
            "gotta": "have to",
            "kinda": "kind of",
            "sorta": "sort of"
        ]
        
        for (casual, formal) in replacements {
            result = result.replacingOccurrences(
                of: "\\b\(casual)\\b",
                with: formal,
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        return result
    }
    
    private func applyCasualAdjustments(_ text: String) -> String {
        var result = text
        
        // Make slightly more casual
        let replacements = [
            "thank you": "thanks",
            "going to": "gonna"
        ]
        
        for (formal, casual) in replacements {
            result = result.replacingOccurrences(of: formal, with: casual)
        }
        
        return result
    }
    
    private func applyConciseAdjustments(_ text: String) -> String {
        var result = text
        
        // Remove filler phrases
        let fillers = [
            "in order to": "to",
            "at this point in time": "now",
            "due to the fact that": "because",
            "in the event that": "if"
        ]
        
        for (verbose, concise) in fillers {
            result = result.replacingOccurrences(of: verbose, with: concise)
        }
        
        return result
    }
    
    // MARK: - Persistence
    
    private func updatePreference(_ type: UserPreference.PreferenceType, delta: Double) {
        let current = preferences[type] ?? 0.0
        let updated = (current + delta * 0.1).clamped(to: -1.0...1.0) // Gradual updates
        preferences[type] = updated
    }
    
    private func savePreferences() {
        for (type, value) in preferences {
            let preference = UserPreference(
                id: UUID(),
                type: type,
                value: value,
                sampleCount: 1,
                lastUpdated: Date()
            )
            
            LocalDatabase.shared.saveOrUpdatePreference(preference)
        }
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return max(range.lowerBound, min(self, range.upperBound))
    }
}