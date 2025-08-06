# Transcriptly App Detection & Assignment - Detailed Task List

## Phase A.0: Setup and Architecture

### Task A.0.1: Create Feature Branch
```bash
git checkout main
git pull origin main
git checkout -b feature-app-detection-assignment
git push -u origin feature-app-detection-assignment
```

### Task A.0.2: Create App Detection Architecture
```
Transcriptly/
├── Services/
│   └── AppDetection/
│       ├── AppDetectionService.swift
│       ├── AppAssignmentManager.swift
│       └── AppDetectionModels.swift
├── Views/
│   └── AppSelection/
│       ├── AppPickerView.swift
│       └── AppAssignmentSheet.swift
└── Models/
    └── AppDetection/
        ├── AppInfo.swift
        ├── AppAssignment.swift
        └── DefaultAppMappings.swift
```

### Task A.0.3: Update Supabase Schema
```sql
-- Add app assignments table
CREATE TABLE app_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    app_bundle_id TEXT NOT NULL,
    app_name TEXT NOT NULL,
    assigned_mode TEXT NOT NULL,
    is_user_override BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, app_bundle_id)
);

-- Update learned_patterns table for app context
ALTER TABLE learned_patterns 
ADD COLUMN app_context TEXT;

-- Update user_preferences table for app context  
ALTER TABLE user_preferences
ADD COLUMN app_context TEXT;

-- Create indexes
CREATE INDEX idx_app_assignments_user_bundle ON app_assignments(user_id, app_bundle_id);
CREATE INDEX idx_patterns_app_context ON learned_patterns(user_id, app_context);
CREATE INDEX idx_preferences_app_context ON user_preferences(user_id, app_context);

-- RLS policies
CREATE POLICY "Users can manage own app assignments" ON app_assignments
    FOR ALL USING (auth.uid() = user_id);
```

**Checkpoint A.0**:
- [ ] Feature branch created
- [ ] File structure created
- [ ] Supabase schema updated
- [ ] Git commit: "Setup app detection architecture"

---

## Phase A.1: Core App Detection Service

### Task A.1.1: Create App Detection Models
```swift
// Models/AppDetection/AppInfo.swift
import Foundation

struct AppInfo: Codable, Equatable {
    let bundleIdentifier: String
    let localizedName: String
    let executablePath: String?
    
    init(from app: NSRunningApplication) {
        self.bundleIdentifier = app.bundleIdentifier ?? "unknown"
        self.localizedName = app.localizedName ?? "Unknown App"
        self.executablePath = app.executableURL?.path
    }
    
    var isSystemApp: Bool {
        bundleIdentifier.hasPrefix("com.apple.") && 
        !bundleIdentifier.contains("mail") &&
        !bundleIdentifier.contains("messages")
    }
    
    var displayName: String {
        localizedName.replacingOccurrences(of: ".app", with: "")
    }
}

// Models/AppDetection/AppAssignment.swift
import Foundation

struct AppAssignment: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    let appBundleId: String
    let appName: String
    let assignedMode: RefinementMode
    let isUserOverride: Bool
    let createdAt: Date
    let updatedAt: Date
    
    init(
        appInfo: AppInfo,
        mode: RefinementMode,
        isUserOverride: Bool = true,
        userId: UUID? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.appBundleId = appInfo.bundleIdentifier
        self.appName = appInfo.displayName
        self.assignedMode = mode
        self.isUserOverride = isUserOverride
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// Models/AppDetection/DefaultAppMappings.swift
import Foundation

struct DefaultAppMappings {
    static let mappings: [String: RefinementMode] = [
        // Email clients
        "com.apple.mail": .email,
        "com.microsoft.Outlook": .email,
        "com.apple.MailCompose": .email,
        "com.readdle.smartemail-Mac": .email,
        
        // Messaging apps
        "com.apple.MobileSMS": .messaging,
        "com.tinyspeck.slackmacgap": .messaging,
        "com.hnc.Discord": .messaging,
        "com.facebook.archon.developerID": .messaging,
        "com.microsoft.teams2": .messaging,
        "org.whispersystems.signal-desktop": .messaging,
        "com.telegram.desktop": .messaging,
        
        // Text editors and writing apps
        "com.apple.TextEdit": .cleanup,
        "com.microsoft.Word": .cleanup,
        "com.apple.Notes": .cleanup,
        "com.notion.desktop": .cleanup,
        "com.bear-writer.BearOSX": .cleanup,
        "com.uranusjr.macdown": .cleanup,
        "com.typora.typora": .cleanup,
        
        // Development tools (cleanup for comments/docs)
        "com.microsoft.VSCode": .cleanup,
        "com.apple.dt.Xcode": .cleanup,
        "com.jetbrains.intellij": .cleanup,
        
        // Browsers default to cleanup
        "com.apple.Safari": .cleanup,
        "com.google.Chrome": .cleanup,
        "org.mozilla.firefox": .cleanup,
        "com.microsoft.edgemac": .cleanup
    ]
    
    static func defaultMode(for bundleId: String) -> RefinementMode? {
        return mappings[bundleId]
    }
    
    static var allSupportedApps: [(String, String, RefinementMode)] {
        return mappings.map { (bundleId, mode) in
            // Get app name from bundle ID or use simplified name
            let appName = bundleId.components(separatedBy: ".").last?.capitalized ?? "Unknown"
            return (bundleId, appName, mode)
        }
    }
}
```

