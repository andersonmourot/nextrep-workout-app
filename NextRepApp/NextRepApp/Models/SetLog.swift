import Foundation

struct SetLog: Codable, Identifiable, Hashable {
    var id = UUID()
    var weight: Double
    var reps: Int
    var completed: Bool
}