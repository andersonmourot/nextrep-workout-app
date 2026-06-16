import Foundation

struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var primaryMuscle: String?
    var secondaryMuscles: [String]?
    var equipment: String?
    var difficulty: String?
    var instructions: [String]?
    var tips: [String]?
    var photos: [String]?  // Optional
    
    // User/custom exercise fields (optional)
    var ownerId: String?
    var collaborative: Bool?
    var version: Int?
}