### Task A.1.2: Create App Detection Service
```swift
// Services/AppDetection/AppDetectionService.swift
import Foundation
import AppKit

@MainActor
class AppDetectionService: ObservableObject {
    static let shared = AppDetectionService()
    
    @Published var currentApp: AppInfo?
    @Published var detectedMode: RefinementMode?
    @Published var isAutoDetectionEnabled = true
    
    private let assignmentManager = AppAssignmentManager.shared
    private let confidenceThreshold: Double = 0.7
    
    private init() {
        loadSettings()
    }
    
    // MARK: - App Detection
    
    func detectActiveApp() -> AppInfo? {
        guard isAutoDetectionEnabled else { return nil }
        
        // Get frontmost application
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              frontmostApp.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return nil
        }
        
        let appInfo = AppInfo(from: frontmostApp)
        currentApp = appInfo
        
        return appInfo
    }
    
    func getRecommendedMode(for app: AppInfo) async -> RefinementMode? {
        guard isAutoDetectionEnabled else { return nil }
        
        // Check user assignments first
        if let userAssignment = await assignmentManager.getAssignment(for: app) {
            detectedMode = userAssignment.assignedMode
            return userAssignment.assignedMode
        }
        
        // Check built-in defaults
        if let defaultMode = DefaultAppMappings.defaultMode(for: app.bundleIdentifier) {
            detectedMode = defaultMode
            return defaultMode
        }
        
        // No specific assignment found
        detectedMode = nil
        return nil
    }
    
    func getDetectionConfidence(for app: AppInfo) async -> Double {
        // User assignments have highest confidence
        if await assignmentManager.hasUserAssignment(for: app) {
            return 1.0
        }
        
        // Built-in defaults have medium-high confidence
        if DefaultAppMappings.defaultMode(for: app.bundleIdentifier) != nil {
            return 0.8
        }
        
        // Unknown apps have low confidence
        return 0.0
    }
    
    // MARK: - Integration Points
    
    func detectAndRecommendMode() async -> (app: AppInfo?, mode: RefinementMode?) {
        guard let app = detectActiveApp() else {
            return (nil, nil)
        }
        
        let confidence = await getDetectionConfidence(for: app)
        guard confidence >= confidenceThreshold else {
            return (app, nil)
        }
        
        let mode = await getRecommendedMode(for: app)
        return (app, mode)
    }
    
    // MARK: - Settings
    
    func toggleAutoDetection() {
        isAutoDetectionEnabled.toggle()
        saveSettings()
    }
    
    func setAutoDetectionEnabled(_ enabled: Bool) {
        isAutoDetectionEnabled = enabled
        saveSettings()
    }
    
    private func loadSettings() {
        isAutoDetectionEnabled = UserDefaults.standard.bool(forKey: "appDetectionEnabled")
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(isAutoDetectionEnabled, forKey: "appDetectionEnabled")
    }
    
    // MARK: - Utility
    
    func getDisplayString(for app: AppInfo, mode: RefinementMode) -> String {
        return "\(app.displayName) → \(mode.displayName)"
    }
}
```

