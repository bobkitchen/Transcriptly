//
//  AppInfo.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation
import AppKit

struct AppInfo: Identifiable, Hashable {
    let bundleIdentifier: String
    let localizedName: String
    let icon: NSImage?
    
    var id: String { bundleIdentifier }
    
    init(bundleIdentifier: String, localizedName: String, icon: NSImage? = nil) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.icon = icon
    }
}