import Foundation

struct LearningSession: Codable, Sendable {
    let id: UUID
    var userId: UUID?
    let timestamp: Date
    let originalTranscription: String
    let aiRefinement: String
    let userFinalVersion: String
    let refinementMode: RefinementMode
    let textLength: Int
    let learningType: LearningType
    let wasSkipped: Bool
    var deviceId: String?
    
    enum LearningType: String, Codable {
        case editReview
        case abTesting
    }
}