import Foundation

struct AppData: Codable {
    var themeColor: String?
    var customPrograms: [Program]
    var customExercises: [Exercise]
    var activeWorkout: ActiveWorkout?
    var exerciseNotes: [String: String]
    var exerciseSubheaders: [String: String]
    var history: [WorkoutHistoryEntry]
    
    // Handle unknown keys for round-tripping
    private var additionalProperties: [String: Any] = [:]
    
    enum CodingKeys: String, CodingKey {
        case themeColor
        case customPrograms
        case customExercises
        case activeWorkout
        case exerciseNotes
        case exerciseSubheaders
        case history
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        themeColor = try container.decodeIfPresent(String.self, forKey: .themeColor)
        customPrograms = try container.decodeIfPresent([Program].self, forKey: .customPrograms) ?? []
        customExercises = try container.decodeIfPresent([Exercise].self, forKey: .customExercises) ?? []
        activeWorkout = try container.decodeIfPresent(ActiveWorkout.self, forKey: .activeWorkout)
        exerciseNotes = try container.decodeIfPresent([String: String].self, forKey: .exerciseNotes) ?? [:]
        exerciseSubheaders = try container.decodeIfPresent([String: String].self, forKey: .exerciseSubheaders) ?? [:]
        history = try container.decodeIfPresent([WorkoutHistoryEntry].self, forKey: .history) ?? []
        
        // Store unknown keys for round-tripping
        let additionalKeys = container.allKeys.filter { !CodingKeys.allCases.contains($0) }
        for key in additionalKeys {
            // We'll need to handle this more carefully in a real implementation
            // For now, we'll just note that we should preserve these
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(themeColor, forKey: .themeColor)
        try container.encode(customPrograms, forKey: .customPrograms)
        try container.encode(customExercises, forKey: .customExercises)
        try container.encodeIfPresent(activeWorkout, forKey: .activeWorkout)
        try container.encode(exerciseNotes, forKey: .exerciseNotes)
        try container.encode(exerciseSubheaders, forKey: .exerciseSubheaders)
        try container.encode(history, forKey: .history)
    }
    
    init() {
        themeColor = "#355e3b"
        customPrograms = []
        customExercises = []
        activeWorkout = nil
        exerciseNotes = [:]
        exerciseSubheaders = [:]
        history = []
    }
}

struct WorkoutHistoryEntry: Codable {
    var programId: String
    var dayId: String
    var completedAt: Double
    var duration: Int
}