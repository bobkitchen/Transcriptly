# Transcriptly Phase 6 - UI Polish & Native Compliance Task List

## Phase 6.0: Setup and Planning

### Task 6.0.1: Create Phase 6 Branch
```bash
git checkout main
git pull origin main
git checkout -b phase-6-ui-polish
git push -u origin phase-6-ui-polish
```

### Task 6.0.2: Audit Current UI Against Apple Standards
Document specific differences between current implementation and Apple's native apps:
- Screenshot comparison with Tasks/Notes apps
- List all non-compliant elements
- Prioritize by user impact

### Task 6.0.3: Create UI Polish Design System
```swift
// Create UIPolishDesignSystem.swift
struct UIPolishDesignSystem {
    // Sidebar specifications
    static let sidebarWidth: CGFloat = 200
    static let sidebarInset: CGFloat = 16
    static let sidebarCornerRadius: CGFloat = 12
    
    // Enhanced contrast values
    static let cardContrastMaterial: Material = .regularMaterial
    static let borderOpacity: Double = 0.15
    static let shadowRadius: CGFloat = 8
    
    // Mode indicator styling
    static let modeIndicatorHeight: CGFloat = 28
    static let modeIndicatorPadding: CGFloat = 12
}
```

**Checkpoint 6.0**:
- [ ] Branch created and current state documented
- [ ] Design system constants defined
- [ ] Implementation plan finalized
- [ ] Git commit: "Setup Phase 6 UI polish foundation"

---

## Phase 6.1: Inset Sidebar Implementation (Apple 2024 Standard)

### Task 6.1.1: Restructure Main Window Layout
```swift
// Update MainWindowView.swift - CRITICAL ARCHITECTURAL CHANGE
struct MainWindowView: View {
    @StateObject var viewModel = MainViewModel()
    @State private var selectedSection: SidebarSection = .home
    
    var body: some View {
        VStack(spacing: 0) {
            // Keep top bar
            TopBar(viewModel: viewModel, showCapsuleMode: capsuleManager.showCapsule)
            
            // NEW LAYOUT: Full-width content with floating sidebar
            ZStack(alignment: .leading) {
                // Full-width content area (extends behind sidebar)
                MainContentView(
                    selectedSection: $selectedSection,
                    viewModel: viewModel
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primaryBackground)
                
                // Floating inset sidebar
                InsetSidebarView(selectedSection: $selectedSection)
                    .padding(.leading, UIPolishDesignSystem.sidebarInset)
                    .padding(.vertical, UIPolishDesignSystem.sidebarInset)
            }
        }
        .frame(minWidth: 920, minHeight: 640)
    }
}
```

### Task 6.1.2: Create Inset Sidebar Component
```swift
// Create Views/Sidebar/InsetSidebarView.swift
struct InsetSidebarView: View {
    @Binding var selectedSection: SidebarSection
    @State private var hoveredSection: SidebarSection?
    
    var body: some View {
        VStack(spacing: 2) {
            // Navigation header
            HStack {
                Text("NAVIGATION")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.tertiaryText)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Navigation items
            VStack(spacing: 2) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    SidebarItemView(
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
            }
            .padding(.horizontal, 8)
            
            Spacer()
        }
        .frame(width: UIPolishDesignSystem.sidebarWidth)
        .padding(.vertical, 12)
        .background(.sidebar)  // Use proper sidebar material
        .cornerRadius(UIPolishDesignSystem.sidebarCornerRadius)
        .shadow(
            color: .black.opacity(0.1),
            radius: UIPolishDesignSystem.shadowRadius,
            y: 4
        )
    }
}
```

