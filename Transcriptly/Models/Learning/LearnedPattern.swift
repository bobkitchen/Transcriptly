import Foundation

struct LearnedPattern: Codable, Identifiable {
    let id: UUID
    let originalPhrase: String
    let correctedPhrase: String
    let occurrenceCount: Int
    let firstSeen: Date
    let lastSeen: Date
    let refinementMode: RefinementMode?
    let confidence: Double // 0.0 to 1.0
    
    var isActive: Bool {
        occurrenceCount >= 3 && confidence > 0.6
    }
}