### Task A.1.3: Create App Assignment Manager
```swift
// Services/AppDetection/AppAssignmentManager.swift
import Foundation

@MainActor
class AppAssignmentManager: ObservableObject {
    static let shared = AppAssignmentManager()
    
    @Published var userAssignments: [AppAssignment] = []
    
    private let supabase = SupabaseManager.shared
    private var cachedAssignments: [String: AppAssignment] = [:]
    
    private init() {
        Task {
            await loadAssignments()
        }
    }
    
    // MARK: - Assignment Management
    
    func saveAssignment(_ assignment: AppAssignment) async throws {
        var assignmentData = assignment
        assignmentData.userId = supabase.currentUser?.id
        
        try await supabase.saveAppAssignment(assignmentData)
        
        // Update local cache
        cachedAssignments[assignment.appBundleId] = assignmentData
        
        // Update published array
        if let index = userAssignments.firstIndex(where: { $0.appBundleId == assignment.appBundleId }) {
            userAssignments[index] = assignmentData
        } else {
            userAssignments.append(assignmentData)
        }
    }
    
    func removeAssignment(for app: AppInfo) async throws {
        try await supabase.removeAppAssignment(bundleId: app.bundleIdentifier)
        
        // Update local cache
        cachedAssignments.removeValue(forKey: app.bundleIdentifier)
        
        // Update published array
        userAssignments.removeAll { $0.appBundleId == app.bundleIdentifier }
    }
    
    func getAssignment(for app: AppInfo) async -> AppAssignment? {
        // Check cache first
        if let cached = cachedAssignments[app.bundleIdentifier] {
            return cached
        }
        
        // Check Supabase
        do {
            let assignment = try await supabase.getAppAssignment(bundleId: app.bundleIdentifier)
            if let assignment = assignment {
                cachedAssignments[app.bundleIdentifier] = assignment
            }
            return assignment
        } catch {
            print("Failed to get app assignment: \(error)")
            return nil
        }
    }
    
    func hasUserAssignment(for app: AppInfo) async -> Bool {
        return await getAssignment(for: app) != nil
    }
    
    func getAssignedApps(for mode: RefinementMode) -> [AppAssignment] {
        return userAssignments.filter { $0.assignedMode == mode }
    }
    
    // MARK: - Bulk Operations
    
    func loadAssignments() async {
        do {
            let assignments = try await supabase.getAllAppAssignments()
            userAssignments = assignments
            
            // Update cache
            cachedAssignments = Dictionary(uniqueKeysWithValues: 
                assignments.map { ($0.appBundleId, $0) }
            )
        } catch {
            print("Failed to load app assignments: \(error)")
        }
    }
    
    func resetAllAssignments() async throws {
        try await supabase.clearAllAppAssignments()
        userAssignments.removeAll()
        cachedAssignments.removeAll()
    }
}

// MARK: - Supabase Extensions

extension SupabaseManager {
    func saveAppAssignment(_ assignment: AppAssignment) async throws {
        guard let userId = currentUser?.id else {
            queueOfflineOperation(.saveAppAssignment(assignment))
            return
        }
        
        var assignmentData = assignment
        assignmentData.userId = userId
        
        try await client
            .from("app_assignments")
            .upsert(assignmentData)
            .execute()
    }
    
    func getAppAssignment(bundleId: String) async throws -> AppAssignment? {
        guard let userId = currentUser?.id else { return nil }
        
        let response = try await client
            .from("app_assignments")
            .select()
            .eq("user_id", value: userId)
            .eq("app_bundle_id", value: bundleId)
            .single()
            .execute()
        
        return try response.decoded(to: AppAssignment.self)
    }
    
    func getAllAppAssignments() async throws -> [AppAssignment] {
        guard let userId = currentUser?.id else { return [] }
        
        let response = try await client
            .from("app_assignments")
            .select()
            .eq("user_id", value: userId)
            .order("app_name", ascending: true)
            .execute()
        
        return try response.decoded(to: [AppAssignment].self)
    }
    
    func removeAppAssignment(bundleId: String) async throws {
        guard let userId = currentUser?.id else { return }
        
        try await client
            .from("app_assignments")
            .delete()
            .eq("user_id", value: userId)
            .eq("app_bundle_id", value: bundleId)
            .execute()
    }
    
    func clearAllAppAssignments() async throws {
        guard let userId = currentUser?.id else { return }
        
        try await client
            .from("app_assignments")
            .delete()
            .eq("user_id", value: userId)
            .execute()
    }
}

// Add to PendingOperation enum
private enum PendingOperation {
    // ... existing cases
    case saveAppAssignment(AppAssignment)
}
```

**Test Protocol A.1**:
1. Test app detection with 5 different apps
2. Verify default mappings work
3. Test confidence scoring
4. Verify Supabase integration
5. Test offline queueing

**Checkpoint A.1**:
- [ ] App detection service functional
- [ ] Default mappings work
- [ ] Assignment manager integrated
- [ ] Supabase schema working
- [ ] Git commit: "Core app detection service"

---

## Phase A.2: UI Integration - App Picker

