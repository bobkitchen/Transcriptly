# Transcriptly Phase 11 - System Reliability & Feature Expansion - Complete Task List

## Overview
This phase addresses critical system reliability issues while expanding Transcriptly's capabilities with comprehensive file transcription, enhanced learning system, and improved user experience. Implementation includes testing gates between each major feature to ensure quality.

## Phase 11.0: Setup and Architecture

### Task 11.0.1: Create Phase 11 Branch
```bash
git checkout main
git pull origin main
git checkout -b phase-11-system-reliability
git push -u origin phase-11-system-reliability
```

### Task 11.0.2: Create Feature Architecture
```
Transcriptly/
├── Services/
│   ├── KeyboardShortcuts/
│   │   ├── ShortcutManager.swift
│   │   ├── ConflictDetector.swift
│   │   └── ShortcutRecorder.swift
│   ├── Sync/
│   │   ├── SyncMonitor.swift
│   │   ├── OfflineQueue.swift
│   │   └── SyncDiagnostics.swift
│   ├── FileTranscription/
│   │   ├── FileTranscriptionService.swift
│   │   ├── AppleSpeechTranscriber.swift
│   │   └── CloudTranscriber.swift
│   └── Learning/ (existing, to be enhanced)
├── Views/
│   ├── FileTranscription/
│   │   ├── FileTranscriptionView.swift
│   │   ├── TranscriptionProgressView.swift
│   │   └── FileDropZone.swift
│   ├── Settings/
│   │   ├── SyncStatusView.swift
│   │   ├── ShortcutSettingsView.swift
│   │   └── LearningDashboard.swift
│   └── Learning/ (to be activated)
└── Models/
    ├── FileTranscription/
    │   ├── TranscriptionJob.swift
    │   ├── FileInfo.swift
    │   └── TranscriptionResult.swift
    └── Sync/
        ├── SyncStatus.swift
        ├── SyncOperation.swift
        └── OfflineOperation.swift
```

### Task 11.0.3: Update Dependencies
```swift
// Add required imports for file handling and enhanced sync
import AVFoundation  // For audio/video file processing
import Speech        // Enhanced Speech framework usage
import UniformTypeIdentifiers  // For file type validation
```

**Checkpoint 11.0**:
- [ ] Branch created and architecture planned
- [ ] File structure created
- [ ] Dependencies updated
- [ ] Git commit: "Setup Phase 11 architecture"

---

## Phase 11.1: Enhanced Keyboard Shortcut System

