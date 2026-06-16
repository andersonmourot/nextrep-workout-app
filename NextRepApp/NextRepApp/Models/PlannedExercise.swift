import Foundation

struct PlannedExercise: Codable, Identifiable {
    var exerciseId: String
    var name: String?
    var sets: Int
    var reps: String
    var restSec: Int
    var notes: String?
    var groupId: String?
    
    var id: String {
        return exerciseId
    }
}