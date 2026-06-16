import Foundation

struct Program: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var category: String?
    var level: String?
    var goal: String?
    var coach: String?
    var durationWeeks: Int?
    var daysPerWeek: Int?
    var accent: String?
    var summary: String?
    var description: String?
    var tags: [String]?
    var days: [Day]
    
    // User/custom program fields (optional)
    var ownerId: String?
    var ownerName: String?
    var collaborative: Bool?
    var version: Int?
    var weekOverrides: [String: String]?
    var isCustom: Bool?
}