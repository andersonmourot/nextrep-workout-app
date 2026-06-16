import Foundation

struct SessionUser: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var email: String
    var isAdmin: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case isAdmin = "is_admin"
    }
}

struct AuthResponse: Codable, Equatable {
    var token: String
    var user: SessionUser
}

struct Catalog: Codable, Equatable {
    var programs: [Program]
    var exercises: [Exercise]

    init(programs: [Program] = [], exercises: [Exercise] = []) {
        self.programs = programs
        self.exercises = exercises
    }
}

struct Exercise: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var primaryMuscle: String
    var secondaryMuscles: [String]
    var equipment: String
    var difficulty: String
    var instructions: [String]
    var tips: [String]
    var photos: [String]?
    var shared: Bool?
    var ownerName: String?
    var ownerId: String?
    var collaborative: Bool?
    var version: Int?
}

struct PlannedExercise: Codable, Equatable {
    var exerciseId: String
    var name: String?
    var sets: Int
    var reps: String
    var restSec: Int
    var notes: String?
    var groupId: String?
}

struct ProgramDay: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var focus: String
    var exercises: [PlannedExercise]
}

struct ProgramWeekOverride: Codable, Equatable {
    var fromWeek: Int
    var day: ProgramDay
}

struct Program: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var category: String
    var level: String
    var goal: String?
    var coach: String
    var durationWeeks: Int
    var daysPerWeek: Int
    var accent: String
    var summary: String
    var description: String
    var tags: [String]?
    var days: [ProgramDay]
    var weekOverrides: [String: [ProgramWeekOverride]]?
    var ownerId: String?
    var ownerName: String?
    var collaborative: Bool?
    var version: Int?
}

struct SetLog: Codable, Equatable {
    var weight: Double
    var reps: Int
    var completed: Bool
}

struct ActiveWorkout: Codable, Equatable {
    var programId: String
    var dayId: String
    var week: Int?
    var startedAt: Double
    var sets: [[SetLog]]
    var exerciseIds: [String]?
    var restEndsAt: Double?
    var restTotal: Int
}

struct LoggedExercise: Codable, Equatable {
    var exerciseId: String
    var sets: [SetLog]
}

struct WorkoutLog: Codable, Identifiable, Equatable {
    var id: String
    var date: String
    var programId: String
    var programName: String
    var dayId: String
    var dayName: String
    var week: Int?
    var durationSec: Int
    var exercises: [LoggedExercise]
    var totalVolume: Double
    var notes: String?
}

struct BodyWeightEntry: Codable, Identifiable, Equatable {
    var id: String
    var date: String
    var weight: Double
    var createdAt: String?
}

struct NutritionEntry: Codable, Identifiable, Equatable {
    var id: String { date }
    var date: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var water: Int
    var photos: [String]?
}

struct NutritionGoals: Codable, Equatable {
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var water: Int

    static let defaults = NutritionGoals(calories: 2200, protein: 160, carbs: 220, fat: 70, water: 8)
}

struct MaxRecord: Codable, Identifiable, Equatable {
    var id: String
    var date: String
    var weight: Double
    var reps: Int
}

struct MaxTracker: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var records: [MaxRecord]
}

struct CompletedProgram: Codable, Identifiable, Equatable {
    var id: String
    var programId: String
    var name: String
    var accent: String
    var durationWeeks: Int
    var daysPerWeek: Int
    var completedAt: String
    var program: Program
    var logs: [WorkoutLog]
}

struct TrashedProgram: Codable, Identifiable, Equatable {
    var id: String { program.id }
    var program: Program
    var deletedAt: Double
}

struct TrashedExercise: Codable, Identifiable, Equatable {
    var id: String { exercise.id }
    var exercise: Exercise
    var deletedAt: Double
}

struct SavedTimer: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var seconds: Int
}

struct IntervalSettings: Codable, Equatable {
    var emomInterval: Int
    var emomRounds: Int
    var emomSets: Int
    var emomSetRest: Int
    var amrapCap: Int
    var tabataWork: Int
    var tabataRest: Int
    var tabataRounds: Int
    var tabataSets: Int
    var tabataSetRest: Int
    var forTimeCap: Int