### Task 11.1.1: Create Advanced Shortcut Manager
```swift
// Services/KeyboardShortcuts/ShortcutManager.swift
import Cocoa
import Carbon

@MainActor
class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()
    
    @Published var currentShortcuts: [ShortcutBinding] = []
    @Published var hasConflicts: Bool = false
    
    private let conflictDetector = ConflictDetector()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private init() {
        setupDefaultShortcuts()
        setupEventTap()
    }
    
    func setupDefaultShortcuts() {
        currentShortcuts = [
            ShortcutBinding(
                id: "primary_record",
                keyCode: kVK_ANSI_M,
                modifiers: .command,
                action: .toggleRecording,
                name: "Start/Stop Recording",
                isCustomizable: true,
                isDefault: true
            ),
            ShortcutBinding(
                id: "mode_raw",
                keyCode: kVK_ANSI_1,
                modifiers: .command,
                action: .switchMode(.raw),
                name: "Raw Transcription Mode",
                isCustomizable: true
            ),
            ShortcutBinding(
                id: "mode_cleanup",
                keyCode: kVK_ANSI_2,
                modifiers: .command,
                action: .switchMode(.cleanup),
                name: "Clean-up Mode",
                isCustomizable: true
            ),
            ShortcutBinding(
                id: "mode_email",
                keyCode: kVK_ANSI_3,
                modifiers: .command,
                action: .switchMode(.email),
                name: "Email Mode",
                isCustomizable: true
            ),
            ShortcutBinding(
                id: "mode_messaging",
                keyCode: kVK_ANSI_4,
                modifiers: .command,
                action: .switchMode(.messaging),
                name: "Messaging Mode",
                isCustomizable: true
            ),
            ShortcutBinding(
                id: "cancel_recording",
                keyCode: kVK_Escape,
                modifiers: [],
                action: .cancelRecording,
                name: "Cancel Recording",
                isCustomizable: false
            )
        ]
        
        registerAllShortcuts()
    }
    
    func updateShortcut(_ shortcutId: String, keyCode: Int, modifiers: NSEvent.ModifierFlags) async -> ShortcutUpdateResult {
        // Check for conflicts before updating
        let conflicts = await conflictDetector.detectConflicts(keyCode: keyCode, modifiers: modifiers)
        
        if !conflicts.isEmpty {
            return .conflictDetected(conflicts)
        }
        
        // Update shortcut
        if let index = currentShortcuts.firstIndex(where: { $0.id == shortcutId }) {
            currentShortcuts[index].keyCode = keyCode
            currentShortcuts[index].modifiers = modifiers
            
            saveShortcuts()
            registerAllShortcuts()
            
            return .success
        }
        
        return .notFound
    }
    
    func testShortcut(_ shortcutId: String) -> Bool {
        guard let shortcut = currentShortcuts.first(where: { $0.id == shortcutId }) else {
            return false
        }
        
        // Simulate shortcut execution for testing
        executeShortcutAction(shortcut.action)
        return true
    }
    
    func resetToDefaults() {
        setupDefaultShortcuts()
        saveShortcuts()
    }
    
    func resetShortcut(_ shortcutId: String) {
        setupDefaultShortcuts()
        if let defaultShortcut = currentShortcuts.first(where: { $0.id == shortcutId }) {
            updateShortcut(shortcutId, keyCode: defaultShortcut.keyCode, modifiers: defaultShortcut.modifiers)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let manager = Unmanaged<ShortcutManager>.fromOpaque(refcon!).takeUnretainedValue()
                return manager.handleKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("Failed to create event tap")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }
        
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue))
        
        // Check if this matches any of our shortcuts
        for shortcut in currentShortcuts {
            if shortcut.keyCode == keyCode && shortcut.modifiers == modifiers {
                executeShortcutAction(shortcut.action)
                return nil // Consume the event
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func executeShortcutAction(_ action: ShortcutAction) {
        Task { @MainActor in
            switch action {
            case .toggleRecording:
                NotificationCenter.default.post(name: .toggleRecording, object: nil)
            case .switchMode(let mode):
                NotificationCenter.default.post(name: .switchRefinementMode, object: mode)
            case .cancelRecording:
                NotificationCenter.default.post(name: .cancelRecording, object: nil)
            }
        }
    }
    
    private func registerAllShortcuts() {
        // Implementation for registering shortcuts with system
    }
    
    private func saveShortcuts() {
        do {
            let data = try JSONEncoder().encode(currentShortcuts)
            UserDefaults.standard.set(data, forKey: "customShortcuts")
        } catch {
            print("Failed to save shortcuts: \(error)")
        }
    }
    
    deinit {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }
}

// MARK: - Supporting Types

struct ShortcutBinding: Codable, Identifiable {
    let id: String
    var keyCode: Int
    var modifiers: NSEvent.ModifierFlags
    let action: ShortcutAction
    let name: String
    let isCustomizable: Bool
    var isDefault: Bool = false
    
    var displayString: String {
        var result = ""
        
        if modifiers.contains(.command) { result += "⌘" }
        if modifiers.contains(.option) { result += "⌥" }
        if modifiers.contains(.shift) { result += "⇧" }
        if modifiers.contains(.control) { result += "⌃" }
        
        result += keyCodeToString(keyCode)
        return result
    }
    
    private func keyCodeToString(_ keyCode: Int) -> String {
        switch keyCode {
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_Escape: return "⎋"
        default: return String(UnicodeScalar(keyCode + 65) ?? "?")
        }
    }
}

enum ShortcutAction: Codable {
    case toggleRecording
    case switchMode(RefinementMode)
    case cancelRecording
}

enum ShortcutUpdateResult {
    case success
    case conflictDetected([ConflictInfo])
    case notFound
    case invalidKeyCode
}

// Notification extensions
extension Notification.Name {
    static let toggleRecording = Notification.Name("toggleRecording")
    static let switchRefinementMode = Notification.Name("switchRefinementMode")
    static let cancelRecording = Notification.Name("cancelRecording")
}
```

