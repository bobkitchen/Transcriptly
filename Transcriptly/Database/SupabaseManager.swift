import Foundation
import Combine
import Supabase

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
        
        // Temporarily disabled for build compatibility
        // TODO: Re-enable once SDK compatibility is resolved
        print("Learning session would be saved: \(sessionData.originalTranscription.prefix(50))...")
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
        
        // Temporarily disabled for build compatibility
        // TODO: Re-enable once SDK compatibility is resolved
        print("Pattern would be saved: \(pattern.originalPhrase) -> \(pattern.correctedPhrase)")
        
        // Update local cache
        await refreshPatternCache()
    }
    
    func getActivePatterns() async throws -> [LearnedPattern] {
        // Return cached patterns if offline or not authenticated
        guard isOnline, let userId = currentUser?.id else { 
            return cachedPatterns.filter { $0.isActive && $0.occurrenceCount >= 3 }
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Temporarily return cached patterns only
        // TODO: Implement proper Supabase query once SDK compatibility is resolved
        let activePatterns = cachedPatterns.filter { $0.isActive && $0.occurrenceCount >= 3 }
        print("Returning \(activePatterns.count) cached patterns")
        return activePatterns.sorted { $0.confidence > $1.confidence }
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
        
        // Temporarily disabled for build compatibility
        // TODO: Re-enable once SDK compatibility is resolved
        print("Preference would be saved: \(preference.type)")
    }
    
    func getPreferences() async throws -> [UserPreference] {
        guard let userId = currentUser?.id else { return [] }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Temporarily return empty
        // TODO: Implement proper Supabase query once SDK compatibility is resolved
        print("Would fetch preferences for user: \(userId)")
        return []
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
    
    // MARK: - App Assignments
    
    func saveAppAssignment(_ assignment: AppAssignment) async throws {
        guard let userId = currentUser?.id else {
            queueOfflineOperation(.saveAppAssignment(assignment))
            return
        }
        
        var assignmentData = assignment
        assignmentData.userId = userId
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Temporarily disabled for build compatibility
        // TODO: Re-enable once SDK compatibility is resolved
        print("App assignment would be saved: \(assignmentData.appName) -> \(assignmentData.assignedMode.displayName)")
    }
    
    func getAppAssignment(bundleId: String) async throws -> AppAssignment? {
        guard let userId = currentUser?.id else { return nil }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Temporarily return nil - would query Supabase
        // TODO: Implement proper Supabase query once SDK compatibility is resolved
        print("Would fetch app assignment for bundle ID: \(bundleId)")
        return nil
    }
    
    func getAllAppAssignments() async throws -> [AppAssignment] {
        guard let userId = currentUser?.id else { return [] }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Temporarily return empty - would query Supabase
        // TODO: Implement proper Supabase query once SDK compatibility is resolved
        print("Would fetch all app assignments for user: \(userId)")
        return []
    }
    
    func removeAppAssignment(bundleId: String) async throws {
        guard let userId = currentUser?.id else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Temporarily disabled for build compatibility
        // TODO: Re-enable once SDK compatibility is resolved
        print("Would remove app assignment for bundle ID: \(bundleId)")
    }
    
    func clearAllAppAssignments() async throws {
        guard let userId = currentUser?.id else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Temporarily disabled for build compatibility
        // TODO: Re-enable once SDK compatibility is resolved
        print("Would clear all app assignments")
    }
    
    // MARK: - Offline Support
    
    private enum PendingOperation {
        case saveLearningSession(LearningSession)
        case savePattern(LearnedPattern)
        case savePreference(UserPreference)
        case saveAppAssignment(AppAssignment)
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
                case .saveAppAssignment(let assignment):
                    try await saveAppAssignment(assignment)
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
            
            if event == .signedIn {
                await downloadUserData()
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