    static let defaults = IntervalSettings(
        emomInterval: 60,
        emomRounds: 10,
        emomSets: 1,
        emomSetRest: 60,
        amrapCap: 600,
        tabataWork: 20,
        tabataRest: 10,
        tabataRounds: 8,
        tabataSets: 1,
        tabataSetRest: 60,
        forTimeCap: 1200
    )
}

struct AppData: Codable, Equatable {
    var name: String
    var unit: String
    var themeColor: String
    var themeMode: String
    var activeProgramId: String?
    var programAnchors: [String: String]
    var logs: [WorkoutLog]
    var bodyWeight: [BodyWeightEntry]
    var customPrograms: [Program]
    var customExercises: [Exercise]
    var hiddenProgramIds: [String]
    var hiddenExerciseIds: [String]
    var exerciseOverrides: [String: Exercise]
    var savedTimers: [SavedTimer]
    var timerSound: String
    var timerMode: String
    var intervalSettings: IntervalSettings
    var intervalFormat: String?
    var favoriteUserIds: [String]
    var favoriteProgramIds: [String]
    var nutritionLog: [NutritionEntry]
    var nutritionGoals: NutritionGoals
    var maxTrackers: [MaxTracker]
    var activeWorkout: ActiveWorkout?
    var trashedPrograms: [TrashedProgram]
    var trashedExercises: [TrashedExercise]
    var completedPrograms: [CompletedProgram]
    var exerciseNotes: [String: String]
    var exerciseSubheaders: [String: String]
    var unknownFields: [String: JSONValue]

    init(
        name: String = "Athlete",
        unit: String = "lb",
        themeColor: String = "#355e3b",
        themeMode: String = "dark",
        activeProgramId: String? = nil,
        programAnchors: [String: String] = [:],
        logs: [WorkoutLog] = [],
        bodyWeight: [BodyWeightEntry] = [],
        customPrograms: [Program] = [],
        customExercises: [Exercise] = [],
        hiddenProgramIds: [String] = [],
        hiddenExerciseIds: [String] = [],
        exerciseOverrides: [String: Exercise] = [:],
        savedTimers: [SavedTimer] = [],
        timerSound: String = "beep",
        timerMode: String = "timer",
        intervalSettings: IntervalSettings = .defaults,
        intervalFormat: String? = nil,
        favoriteUserIds: [String] = [],
        favoriteProgramIds: [String] = [],
        nutritionLog: [NutritionEntry] = [],
        nutritionGoals: NutritionGoals = .defaults,
        maxTrackers: [MaxTracker] = [],
        activeWorkout: ActiveWorkout? = nil,
        trashedPrograms: [TrashedProgram] = [],
        trashedExercises: [TrashedExercise] = [],
        completedPrograms: [CompletedProgram] = [],
        exerciseNotes: [String: String] = [:],
        exerciseSubheaders: [String: String] = [:],
        unknownFields: [String: JSONValue] = [:]
    ) {
        self.name = name
        self.unit = unit
        self.themeColor = themeColor
        self.themeMode = themeMode
        self.activeProgramId = activeProgramId
        self.programAnchors = programAnchors
        self.logs = logs
        self.bodyWeight = bodyWeight
        self.customPrograms = customPrograms
        self.customExercises = customExercises
        self.hiddenProgramIds = hiddenProgramIds
        self.hiddenExerciseIds = hiddenExerciseIds
        self.exerciseOverrides = exerciseOverrides
        self.savedTimers = savedTimers
        self.timerSound = timerSound
        self.timerMode = timerMode
        self.intervalSettings = intervalSettings
        self.intervalFormat = intervalFormat
        self.favoriteUserIds = favoriteUserIds
        self.favoriteProgramIds = favoriteProgramIds
        self.nutritionLog = nutritionLog
        self.nutritionGoals = nutritionGoals
        self.maxTrackers = maxTrackers
        self.activeWorkout = activeWorkout
        self.trashedPrograms = trashedPrograms
        self.trashedExercises = trashedExercises
        self.completedPrograms = completedPrograms
        self.exerciseNotes = exerciseNotes
        self.exerciseSubheaders = exerciseSubheaders
        self.unknownFields = unknownFields
    }