### Task 11.1.2: Create Conflict Detection System
```swift
// Services/KeyboardShortcuts/ConflictDetector.swift
import Cocoa
import ApplicationServices

@MainActor
class ConflictDetector: ObservableObject {
    
    func detectConflicts(keyCode: Int, modifiers: NSEvent.ModifierFlags) async -> [ConflictInfo] {
        var conflicts: [ConflictInfo] = []
        
        // Check system shortcuts
        let systemConflicts = checkSystemShortcuts(keyCode: keyCode, modifiers: modifiers)
        conflicts.append(contentsOf: systemConflicts)
        
        // Check running applications
        let appConflicts = await checkRunningApplications(keyCode: keyCode, modifiers: modifiers)
        conflicts.append(contentsOf: appConflicts)
        
        return conflicts
    }
    
    private func checkSystemShortcuts(keyCode: Int, modifiers: NSEvent.ModifierFlags) -> [ConflictInfo] {
        var conflicts: [ConflictInfo] = []
        
        // Known system shortcuts that commonly conflict
        let systemShortcuts: [(Int, NSEvent.ModifierFlags, String, String)] = [
            (kVK_Space, [.command], "Spotlight", "Show Spotlight search"),
            (kVK_Tab, [.command], "System", "Switch between applications"),
            (kVK_ANSI_W, [.command], "System", "Close window"),
            (kVK_ANSI_Q, [.command], "System", "Quit application"),
            (kVK_ANSI_N, [.command], "System", "New window/document"),
            (kVK_ANSI_S, [.command], "System", "Save"),
            (kVK_ANSI_A, [.command], "System", "Select all"),
            (kVK_ANSI_C, [.command], "System", "Copy"),
            (kVK_ANSI_V, [.command], "System", "Paste"),
            (kVK_ANSI_Z, [.command], "System", "Undo"),
            (kVK_ANSI_3, [.command, .shift], "System", "Screenshot selected area"),
            (kVK_ANSI_4, [.command, .shift], "System", "Screenshot to clipboard"),
            (kVK_ANSI_5, [.command, .shift], "System", "Screenshot or recording options")
        ]
        
        for (sysKeyCode, sysModifiers, app, description) in systemShortcuts {
            if sysKeyCode == keyCode && sysModifiers == modifiers {
                conflicts.append(ConflictInfo(
                    appName: app,
                    shortcutDescription: description,
                    severity: .high,
                    canBeDisabled: app != "System"
                ))
            }
        }
        
        return conflicts
    }
    
    private func checkRunningApplications(keyCode: Int, modifiers: NSEvent.ModifierFlags) async -> [ConflictInfo] {
        var conflicts: [ConflictInfo] = []
        
        // Get running applications
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            guard let bundleId = app.bundleIdentifier,
                  bundleId != Bundle.main.bundleIdentifier else { continue }
            
            // Check known shortcuts for popular applications
            let appConflicts = checkKnownAppShortcuts(bundleId: bundleId, keyCode: keyCode, modifiers: modifiers)
            conflicts.append(contentsOf: appConflicts)
        }
        
        return conflicts
    }
    
    private func checkKnownAppShortcuts(bundleId: String, keyCode: Int, modifiers: NSEvent.ModifierFlags) -> [ConflictInfo] {
        let knownShortcuts: [String: [(Int, NSEvent.ModifierFlags, String)]] = [
            "com.apple.Safari": [
                (kVK_ANSI_R, [.command], "Reload page"),
                (kVK_ANSI_D, [.command], "Add bookmark"),
                (kVK_ANSI_L, [.command], "Focus address bar"),
                (kVK_ANSI_T, [.command], "New tab"),
                (kVK_ANSI_W, [.command], "Close tab")
            ],
            "com.google.Chrome": [
                (kVK_ANSI_R, [.command], "Reload page"),
                (kVK_ANSI_D, [.command], "Bookmark page"),
                (kVK_ANSI_L, [.command], "Focus address bar"),
                (kVK_ANSI_T, [.command], "New tab")
            ],
            "com.microsoft.VSCode": [
                (kVK_ANSI_P, [.command, .shift], "Command palette"),
                (kVK_ANSI_F, [.command, .shift], "Find in files"),
                (kVK_ANSI_N, [.command], "New file")
            ],
            "com.apple.dt.Xcode": [
                (kVK_ANSI_B, [.command], "Build"),
                (kVK_ANSI_R, [.command], "Run"),
                (kVK_ANSI_U, [.command], "Test")
            ]
        ]
        
        guard let appShortcuts = knownShortcuts[bundleId] else { return [] }
        
        var conflicts: [ConflictInfo] = []
        
        for (shortcutKeyCode, shortcutModifiers, description) in appShortcuts {
            if shortcutKeyCode == keyCode && shortcutModifiers == modifiers {
                let appName = getAppName(from: bundleId)
                conflicts.append(ConflictInfo(
                    appName: appName,
                    shortcutDescription: description,
                    severity: .medium,
                    canBeDisabled: true
                ))
            }
        }
        
        return conflicts
    }
    
    private func getAppName(from bundleId: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId),
           let bundle = Bundle(url: url),
           let name = bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String ??
                     bundle.infoDictionary?["CFBundleDisplayName"] as? String {
            return name
        }
        
        // Fallback to extracting from bundle ID
        return bundleId.components(separatedBy: ".").last?.capitalized ?? bundleId
    }
}

struct ConflictInfo: Identifiable {
    let id = UUID()
    let appName: String
    let shortcutDescription: String
    let severity: ConflictSeverity
    let canBeDisabled: Bool
}

enum ConflictSeverity {
    case low, medium, high
    
    var color: Color {
        switch self {
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var systemImage: String {
        switch self {
        case .low: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        }
    }
}
```

