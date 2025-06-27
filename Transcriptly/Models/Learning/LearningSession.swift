import Foundation

struct LearningSession: Codable {
    let id: UUID
    let timestamp: Date
    let originalTranscription: String
    let aiRefinement: String
    let userFinalVersion: String
    let refinementMode: RefinementMode
    let textLength: Int
    let learningType: LearningType
    let wasSkipped: Bool
    
    enum LearningType: String, Codable {
        case editReview
        case abTesting
    }
}