### Task A.2.1: Create App Picker View
```swift
// Views/AppSelection/AppPickerView.swift
import SwiftUI
import AppKit

struct AppPickerView: View {
    @Binding var isPresented: Bool
    let mode: RefinementMode
    let onAppSelected: (AppInfo) -> Void
    
    @State private var availableApps: [AppInfo] = []
    @State private var filteredApps: [AppInfo] = []
    @State private var searchText = ""
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Assign Apps to \(mode.displayName)")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
            }
            .padding(DesignSystem.spacingLarge)
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search applications...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _ in
                        filterApps()
                    }
            }
            .padding(DesignSystem.spacingMedium)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, DesignSystem.spacingLarge)
            .padding(.top, DesignSystem.spacingMedium)
            
            // App list
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading applications...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.spacingSmall) {
                        ForEach(filteredApps, id: \.bundleIdentifier) { app in
                            AppRowView(
                                app: app,
                                isRecommended: isRecommended(app),
                                onSelect: {
                                    onAppSelected(app)
                                    isPresented = false
                                }
                            )
                        }
                    }
                    .padding(DesignSystem.spacingMedium)
                }
            }
        }
        .frame(width: 500, height: 600)
        .background(.regularMaterial)
        .onAppear {
            loadAvailableApps()
        }
    }
    
    private func loadAvailableApps() {
        Task {
            let apps = await getInstalledApplications()
            await MainActor.run {
                availableApps = apps
                filteredApps = apps
                isLoading = false
            }
        }
    }
    
    private func filterApps() {
        if searchText.isEmpty {
            filteredApps = availableApps
        } else {
            filteredApps = availableApps.filter { app in
                app.displayName.localizedCaseInsensitiveContains(searchText) ||
                app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func isRecommended(_ app: AppInfo) -> Bool {
        DefaultAppMappings.defaultMode(for: app.bundleIdentifier) == mode
    }
    
    private func getInstalledApplications() async -> [AppInfo] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let workspace = NSWorkspace.shared
                let applicationURLs = workspace.urlsForApplications(toOpen: URL(fileURLWithPath: "/"))
                
                var apps: [AppInfo] = []
                
                for url in applicationURLs {
                    if let bundle = Bundle(url: url),
                       let bundleId = bundle.bundleIdentifier,
                       let appName = bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String ??
                                   bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
                                   url.deletingPathExtension().lastPathComponent as String? {
                        
                        // Create mock NSRunningApplication for AppInfo init
                        let appInfo = AppInfo(
                            bundleIdentifier: bundleId,
                            localizedName: appName,
                            executablePath: url.path
                        )
                        
                        // Filter out system apps we don't want
                        if !shouldExcludeApp(appInfo) {
                            apps.append(appInfo)
                        }
                    }
                }
                
                // Sort alphabetically
                apps.sort { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
                
                continuation.resume(returning: apps)
            }
        }
    }
    
    private func shouldExcludeApp(_ app: AppInfo) -> Bool {
        let excludedPrefixes = [
            "com.apple.ActivityMonitor",
            "com.apple.Console",
            "com.apple.SystemPreferences",
            "com.apple.finder",
            "com.apple.loginwindow"
        ]
        
        return excludedPrefixes.contains { app.bundleIdentifier.hasPrefix($0) }
    }
}

// Extension to create AppInfo without NSRunningApplication
extension AppInfo {
    init(bundleIdentifier: String, localizedName: String, executablePath: String?) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.executablePath = executablePath
    }
}

struct AppRowView: View {
    let app: AppInfo
    let isRecommended: Bool
    let onSelect: () -> Void
    
    @State private var appIcon: NSImage?
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DesignSystem.spacingMedium) {
                // App icon
                Group {
                    if let icon = appIcon {
                        Image(nsImage: icon)
                            .resizable()
                    } else {
                        Image(systemName: "app.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 32, height: 32)
                
                // App info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(app.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        if isRecommended {
                            Text("Recommended")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text(app.bundleIdentifier)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 20))
            }
            .padding(DesignSystem.spacingMedium)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            loadAppIcon()
        }
    }
    
    private func loadAppIcon() {
        guard let executablePath = app.executablePath else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let icon = NSWorkspace.shared.icon(forFile: executablePath)
            
            DispatchQueue.main.async {
                appIcon = icon
            }
        }
    }
}
```