### Task 11.1.3: Create Shortcut Recorder Component
```swift
// Services/KeyboardShortcuts/ShortcutRecorder.swift
import SwiftUI
import Cocoa

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var keyCode: Int
    @Binding var modifiers: NSEvent.ModifierFlags
    let onShortcutChange: (Int, NSEvent.ModifierFlags) -> Void
    
    func makeNSView(context: Context) -> ShortcutRecorderView {
        let view = ShortcutRecorderView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateNSView(_ nsView: ShortcutRecorderView, context: Context) {
        nsView.currentKeyCode = keyCode
        nsView.currentModifiers = modifiers
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ShortcutRecorderDelegate {
        let parent: ShortcutRecorder
        
        init(_ parent: ShortcutRecorder) {
            self.parent = parent
        }
        
        func shortcutRecorderDidChange(keyCode: Int, modifiers: NSEvent.ModifierFlags) {
            parent.keyCode = keyCode
            parent.modifiers = modifiers
            parent.onShortcutChange(keyCode, modifiers)
        }
    }
}

protocol ShortcutRecorderDelegate: AnyObject {
    func shortcutRecorderDidChange(keyCode: Int, modifiers: NSEvent.ModifierFlags)
}

class ShortcutRecorderView: NSView {
    weak var delegate: ShortcutRecorderDelegate?
    
    var currentKeyCode: Int = 0 {
        didSet { needsDisplay = true }
    }
    
    var currentModifiers: NSEvent.ModifierFlags = [] {
        didSet { needsDisplay = true }
    }
    
    private var isRecording = false
    private var monitor: Any?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.controlAccentColor.cgColor
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func becomeFirstResponder() -> Bool {
        startRecording()
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        stopRecording()
        return super.resignFirstResponder()
    }
    
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }
    
    private func startRecording() {
        isRecording = true
        needsDisplay = true
        
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil // Consume the event
        }
    }
    
    private func stopRecording() {
        isRecording = false
        needsDisplay = true
        
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard isRecording else { return }
        
        if event.type == .keyDown {
            let keyCode = Int(event.keyCode)
            let modifiers = event.modifierFlags.intersection([.command, .option, .shift, .control])
            
            // Require at least one modifier key
            if !modifiers.isEmpty {
                currentKeyCode = keyCode
                currentModifiers = modifiers
                delegate?.shortcutRecorderDidChange(keyCode: keyCode, modifiers: modifiers)
                stopRecording()
                window?.makeFirstResponder(nil)
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor.controlBackgroundColor.setFill()
        dirtyRect.fill()
        
        let text: String
        let textColor: NSColor
        
        if isRecording {
            text = "Press shortcut keys..."
            textColor = .systemBlue
        } else if currentKeyCode > 0 {
            text = formatShortcut(keyCode: currentKeyCode, modifiers: currentModifiers)
            textColor = .labelColor
        } else {
            text = "Click to record shortcut"
            textColor = .secondaryLabelColor
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: textColor
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textRect = NSRect(
            x: 10,
            y: (bounds.height - attributedString.size().height) / 2,
            width: bounds.width - 20,
            height: attributedString.size().height
        )
        
        attributedString.draw(in: textRect)
    }
    
    private func formatShortcut(keyCode: Int, modifiers: NSEvent.ModifierFlags) -> String {
        var result = ""
        
        if modifiers.contains(.command) { result += "⌘" }
        if modifiers.contains(.option) { result += "⌥" }
        if modifiers.contains(.shift) { result += "⇧" }
        if modifiers.contains(.control) { result += "⌃" }
        
        result += keyCodeToString(keyCode)
        return result
    }
    
    private func keyCodeToString(_ keyCode: Int) -> String {
        switch keyCode {
        case kVK_ANSI_A...kVK_ANSI_Z:
            return String(Character(UnicodeScalar(keyCode - kVK_ANSI_A + 65)!))
        case kVK_ANSI_0...kVK_ANSI_9:
            return String(keyCode - kVK_ANSI_0)
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Escape: return "Escape"
        case kVK_Delete: return "Delete"
        case kVK_Tab: return "Tab"
        default: return "Key \(keyCode)"
        }
    }
}
```

