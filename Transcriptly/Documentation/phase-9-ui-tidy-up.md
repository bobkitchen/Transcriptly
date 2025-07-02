# Transcriptly Phase 9 - UI Tidy Up - Complete Task List

## Overview
This phase implements comprehensive UI/UX improvements to bring Transcriptly into full compliance with Apple's Liquid Glass design system while fixing identified usability issues.

## Phase 9.0: Setup and Planning

### Task 9.0.1: Create UI Tidy Up Branch
```bash
git checkout main
git pull origin main
git checkout -b phase-9-ui-tidy-up
git push -u origin phase-9-ui-tidy-up
```

### Task 9.0.2: Create Design System File
```swift
// Create DesignSystem.swift
struct DesignSystem {
    // Liquid Glass Materials
    static let primaryMaterial: Material = .regularMaterial
    static let secondaryMaterial: Material = .thinMaterial
    static let overlayMaterial: Material = .ultraThinMaterial
    
    // Spacing System (Liquid Glass compliant)
    static let marginStandard: CGFloat = 20
    static let spacingLarge: CGFloat = 16
    static let spacingMedium: CGFloat = 12
    static let spacingSmall: CGFloat = 8
    static let spacingXSmall: CGFloat = 4
    
    // Corner Radius (Capsule-first approach)
    static let cornerRadiusLarge: CGFloat = 12  // Large controls (capsules)
    static let cornerRadiusMedium: CGFloat = 8  // Medium controls
    static let cornerRadiusSmall: CGFloat = 6   // Small elements
    
    // Shadows (Liquid Glass depth)
    static let shadowLight = Shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    static let shadowMedium = Shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    static let shadowHover = Shadow(color: .black.opacity(0.2), radius: 12, y: 6)
    
    // Animation (Spring-based)
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let quickAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let fadeAnimation = Animation.easeInOut(duration: 0.2)
}

// Liquid Glass View Modifiers
extension View {
    func liquidGlassCard() -> some View {
        self
            .background(DesignSystem.primaryMaterial)
            .cornerRadius(DesignSystem.cornerRadiusMedium)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
    
    func liquidGlassHover() -> some View {
        self.onHover { isHovered in
            // Implement hover state changes
        }
    }
    
    func liquidGlassButton(style: ButtonStyle = .primary) -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(style == .primary ? 
                DesignSystem.primaryMaterial : DesignSystem.secondaryMaterial)
            .cornerRadius(style == .primary ? 
                DesignSystem.cornerRadiusLarge : DesignSystem.cornerRadiusMedium)
    }
}

enum ButtonStyle {
    case primary, secondary
}
```

### Task 9.0.3: Update Project Documentation
```markdown
# Update CLAUDE.md with Phase 9 objectives:
- Full Liquid Glass implementation
- Navigation consolidation (AI Providers → Settings)
- Responsive sidebar with proper collapse behavior
- Media controls optimization
- Home screen title cleanup
- Comprehensive hover states and animations
```

**Checkpoint 9.0**:
- [ ] Branch created and pushed
- [ ] Design system file created
- [ ] Documentation updated
- [ ] Git commit: "Setup Phase 9 - UI Tidy Up framework"

---

## Phase 9.1: Navigation Restructuring

### Task 9.1.1: Consolidate AI Providers into Settings
```swift
// Update SidebarView.swift
enum SidebarSection: String, CaseIterable {
    case home = "Home"
    case dictation = "Dictation"  
    case readAloud = "Read Aloud"
    case learning = "Learning"
    case settings = "Settings"
    // Remove: case aiProviders = "AI Providers"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .dictation: return "mic.fill"
        case .readAloud: return "speaker.wave.3.fill"
        case .learning: return "brain.head.profile"
        case .settings: return "gearshape.fill"
        }
    }
    
    var isEnabled: Bool {
        switch self {
        case .home, .dictation, .readAloud, .settings: return true
        case .learning: return false  // Still coming soon
        }
    }
}
```

