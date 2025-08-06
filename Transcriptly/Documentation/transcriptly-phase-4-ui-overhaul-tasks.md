# Transcriptly UI Overhaul - Detailed Task List

## Phase 4.0: Foundation Setup

### Task 4.0.1: Create UI Overhaul Branch
```bash
git checkout main
git pull origin main
git checkout -b phase-4-ui-overhaul
git push -u origin phase-4-ui-overhaul
```

### Task 4.0.2: Audit Current UI Code
Document all views that need updates:
- MainWindowView.swift
- SidebarView.swift
- HomeView.swift
- TranscriptionView.swift
- LearningView.swift
- SettingsView.swift

### Task 4.0.3: Create UI Components Library
```
Transcriptly/
├── Components/
│   ├── Materials/
│   │   ├── LiquidGlassBackground.swift
│   │   └── MaterialEffects.swift
│   ├── Buttons/
│   │   ├── PrimaryButton.swift
│   │   ├── SecondaryButton.swift
│   │   └── RecordButton.swift
│   ├── Cards/
│   │   ├── StatCard.swift
│   │   ├── ModeCard.swift
│   │   └── TranscriptionCard.swift
│   └── Animations/
│       ├── SpringAnimations.swift
│       └── RecordingPulse.swift
```

### Task 4.0.4: Define Design System
```swift
// Create DesignSystem.swift
struct DesignSystem {
    // Spacing
    static let marginStandard: CGFloat = 20
    static let spacingLarge: CGFloat = 16
    static let spacingMedium: CGFloat = 12
    static let spacingSmall: CGFloat = 8
    
    // Corner Radius
    static let cornerRadiusLarge: CGFloat = 10
    static let cornerRadiusMedium: CGFloat = 8
    static let cornerRadiusSmall: CGFloat = 6
    
    // Shadows
    static let shadowLight = Shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    static let shadowMedium = Shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    
    // Animation
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let fadeAnimation = Animation.easeInOut(duration: 0.2)
}
```

**Checkpoint 4.0**:
- [ ] Branch created
- [ ] Current UI audited
- [ ] Component structure ready
- [ ] Design system defined
- [ ] Git commit: "Setup UI overhaul foundation"

---

## Phase 4.1: Liquid Glass Implementation

### Task 4.1.1: Create Liquid Glass Backgrounds
```swift
// Components/Materials/LiquidGlassBackground.swift
import SwiftUI

struct LiquidGlassBackground: View {
    let material: Material
    let cornerRadius: CGFloat
    
    init(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(material)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}

// Usage modifier
extension View {
    func liquidGlassBackground(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = DesignSystem.cornerRadiusMedium
    ) -> some View {
        self.background(
            LiquidGlassBackground(material: material, cornerRadius: cornerRadius)
        )
    }
}
```

### Task 4.1.2: Update Color System
```swift
// Extensions/Colors.swift
extension Color {
    // Semantic colors that adapt to appearance
    static let primaryBackground = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    static let tertiaryBackground = Color(NSColor.textBackgroundColor)
    
    static let primaryText = Color(NSColor.labelColor)
    static let secondaryText = Color(NSColor.secondaryLabelColor)
    static let tertiaryText = Color(NSColor.tertiaryLabelColor)
    
    // Accent with vibrancy
    static let accentWithVibrancy = Color.accentColor.opacity(0.8)
}
```

### Task 4.1.3: Implement Shadow System
```swift
// Components/Materials/MaterialEffects.swift
struct ElevatedCard: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .liquidGlassBackground()
            .shadow(
                color: .black.opacity(isHovered ? 0.15 : 0.1),
                radius: isHovered ? 12 : 8,
                y: isHovered ? 6 : 4
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(DesignSystem.springAnimation, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
```

**Test Protocol 4.1**:
1. Apply liquid glass to one view
2. Verify translucency works
3. Test in Light and Dark mode
4. Check shadow rendering
5. Verify hover animations