### Task 6.1.3: Update Sidebar Item for Native Selection
```swift
// Update Views/Sidebar/SidebarItemView.swift for native compliance
struct SidebarItemView: View {
    let section: SidebarSection
    let isSelected: Bool
    let isHovered: Bool
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.icon)
                .font(.system(size: 16))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(section.rawValue)
                .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                .foregroundColor(textColor)
            
            Spacer()
            
            if !isEnabled {
                Text("Soon")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.tertiaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(selectionBackground)
        .cornerRadius(6)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
    
    @ViewBuilder
    private var selectionBackground: some View {
        if isSelected {
            // Native macOS selection style
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.15))
        } else if isHovered && isEnabled {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
        } else {
            Color.clear
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

### Task 6.1.4: Adjust Content Views for New Layout
```swift
// Update all main content views to account for sidebar overlay
// Add appropriate leading padding where needed
extension View {
    func adjustForInsetSidebar() -> some View {
        self.padding(.leading, UIPolishDesignSystem.sidebarWidth + (UIPolishDesignSystem.sidebarInset * 2))
    }
}

// Apply to main content areas that need adjustment
struct HomeView: View {
    var body: some View {
        ScrollView {
            // Existing content
        }
        .adjustForInsetSidebar()
    }
}
```

**Test Protocol 6.1**:
1. Verify sidebar floats over content
2. Check content flows behind sidebar
3. Test sidebar material transparency
4. Verify selection states match Apple apps
5. Ensure smooth hover animations

**Checkpoint 6.1**:
- [ ] Inset sidebar implemented
- [ ] Content flows behind sidebar
- [ ] Selection states native-compliant
- [ ] All views properly adjusted
- [ ] Git commit: "Implement Apple-standard inset sidebar"

---

## Phase 6.2: Custom Mode Indicator

### Task 6.2.1: Create Custom Mode Indicator Component
```swift
// Create Components/ModeIndicator.swift
struct ModeIndicator: View {
    @Binding var currentMode: RefinementMode
    @State private var showModeMenu = false
    
    var body: some View {
        Menu {
            ForEach(RefinementMode.allCases, id: \.self) { mode in
                Button(action: { 
                    currentMode = mode
                    HapticFeedback.selection()
                }) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.displayName)
                                .font(.system(size: 14, weight: .medium))
                            Text(mode.description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: mode.icon)
                            .foregroundColor(mode.accentColor)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                // Mode icon with accent color
                Image(systemName: currentMode.icon)
                    .font(.system(size: 14))
                    .foregroundColor(currentMode.accentColor)
                    .symbolRenderingMode(.hierarchical)
                
                // Full mode name (no truncation)
                Text(currentMode.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primaryText)
                
                // Subtle dropdown indicator
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.tertiaryText)
            }
            .padding(.horizontal, UIPolishDesignSystem.modeIndicatorPadding)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .cornerRadius(UIPolishDesignSystem.modeIndicatorHeight / 2)
            .overlay(
                RoundedRectangle(cornerRadius: UIPolishDesignSystem.modeIndicatorHeight / 2)
                    .strokeBorder(Color.white.opacity(UIPolishDesignSystem.borderOpacity), lineWidth: 0.5)
            )
        }
        .menuStyle(.borderlessButton)
        .help("Switch refinement mode")
    }
}

// Add accent colors to RefinementMode
extension RefinementMode {
    var accentColor: Color {
        switch self {
        case .raw: return .gray
        case .cleanup: return .blue
        case .email: return .green
        case .messaging: return .purple
        }
    }
}

