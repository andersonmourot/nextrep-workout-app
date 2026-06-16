import Foundation

struct ActiveWorkoutSummary: Codable, Identifiable {
    var id = UUID()
    var programId: String
    var programName: String
    var dayId: String
    var dayName: String
    var startedAt: Double
    var completedAt: Double
    var durationSeconds: Int
    var setsCompleted: Int
    var totalSets: Int
    var totalVolume: Double
    var sets: [[SetLog]]  // Flattened sets from all exercises
}