### Task 9.1.2: Update Settings View with AI Providers Section
```swift
// Update SettingsView.swift
struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Account Section (Placeholder)
            SettingsSection(
                title: "Account",
                icon: "person.circle",
                content: {
                    AccountSettingsContent()
                }
            )
            
            // AI Providers Section (moved from main navigation)
            SettingsSection(
                title: "AI Providers",
                icon: "cpu",
                content: {
                    AIProvidersSettingsContent()
                }
            )
            
            // Notifications Section
            SettingsSection(
                title: "Notifications", 
                icon: "bell",
                content: {
                    NotificationSettingsContent()
                }
            )
            
            // Keyboard Shortcuts Section
            SettingsSection(
                title: "Keyboard Shortcuts",
                icon: "keyboard",
                content: {
                    KeyboardShortcutsContent()
                }
            )
            
            // History Section
            SettingsSection(
                title: "History",
                icon: "clock.arrow.circlepath",
                content: {
                    HistorySettingsContent()
                }
            )
            
            // About Section
            SettingsSection(
                title: "About",
                icon: "info.circle",
                content: {
                    AboutSettingsContent()
                }
            )
            
            Spacer()
        }
        .padding(DesignSystem.marginStandard)
        .background(Color.clear)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            Button(action: { 
                withAnimation(DesignSystem.springAnimation) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(DesignSystem.quickAnimation, value: isExpanded)
                }
                .padding(DesignSystem.spacingMedium)
            }
            .buttonStyle(.plain)
            .liquidGlassCard()
            
            // Section Content
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    content()
                }
                .padding(.top, DesignSystem.spacingSmall)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }
}

// Move existing AI Providers content here
struct AIProvidersSettingsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            Text("Configure AI services for transcription and refinement")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Apple Intelligence (Local)
            ProviderRow(
                name: "Apple Intelligence",
                description: "On-device processing (Recommended)",
                isEnabled: true,
                isRecommended: true
            )
            
            // Cloud Providers
            ProviderRow(
                name: "OpenAI GPT-4",
                description: "Cloud-based processing",
                isEnabled: false
            )
            
            ProviderRow(
                name: "Anthropic Claude",
                description: "Cloud-based processing", 
                isEnabled: false
            )
            
            Button("Configure API Keys") {
                // Open API configuration
            }
            .buttonStyle(.bordered)
        }
        .padding(DesignSystem.spacingMedium)
        .liquidGlassCard()
    }
}

struct ProviderRow: View {
    let name: String
    let description: String
    let isEnabled: Bool
    let isRecommended: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name)
                        .font(.system(size: 14, weight: .medium))
                    
                    if isRecommended {
                        Text("Recommended")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(isEnabled))
                .disabled(!isEnabled && !isRecommended)
        }
    }
}
```

### Task 9.1.3: Update MainContentView Router
```swift
// Update MainContentView.swift
struct MainContentView: View {
    @Binding var selectedSection: SidebarView.SidebarSection
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        Group {
            switch selectedSection {
            case .home:
                HomeView(viewModel: viewModel)
            case .dictation:
                DictationView(viewModel: viewModel) // Rename from TranscriptionView
            case .readAloud:
                ReadAloudView()
            case .learning:
                LearningView()
            case .settings:
                SettingsView() // Now includes AI Providers
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}
```

**Test Protocol 9.1**:
1. Verify AI Providers section appears in Settings
2. Test collapsible sections in Settings
3. Verify main navigation has 5 items (not 6)
4. Test all settings sections expand/collapse properly

**Checkpoint 9.1**:
- [ ] AI Providers moved to Settings
- [ ] Navigation reduced to 5 items
- [ ] Settings sections collapsible
- [ ] All routing updated
- [ ] Git commit: "Consolidate AI Providers into Settings"

---

## Phase 9.2: Responsive Sidebar Implementation