// Haptic feedback helper
struct HapticFeedback {
    static func selection() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
}
```

### Task 6.2.2: Update Top Bar with New Mode Indicator
```swift
// Update Components/TopBar.swift
struct TopBar: View {
    @ObservedObject var viewModel: MainViewModel
    let showCapsuleMode: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Subtle app title
            Text("Transcriptly")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.tertiaryText)
            
            Spacer()
            
            // New custom mode indicator
            ModeIndicator(currentMode: $viewModel.currentMode)
            
            // Compact record button
            CompactRecordButton(
                isRecording: viewModel.isRecording,
                recordingTime: viewModel.recordingTime,
                action: viewModel.toggleRecording
            )
            
            // Updated capsule button (next task)
            FloatingModeButton(action: showCapsuleMode)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .overlay(
            Divider()
                .background(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }
}
```

**Test Protocol 6.2**:
1. Verify mode indicator shows full names
2. Test dropdown menu functionality
3. Check haptic feedback on selection
4. Verify visual connection to mode cards
5. Test accessibility with VoiceOver

**Checkpoint 6.2**:
- [ ] Custom mode indicator implemented
- [ ] Full mode names displayed
- [ ] Interactive menu functional
- [ ] Haptic feedback working
- [ ] Git commit: "Replace dropdown with custom mode indicator"

---

## Phase 6.3: Intuitive Capsule Control

### Task 6.3.1: Create Clear Floating Mode Button
```swift
// Create Components/FloatingModeButton.swift
struct FloatingModeButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Clear "floating overlay" icon
                Image(systemName: "pip.enter")
                    .font(.system(size: 12))
                    .symbolRenderingMode(.hierarchical)
                
                // Text label for ultimate clarity
                Text("Float")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? Color.white.opacity(0.1) : Color.clear)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .help("Enter floating recording mode")
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Alternative: Icon-only with better symbol
struct FloatingModeIconButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "pip.enter")
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .help("Enter floating recording mode")
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
```

### Task 6.3.2: Test Icon Options and Choose Best
Create variants to test:
1. **`pip.enter`** - Picture-in-Picture (floating overlay concept)
2. **`macwindow.on.rectangle`** - Window floating over content
3. **Text + Icon combo** - "Float" + `pip.enter`
4. **Custom combined icon** - Microphone + floating indicator

Test with 3-5 users to determine most intuitive option.

### Task 6.3.3: Update Capsule Mode Integration
```swift
// Ensure floating mode button properly launches capsule
// Add animation/feedback when entering capsule mode
// Consider brief tutorial overlay on first use
```

**Test Protocol 6.3**:
1. Test icon recognition with users
2. Verify help text clarity
3. Check button launching capsule mode
4. Test hover animations
5. Validate accessibility

**Checkpoint 6.3**:
- [ ] Clear floating mode button implemented
- [ ] User testing confirms icon clarity
- [ ] Help text is descriptive
- [ ] Smooth hover animations
- [ ] Git commit: "Replace confusing capsule icon with clear floating mode button"

---

## Phase 6.4: Enhanced Visual Polish

### Task 6.4.1: Improve Card Contrast and Definition
```swift
// Update all card components for better contrast
extension View {
    func enhancedCard() -> some View {
        self
            .padding(20)
            .background(.regularMaterial)  // Stronger than ultraThin
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(UIPolishDesignSystem.borderOpacity), lineWidth: 0.5)
            )
            .shadow(
                color: .black.opacity(0.1),
                radius: UIPolishDesignSystem.shadowRadius,
                y: 4
            )
    }
}

