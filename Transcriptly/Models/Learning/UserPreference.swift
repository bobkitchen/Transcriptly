import Foundation

struct UserPreference: Codable, Sendable {
    enum PreferenceType: String, Codable {
        case formality
        case conciseness
        case contractions
        case punctuation
    }
    
    let id: UUID
    var userId: UUID?
    let type: PreferenceType
    let value: Double // -1.0 to 1.0
    let sampleCount: Int
    let lastUpdated: Date
}