//
//  AppInfo.swift
//  Transcriptly
//
//  Created by Claude Code on 6/26/25.
//

import Foundation
import AppKit

struct AppInfo: Identifiable, Hashable, Sendable {
    let bundleIdentifier: String
    let localizedName: String
    nonisolated(unsafe) let icon: NSImage?
    let executablePath: String?
    
    var id: String { bundleIdentifier }
    
    var displayName: String {
        localizedName
    }
    
    init(bundleIdentifier: String, localizedName: String, icon: NSImage? = nil, executablePath: String? = nil) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.icon = icon
        self.executablePath = executablePath
    }
}