    init(from decoder: Decoder) throws {
        let typed = try decoder.container(keyedBy: CodingKeys.self)
        let dynamic = try decoder.container(keyedBy: DynamicCodingKey.self)

        name = try typed.decodeIfPresent(String.self, forKey: .name) ?? "Athlete"
        unit = try typed.decodeIfPresent(String.self, forKey: .unit) ?? "lb"
        themeColor = try typed.decodeIfPresent(String.self, forKey: .themeColor) ?? "#355e3b"
        themeMode = try typed.decodeIfPresent(String.self, forKey: .themeMode) ?? "dark"
        activeProgramId = try typed.decodeIfPresent(String.self, forKey: .activeProgramId)
        programAnchors = try typed.decodeIfPresent([String: String].self, forKey: .programAnchors) ?? [:]
        logs = try typed.decodeIfPresent([WorkoutLog].self, forKey: .logs) ?? []
        bodyWeight = try typed.decodeIfPresent([BodyWeightEntry].self, forKey: .bodyWeight) ?? []
        customPrograms = try typed.decodeIfPresent([Program].self, forKey: .customPrograms) ?? []
        customExercises = try typed.decodeIfPresent([Exercise].self, forKey: .customExercises) ?? []
        hiddenProgramIds = try typed.decodeIfPresent([String].self, forKey: .hiddenProgramIds) ?? []
        hiddenExerciseIds = try typed.decodeIfPresent([String].self, forKey: .hiddenExerciseIds) ?? []
        exerciseOverrides = try typed.decodeIfPresent([String: Exercise].self, forKey: .exerciseOverrides) ?? [:]
        savedTimers = try typed.decodeIfPresent([SavedTimer].self, forKey: .savedTimers) ?? []
        timerSound = try typed.decodeIfPresent(String.self, forKey: .timerSound) ?? "beep"
        timerMode = try typed.decodeIfPresent(String.self, forKey: .timerMode) ?? "timer"
        intervalSettings = try typed.decodeIfPresent(IntervalSettings.self, forKey: .intervalSettings) ?? .defaults
        intervalFormat = try typed.decodeIfPresent(String.self, forKey: .intervalFormat)
        favoriteUserIds = try typed.decodeIfPresent([String].self, forKey: .favoriteUserIds) ?? []
        favoriteProgramIds = try typed.decodeIfPresent([String].self, forKey: .favoriteProgramIds) ?? []
        nutritionLog = try typed.decodeIfPresent([NutritionEntry].self, forKey: .nutritionLog) ?? []
        nutritionGoals = try typed.decodeIfPresent(NutritionGoals.self, forKey: .nutritionGoals) ?? .defaults
        maxTrackers = try typed.decodeIfPresent([MaxTracker].self, forKey: .maxTrackers) ?? []
        activeWorkout = try typed.decodeIfPresent(ActiveWorkout.self, forKey: .activeWorkout)
        trashedPrograms = try typed.decodeIfPresent([TrashedProgram].self, forKey: .trashedPrograms) ?? []
        trashedExercises = try typed.decodeIfPresent([TrashedExercise].self, forKey: .trashedExercises) ?? []
        completedPrograms = try typed.decodeIfPresent([CompletedProgram].self, forKey: .completedPrograms) ?? []
        exerciseNotes = try typed.decodeIfPresent([String: String].self, forKey: .exerciseNotes) ?? [:]
        exerciseSubheaders = try typed.decodeIfPresent([String: String].self, forKey: .exerciseSubheaders) ?? [:]

        var extras: [String: JSONValue] = [:]
        for key in dynamic.allKeys where !Self.knownKeyNames.contains(key.stringValue) {
            extras[key.stringValue] = try dynamic.decode(JSONValue.self, forKey: key)
        }
        unknownFields = extras
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)

        for (name, value) in unknownFields where !Self.knownKeyNames.contains(name) {
            try container.encode(value, forKey: DynamicCodingKey(name))
        }