### Task 9.2.1: Fix Collapsed Sidebar Usability
```swift
// Update SidebarView.swift
struct SidebarView: View {
    @Binding var selectedSection: SidebarSection
    @State private var isCollapsed = false
    @State private var hoveredSection: SidebarSection?
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapse Toggle Button
            HStack {
                Button(action: { 
                    withAnimation(DesignSystem.springAnimation) {
                        isCollapsed.toggle()
                    }
                }) {
                    Image(systemName: isCollapsed ? "sidebar.squares.right" : "sidebar.squares.left")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(8)
                .help(isCollapsed ? "Expand Sidebar" : "Collapse Sidebar")
                
                if !isCollapsed {
                    Spacer()
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Navigation Items
            VStack(spacing: DesignSystem.spacingSmall) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    SidebarItemView(
                        section: section,
                        isSelected: selectedSection == section,
                        isCollapsed: isCollapsed,
                        isHovered: hoveredSection == section,
                        isEnabled: section.isEnabled
                    )
                    .onTapGesture {
                        if section.isEnabled {
                            withAnimation(DesignSystem.quickAnimation) {
                                selectedSection = section
                            }
                        }
                    }
                    .onHover { hovering in
                        hoveredSection = hovering ? section : nil
                    }
                }
            }
            .padding(DesignSystem.spacingMedium)
            
            Spacer()
        }
        .frame(width: isCollapsed ? 60 : 200)
        .background(DesignSystem.secondaryMaterial)
        .animation(DesignSystem.springAnimation, value: isCollapsed)
    }
}

struct SidebarItemView: View {
    let section: SidebarView.SidebarSection
    let isSelected: Bool
    let isCollapsed: Bool
    let isHovered: Bool
    let isEnabled: Bool
    
    @State private var showTooltip = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: section.icon)
                .font(.system(size: 18))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            // Label (hidden when collapsed)
            if !isCollapsed {
                Text(section.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                    .foregroundColor(textColor)
                
                Spacer()
                
                // "Soon" badge for disabled items
                if !isEnabled {
                    Text("Soon")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(DesignSystem.overlayMaterial)
                        .cornerRadius(DesignSystem.cornerRadiusSmall)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(backgroundView)
        .cornerRadius(DesignSystem.cornerRadiusMedium)
        .scaleEffect(isHovered && isEnabled ? 1.02 : 1.0)
        .animation(DesignSystem.springAnimation, value: isSelected)
        .animation(DesignSystem.quickAnimation, value: isHovered)
        .help(isCollapsed ? section.rawValue : "") // Tooltip when collapsed
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected && isEnabled {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                    .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        } else if isHovered && isEnabled {
            Color.white.opacity(0.05)
        }
    }
    
    private var iconColor: Color {
        if !isEnabled { return .tertiary }
        return isSelected ? .accentColor : .secondary
    }
    
    private var textColor: Color {
        if !isEnabled { return .tertiary }
        return isSelected ? .primary : .secondary
    }
}
```

### Task 9.2.2: Implement Responsive Main Content Area
```swift
// Update MainWindowView.swift
struct MainWindowView: View {
    @StateObject var viewModel = MainViewModel()
    @State private var selectedSection: SidebarView.SidebarSection = .home
    @State private var showCapsuleMode = false
    @State private var sidebarCollapsed = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(
                selectedSection: $selectedSection,
                isCollapsed: $sidebarCollapsed
            )
            .transition(.move(edge: .leading))
            
            // Divider
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Main Content - RESPONSIVE TO SIDEBAR STATE
            MainContentView(
                selectedSection: $selectedSection,
                viewModel: viewModel
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(DesignSystem.springAnimation, value: sidebarCollapsed)
        }
        .frame(minWidth: sidebarCollapsed ? 700 : 900, minHeight: 600)
        .background(Color.clear)
        .sheet(isPresented: $showCapsuleMode) {
            CapsuleMode(viewModel: viewModel)
        }
    }
}
```

**Test Protocol 9.2**:
1. Test sidebar collapse/expand animation
2. Verify tooltips appear on collapsed sidebar items
3. Test content area expands when sidebar collapses
4. Verify active state indicators work in both modes
5. Test minimum window size adjustments