### Task 11.1.4: Create Shortcut Settings View
```swift
// Views/Settings/ShortcutSettingsView.swift
struct ShortcutSettingsView: View {
    @ObservedObject private var shortcutManager = ShortcutManager.shared
    @ObservedObject private var conflictDetector = ConflictDetector()
    
    @State private var editingShortcut: String?
    @State private var showingConflicts: [ConflictInfo] = []
    @State private var showConflictAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
            Text("Keyboard Shortcuts")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: DesignSystem.spacingMedium) {
                ForEach(shortcutManager.currentShortcuts) { shortcut in
                    ShortcutRowView(
                        shortcut: shortcut,
                        isEditing: editingShortcut == shortcut.id,
                        onEdit: { 
                            editingShortcut = shortcut.id
                        },
                        onSave: { keyCode, modifiers in
                            Task {
                                let result = await shortcutManager.updateShortcut(
                                    shortcut.id, 
                                    keyCode: keyCode, 
                                    modifiers: modifiers
                                )
                                
                                await MainActor.run {
                                    switch result {
                                    case .success:
                                        editingShortcut = nil
                                    case .conflictDetected(let conflicts):
                                        showingConflicts = conflicts
                                        showConflictAlert = true
                                    case .notFound, .invalidKeyCode:
                                        // Handle error
                                        break
                                    }
                                }
                            }
                        },
                        onCancel: {
                            editingShortcut = nil
                        },
                        onTest: {
                            let success = shortcutManager.testShortcut(shortcut.id)
                            // Show test feedback
                        },
                        onReset: {
                            shortcutManager.resetShortcut(shortcut.id)
                        }
                    )
                }
            }
            
            HStack {
                Button("Reset All to Defaults") {
                    shortcutManager.resetToDefaults()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Import Shortcuts") {
                    // TODO: Implement import
                }
                .buttonStyle(.bordered)
                
                Button("Export Shortcuts") {
                    // TODO: Implement export
                }
                .buttonStyle(.bordered)
            }
        }
        .alert("Shortcut Conflicts Detected", isPresented: $showConflictAlert) {
            Button("Cancel", role: .cancel) {
                editingShortcut = nil
            }
            Button("Use Anyway", role: .destructive) {
                // Force update despite conflicts
                editingShortcut = nil
            }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text("This shortcut conflicts with:")
                ForEach(showingConflicts) { conflict in
                    HStack {
                        Image(systemName: conflict.severity.systemImage)
                            .foregroundColor(conflict.severity.color)
                        Text("\(conflict.appName): \(conflict.shortcutDescription)")
                    }
                }
            }
        }
    }
}

struct ShortcutRowView: View {
    let shortcut: ShortcutBinding
    let isEditing: Bool
    let onEdit: () -> Void
    let onSave: (Int, NSEvent.ModifierFlags) -> Void
    let onCancel: () -> Void
    let onTest: () -> Void
    let onReset: () -> Void
    
    @State private var tempKeyCode: Int = 0
    @State private var tempModifiers: NSEvent.ModifierFlags = []
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shortcut.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                if !shortcut.isCustomizable {
                    Text("Cannot be changed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isEditing {
                ShortcutRecorder(
                    keyCode: $tempKeyCode,
                    modifiers: $tempModifiers,
                    onShortcutChange: { keyCode, modifiers in
                        tempKeyCode = keyCode
                        tempModifiers = modifiers
                    }
                )
                .frame(width: 200, height: 30)
                
                Button("Save") {
                    onSave(tempKeyCode, tempModifiers)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
            } else {
                Text(shortcut.displayString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                
                if shortcut.isCustomizable {
                    Button("Edit") {
                        tempKeyCode = shortcut.keyCode
                        tempModifiers = shortcut.modifiers
                        onEdit()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Test") {
                        onTest()
                    }
                    .buttonStyle(.bordered)
                    
                    if !shortcut.isDefault {
                        Button("Reset") {
                            onReset()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(DesignSystem.spacingMedium)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}
```

