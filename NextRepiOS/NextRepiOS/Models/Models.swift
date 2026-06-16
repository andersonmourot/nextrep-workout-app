import Foundation

// MARK: - Exercise
struct Exercise: Codable, Identifiable {
    let id: String
    var name: String
    var primaryMuscle: String
    var secondaryMuscles: [String]
    var equipment: String
    var difficulty: String
    var instructions: [String]
    var tips: [String]
    var ownerId: String?
    var collaborative: Bool?
    var version: Int?
    
    // Optional catalog fields
    var goal: String?
    var accent: String?
    var summary: String?
    var tags: [String]?
}

// MARK: - PlannedExercise
struct PlannedExercise: Codable, Identifiable {
    var exerciseId: String
    var name: String?
    var sets: Int
    var reps: String
    var restSec: Int
    var notes: String?
    var groupId: String?
    
    var id: String {
        exerciseId
    }
}

// MARK: - ProgramDay
struct ProgramDay: Codable, Identifiable {
    let id: String
    var name: String
    var focus: String
    var exercises: [PlannedExercise]
}

// MARK: - Program
struct Program: Codable, Identifiable {
    let id: String
    var name: String
    var category: String
    var level: String
    var coach: String
    var durationWeeks: Int
    var daysPerWeek: Int
    var days: [ProgramDay]
    var weekOverrides: [String: [WeekOverride]]?
    var ownerId: String?
    var ownerName: String?
    var collaborative: Bool?
    var version: Int?
    var completedAt: String?
    
    // Optional catalog fields
    var goal: String?
    var accent: String?
    var summary: String?
    var tags: [String]?
}

// MARK: - WeekOverride
struct WeekOverride: Codable {
    let fromWeek: Int
    let day: ProgramDay
}

// MARK: - SetLog
struct SetLog: Codable, Identifiable {
    let id: String
    var weight: Double
    var reps: Int
    var completed: Bool
}

// MARK: - ExerciseLog
struct ExerciseLog: Codable, Identifiable {
    let id: String
    let exerciseId: String
    let sets: [SetLog]
}

// MARK: - WorkoutLog
struct WorkoutLog: Codable, Identifiable {
    let id: String
    let programId: String
    let dayId: String
    let week: Int?
    let date: String
    let totalVolume: Double
    let exercises: [ExerciseLog]
}

// MARK: - CompletedProgram
struct CompletedProgram: Codable, Identifiable {
    let id: String
    let program: Program
    let completedAt: String
    let loggedWorkoutCount: Int
    
    var name: String {
        program.name
    }
    
    var accent: String? {
        program.accent
    }
}

// MARK: - MaxRecord
struct MaxRecord: Codable, Identifiable {
    let id: String
    let date: String
    let weight: Double
    let reps: Int
}

// MARK: - MaxTracker
struct MaxTracker: Codable, Identifiable {
    let id: String
    let name: String
    let records: [MaxRecord]
    
    var latestRecord: MaxRecord? {
        records.sorted { $0.date > $1.date }.first
    }
    
    var bestWeight: Double {
        records.map { $0.weight }.max() ?? 0
    }
}

// MARK: - DiscoverUser
struct DiscoverUser: Codable, Identifiable {
    let id: String
    let name: String
    let following: Bool
    let sharedProgramCount: Int
    let sharedExerciseCount: Int
}

// MARK: - UserSharedContent
struct UserSharedContent: Codable {
    let programs: [Program]
    let exercises: [Exercise]
}

// MARK: - Nutrition Entry

struct NutritionEntry: Codable, Identifiable {
    let id: String
    let date: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var water: Int
    var photos: [String] // Base64 encoded JPEGs
}

// MARK: - Nutrition Goals

struct NutritionGoals: Codable {
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var water: Int
}

// MARK: - Admin User

struct AdminUser: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let joinedAt: String
    let lastActive: String?
}

// MARK: - Catalog

struct Catalog: Codable {
    let programs: [Program]
    let exercises: [Exercise]
}

// MARK: - ActiveWorkout
struct ActiveWorkout: Codable {
    var programId: String
    var dayId: String
    var dayIndex: Int
    var week: Int?
    var startedAt: Double
    var sets: [[SetLog]]
    var exerciseIds: [String]
}