        try container.encode(name, forKey: DynamicCodingKey(CodingKeys.name.rawValue))
        try container.encode(unit, forKey: DynamicCodingKey(CodingKeys.unit.rawValue))
        try container.encode(themeColor, forKey: DynamicCodingKey(CodingKeys.themeColor.rawValue))
        try container.encode(themeMode, forKey: DynamicCodingKey(CodingKeys.themeMode.rawValue))
        try container.encodeIfPresent(activeProgramId, forKey: DynamicCodingKey(CodingKeys.activeProgramId.rawValue))
        try container.encode(programAnchors, forKey: DynamicCodingKey(CodingKeys.programAnchors.rawValue))
        try container.encode(logs, forKey: DynamicCodingKey(CodingKeys.logs.rawValue))
        try container.encode(bodyWeight, forKey: DynamicCodingKey(CodingKeys.bodyWeight.rawValue))
        try container.encode(customPrograms, forKey: DynamicCodingKey(CodingKeys.customPrograms.rawValue))
        try container.encode(customExercises, forKey: DynamicCodingKey(CodingKeys.customExercises.rawValue))
        try container.encode(hiddenProgramIds, forKey: DynamicCodingKey(CodingKeys.hiddenProgramIds.rawValue))
        try container.encode(hiddenExerciseIds, forKey: DynamicCodingKey(CodingKeys.hiddenExerciseIds.rawValue))
        try container.encode(exerciseOverrides, forKey: DynamicCodingKey(CodingKeys.exerciseOverrides.rawValue))
        try container.encode(savedTimers, forKey: DynamicCodingKey(CodingKeys.savedTimers.rawValue))
        try container.encode(timerSound, forKey: DynamicCodingKey(CodingKeys.timerSound.rawValue))
        try container.encode(timerMode, forKey: DynamicCodingKey(CodingKeys.timerMode.rawValue))
        try container.encode(intervalSettings, forKey: DynamicCodingKey(CodingKeys.intervalSettings.rawValue))
        try container.encodeIfPresent(intervalFormat, forKey: DynamicCodingKey(CodingKeys.intervalFormat.rawValue))
        try container.encode(favoriteUserIds, forKey: DynamicCodingKey(CodingKeys.favoriteUserIds.rawValue))
        try container.encode(favoriteProgramIds, forKey: DynamicCodingKey(CodingKeys.favoriteProgramIds.rawValue))
        try container.encode(nutritionLog, forKey: DynamicCodingKey(CodingKeys.nutritionLog.rawValue))
        try container.encode(nutritionGoals, forKey: DynamicCodingKey(CodingKeys.nutritionGoals.rawValue))
        try container.encode(maxTrackers, forKey: DynamicCodingKey(CodingKeys.maxTrackers.rawValue))
        try container.encodeIfPresent(activeWorkout, forKey: DynamicCodingKey(CodingKeys.activeWorkout.rawValue))
        try container.encode(trashedPrograms, forKey: DynamicCodingKey(CodingKeys.trashedPrograms.rawValue))
        try container.encode(trashedExercises, forKey: DynamicCodingKey(CodingKeys.trashedExercises.rawValue))
        try container.encode(completedPrograms, forKey: DynamicCodingKey(CodingKeys.completedPrograms.rawValue))
        try container.encode(exerciseNotes, forKey: DynamicCodingKey(CodingKeys.exerciseNotes.rawValue))
        try container.encode(exerciseSubheaders, forKey: DynamicCodingKey(CodingKeys.exerciseSubheaders.rawValue))
    }

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case unit
        case themeColor
        case themeMode
        case activeProgramId
        case programAnchors
        case logs
        case bodyWeight
        case customPrograms
        case customExercises
        case hiddenProgramIds
        case hiddenExerciseIds
        case exerciseOverrides
        case savedTimers
        case timerSound
        case timerMode
        case intervalSettings
        case intervalFormat
        case favoriteUserIds
        case favoriteProgramIds
        case nutritionLog
        case nutritionGoals
        case maxTrackers
        case activeWorkout
        case trashedPrograms
        case trashedExercises
        case completedPrograms
        case exerciseNotes
        case exerciseSubheaders
    }

    private static let knownKeyNames = Set(CodingKeys.allCases.map(\.rawValue))
}