**Checkpoint 4.1**:
- [ ] Liquid glass backgrounds working
- [ ] Semantic colors implemented
- [ ] Shadow system functional
- [ ] All materials support Dark Mode
- [ ] Git commit: "Implement Liquid Glass design system"

---

## Phase 4.2: Top Bar Implementation

### Task 4.2.1: Create Persistent Top Bar
```swift
// Components/TopBar.swift
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
    }
}
```

### Task 4.2.2: Create Advanced Record Button
```swift
// Components/Buttons/RecordButton.swift
struct RecordButton: View {
    let isRecording: Bool
    let recordingTime: TimeInterval
    let action: () -> Void
    
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 18))
                    .symbolRenderingMode(.hierarchical)
                
                if isRecording {
                    Text(timeString(from: recordingTime))
                        .font(.system(.caption, design: .monospaced))
                        .frame(width: 44)
                } else {
                    Text("Record")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: isRecording ? [.red, .red.opacity(0.8)] : [.accentColor, .accentColor.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(20)
            .shadow(color: isRecording ? .red.opacity(0.3) : .accentColor.opacity(0.3), radius: 8, y: 2)
            .scaleEffect(pulseAnimation && isRecording ? 1.05 : 1.0)
            .animation(
                isRecording ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : .default,
                value: pulseAnimation
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
```

### Task 4.2.3: Integrate Top Bar into Main Window
```swift
// Update MainWindowView.swift
struct MainWindowView: View {
    @StateObject var viewModel = MainViewModel()
    @State private var selectedSection: SidebarSection = .home
    @State private var showCapsuleMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Persistent Top Bar
            TopBar(
                viewModel: viewModel,
                showCapsuleMode: $showCapsuleMode
            )
            
            // Main Content
            HStack(spacing: 0) {
                SidebarView(selectedSection: $selectedSection)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                MainContentView(
                    selectedSection: $selectedSection,
                    viewModel: viewModel
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $showCapsuleMode) {
            CapsuleMode(viewModel: viewModel)
        }
    }
}
```

**Test Protocol 4.2**:
1. Verify top bar stays visible in all views
2. Test record button states
3. Check mode dropdown syncs with cards
4. Verify capsule button launches capsule mode
5. Test recording timer display

**Checkpoint 4.2**:
- [ ] Top bar implemented
- [ ] Record button with all states
- [ ] Mode dropdown functional
- [ ] Capsule button integrated
- [ ] Git commit: "Add persistent top bar"

---

## Phase 4.3: Sidebar Redesign

### Task 4.3.1: Implement Liquid Glass Sidebar
```swift
// Views/Sidebar/SidebarView.swift
struct SidebarView: View {
    @Binding var selectedSection: SidebarSection
    @State private var hoveredSection: SidebarSection?
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingSmall) {
            ForEach(SidebarSection.allCases, id: \.self) { section in
                SidebarItem(
                    section: section,
                    isSelected: selectedSection == section,
                    isHovered: hoveredSection == section,
                    isEnabled: section.isEnabled
                )
                .onTapGesture {
                    if section.isEnabled {
                        selectedSection = section
                    }
                }
                .onHover { hovering in
                    hoveredSection = hovering ? section : nil
                }
            }
            
            Spacer()
        }
        .padding(DesignSystem.spacingMedium)
        .frame(width: 200)
        .background(.ultraThinMaterial)
    }
}

struct SidebarItem: View {
    let section: SidebarSection
    let isSelected: Bool
    let isHovered: Bool
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.icon)
                .font(.system(size: 18))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(section.rawValue)
                .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                .foregroundColor(textColor)
            
            Spacer()
            
            if !isEnabled {
                Text("Soon")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(backgroundView)
        .animation(DesignSystem.springAnimation, value: isSelected)
        .animation(DesignSystem.fadeAnimation, value: isHovered)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
        } else if isHovered && isEnabled {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        }
    }
    
    private var iconColor: Color {
        if !isEnabled { return .tertiaryText }
        return isSelected ? .accentColor : .secondaryText
    }
    
    private var textColor: Color {
        if !isEnabled { return .tertiaryText }
        return isSelected ? .primaryText : .secondaryText
    }
}
```