**Checkpoint 9.2**:
- [ ] Collapsed sidebar shows tooltips
- [ ] Content area responds to sidebar state
- [ ] Smooth collapse/expand animations
- [ ] Active states work in both modes
- [ ] Git commit: "Implement responsive sidebar with tooltips"

---

## Phase 9.3: Home Screen Title Cleanup

### Task 9.3.1: Simplify Home Screen Headers
```swift
// Update HomeView.swift
struct HomeView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                // SIMPLIFIED HEADER - Remove redundant titles
                Text("Welcome back")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, DesignSystem.marginStandard)
                
                // Action Cards - More prominent without competing headers
                HStack(spacing: DesignSystem.spacingLarge) {
                    ActionCard(
                        icon: "mic.circle.fill",
                        title: "Record Dictation",
                        subtitle: "Voice to text with AI refinement",
                        buttonText: "Start Recording",
                        buttonColor: .blue,
                        action: { viewModel.startRecording() }
                    )
                    
                    ActionCard(
                        icon: "doc.text.fill",
                        title: "Read Documents", 
                        subtitle: "Text to speech for any document",
                        buttonText: "+ Choose Document",
                        buttonColor: .green,
                        action: { /* Navigate to Read Aloud */ }
                    )
                    
                    ActionCard(
                        icon: "waveform",
                        title: "Transcribe Media",
                        subtitle: "Convert audio files to text", 
                        buttonText: "+ Select Audio",
                        buttonColor: .purple,
                        action: { /* Navigate to Media Transcription */ }
                    )
                }
                .padding(.horizontal, DesignSystem.marginStandard)
                
                // Recent Activity Section
                VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                    HStack {
                        Text("Recent Activity")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("View All") {
                            // Navigate to history
                        }
                        .foregroundColor(.accentColor)
                    }
                    
                    VStack(spacing: DesignSystem.spacingSmall) {
                        ForEach(viewModel.recentTranscriptions) { transcription in
                            RecentActivityRow(transcription: transcription)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.marginStandard)
            }
            .padding(.vertical, DesignSystem.marginStandard)
        }
        .background(Color.clear)
    }
}

// Enhanced Action Card with Liquid Glass
struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonText: String
    let buttonColor: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(buttonColor)
                
                VStack(alignment: .leading, spacing: DesignSystem.spacingXSmall) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Button(action: action) {
                Text(buttonText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(buttonColor)
                    .cornerRadius(DesignSystem.cornerRadiusLarge) // Capsule style
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.spacingLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.primaryMaterial)
        .cornerRadius(DesignSystem.cornerRadiusMedium)
        .shadow(
            color: .black.opacity(isHovered ? 0.15 : 0.1),
            radius: isHovered ? 8 : 4,
            y: isHovered ? 4 : 2
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(DesignSystem.springAnimation, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct RecentActivityRow: View {
    let transcription: TranscriptionRecord
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transcription.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Text(transcription.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.tertiary)
                    
                    Text("\(transcription.wordCount) words")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.tertiary)
                    
                    Label(transcription.mode.displayName, systemImage: transcription.mode.icon)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isHovered {
                Button("View") {
                    // View action
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.accentColor)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(DesignSystem.spacingMedium)
        .background(
            isHovered ? DesignSystem.overlayMaterial : Color.clear
        )
        .cornerRadius(DesignSystem.cornerRadiusMedium)
        .onHover { hovering in
            withAnimation(DesignSystem.fadeAnimation) {
                isHovered = hovering
            }
        }
    }
}
```

**Test Protocol 9.3**:
1. Verify duplicate "Transcriptly" title removed
2. Test simplified header layout
3. Verify action cards have proper hover states
4. Test recent activity hover interactions
5. Confirm improved vertical space usage

**Checkpoint 9.3**:
- [ ] Home screen titles simplified
- [ ] Action cards use Liquid Glass materials
- [ ] Hover states implemented
- [ ] More space for content
- [ ] Git commit: "Simplify home screen titles and enhance cards"