// MARK: - BodyWeightEntry
struct BodyWeightEntry: Codable, Identifiable {
    let id: String
    let date: String // ISO8601 date string
    let weight: Double // in user's unit
}

// MARK: - PublicUser
struct PublicUser: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let isAdmin: Bool
    let programCount: Int?
    let exerciseCount: Int?
}

// MARK: - AuthResponse
struct AuthResponse: Codable {
    let token: String
    let user: PublicUser
}

// MARK: - AppData
struct AppData: Codable {
    var name: String?
    var themeColor: String?
    var themeMode: String?
    var activeProgramId: String?
    var programAnchors: [String: String]
    var logs: [WorkoutLog]
    var unit: String
    var customPrograms: [Program]
    var customExercises: [Exercise]
    var activeWorkout: ActiveWorkout?
    var exerciseNotes: [String: String]
    var exerciseSubheaders: [String: String]
    var favoriteProgramIds: [String]
    var hiddenProgramIds: [String]
    var trashedPrograms: [String]
    var bodyWeightEntries: [BodyWeightEntry]
    var completedPrograms: [CompletedProgram]
    var maxTrackers: [MaxTracker]
    var followingUsers: [DiscoverUser]
    var favoriteUserIds: [String]
    var nutritionLog: [String: NutritionEntry]
    var nutritionGoals: NutritionGoals
    
