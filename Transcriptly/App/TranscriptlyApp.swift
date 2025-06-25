//
//  TranscriptlyApp.swift
//  Transcriptly
//
//  Created by Bob Kitchen on 6/25/25.
//

import SwiftUI
import CoreData

@main
struct TranscriptlyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