**Test Protocol 4.3**:
1. Test selection animations
2. Verify hover states
3. Check disabled items appearance
4. Test in Light/Dark mode
5. Verify smooth transitions

**Checkpoint 4.3**:
- [ ] Sidebar uses Liquid Glass
- [ ] Selection states animated
- [ ] Hover effects working
- [ ] "Soon" badges styled
- [ ] Git commit: "Redesign sidebar with Liquid Glass"

---

## Phase 4.4: Home Screen Dashboard

### Task 4.4.1: Create Dashboard Layout
```swift
// Views/Home/HomeView.swift
struct HomeView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                // Welcome Header
                Text("Welcome back")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                // Stats Cards
                HStack(spacing: DesignSystem.spacingLarge) {
                    StatCard(
                        icon: "chart.bar.fill",
                        title: "Today",
                        value: "1,234",
                        subtitle: "words",
                        secondaryValue: "12 sessions"
                    )
                    
                    StatCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "This Week",
                        value: "8,456",
                        subtitle: "words",
                        secondaryValue: "45 min saved"
                    )
                    
                    StatCard(
                        icon: "target",
                        title: "Efficiency",
                        value: "87%",
                        subtitle: "refined",
                        secondaryValue: "23 patterns"
                    )
                }
                
                // Recent Transcriptions
                VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                    Text("Recent Transcriptions")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    VStack(spacing: DesignSystem.spacingSmall) {
                        ForEach(viewModel.recentTranscriptions) { transcription in
                            TranscriptionCard(transcription: transcription)
                        }
                    }
                }
                
                // Quick Actions
                HStack(spacing: DesignSystem.spacingMedium) {
                    SecondaryButton(title: "View All History", icon: "clock.arrow.circlepath") {
                        // Action
                    }
                    
                    SecondaryButton(title: "Export Today's Work", icon: "square.and.arrow.up") {
                        // Action
                    }
                }
            }
            .padding(DesignSystem.marginStandard)
        }
        .background(Color.primaryBackground)
    }
}
```

### Task 4.4.2: Create Stat Card Component
```swift
// Components/Cards/StatCard.swift
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let secondaryValue: String
    
    @State private var isHovered = false
    @State private var displayValue: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryText)
                    .contentTransition(.numericText())
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                
                Text(secondaryValue)
                    .font(.system(size: 12))
                    .foregroundColor(.tertiaryText)
                    .padding(.top, 4)
            }
        }
        .padding(DesignSystem.spacingLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ElevatedCard())
    }
}
```

### Task 4.4.3: Create Transcription Card
```swift
// Components/Cards/TranscriptionCard.swift
struct TranscriptionCard: View {
    let transcription: TranscriptionRecord
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transcription.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryText)
                
                HStack(spacing: 12) {
                    Text(transcription.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                    
                    Text("•")
                        .foregroundColor(.tertiaryText)
                    
                    Text("\(transcription.wordCount) words")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                    
                    Text("•")
                        .foregroundColor(.tertiaryText)
                    
                    Label(transcription.mode.displayName, systemImage: transcription.mode.icon)
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                }
            }
            
            Spacer()
            
            if isHovered {
                Button("View") {
                    // View action
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(DesignSystem.spacingMedium)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondaryBackground.opacity(isHovered ? 1 : 0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(DesignSystem.fadeAnimation) {
                isHovered = hovering
            }
        }
    }
}
```

**Test Protocol 4.4**:
1. Verify dashboard layout
2. Test stat card animations
3. Check hover states on cards
4. Verify recent items display
5. Test quick action buttons

**Checkpoint 4.4**:
- [ ] Dashboard layout complete
- [ ] Stat cards with animations
- [ ] Recent transcriptions display
- [ ] Quick actions functional
- [ ] Git commit: "Transform home to dashboard"

---

## Phase 4.5: Transcription View - Unified Mode Cards