    // For handling unknown keys from the backend
    private var additionalData: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case themeColor = "themeColor"
        case themeMode = "themeMode"
        case activeProgramId = "activeProgramId"
        case programAnchors = "programAnchors"
        case logs = "logs"
        case unit = "unit"
        case customPrograms = "customPrograms"
        case customExercises = "customExercises"
        case activeWorkout = "activeWorkout"
        case exerciseNotes = "exerciseNotes"
        case exerciseSubheaders = "exerciseSubheaders"
        case favoriteProgramIds = "favoriteProgramIds"
        case hiddenProgramIds = "hiddenProgramIds"
        case trashedPrograms = "trashedPrograms"
        case bodyWeightEntries = "bodyWeightEntries"
        case completedPrograms = "completedPrograms"
        case maxTrackers = "maxTrackers"
        case followingUsers = "followingUsers"
        case favoriteUserIds = "favoriteUserIds"
        case nutritionLog = "nutritionLog"
        case nutritionGoals = "nutritionGoals"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        themeColor = try container.decodeIfPresent(String.self, forKey: .themeColor)
        themeMode = try container.decodeIfPresent(String.self, forKey: .themeMode)
        activeProgramId = try container.decodeIfPresent(String.self, forKey: .activeProgramId)
        programAnchors = try container.decodeIfPresent([String: String].self, forKey: .programAnchors) ?? [:]
        logs = try container.decodeIfPresent([WorkoutLog].self, forKey: .logs) ?? []
        unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? "lb"
        customPrograms = try container.decodeIfPresent([Program].self, forKey: .customPrograms) ?? []
        customExercises = try container.decodeIfPresent([Exercise].self, forKey: .customExercises) ?? []
        activeWorkout = try container.decodeIfPresent(ActiveWorkout.self, forKey: .activeWorkout)
        exerciseNotes = try container.decodeIfPresent([String: String].self, forKey: .exerciseNotes) ?? [:]
        exerciseSubheaders = try container.decodeIfPresent([String: String].self, forKey: .exerciseSubheaders) ?? [:]
        favoriteProgramIds = try container.decodeIfPresent([String].self, forKey: .favoriteProgramIds) ?? []
        hiddenProgramIds = try container.decodeIfPresent([String].self, forKey: .hiddenProgramIds) ?? []
        trashedPrograms = try container.decodeIfPresent([String].self, forKey: .trashedPrograms) ?? []
        bodyWeightEntries = try container.decodeIfPresent([BodyWeightEntry].self, forKey: .bodyWeightEntries) ?? []
        completedPrograms = try container.decodeIfPresent([CompletedProgram].self, forKey: .completedPrograms) ?? []
        maxTrackers = try container.decodeIfPresent([MaxTracker].self, forKey: .maxTrackers) ?? []
        followingUsers = try container.decodeIfPresent([DiscoverUser].self, forKey: .followingUsers) ?? []
        favoriteUserIds = try container.decodeIfPresent([String].self, forKey: .favoriteUserIds) ?? []
        nutritionLog = try container.decodeIfPresent([String: NutritionEntry].self, forKey: .nutritionLog) ?? [:]
        nutritionGoals = try container.decodeIfPresent(NutritionGoals.self, forKey: .nutritionGoals) ?? NutritionGoals(calories: 2000, protein: 150, carbs: 200, fat: 65, water: 8)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(themeColor, forKey: .themeColor)
        try container.encodeIfPresent(themeMode, forKey: .themeMode)
        try container.encodeIfPresent(activeProgramId, forKey: .activeProgramId)
        try container.encode(programAnchors, forKey: .programAnchors)
        try container.encode(logs, forKey: .logs)
        try container.encode(unit, forKey: .unit)
        try container.encode(customPrograms, forKey: .customPrograms)
        try container.encode(customExercises, forKey: .customExercises)
        try container.encodeIfPresent(activeWorkout, forKey: .activeWorkout)
        try container.encode(exerciseNotes, forKey: .exerciseNotes)
        try container.encode(exerciseSubheaders, forKey: .exerciseSubheaders)
        try container.encode(favoriteProgramIds, forKey: .favoriteProgramIds)
        try container.encode(hiddenProgramIds, forKey: .hiddenProgramIds)
        try container.encode(trashedPrograms, forKey: .trashedPrograms)
        try container.encode(bodyWeightEntries, forKey: .bodyWeightEntries)
        try container.encode(completedPrograms, forKey: .completedPrograms)
        try container.encode(maxTrackers, forKey: .maxTrackers)
        try container.encode(followingUsers, forKey: .followingUsers)
        try container.encode(favoriteUserIds, forKey: .favoriteUserIds)
        try container.encode(nutritionLog, forKey: .nutritionLog)
        try container.encode(nutritionGoals, forKey: .nutritionGoals)
    }
    
    init(name: String? = nil,
         themeColor: String? = nil,
         themeMode: String? = nil,
         activeProgramId: String? = nil,
         programAnchors: [String: String] = [:],
         logs: [WorkoutLog] = [],
         unit: String = "lb",
         customPrograms: [Program] = [],
         customExercises: [Exercise] = [],
         activeWorkout: ActiveWorkout? = nil,
         exerciseNotes: [String: String] = [:],
         exerciseSubheaders: [String: String] = [:],
         favoriteProgramIds: [String] = [],
         hiddenProgramIds: [String] = [],
         trashedPrograms: [String] = [],
         bodyWeightEntries: [BodyWeightEntry] = [],
         completedPrograms: [CompletedProgram] = [],
         maxTrackers: [MaxTracker] = [],
         followingUsers: [DiscoverUser] = [],
         favoriteUserIds: [String] = [],
         nutritionLog: [String: NutritionEntry] = [:],
         nutritionGoals: NutritionGoals = NutritionGoals(calories: 2000, protein: 150, carbs: 200, fat: 65, water: 8)) {
        self.name = name
        self.themeColor = themeColor
        self.themeMode = themeMode
        self.activeProgramId = activeProgramId
        self.programAnchors = programAnchors
        self.logs = logs
        self.unit = unit
        self.customPrograms = customPrograms
        self.customExercises = customExercises
        self.activeWorkout = activeWorkout
        self.exerciseNotes = exerciseNotes
        self.exerciseSubheaders = exerciseSubheaders
        self.favoriteProgramIds = favoriteProgramIds
        self.hiddenProgramIds = hiddenProgramIds
        self.trashedPrograms = trashedPrograms
        self.bodyWeightEntries = bodyWeightEntries
        self.completedPrograms = completedPrograms
        self.maxTrackers = maxTrackers
        self.followingUsers = followingUsers
        self.favoriteUserIds = favoriteUserIds
        self.nutritionLog = nutritionLog
        self.nutritionGoals = nutritionGoals
    }
}

// MARK: - WorkoutHistoryEntry (legacy, kept for compatibility)
struct WorkoutHistoryEntry: Codable {
    let id: String
    let programId: String
    let dayId: String
    let date: Double
    let duration: Int
    let exercises: [String]
}