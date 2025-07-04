//
//  ShortcutRecorder.swift
//  Transcriptly
//
//  NSView-based shortcut recorder for capturing custom keyboard shortcuts
//

import SwiftUI
import Cocoa
import Carbon

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var keyCode: Int
    @Binding var modifiers: NSEvent.ModifierFlags
    let onShortcutChange: (Int, NSEvent.ModifierFlags) -> Void
    
    func makeNSView(context: Context) -> ShortcutRecorderView {
        let view = ShortcutRecorderView()
        view.delegate = context.coordinator
        view.currentKeyCode = keyCode
        view.currentModifiers = modifiers
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
        didSet { 
            DispatchQueue.main.async { [weak self] in
                self?.needsDisplay = true
            }
        }
    }
    
    var currentModifiers: NSEvent.ModifierFlags = [] {
        didSet { 
            DispatchQueue.main.async { [weak self] in
                self?.needsDisplay = true
            }
        }
    }
    
    private var isRecording = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.needsDisplay = true
            }
        }
    }
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
        
        // Set initial drawing state
        needsDisplay = true
    }
    
    override var acceptsFirstResponder: Bool { false }
    
    override func mouseDown(with event: NSEvent) {
        // Handle the click directly without changing first responder
        if !isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        
        // Use global monitor to avoid focus issues
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleKeyEvent(event)
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
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Ensure we're on main thread and have a valid context
        guard Thread.isMainThread,
              let context = NSGraphicsContext.current else { return }
        
        super.draw(dirtyRect)
        
        // Save graphics state
        context.saveGraphicsState()
        defer { context.restoreGraphicsState() }
        
        // Fill background
        NSColor.controlBackgroundColor.setFill()
        dirtyRect.fill()
        
        // Determine text and color
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
        
        // Create attributed string
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        // Calculate text rect
        let textSize = attributedString.size()
        let textRect = NSRect(
            x: 0,
            y: (bounds.height - textSize.height) / 2,
            width: bounds.width,
            height: textSize.height
        )
        
        // Draw the text
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