import Foundation

struct ProgramDay: Codable, Identifiable {
    let id: String
    var name: String
    var focus: String
    var exercises: [PlannedExercise]
}