---

## Phase 9.4: Media Controls Optimization

### Task 9.4.1: Compact Read Aloud Controls
```swift
// Update ReadAloudView.swift media controls section
struct MediaControlsView: View {
    @ObservedObject var player: ReadAloudPlayer
    @State private var showSpeedMenu = false
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingMedium) {
            // Document Header (keep existing)
            DocumentHeaderView(document: player.currentDocument)
            
            // COMPACT CONTROLS - Single row design
            HStack(spacing: DesignSystem.spacingLarge) {
                // Playback Controls
                HStack(spacing: DesignSystem.spacingMedium) {
                    Button(action: player.previousSentence) {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(MediaButtonStyle())
                    .disabled(!player.canGoPrevious)
                    
                    Button(action: player.togglePlayPause) {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 24))
                    }
                    .buttonStyle(MediaButtonStyle(isPrimary: true))
                    
                    Button(action: player.nextSentence) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(MediaButtonStyle())
                    .disabled(!player.canGoNext)
                }
                
                Spacer()
                
                // Speed Control - Compact dropdown
                Menu {
                    ForEach([0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                        Button(action: { player.setPlaybackSpeed(speed) }) {
                            HStack {
                                Text("\(speed, specifier: "%.2f")x")
                                if speed == player.playbackSpeed {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("\(player.playbackSpeed, specifier: "%.1f")x")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignSystem.overlayMaterial)
                    .cornerRadius(DesignSystem.cornerRadiusSmall)
                }
                .menuStyle(.borderlessButton)
                
                // Progress Indicator
                HStack(spacing: 8) {
                    Text("\(player.currentSentence + 1)")
                        .font(.system(.caption, design: .monospaced))
                    Text("of")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(player.totalSentences)")
                        .font(.system(.caption, design: .monospaced))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(DesignSystem.overlayMaterial)
                .cornerRadius(DesignSystem.cornerRadiusSmall)
            }
            .padding(.horizontal, DesignSystem.marginStandard)
            .padding(.vertical, DesignSystem.spacingMedium)
            .background(DesignSystem.secondaryMaterial)
            .cornerRadius(DesignSystem.cornerRadiusMedium)
            
            // Progress Bar - Separate and prominent
            ProgressBarView(
                progress: player.progress,
                onSeek: player.seekToProgress
            )
            .padding(.horizontal, DesignSystem.marginStandard)
        }
    }
}

struct MediaButtonStyle: ButtonStyle {
    let isPrimary: Bool
    
    init(isPrimary: Bool = false) {
        self.isPrimary = isPrimary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isPrimary ? .accentColor : .secondary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.quickAnimation, value: configuration.isPressed)
    }
}

struct ProgressBarView: View {
    let progress: Double
    let onSeek: (Double) -> Void
    
    @State private var isDragging = false
    @State private var dragProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 4)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(
                        width: geometry.size.width * (isDragging ? dragProgress : progress),
                        height: 4
                    )
                    .animation(.linear(duration: isDragging ? 0 : 0.1), value: progress)
            }
        }
        .frame(height: 20) // Increased hit target
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragProgress = max(0, min(1, value.location.x / value.startLocation.x))
                }
                .onEnded { value in
                    isDragging = false
                    onSeek(dragProgress)
                }
        )
    }
}
```

