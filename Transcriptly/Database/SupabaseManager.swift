import Foundation
import Combine
import Supabase

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
        client = SupabaseConfig.shared.client
        
        // Set up authentication and monitoring
        Task {
            await setupAuthListener()
            await checkCurrentUser()
        }
        
        setupNetworkMonitoring()
        
        // Offline queue starts empty (in-memory only)
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        currentUser = response.user
        isAuthenticated = true
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
        cachedPatterns.removeAll()
    }
    
    // MARK: - Learning Sessions
    
    func saveLearningSession(_ session: LearningSession) async throws {
        guard let userId = currentUser?.id else {
            queueOfflineOperation(.saveLearningSession(session))
            return
        }
        
        var sessionData = session
        sessionData.userId = userId
        sessionData.deviceId = getDeviceId()
        
        isSyncing = true
        defer { isSyncing = false }
        
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
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Try to find existing pattern
        let existingQuery = try await client
            .from("learned_patterns")
            .select()
            .eq("user_id", value: userId)
            .eq("original_phrase", value: pattern.originalPhrase)
            .eq("corrected_phrase", value: pattern.correctedPhrase)
            .limit(1)
            .execute()
        
        let existingPatterns = try existingQuery.value as [LearnedPattern]
        if let existingPattern = existingPatterns.first {
            // Update existing pattern
            let updatedPattern = LearnedPattern(
                id: existingPattern.id,
                userId: userId,
                originalPhrase: existingPattern.originalPhrase,
                correctedPhrase: existingPattern.correctedPhrase,
                occurrenceCount: existingPattern.occurrenceCount + 1,
                firstSeen: existingPattern.firstSeen,
                lastSeen: Date(),
                refinementMode: pattern.refinementMode,
                confidence: min(1.0, existingPattern.confidence + 0.1),
                isActive: true
            )
            
            try await client
                .from("learned_patterns")
                .update(updatedPattern)
                .eq("id", value: existingPattern.id)
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
        
        isSyncing = true
        defer { isSyncing = false }
        
        let response = try await client
            .from("learned_patterns")
            .select()
            .eq("user_id", value: userId)
            .eq("is_active", value: true)
            .gte("occurrence_count", value: 3)
            .order("confidence", ascending: false)
            .execute()
        
        let patterns = try response.value as [LearnedPattern]
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
        
        isSyncing = true
        defer { isSyncing = false }
        
        try await client
            .from("user_preferences")
            .upsert(prefData)
            .execute()
    }
    
    func getPreferences() async throws -> [UserPreference] {
        guard let userId = currentUser?.id else { return [] }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let response = try await client
            .from("user_preferences")
            .select()
            .eq("user_id", value: userId)
            .execute()
        
        return try response.value as [UserPreference]
    }
    
    // MARK: - Data Management
    
    func clearAllUserData() async throws {
        guard let userId = currentUser?.id else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
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
        // Note: Offline queue is now in-memory only for simplicity
        // Could be enhanced to persist to UserDefaults if needed
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
    }
    
    // MARK: - Helpers
    
    private var isOnline: Bool {
        // TODO: Implement proper network monitoring
        return true // Placeholder
    }
    
    private func setupNetworkMonitoring() {
        // TODO: Monitor network status and trigger sync when online
        NotificationCenter.default.publisher(for: .init("NetworkStatusChanged"))
            .sink { [weak self] _ in
                Task {
                    await self?.processOfflineQueue()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupAuthListener() async {
        for await (event, session) in client.auth.authStateChanges {
            await MainActor.run {
                switch event {
                case .signedIn:
                    currentUser = session?.user
                    isAuthenticated = true
                case .signedOut:
                    currentUser = nil
                    isAuthenticated = false
                    cachedPatterns.removeAll()
                default:
                    break
                }
            }
            
            if event == .signedIn {
                await downloadUserData()
            }
        }
    }
    
    private func checkCurrentUser() async {
        if let user = try? await client.auth.user() {
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
            }
            await downloadUserData()
        }
    }
    
    private func refreshPatternCache() async {
        do {
            _ = try await getActivePatterns()
        } catch {
            print("Failed to refresh pattern cache: \(error)")
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