### Task 4.5.1: Create Mode Card Component
```swift
// Components/Cards/ModeCard.swift
struct ModeCard: View {
    let mode: RefinementMode
    @Binding var selectedMode: RefinementMode
    let stats: ModeStatistics?
    let onEdit: () -> Void
    let onAppsConfig: (() -> Void)?
    
    @State private var isHovered = false
    
    private var isSelected: Bool {
        selectedMode == mode
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack {
                // Radio button
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .accentColor : .secondaryText)
                    .symbolRenderingMode(.hierarchical)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    Text(mode.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }
                
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
                        
                        if let appsConfig = onAppsConfig {
                            Button(action: appsConfig) {
                                HStack(spacing: 4) {
                                    Text("Apps")
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            
            // Stats line (if available and selected)
            if isSelected, let stats = stats {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 12))
                    
                    Text("Used \(stats.usageCount) times")
                        .font(.system(size: 12))
                    
                    if let lastEdited = stats.lastEditedDisplay {
                        Text("•")
                        Text("Edited \(lastEdited)")
                            .font(.system(size: 12))
                    }
                    
                    if !stats.assignedApps.isEmpty {
                        Text("•")
                        HStack(spacing: 4) {
                            ForEach(stats.assignedApps.prefix(3), id: \.self) { app in
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                            if stats.assignedApps.count > 3 {
                                Text("+\(stats.assignedApps.count - 3)")
                                    .font(.system(size: 10))
                            }
                        }
                    }
                }
                .foregroundColor(.tertiaryText)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(DesignSystem.spacingLarge)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundMaterial)
                .shadow(
                    color: shadowColor,
                    radius: isSelected ? 8 : 4,
                    y: isSelected ? 4 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(borderColor, lineWidth: isSelected ? 1.5 : 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(DesignSystem.springAnimation, value: isHovered)
        .animation(DesignSystem.springAnimation, value: isSelected)
        .onTapGesture {
            selectedMode = mode
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var backgroundMaterial: Material {
        if isSelected {
            return .regularMaterial
        } else {
            return .ultraThinMaterial
        }
    }
    
    private var shadowColor: Color {
        isSelected ? .accentColor.opacity(0.2) : .black.opacity(0.1)
    }
    
    private var borderColor: Color {
        if isSelected {
            return .accentColor.opacity(0.5)
        } else if isHovered {
            return .white.opacity(0.2)
        } else {
            return .white.opacity(0.1)
        }
    }
}
```

### Task 4.5.2: Redesign Transcription View
```swift
// Views/Transcription/TranscriptionView.swift
struct TranscriptionView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showEditPrompt = false
    @State private var editingMode: RefinementMode?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                Text("AI Refinement Modes")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                VStack(spacing: DesignSystem.spacingMedium) {
                    ForEach(RefinementMode.allCases, id: \.self) { mode in
                        ModeCard(
                            mode: mode,
                            selectedMode: $viewModel.currentMode,
                            stats: viewModel.modeStatistics[mode],
                            onEdit: {
                                editingMode = mode
                                showEditPrompt = true
                            },
                            onAppsConfig: mode != .raw ? {
                                // Future: Show apps configuration
                            } : nil
                        )
                    }
                }
            }
            .padding(DesignSystem.marginStandard)
        }
        .background(Color.primaryBackground)
        .sheet(isPresented: $showEditPrompt) {
            if let mode = editingMode {
                EditPromptView(
                    mode: mode,
                    prompt: viewModel.prompts[mode] ?? "",
                    onSave: { newPrompt in
                        viewModel.updatePrompt(for: mode, prompt: newPrompt)
                    }
                )
            }
        }
    }
}
```