### Task 9.4.2: Update Document Content Area
```swift
// Increase content area space by reducing controls height
struct ReadAloudDocumentView: View {
    @ObservedObject var player: ReadAloudPlayer
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Media Controls (~80px total height vs previous ~200px)
            MediaControlsView(player: player)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // EXPANDED Content Area (now gets ~70% more space)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        ForEach(Array(player.sentences.enumerated()), id: \.offset) { index, sentence in
                            SentenceView(
                                sentence: sentence,
                                isActive: index == player.currentSentence,
                                index: index
                            )
                            .id(index)
                        }
                    }
                    .padding(DesignSystem.marginStandard)
                }
                .background(DesignSystem.overlayMaterial)
                .onChange(of: player.currentSentence) { newSentence in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(newSentence, anchor: .center)
                    }
                }
            }
        }
    }
}

struct SentenceView: View {
    let sentence: String
    let isActive: Bool
    let index: Int
    
    var body: some View {
        Text(sentence)
            .font(.system(size: 16, weight: isActive ? .medium : .regular))
            .foregroundColor(isActive ? .primary : .secondary)
            .padding(.vertical, DesignSystem.spacingSmall)
            .padding(.horizontal, DesignSystem.spacingMedium)
            .background(
                isActive ? Color.accentColor.opacity(0.1) : Color.clear
            )
            .cornerRadius(DesignSystem.cornerRadiusSmall)
            .animation(DesignSystem.fadeAnimation, value: isActive)
    }
}
```

**Test Protocol 9.4**:
1. Verify media controls fit in single compact row
2. Test speed dropdown functionality  
3. Test progress bar drag interaction
4. Verify content area uses gained vertical space
5. Test playback controls responsiveness

**Checkpoint 9.4**:
- [ ] Media controls significantly more compact
- [ ] Speed control uses dropdown format
- [ ] Content area expanded substantially
- [ ] All controls maintain functionality
- [ ] Git commit: "Optimize media controls for better space usage"

---

## Phase 9.5: Comprehensive Liquid Glass Implementation

### Task 9.5.1: Apply Liquid Glass Materials Throughout App
```swift
// Update all major views to use Liquid Glass materials

// MainWindowView.swift
struct MainWindowView: View {
    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedSection: $selectedSection)
                .background(DesignSystem.secondaryMaterial) // Liquid Glass
            
            Divider()
            
            MainContentView(selectedSection: $selectedSection, viewModel: viewModel)
                .background(Color.clear) // Let content choose its materials
        }
        .background(DesignSystem.overlayMaterial) // Window background
    }
}

// All Card Components
extension View {
    func liquidGlassCard(isHovered: Bool = false) -> some View {
        self
            .background(DesignSystem.primaryMaterial)
            .cornerRadius(DesignSystem.cornerRadiusMedium)
            .shadow(
                color: .black.opacity(isHovered ? 0.15 : 0.1),
                radius: isHovered ? 8 : 4,
                y: isHovered ? 4 : 2
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}

// Update DictationView.swift (former TranscriptionView)
struct DictationView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.spacingLarge) {
                Text("AI Refinement Modes")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                
                VStack(spacing: DesignSystem.spacingMedium) {
                    ForEach(RefinementMode.allCases, id: \.self) { mode in
                        RefinementModeCard(
                            mode: mode,
                            selectedMode: $viewModel.currentMode,
                            onEdit: { editMode(mode) },
                            stats: viewModel.modeStatistics[mode]
                        )
                    }
                }
            }
            .padding(DesignSystem.marginStandard)
        }
        .background(Color.clear)
    }
}

struct RefinementModeCard: View {
    let mode: RefinementMode
    @Binding var selectedMode: RefinementMode
    let onEdit: () -> Void
    let stats: ModeStatistics?
    
    @State private var isHovered = false
    
    private var isSelected: Bool {
        selectedMode == mode
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
            HStack {
                // Selection indicator
                Button(action: { selectedMode = mode }) {
                    Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .animation(DesignSystem.springAnimation, value: isSelected)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(mode.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Edit button (show on hover or selection)
                if (isHovered || isSelected) && mode != .raw {
                    Button("Edit", action: onEdit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DesignSystem.overlayMaterial)
                        .cornerRadius(DesignSystem.cornerRadiusSmall)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            
            // Stats (if selected and available)
            if isSelected, let stats = stats {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("Used \(stats.usageCount) times")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    if let lastEdited = stats.lastEditedDisplay {
                        Text("•")
                            .foregroundColor(.tertiary)
                        Text("Edited \(lastEdited)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(DesignSystem.spacingLarge)
        .liquidGlassCard(isHovered: isHovered)
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
}
```

