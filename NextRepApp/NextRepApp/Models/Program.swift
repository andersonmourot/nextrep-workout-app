import Foundation

struct Program: Codable, Identifiable {
    let id: String
    var name: String
    var category: String
    var level: String
    var coach: String
    var durationWeeks: Int
    var daysPerWeek: Int
    var days: [ProgramDay]
    var ownerId: String?
    var ownerName: String?
    var collaborative: Bool?
    var version: Int?
    var weekOverrides: [String: String]?
}