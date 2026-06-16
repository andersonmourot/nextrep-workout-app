import Foundation

struct AppData: Codable {
    var themeColor: String?
    var customPrograms: [Program]
    var customExercises: [Exercise]
    var activeWorkout: ActiveWorkout?
    var exerciseNotes: [String: String]
    var exerciseSubheaders: [String: String]
    var history: [WorkoutHistoryEntry]
    var completedPrograms: [CompletedProgram]
    var logs: [WorkoutLog]
    
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
        case completedPrograms
        case logs
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
        completedPrograms = try container.decodeIfPresent([CompletedProgram].self, forKey: .completedPrograms) ?? []
        logs = try container.decodeIfPresent([WorkoutLog].self, forKey: .logs) ?? []
        
        // Store unknown keys for round-tripping
        let knownKeys: Set<String> = ["themeColor", "customPrograms", "customExercises", "activeWorkout", "exerciseNotes", "exerciseSubheaders", "history", "completedPrograms", "logs"]
        let additionalKeys = container.allKeys.filter { !knownKeys.contains($0.stringValue) }
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
        try container.encode(completedPrograms, forKey: .completedPrograms)
        try container.encode(logs, forKey: .logs)
    }
    
    init() {
        themeColor = "#355e3b"
        customPrograms = []
        customExercises = []
        activeWorkout = nil
        exerciseNotes = [:]
        exerciseSubheaders = [:]
        history = []
        completedPrograms = []
        logs = []
    }
}

struct WorkoutHistoryEntry: Codable {
    var programId: String
    var dayId: String
    var completedAt: Double
    var duration: Int
}

struct ExerciseLog: Codable, Identifiable {
    let id: String
    let exerciseId: String
    let sets: [SetLog]
}

struct WorkoutLog: Codable, Identifiable {
    let id: String
    let programId: String
    let dayId: String
    let week: Int?
    let date: String
    let totalVolume: Double
    let exercises: [ExerciseLog]
}

struct CompletedProgram: Codable, Identifiable {
    var id: String
    var programId: String
    var program: Program
    var completedAt: String
    var loggedWorkoutCount: Int
    
    var name: String {
        program.name
    }
    
    var accent: String? {
        program.accent
    }
}