**Test Protocol 11.1**:
1. Test ⌘M shortcut works globally without conflicts
2. Verify conflict detection identifies specific apps
3. Test shortcut recorder with various key combinations
4. Verify shortcut testing functionality works
5. Test reset to defaults restores ⌘M

**Testing Gate 11.1**: User confirms all shortcuts work reliably without conflicts and can customize them successfully.

**Checkpoint 11.1**:
- [ ] ⌘M shortcut implemented and working
- [ ] Enhanced conflict detection with app identification
- [ ] Working shortcut recorder with live testing
- [ ] Settings UI complete and functional
- [ ] Git commit: "Implement enhanced keyboard shortcut system"

---

## Phase 11.2: Supabase Sync Monitoring & Management

### Task 11.2.1: Create Sync Monitoring Service
```swift
// Services/Sync/SyncMonitor.swift
import Foundation
import Combine

@MainActor
class SyncMonitor: ObservableObject {
    static let shared = SyncMonitor()
    
    @Published var connectionStatus: ConnectionStatus = .unknown
    @Published var lastSyncTime: Date?
    @Published var syncProgress: SyncProgress?
    @Published var isManualSyncInProgress = false
    @Published var hasOfflineOperations = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared
    private let offlineQueue = OfflineQueue.shared
    private let diagnostics = SyncDiagnostics()
    
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    
    private init() {
        setupMonitoring()
        startPeriodicSync()
    }
    
    func setupMonitoring() {
        // Monitor Supabase connection status
        supabase.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                self?.updateConnectionStatus()
            }
            .store(in: &cancellables)
        
        // Monitor offline queue
        offlineQueue.$pendingOperations
            .sink { [weak self] operations in
                self?.hasOfflineOperations = !operations.isEmpty
            }
            .store(in: &cancellables)
        
        // Check initial status
        updateConnectionStatus()
    }
    
    func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.performBackgroundSync()
            }
        }
    }
    
    func manualSync() async {
        guard !isManualSyncInProgress else { return }
        
        isManualSyncInProgress = true
        errorMessage = nil
        
        do {
            // Test connection
            connectionStatus = .connecting
            let isConnected = await testConnection()
            
            if isConnected {
                connectionStatus = .connected
                
                // Sync offline operations
                await offlineQueue.processQueue()
                
                // Download latest data
                await downloadLatestData()
                
                lastSyncTime = Date()
                errorMessage = nil
            } else {
                connectionStatus = .disconnected
                errorMessage = "Unable to connect to sync service"
            }
        } catch {
            connectionStatus = .error
            errorMessage = error.localizedDescription
        }
        
        isManualSyncInProgress = false
    }
    
    func resetSync() async {
        // Clear local cache
        await supabase.clearAllCachedData()
        
        // Clear offline queue
        offlineQueue.clearQueue()
        
        // Reset sync state
        lastSyncTime = nil
        errorMessage = nil
        
        // Trigger fresh sync
        await manualSync()
    }
    
    func exportData() async -> URL? {
        do {
            let exportData = SyncExportData(
                learningPatterns: try await supabase.getAllLearnedPatterns(),
                learningPreferences: try await supabase.getPreferences(),
                appAssignments: try await supabase.getAllAppAssignments(),
                exportDate: Date(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(exportData)
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Transcriptly_Export_\(Date().ISO8601Format()).json")
            
            try data.write(to: tempURL)
            return tempURL
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            return nil
        }
    }
    
    func importData(from url: URL) async -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let importData = try decoder.decode(SyncExportData.self, from: data)
            
            // Import patterns
            for pattern in importData.learningPatterns {
                try await supabase.saveOrUpdatePattern(pattern)
            }
            
            // Import preferences
            for preference in importData.learningPreferences {
                try await supabase.saveOrUpdatePreference(preference)
            }
            
            // Import app assignments
            for assignment in importData.appAssignments {
                try await supabase.saveAppAssignment(assignment)
            }
            
            lastSyncTime = Date()
            return true
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func updateConnectionStatus() {
        Task {
            if supabase.isAuthenticated {
                connectionStatus = await testConnection() ? .connected : .disconnected
            } else {
                connectionStatus = .offline
            }
        }
    }
    
    private func testConnection() async -> Bool {
        do {
            // Simple connection test
            _ = try await supabase.client.from("users").select("id").limit(1).execute()
            return true
        } catch {
            return false
        }
    }
    
    private func performBackgroundSync() async {
        guard connectionStatus == .connected else { return }
        
        do {
            // Sync offline operations
            await offlineQueue.processQueue()
            
            // Update last sync time if successful
            if !hasOfflineOperations {
                lastSyncTime = Date()
            }
        } catch {
            // Log error but don't update UI for background sync failures
            print("Background sync failed: \(error)")
        }
    }
    
    private func downloadLatestData() async {
        do {
            // Download latest patterns
            _ = try await supabase.getActivePatterns()
            
            // Download latest preferences
            _ = try await supabase.getPreferences()
            
            // Download latest app assignments
            _ = try await supabase.getAllAppAssignments()
        } catch {
            print("Failed to download latest data: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum ConnectionStatus {
    case unknown, connecting, connected, disconnected, offline, error
    
    var statusText: String {
        switch self {
        case .unknown: return "Unknown"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .offline: return "Offline"
        case .error: return "Error"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .unknown: return .gray
        case .connecting: return .blue
        case .connected: return .green
        case .disconnected: return .orange
        case .offline: return .gray
        case .error: return .red
        }
    }
    
    var statusIcon: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .connecting: return "arrow.triangle.2.circlepath"
        case .connected: return "checkmark.circle.fill"
        case .disconnected: return "exclamationmark.triangle.fill"
        case .offline: return "wifi.slash"
        case .error: return "xmark.circle.fill"
        }
    }
}

struct SyncProgress {
    let operation: String
    let progress: Double
    let itemsProcessed: Int
    let totalItems: Int
}

struct SyncExportData: Codable {
    let learningPatterns: [LearnedPattern]
    let learningPreferences: [UserPreference]
    let appAssignments: [AppAssignment]
    let exportDate: Date
    let appVersion: String
}
```

