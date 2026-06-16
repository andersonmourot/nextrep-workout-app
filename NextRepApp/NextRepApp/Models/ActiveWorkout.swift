import Foundation

struct ActiveWorkout: Codable {
    var programId: String
    var dayId: String
    var week: Int?
    var startedAt: Double
    var sets: [[SetLog]]
    var exerciseIds: [String]
}