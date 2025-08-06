//
//  VisualEffectView.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

extension VisualEffectView {
    func cornerRadius(_ radius: CGFloat) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius))
    }
}