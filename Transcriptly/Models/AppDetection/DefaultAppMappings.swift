//
//  DefaultAppMappings.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  App Detection & Assignment - Default App to Mode Mappings
//

import Foundation

struct DefaultAppMappings {
    static let mappings: [String: RefinementMode] = [
        // Email clients
        "com.apple.mail": .email,
        "com.microsoft.Outlook": .email,
        "com.apple.MailCompose": .email,
        "com.readdle.smartemail-Mac": .email,
        "com.postbox-inc.postboxexpress": .email,
        "com.freron.MailMate": .email,
        "com.aerofs.thunderbird": .email,
        
        // Messaging apps
        "com.apple.MobileSMS": .messaging,
        "com.tinyspeck.slackmacgap": .messaging,
        "com.hnc.Discord": .messaging,
        "com.facebook.archon.developerID": .messaging,
        "com.microsoft.teams2": .messaging,
        "org.whispersystems.signal-desktop": .messaging,
        "com.telegram.desktop": .messaging,
        "com.skype.skype": .messaging,
        "us.zoom.xos": .messaging,
        "com.apple.FaceTime": .messaging,
        
        // Text editors and writing apps
        "com.apple.TextEdit": .cleanup,
        "com.microsoft.Word": .cleanup,
        "com.apple.Notes": .cleanup,
        "com.notion.desktop": .cleanup,
        "com.bear-writer.BearOSX": .cleanup,
        "com.uranusjr.macdown": .cleanup,
        "com.typora.typora": .cleanup,
        "com.ulyssesapp.mac": .cleanup,
        "com.literatureandlatte.scrivener3": .cleanup,
        "com.apple.iWork.Pages": .cleanup,
        "com.google.GoogleDocs": .cleanup,
        
        // Development tools (cleanup for comments/docs)
        "com.microsoft.VSCode": .cleanup,
        "com.apple.dt.Xcode": .cleanup,
        "com.jetbrains.intellij": .cleanup,
        "com.jetbrains.AppCode": .cleanup,
        "com.sublimetext.4": .cleanup,
        "com.github.atom": .cleanup,
        "com.coteditor.CotEditor": .cleanup,
        "com.apple.Terminal": .cleanup,
        
        // Browsers default to cleanup
        "com.apple.Safari": .cleanup,
        "com.google.Chrome": .cleanup,
        "org.mozilla.firefox": .cleanup,
        "com.microsoft.edgemac": .cleanup,
        "com.vivaldi.Vivaldi": .cleanup,
        "com.operasoftware.Opera": .cleanup,
        "com.brave.Browser": .cleanup
    ]
    
    static func defaultMode(for bundleId: String) -> RefinementMode? {
        return mappings[bundleId]
    }
    
    static var allSupportedApps: [(String, String, RefinementMode)] {
        return mappings.map { (bundleId, mode) in
            // Extract app name from bundle ID
            let components = bundleId.components(separatedBy: ".")
            let appName = components.last?.capitalized ?? "Unknown"
            return (bundleId, appName, mode)
        }
    }
    
    static func getAppsForMode(_ mode: RefinementMode) -> [String] {
        return mappings.compactMap { (bundleId, mappedMode) in
            mappedMode == mode ? bundleId : nil
        }
    }
    
    static var supportedAppCount: Int {
        return mappings.count
    }
}