### Task A.2.2: Update Mode Cards with App Picker
```swift
// Update Components/Cards/ModeCard.swift
// Add app picker sheet integration

struct ModeCard: View {
    // ... existing properties
    @State private var showAppPicker = false
    @State private var assignedApps: [AppAssignment] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack {
                // ... existing radio button and title
                
                Spacer()
                
                // Action buttons (show on hover or selection)
                if isHovered || isSelected {
                    HStack(spacing: 8) {
                        if mode != .raw {
                            Button("Edit") {
                                onEdit()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        
                        Button(action: { showAppPicker = true }) {
                            HStack(spacing: 4) {
                                Text("Apps")
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            
            // Stats line with assigned apps
            if isSelected {
                HStack(spacing: 12) {
                    // ... existing stats
                    
                    if !assignedApps.isEmpty {
                        Text("•")
                            .foregroundColor(.tertiaryText)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "app.fill")
                                .font(.system(size: 12))
                            
                            Text("\(assignedApps.count) app\(assignedApps.count == 1 ? "" : "s")")
                                .font(.system(size: 12))
                            
                            // Show first few app icons
                            ForEach(assignedApps.prefix(3), id: \.id) { assignment in
                                AsyncAppIcon(bundleId: assignment.appBundleId)
                                    .frame(width: 16, height: 16)
                            }
                            
                            if assignedApps.count > 3 {
                                Text("+\(assignedApps.count - 3)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .foregroundColor(.tertiaryText)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // ... existing styling
        .sheet(isPresented: $showAppPicker) {
            AppPickerView(
                isPresented: $showAppPicker,
                mode: mode,
                onAppSelected: { app in
                    Task {
                        await assignApp(app)
                    }
                }
            )
        }
        .onAppear {
            loadAssignedApps()
        }
    }
    
    private func assignApp(_ app: AppInfo) async {
        let assignment = AppAssignment(
            appInfo: app,
            mode: mode,
            isUserOverride: true
        )
        
        do {
            try await AppAssignmentManager.shared.saveAssignment(assignment)
            loadAssignedApps()
        } catch {
            print("Failed to assign app: \(error)")
        }
    }
    
    private func loadAssignedApps() {
        assignedApps = AppAssignmentManager.shared.getAssignedApps(for: mode)
    }
}

struct AsyncAppIcon: View {
    let bundleId: String
    @State private var icon: NSImage?
    
    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
            } else {
                Image(systemName: "app.fill")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadIcon()
        }
    }
    
    private func loadIcon() {
        DispatchQueue.global(qos: .userInitiated).async {
            let workspace = NSWorkspace.shared
            let appURL = workspace.urlForApplication(withBundleIdentifier: bundleId)
            
            let appIcon = appURL.map { workspace.icon(forFile: $0.path) }
            
            DispatchQueue.main.async {
                icon = appIcon
            }
        }
    }
}
```

**Test Protocol A.2**:
1. Click "Apps" button on mode card
2. Verify app picker opens with applications
3. Test search functionality
4. Assign app and verify it appears in mode card
5. Test recommended apps highlighting

**Checkpoint A.2**:
- [ ] App picker UI complete
- [ ] Mode cards show assigned apps
- [ ] Assignment process works
- [ ] Search and filtering functional
- [ ] Git commit: "App picker UI integration"

---

## Phase A.3: Recording Integration

### Task A.3.1: Update Main ViewModel for App Detection
```swift
// Update ViewModels/MainViewModel.swift
class MainViewModel: ObservableObject {
    // ... existing properties
    @Published var detectedApp: AppInfo?
    @Published var autoSelectedMode: RefinementMode?
    @Published var showModeDetectionIndicator = false
    
    private let appDetectionService = AppDetectionService.shared
    
    // ... existing methods
    
    func startRecording() {
        // Detect app before starting recording
        Task {
            let (app, recommendedMode) = await appDetectionService.detectAndRecommendMode()
            
            await MainActor.run {
                detectedApp = app
                
                if let mode = recommendedMode {
                    autoSelectedMode = mode
                    currentMode = mode
                    showModeDetectionIndicator = true
                    
                    // Hide indicator after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showModeDetectionIndicator = false
                    }
                }
                
                // Continue with existing recording logic
                isRecording = true
                recordingTime = 0
                status = "Recording..."
                
                audioService.startRecording()
                updateMenuBarState()
            }
        }
    }
    
    // ... rest of existing implementation
}
```