### Task 11.2.2: Create Offline Queue Manager
```swift
// Services/Sync/OfflineQueue.swift
import Foundation

@MainActor
class OfflineQueue: ObservableObject {
    static let shared = OfflineQueue()
    
    @Published var pendingOperations: [OfflineOperation] = []
    @Published var isProcessingQueue = false
    @Published var lastProcessedOperation: OfflineOperation?
    
    private let supabase = SupabaseManager.shared
    private let queueKey = "offlineOperationQueue"
    
    private init() {
        loadQueue()
    }
    
    func addOperation(_ operation: OfflineOperation) {
        pendingOperations.append(operation)
        saveQueue()
    }
    
    func processQueue() async {
        guard !isProcessingQueue, !pendingOperations.isEmpty else { return }
        
        isProcessingQueue = true
        
        var operationsToRemove: [UUID] = []
        
        for operation in pendingOperations {
            do {
                let success = try await processOperation(operation)
                if success {
                    operationsToRemove.append(operation.id)
                    lastProcessedOperation = operation
                }
            } catch {
                print("Failed to process operation \(operation.id): \(error)")
                // Mark operation as failed but don't remove it
                operation.lastAttempt = Date()
                operation.attemptCount += 1
                
                // Remove operations that have failed too many times
                if operation.attemptCount >= 5 {
                    operationsToRemove.append(operation.id)
                }
            }
        }
        
        // Remove successful operations
        pendingOperations.removeAll { operationsToRemove.contains($0.id) }
        saveQueue()
        
        isProcessingQueue = false
    }
    
    func clearQueue() {
        pendingOperations.removeAll()
        saveQueue()
    }
    
    func retryOperation(_ operationId: UUID) async {
        guard let operation = pendingOperations.first(where: { $0.id == operationId }) else { return }
        
        do {
            let success = try await processOperation(operation)
            if success {
                pendingOperations.removeAll { $0.id == operationId }
                saveQueue()
            }
        } catch {
            operation.lastAttempt = Date()
            operation.attemptCount += 1
            saveQueue()
        }
    }
    
    // MARK: - Private Methods
    
    private func processOperation(_ operation: OfflineOperation) async throws -> Bool {
        switch operation.type {
        case .saveLearningSession(let session):
            try await supabase.saveLearningSession(session)
            return true
            
        case .savePattern(let pattern):
            try await supabase.saveOrUpdatePattern(pattern)
            return true
            
        case .savePreference(let preference):
            try await supabase.saveOrUpdatePreference(preference)
            return true
            
        case .saveAppAssignment(let assignment):
            try await supabase.saveAppAssignment(assignment)
            return true
            
        case .deletePattern(let patternId):
            // Implement pattern deletion
            return true
        }
    }
    
    private func saveQueue() {
        do {
            let data = try JSONEncoder().encode(pendingOperations)
            UserDefaults.standard.set(data, forKey: queueKey)
        } catch {
            print("Failed to save offline queue: \(error)")
        }
    }
    
    private func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else { return }
        
        do {
            pendingOperations = try JSONDecoder().decode([OfflineOperation].self, from: data)
        } catch {
            print("Failed to load offline queue: \(error)")
            pendingOperations = []
        }
    }
}

// MARK: - Offline Operation Types

class OfflineOperation: Codable, Identifiable, ObservableObject {
    let id = UUID()
    let type: OfflineOperationType
    let createdAt: Date
    var lastAttempt: Date?
    var attemptCount: Int = 0
    
    init(type: OfflineOperationType) {
        self.type = type
        self.createdAt = Date()
    }
    
    var displayName: String {
        switch type {
        case .saveLearningSession: return "Save Learning Session"
        case .savePattern: return "Save Learning Pattern"
        case .savePreference: return "Save User Preference"
        case .saveAppAssignment: return "Save App Assignment"
        case .deletePattern: return "Delete Pattern"
        }
    }
    
    var statusText: String {
        if attemptCount == 0 {
            return "Pending"
        } else {
            return "Retry \(attemptCount)/5"
        }
    }
}

enum OfflineOperationType: Codable {
    case saveLearningSession(LearningSession)
    case savePattern(LearnedPattern)
    case savePreference(UserPreference)
    case saveAppAssignment(AppAssignment)
    case deletePattern(UUID)
}
```