### Task 9.5.2: Implement Comprehensive Hover States
```swift
// Create HoverableCard modifier for consistent hover behavior
struct HoverableCard: ViewModifier {
    @State private var isHovered = false
    let action: (() -> Void)?
    
    init(action: (() -> Void)? = nil) {
        self.action = action
    }
    
    func body(content: Content) -> some View {
        content
            .liquidGlassCard(isHovered: isHovered)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(DesignSystem.springAnimation, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                action?()
            }
    }
}

extension View {
    func hoverableCard(action: (() -> Void)? = nil) -> some View {
        modifier(HoverableCard(action: action))
    }
}

// Apply to all interactive elements
// In HomeView action cards:
ActionCard(...)
    .hoverableCard(action: action)

// In ReadAloudView document cards:
DocumentCard(...)
    .hoverableCard(action: { openDocument() })

// In Settings sections:
SettingsSection(...)
    .hoverableCard()
```

### Task 9.5.3: Button Hierarchy Implementation
```swift
// Create Liquid Glass button styles
struct LiquidGlassButtonStyle: ButtonStyle {
    enum ButtonType {
        case primary, secondary, tertiary
        
        var material: Material {
            switch self {
            case .primary: return .regularMaterial
            case .secondary: return .thinMaterial  
            case .tertiary: return .ultraThinMaterial
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .primary: return DesignSystem.cornerRadiusLarge // Capsule
            case .secondary: return DesignSystem.cornerRadiusMedium
            case .tertiary: return DesignSystem.cornerRadiusSmall
            }
        }
    }
    
    let type: ButtonType
    let isDestructive: Bool
    
    init(_ type: ButtonType = .primary, isDestructive: Bool = false) {
        self.type = type
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(foregroundColor(configuration.isPressed))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(type.material)
            .cornerRadius(type.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.quickAnimation, value: configuration.isPressed)
    }
    
    private var horizontalPadding: CGFloat {
        switch type {
        case .primary: return 20
        case .secondary: return 16
        case .tertiary: return 12
        }
    }
    
    private var verticalPadding: CGFloat {
        switch type {
        case .primary: return 12
        case .secondary: return 8
        case .tertiary: return 6
        }
    }
    
    private func foregroundColor(_ isPressed: Bool) -> Color {
        if isDestructive {
            return .red
        }
        
        switch type {
        case .primary:
            return isPressed ? .accentColor.opacity(0.8) : .accentColor
        case .secondary:
            return isPressed ? .primary.opacity(0.8) : .primary
        case .tertiary:
            return isPressed ? .secondary.opacity(0.8) : .secondary
        }
    }
}

// Usage throughout app:
Button("Start Recording") { ... }
    .buttonStyle(LiquidGlassButtonStyle(.primary))

Button("Edit") { ... }
    .buttonStyle(LiquidGlassButtonStyle(.secondary))

Button("Cancel") { ... }
    .buttonStyle(LiquidGlassButtonStyle(.tertiary, isDestructive: true))
```

**Test Protocol 9.5**:
1. Verify all backgrounds use appropriate Liquid Glass materials
2. Test hover states on all interactive elements
3. Verify button hierarchy follows Liquid Glass guidelines
4. Test animations are smooth and consistent
5. Verify translucency effects work properly

**Checkpoint 9.5**:
- [ ] All views use Liquid Glass materials
- [ ] Comprehensive hover states implemented
- [ ] Button hierarchy standardized
- [ ] Animations consistent throughout
- [ ] Git commit: "Implement comprehensive Liquid Glass design system"

---

## Phase 9.6: Final Polish and Testing

### Task 9.6.1: Performance Optimization
```swift
// Optimize animations for 60fps
// Add @State variables for hover tracking only where needed
// Use .animation() modifiers judiciously
// Test with Instruments for smooth frame rates

// Memory optimization
// Ensure no retain cycles in hover closures
// Use weak references where appropriate
// Test memory usage during extended use
```