### Task A.3.2: Update Top Bar with Detection Indicator
```swift
// Update Components/TopBar.swift
struct TopBar: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var showCapsuleMode: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // App Title
            Text("Transcriptly")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondaryText)
            
            Spacer()
            
            // App detection indicator
            if viewModel.showModeDetectionIndicator,
               let app = viewModel.detectedApp,
               let mode = viewModel.autoSelectedMode {
                AppDetectionIndicator(app: app, mode: mode)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Capsule Button
            Button(action: { showCapsuleMode = true }) {
                Image(systemName: "capsule")
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .help("Enter Capsule Mode")
            
            // Mode Dropdown
            Picker("Mode", selection: $viewModel.currentMode) {
                ForEach(RefinementMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)
            .onChange(of: viewModel.currentMode) { newMode in
                // User override - don't auto-detect for this session
                if newMode != viewModel.autoSelectedMode {
                    viewModel.showModeDetectionIndicator = false
                }
            }
            
            // Record Button
            RecordButton(
                isRecording: viewModel.isRecording,
                recordingTime: viewModel.recordingTime,
                action: viewModel.toggleRecording
            )
        }
        .padding(.horizontal, DesignSystem.marginStandard)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(
            Divider()
                .background(Color.white.opacity(0.1)),
            alignment: .bottom
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showModeDetectionIndicator)
    }
}

struct AppDetectionIndicator: View {
    let app: AppInfo
    let mode: RefinementMode
    @State private var appIcon: NSImage?
    
    var body: some View {
        HStack(spacing: 8) {
            // App icon
            Group {
                if let icon = appIcon {
                    Image(nsImage: icon)
                        .resizable()
                } else {
                    Image(systemName: "app.fill")
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 16, height: 16)
            
            Text("\(app.displayName) → \(mode.displayName)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(6)
        .onAppear {
            loadAppIcon()
        }
    }
    
    private func loadAppIcon() {
        guard let executablePath = app.executablePath else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let icon = NSWorkspace.shared.icon(forFile: executablePath)
            
            DispatchQueue.main.async {
                appIcon = icon
            }
        }
    }
}
```

### Task A.3.3: Update Capsule Mode with App Detection
```swift
// Update Views/Capsule/CapsuleView.swift
struct CapsuleView: View {
    @ObservedObject var viewModel = MainViewModel.shared
    @State private var elapsedTime: TimeInterval = 0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 16) {
            // Record button
            Button(action: { viewModel.toggleRecording() }) {
                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(viewModel.isRecording ? .red : .white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Waveform placeholder
            if viewModel.isRecording {
                WaveformView()
                    .frame(width: 100, height: 40)
            }
            
            // App detection and mode info
            VStack(alignment: .leading, spacing: 2) {
                if viewModel.isRecording {
                    Text(formatTime(elapsedTime))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 4) {
                    if let app = viewModel.detectedApp {
                        AsyncAppIcon(bundleId: app.bundleIdentifier)
                            .frame(width: 12, height: 12)
                        
                        Text(app.displayName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("→")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Text(viewModel.currentMode.displayName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // ... rest of existing implementation
        }
        // ... existing styling
    }
    
    // ... existing helper methods
}
```

**Test Protocol A.3**:
1. Start recording in different apps
2. Verify app detection indicator appears
3. Test mode auto-selection
4. Verify manual override works
5. Test capsule mode shows app info

**Checkpoint A.3**:
- [ ] App detection during recording works
- [ ] Top bar indicator functional
- [ ] Manual override works
- [ ] Capsule mode shows app info
- [ ] Git commit: "Recording integration with app detection"

---

## Phase A.4: Learning System Integration

### Task A.4.1: Update Learning Service for App Context
```swift
// Update Services/Learning/LearningService.swift
class LearningService: ObservableObject {
    // ... existing properties
    
    func processCompletedTranscription(
        original: String,
        refined: String,
        refinementMode: RefinementMode,
        appContext: AppInfo? = nil
    ) {
        guard isLearningEnabled else { return }
        
        // Store app context for learning
        if let app = appContext {
            currentAppContext = app
        }
        
        // ... existing logic with app context
    }
    
    func submitEditReview(
        original: String,
        aiRefined: String,
        userFinal: String,
        refinementMode: RefinementMode,
        skipLearning: Bool,
        appContext: AppInfo? = nil
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
                deviceId: nil,
                appContext: appContext?.bundleIdentifier
            )
            
            try? await supabase.saveLearningSession(session)
            
            if !skipLearning {
                // Extract patterns with app context
                await patternMatcher.extractPatterns(
                    from: aiRefined,
                    to: userFinal,
                    mode: refinementMode,
                    appContext: appContext
                )
                
                // Update preferences with app context
                await preferenceProfiler.analyzePreferences(
                    original: aiRefined,
                    edited: userFinal,
                    appContext: appContext
                )
            }
            
            sessionCount += 1
            updateLearningQuality()
        }
    }
    
    // ... rest of implementation with app context threading
}
```

