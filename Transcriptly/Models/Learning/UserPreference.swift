import Foundation

struct UserPreference: Codable {
    enum PreferenceType: String, Codable {
        case formality // formal vs casual
        case conciseness // verbose vs concise
        case contractions // use vs avoid
        case punctuation // heavy vs light
    }
    
    let id: UUID
    let type: PreferenceType
    let value: Double // -1.0 to 1.0 scale
    let sampleCount: Int
    let lastUpdated: Date
}