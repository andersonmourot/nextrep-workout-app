import Foundation

struct Day: Codable, Identifiable {
    let id: String
    var name: String?
    var focus: String?
    var exercises: [DayExercise]
}

struct DayExercise: Codable, Identifiable {
    let id = UUID()
    let exerciseId: String
    let sets: Int?
    let reps: String  // It's "6-10", NOT an Int
    let restSec: Int?
    let groupId: String?  // Optional - present only on supersets
}