### Task A.4.2: Update Pattern Matcher for App Context
```swift
// Update Services/Learning/PatternMatcher.swift
class PatternMatcher {
    func extractPatterns(
        from original: String, 
        to edited: String, 
        mode: RefinementMode,
        appContext: AppInfo? = nil
    ) async {
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
                    isActive: true,
                    appContext: appContext?.bundleIdentifier
                )
                
                do {
                    try await supabase.saveOrUpdatePattern(pattern)
                } catch {
                    print("Failed to save pattern: \(error)")
                }
            }
        }
    }
    
    func applyPatterns(to text: String, mode: RefinementMode, appContext: AppInfo? = nil) async -> String {
        var result = text
        
        do {
            // Get patterns for this app context first, then general patterns
            let appSpecificPatterns = try await supabase.getActivePatterns(
                appContext: appContext?.bundleIdentifier
            )
            let generalPatterns = try await supabase.getActivePatterns(appContext: nil)
            
            // Apply app-specific patterns first (higher priority)
            for pattern in appSpecificPatterns where pattern.isReady {
                result = applyPattern(pattern, to: result, modeBonus: pattern.refinementMode == mode ? 0.1 : 0.0)
            }
            
            // Then apply general patterns
            for pattern in generalPatterns where pattern.isReady {
                result = applyPattern(pattern, to: result, modeBonus: pattern.refinementMode == mode ? 0.05 : 0.0)
            }
        } catch {
            print("Failed to apply patterns: \(error)")
        }
        
        return result
    }
    
    private func applyPattern(_ pattern: LearnedPattern, to text: String, modeBonus: Double) -> String {
        let effectiveConfidence = min(1.0, pattern.confidence + modeBonus)
        
        if effectiveConfidence > 0.6 {
            return text.replacingOccurrences(
                of: pattern.originalPhrase,
                with: pattern.correctedPhrase,
                options: [.caseInsensitive, .diacriticInsensitive]
            )
        }
        
        return text
    }
}
```

### Task A.4.3: Update Supabase for App Context Queries
```swift
// Add to SupabaseManager extensions
extension SupabaseManager {
    func getActivePatterns(appContext: String? = nil) async throws -> [LearnedPattern] {
        guard let userId = currentUser?.id else { return [] }
        
        var query = client
            .from("learned_patterns")
            .select()
            .eq("user_id", value: userId)
            .eq("is_active", value: true)
            .gte("occurrence_count", value: 3)
        
        if let appContext = appContext {
            query = query.eq("app_context", value: appContext)
        } else {
            query = query.is("app_context", value: nil)
        }
        
        let response = try await query
            .order("confidence", ascending: false)
            .execute()
        
        return try response.decoded(to: [LearnedPattern].self)
    }
    
    func getLearningSessionsForApp(_ bundleId: String) async throws -> [LearningSession] {
        guard let userId = currentUser?.id else { return [] }
        
        let response = try await client
            .from("learning_sessions")
            .select()
            .eq("user_id", value: userId)
            .eq("app_context", value: bundleId)
            .order("timestamp", ascending: false)
            .limit(50)
            .execute()
        
        return try response.decoded(to: [LearningSession].self)
    }
}
```

**Test Protocol A.4**:
1. Create patterns in different apps
2. Verify app-specific patterns apply
3. Test general patterns still work
4. Verify learning session app context
5. Test pattern priority (app-specific > general)

**Checkpoint A.4**:
- [ ] App context in learning system
- [ ] App-specific pattern application
- [ ] Learning sessions track app context
- [ ] Pattern priority system works
- [ ] Git commit: "Learning system app context integration"

---

## Phase A.5: Settings and User Control

### Task A.5.1: Add App Detection Settings
```swift
// Update Views/Settings/SettingsView.swift
struct SettingsView: View {
    @ObservedObject private var appDetectionService = AppDetectionService.shared
    @ObservedObject private var assignmentManager = AppAssignmentManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // ... existing sections
            
            // App Detection Settings
            GroupBox("App Detection") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Auto-detect refinement mode", isOn: $appDetectionService.isAutoDetectionEnabled)
                    
                    Text("Automatically selects the best refinement mode based on the active application")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if appDetectionService.isAutoDetectionEnabled {
                        HStack {
                            Text("Assigned Apps: \(assignmentManager.userAssignments.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Manage App Assignments") {
                                // Navigate to Transcription section
                                // This could be a notification or direct navigation
                            }
                            .font(.caption)
                            .buttonStyle(.link)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // ... existing sections
        }
        // ... rest of implementation
    }
}
```

