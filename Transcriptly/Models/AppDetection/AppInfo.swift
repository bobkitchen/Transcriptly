//
//  AppInfo.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  App Detection & Assignment - App Information Model
//

import Foundation
import AppKit

struct AppInfo: Codable, Equatable, Sendable {
    let bundleIdentifier: String
    let localizedName: String
    let executablePath: String?
    
    init(from app: NSRunningApplication) {
        self.bundleIdentifier = app.bundleIdentifier ?? "unknown"
        self.localizedName = app.localizedName ?? "Unknown App"
        self.executablePath = app.executableURL?.path
    }
    
    init(bundleIdentifier: String, localizedName: String, executablePath: String?) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.executablePath = executablePath
    }
    
    var isSystemApp: Bool {
        let lowercaseBundleId = bundleIdentifier.lowercased()
        return lowercaseBundleId.hasPrefix("com.apple.") && 
        !lowercaseBundleId.contains("mail") &&
        !lowercaseBundleId.contains("messages") &&
        !lowercaseBundleId.contains("notes") &&
        !lowercaseBundleId.contains("textedit") &&
        !lowercaseBundleId.contains("terminal") &&
        !lowercaseBundleId.contains("safari") &&
        !lowercaseBundleId.contains("facetime") &&
        !lowercaseBundleId.contains("pages")
    }
    
    var displayName: String {
        localizedName.replacingOccurrences(of: ".app", with: "")
    }
    
    var isTranscriptly: Bool {
        bundleIdentifier == Bundle.main.bundleIdentifier
    }
}