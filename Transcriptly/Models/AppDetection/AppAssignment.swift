//
//  AppAssignment.swift
//  Transcriptly
//
//  Created by Claude Code on 6/28/25.
//  App Detection & Assignment - App Assignment Model
//

import Foundation

struct AppAssignment: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID?
    let appBundleId: String
    let appName: String
    let assignedMode: RefinementMode
    let isUserOverride: Bool
    let createdAt: Date
    let updatedAt: Date
    
    init(
        appInfo: AppInfo,
        mode: RefinementMode,
        isUserOverride: Bool = true,
        userId: UUID? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.appBundleId = appInfo.bundleIdentifier
        self.appName = appInfo.displayName
        self.assignedMode = mode
        self.isUserOverride = isUserOverride
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // For creating assignments from database data
    init(
        id: UUID,
        userId: UUID?,
        appBundleId: String,
        appName: String,
        assignedMode: RefinementMode,
        isUserOverride: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.appBundleId = appBundleId
        self.appName = appName
        self.assignedMode = assignedMode
        self.isUserOverride = isUserOverride
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}