### Task 11.2.3: Create Sync Status View
```swift
// Views/Settings/SyncStatusView.swift
struct SyncStatusView: View {
    @ObservedObject private var syncMonitor = SyncMonitor.shared
    @ObservedObject private var offlineQueue = OfflineQueue.shared
    @State private var showingExportPicker = false
    @State private var showingImportPicker = false
    @State private var exportURL: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
            // Connection Status
            connectionStatusSection
            
            Divider()
            
            // Sync Controls
            syncControlsSection
            
            Divider()
            
            // Offline Queue
            offlineQueueSection
            
            Divider()
            
            // Data Management
            dataManagementSection
        }
    }
    
    private var connectionStatusSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            Text("Connection Status")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: syncMonitor.connectionStatus.statusIcon)
                    .foregroundColor(syncMonitor.connectionStatus.statusColor)
                
                Text(syncMonitor.connectionStatus.statusText)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let lastSync = syncMonitor.lastSyncTime {
                    Text("Last sync: \(lastSync.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let errorMessage = syncMonitor.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }
    
    private var syncControlsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            Text("Sync Controls")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack {
                Button(action: {
                    Task {
                        await syncMonitor.manualSync()
                    }
                }) {
                    HStack {
                        if syncMonitor.isManualSyncInProgress {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text("Sync Now")
                    }
                }
                .disabled(syncMonitor.isManualSyncInProgress)
                .buttonStyle(.borderedProminent)
                
                Button("Reset Sync") {
                    Task {
                        await syncMonitor.resetSync()
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()