// Apply to StatCard, TranscriptionCard, etc.
struct StatCard: View {
    // ... existing implementation
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ... existing content
        }
        .enhancedCard()
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
```

### Task 6.4.2: Add Meaningful Hover States
```swift
// Update TranscriptionCard with hover actions
struct TranscriptionCard: View {
    let transcription: TranscriptionRecord
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            // Existing content
            VStack(alignment: .leading, spacing: 4) {
                Text(transcription.title)
                    .font(.system(size: 14, weight: .medium))
                
                // Metadata row
                HStack(spacing: 12) {
                    Text(transcription.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                    
                    Text("•").foregroundColor(.tertiaryText)
                    
                    Text("\(transcription.wordCount) words")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                    
                    Text("•").foregroundColor(.tertiaryText)
                    
                    Label(transcription.mode.displayName, systemImage: transcription.mode.icon)
                        .font(.system(size: 12))
                        .foregroundColor(transcription.mode.accentColor)
                }
            }
            
            Spacer()
            
            // Hover actions
            if isHovered {
                HStack(spacing: 8) {
                    Button("Copy") {
                        NSPasteboard.general.setString(transcription.refinedText, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("View") {
                        // Show detail view
                    }
                    .buttonStyle(.borderedProminent)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.white.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}
```

### Task 6.4.3: Refine Typography and Spacing
```swift
// Create consistent typography scale
extension Font {
    static let transcriptlyTitle = Font.system(size: 24, weight: .semibold, design: .default)
    static let transcriptlyHeadline = Font.system(size: 18, weight: .medium, design: .default)
    static let transcriptlyBody = Font.system(size: 14, weight: .regular, design: .default)
    static let transcriptlyCaption = Font.system(size: 12, weight: .regular, design: .default)
    static let transcriptlyMicro = Font.system(size: 10, weight: .medium, design: .default)
}

// Apply consistently throughout app
Text("Welcome back")
    .font(.transcriptlyTitle)
    .foregroundColor(.primaryText)
```

### Task 6.4.4: Add Micro-Interactions
```swift
// Add subtle feedback throughout the app
extension View {
    func pressEffect() -> some View {
        self.scaleEffect(0.98)
            .animation(.spring(response: 0.1, dampingFraction: 0.9), value: true)
    }
    
    func hoverGlow() -> some View {
        self.shadow(
            color: .accentColor.opacity(0.3),
            radius: 8,
            x: 0,
            y: 0
        )
    }
}
```

**Test Protocol 6.4**:
1. Verify improved contrast in all lighting conditions
2. Test hover states feel responsive
3. Check typography hierarchy is clear
4. Validate micro-interactions feel polished
5. Ensure performance remains smooth

**Checkpoint 6.4**:
- [ ] Card contrast significantly improved
- [ ] Meaningful hover states added
- [ ] Typography refined and consistent
- [ ] Micro-interactions feel polished
- [ ] Git commit: "Enhance visual polish and interactions"

---

## Phase 6.5: Final Integration and Testing

### Task 6.5.1: Cross-Platform Testing
1. **Test all screen sizes** - Various resolutions and scaling
2. **Multi-monitor scenarios** - Different configurations
3. **Accessibility validation** - VoiceOver, keyboard navigation
4. **Performance testing** - Smooth 60fps throughout

### Task 6.5.2: User Testing Validation
1. **Icon recognition** - Verify floating mode button is clear
2. **Mode switching** - Test custom indicator usability
3. **Overall feel** - Compare against Apple's native apps
4. **Confusion points** - Identify any remaining unclear elements

### Task 6.5.3: Polish Pass
1. **Animation timing** - Ensure all feel consistent
2. **Color adjustments** - Fine-tune contrast as needed
3. **Spacing refinements** - Perfect the visual rhythm
4. **Edge case handling** - Graceful degradation

**Final Testing Protocol**:
1. Side-by-side comparison with Apple Tasks app
2. Complete user workflow testing
3. Accessibility audit with screen reader
4. Performance validation under load
5. Cross-platform compatibility check

**Phase 6 Final Checkpoint**:
- [ ] Sidebar matches Apple's 2024 standard exactly
- [ ] Mode indicator is elegant and functional
- [ ] Floating mode button is immediately clear
- [ ] Overall app feels premium and native
- [ ] No user confusion points remain
- [ ] Performance is smooth throughout
- [ ] Git commit: "Complete Phase 6 UI polish"
- [ ] Tag: v1.2.0-ui-native-complete

## Success Criteria

### Native Compliance ✅
- Inset sidebar matches Apple's Tasks/Notes apps
- Selection states follow macOS standards
- Materials and effects are system-appropriate

### User Experience ✅
- Mode switching is elegant and clear
- Floating mode button is immediately understandable
- All interactions feel smooth and responsive
- App indistinguishable from first-party Apple apps

### Visual Quality ✅
- Enhanced contrast improves readability
- Hover states provide meaningful feedback
- Typography creates clear information hierarchy
- Micro-interactions delight without distraction

This phase will elevate Transcriptly to truly premium, native-feeling macOS application that exceeds user expectations for polish and usability.