### Task A.5.2: Add App Assignment Management View
```swift
// Views/AppSelection/AppAssignmentSheet.swift
struct AppAssignmentManagementView: View {
    @ObservedObject private var assignmentManager = AppAssignmentManager.shared
    @State private var showingRemoveConfirmation: AppAssignment?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("App Assignments")
                .font(.title2)
                .fontWeight(.semibold)
            
            if assignmentManager.userAssignments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "app.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No app assignments")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Use the 'Apps' button on each refinement mode to assign applications")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(RefinementMode.allCases, id: \.self) { mode in
                        let assignments = assignmentManager.getAssignedApps(for: mode)
                        
                        if !assignments.isEmpty {
                            Section(mode.displayName) {
                                ForEach(assignments) { assignment in
                                    AssignmentRowView(
                                        assignment: assignment,
                                        onRemove: {
                                            showingRemoveConfirmation = assignment
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button("Reset All Assignments") {
                    Task {
                        try? await assignmentManager.resetAllAssignments()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(assignmentManager.userAssignments.isEmpty)
                
                Spacer()
            }
        }
        .padding()
        .frame(width: 500, height: 400)
        .alert("Remove Assignment", isPresented: .constant(showingRemoveConfirmation != nil)) {
            Button("Cancel", role: .cancel) {
                showingRemoveConfirmation = nil
            }
            
            Button("Remove", role: .destructive) {
                if let assignment = showingRemoveConfirmation {
                    Task {
                        try? await assignmentManager.removeAssignment(
                            for: AppInfo(
                                bundleIdentifier: assignment.appBundleId,
                                localizedName: assignment.appName,
                                executablePath: nil
                            )
                        )
                    }
                }
                showingRemoveConfirmation = nil
            }
        } message: {
            if let assignment = showingRemoveConfirmation {
                Text("Are you sure you want to remove the assignment for \(assignment.appName)?")
            }
        }
    }
}

struct AssignmentRowView: View {
    let assignment: AppAssignment
    let onRemove: () -> Void
    @State private var appIcon: NSImage?
    
    var body: some View {
        HStack {
            // App icon
            Group {
                if let icon = appIcon {
                    Image(nsImage: icon)
                        .resizable()
                } else {
                    Image(systemName: "app.fill")
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.appName)
                    .font(.system(size: 14, weight: .medium))
                
                Text(assignment.appBundleId)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Remove") {
                onRemove()
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)
        }
        .onAppear {
            loadAppIcon()
        }
    }
    
    private func loadAppIcon() {
        DispatchQueue.global(qos: .userInitiated).async {
            let workspace = NSWorkspace.shared
            let appURL = workspace.urlForApplication(withBundleIdentifier: assignment.appBundleId)
            
            let icon = appURL.map { workspace.icon(forFile: $0.path) }
            
            DispatchQueue.main.async {
                appIcon = icon
            }
        }
    }
}
```

**Test Protocol A.5**:
1. Toggle app detection in settings
2. Verify toggle disables auto-detection
3. Test app assignment management view
4. Remove assignments and verify they're gone
5. Test reset all assignments

**Checkpoint A.5**:
- [ ] Settings integration complete
- [ ] App detection toggle works
- [ ] Assignment management functional
- [ ] Remove and reset operations work
- [ ] Git commit: "Settings and user control for app detection"

---

## Final Integration and Testing

### Task A.6.1: Complete Integration Testing
1. **Full Workflow Test**: Record in 5 different apps, verify auto-mode selection
2. **Manual Override Test**: Override auto-selection and verify it's respected
3. **Learning Integration Test**: Create patterns in different apps, verify app-specific application
4. **Sync Test**: Test with/without Supabase authentication
5. **Edge Cases Test**: Test with unknown apps, system apps, multiple windows

### Task A.6.2: Performance Optimization
- App detection should not delay recording start
- Icon loading should be async and cached
- Assignment lookups should be <50ms
- UI should remain responsive during app scanning

### Task A.6.3: Documentation Update
```markdown
# Update CLAUDE.md and README.md
## App Detection & Assignment Features Added:
- Automatic app detection during recording
- Manual app assignment to refinement modes
- App-specific learning and pattern application
- User control over auto-detection
- Comprehensive settings and management UI

## Technical Implementation:
- AppDetectionService for active app detection
- AppAssignmentManager for Supabase-synced assignments
- App context integration throughout learning system
- Built-in defaults for common applications
```

**Phase A Final Checkpoint**:
- [ ] All app detection features working
- [ ] Manual assignment system complete
- [ ] Learning system app-context aware
- [ ] Settings and user control implemented
- [ ] Performance requirements met
- [ ] No regressions in existing features
- [ ] Git commit: "Complete app detection and assignment system"
- [ ] Tag: v1.1.0-app-detection-complete

## Success Metrics

### Functionality ✅
- Auto-detection works for 95%+ of common apps
- Manual assignments save and sync correctly
- App-specific learning improves refinement accuracy
- User can disable/override any automatic behavior

### User Experience ✅
- Clear visual feedback when auto-mode switching occurs
- Easy app assignment workflow
- No confusion about current mode selection
- Helpful but never intrusive

### Technical ✅
- No impact on recording performance
- Reliable app detection across macOS versions
- Proper integration with existing learning system
- Clean separation of concerns in codebase