### Task 9.6.2: Accessibility Improvements
```swift
// Add VoiceOver labels for all interactive elements
Button("Start Recording") { ... }
    .accessibilityLabel("Start voice recording")
    .accessibilityHint("Begins recording your voice for transcription")

// Ensure proper focus order
.accessibilityElement(children: .combine)

// Add reduced motion support
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animationToUse: Animation {
    reduceMotion ? .none : DesignSystem.springAnimation
}
```

### Task 9.6.3: Dark Mode Verification
```swift
// Test all Liquid Glass materials in both appearances
// Verify contrast ratios meet accessibility standards
// Test hover states in both modes
// Ensure no hardcoded colors break dark mode
```

### Task 9.6.4: Comprehensive Testing Protocol
1. **Visual Testing**
   - All views in Light and Dark mode
   - Hover states on every interactive element
   - Animation smoothness at 60fps
   - Material translucency effects

2. **Functionality Testing**
   - Sidebar collapse/expand with content response
   - All navigation paths work correctly
   - Settings sections expand/collapse properly
   - Media controls compact layout functional

3. **Accessibility Testing**
   - VoiceOver navigation
   - Keyboard navigation throughout
   - Reduced motion preference respected
   - High contrast compatibility

4. **Performance Testing**
   - Memory usage stable during extended use
   - CPU usage reasonable during animations
   - No memory leaks from hover state tracking

### Task 9.6.5: Documentation Update
```markdown
# Update CLAUDE.md with Phase 9 completion:
- Full Liquid Glass implementation with all materials and animations
- Navigation consolidated (AI Providers moved to Settings)
- Responsive sidebar with proper collapsed state functionality
- Media controls optimized for 60% space reduction
- Home screen titles simplified removing redundancy
- Comprehensive hover states and button hierarchy
- Performance optimized for smooth 60fps animations
- Full accessibility compliance including VoiceOver and reduced motion

# Update README.md with:
- Version bump to v1.2.0-ui-complete
- New UI/UX features summary
- Liquid Glass design system implementation
```

**Final Test Protocol**:
1. Complete app walkthrough in both Light/Dark modes
2. Test every interactive element for hover states
3. Verify sidebar collapse/expand with content response
4. Test all navigation flows
5. Verify smooth 60fps animations
6. Test with VoiceOver enabled
7. Check memory usage over 30-minute session

**Phase 9 Final Checkpoint**:
- [ ] All Liquid Glass materials implemented
- [ ] Sidebar fully responsive with proper collapsed state
- [ ] Home screen titles simplified and cleaned
- [ ] Media controls significantly more compact
- [ ] AI Providers integrated into Settings
- [ ] Comprehensive hover states throughout
- [ ] Button hierarchy standardized
- [ ] Performance optimized for 60fps
- [ ] Full accessibility compliance
- [ ] Documentation updated
- [ ] Git commit: "Complete Phase 9 - UI Tidy Up"
- [ ] Tag: v1.2.0-ui-complete

---

## Success Metrics

### **Visual Polish** ✅
- Every interface element follows Liquid Glass design principles
- Consistent materials, shadows, and corner radius throughout
- Smooth 60fps animations across all interactions
- Perfect Light/Dark mode adaptation

### **Usability Improvements** ✅
- Sidebar collapse provides 200px additional content width
- Media controls use 60% less vertical space
- Home screen eliminates redundant titles
- Navigation reduced from 6 to 5 main sections

### **Technical Excellence** ✅
- No memory leaks from hover state tracking
- Animations optimized for performance
- Full accessibility including VoiceOver support
- Responsive design adapts to all window states

### **User Experience** ✅
- App feels like a premium, first-party macOS application
- Every interaction provides appropriate visual feedback
- Information hierarchy is clear and logical
- No friction in primary user workflows

This comprehensive Phase 9 transforms Transcriptly from a functional app into a polished, professional application that fully embraces Apple's latest design language while solving all identified usability issues.