### Task 4.5.3: Create Edit Prompt Modal
```swift
// Views/Transcription/EditPromptView.swift
struct EditPromptView: View {
    let mode: RefinementMode
    @State private var prompt: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    init(mode: RefinementMode, prompt: String, onSave: @escaping (String) -> Void) {
        self.mode = mode
        self._prompt = State(initialValue: prompt)
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit \(mode.displayName) Prompt")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding(DesignSystem.spacingLarge)
            
            Divider()
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                Text("Customize the AI instructions for this mode:")
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                
                TextEditor(text: $prompt)
                    .font(.system(size: 14))
                    .padding(8)
                    .background(Color.tertiaryBackground)
                    .cornerRadius(8)
                    .frame(height: 150)
                
                HStack {
                    Text("\(prompt.count)/500")
                        .font(.system(size: 12))
                        .foregroundColor(prompt.count > 500 ? .red : .tertiaryText)
                    
                    Spacer()
                    
                    Button("Reset to Default") {
                        prompt = mode.defaultPrompt
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
            }
            .padding(DesignSystem.spacingLarge)
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Button("Save") {
                    onSave(prompt)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(prompt.isEmpty || prompt.count > 500)
            }
            .padding(DesignSystem.spacingLarge)
        }
        .frame(width: 500, height: 400)
        .background(.regularMaterial)
    }
}
```

**Test Protocol 4.5**:
1. Test mode card selection
2. Verify hover states show buttons
3. Test edit prompt modal
4. Check stats display when selected
5. Verify smooth animations

**Checkpoint 4.5**:
- [ ] Mode cards implemented
- [ ] Selection animations smooth
- [ ] Edit prompt modal works
- [ ] Stats display correctly
- [ ] Git commit: "Implement unified mode cards"

---

## Phase 4.6: Final Polish

### Task 4.6.1: Add Loading States
```swift
// Components/LoadingStates.swift
struct ProcessingOverlay: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
        }
        .padding(24)
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 20)
    }
}
```

### Task 4.6.2: Implement Spring Animations
```swift
// Update all view transitions
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: animatedValue)

// Add haptic feedback
extension View {
    func hapticFeedback(_ type: NSHapticFeedbackManager.FeedbackPattern = .levelChange) -> some View {
        self.onTapGesture {
            NSHapticFeedbackManager.defaultPerformer.perform(type, performanceTime: .now)
        }
    }
}
```

### Task 4.6.3: Performance Optimization
- Profile all animations at 60fps
- Reduce view rebuilds
- Optimize shadow rendering
- Cache expensive computations

### Task 4.6.4: Accessibility Pass
- Add VoiceOver labels
- Ensure keyboard navigation
- Test with Accessibility Inspector
- Add focus indicators

**Final Test Protocol**:
1. Test every view in Light/Dark mode
2. Verify all animations at 60fps
3. Test with VoiceOver enabled
4. Check memory usage
5. Verify no UI glitches

**Phase 4 Final Checkpoint**:
- [ ] All views use Liquid Glass
- [ ] Animations smooth throughout
- [ ] Dark Mode perfect
- [ ] Accessibility complete
- [ ] Performance optimized
- [ ] Git commit: "Complete UI overhaul"
- [ ] Tag: v0.8.0-ui-complete

---

## Implementation Notes

### Key SwiftUI Modifiers
```swift
// Use throughout the app:
.background(.ultraThinMaterial)
.shadow(color: .black.opacity(0.1), radius: 8, y: 2)
.animation(.spring(response: 0.4, dampingFraction: 0.8))
.transition(.asymmetric(insertion: .scale.combined(with: .opacity), 
                       removal: .scale.combined(with: .opacity)))
```

### Performance Guidelines
1. Use `@State` for local UI state only
2. Use `@StateObject` for view models
3. Avoid unnecessary view rebuilds
4. Profile with Instruments

### Testing Checklist
- [ ] Light Mode appearance
- [ ] Dark Mode appearance
- [ ] All animations smooth
- [ ] Hover states working
- [ ] Keyboard navigation
- [ ] VoiceOver support
- [ ] No memory leaks
- [ ] 60fps throughout

## Success Metrics

1. **Visual Polish**: Feels like a first-party Apple app
2. **Performance**: All animations at 60fps
3. **Accessibility**: Full VoiceOver and keyboard support
4. **User Delight**: Subtle details that surprise and please
5. **Consistency**: Every element follows the design system