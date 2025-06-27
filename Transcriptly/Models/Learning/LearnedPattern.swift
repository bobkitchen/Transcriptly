import Foundation

struct LearnedPattern: Codable, Identifiable {
    let id: UUID
    var userId: UUID?
    let originalPhrase: String
    let correctedPhrase: String
    let occurrenceCount: Int
    let firstSeen: Date
    let lastSeen: Date
    let refinementMode: RefinementMode?
    let confidence: Double
    var isActive: Bool
    
    var isReady: Bool {
        occurrenceCount >= 3 && confidence > 0.6
    }
}