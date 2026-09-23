//
//  NextRepTests.swift
//  NextRepTests
//

import Foundation
import Testing
@testable import NextRep

@MainActor
struct AppStoreTests {

    // MARK: - Fixtures

    private func makeExercise(_ id: String, _ name: String) -> Exercise {
        Exercise(
            id: id, name: name, primaryMuscle: "Chest", secondaryMuscles: [],
            equipment: "Barbell", difficulty: "Beginner", instructions: [],
            tips: [], photos: nil, shared: false, ownerName: nil, ownerId: nil,
            collaborative: false, version: 1
        )
    }

    private func planned(_ id: String, name: String? = nil, sets: Int = 3, reps: String = "8", rest: Int = 90) -> PlannedExercise {
        PlannedExercise(exerciseId: id, name: name, sets: sets, reps: reps, restSec: rest, notes: nil, groupId: nil)
    }

    private func makeProgram(days: [ProgramDay]) -> Program {
        Program(
            id: "prog-1", name: "Test Program", category: "Strength",
            level: "Beginner", goal: nil, coach: "Test", durationWeeks: 4,
            daysPerWeek: days.count, accent: "#355e3b", summary: "",
            description: "", tags: nil, days: days,
            weekOverrides: nil, ownerId: nil, ownerName: nil,
            collaborative: false, version: 1
        )
    }

    /// Dead-URL API client: `uploadCurrentData` short-circuits on a missing
    /// session token, so no network is ever touched in tests.
    private func makeStore(catalog: Catalog = Catalog()) -> AppStore {
        let store = AppStore(apiClient: APIClient(baseURL: URL(string: "http://127.0.0.1:1")!))
        store.catalog = catalog
        return store
    }

    private func twoExerciseProgram() -> (Program, ProgramDay) {
        let day = ProgramDay(
            id: "day-1", name: "Push", focus: "Chest",
            exercises: [planned("ex-bench"), planned("ex-squat", sets: 2, reps: "5")]
        )
        return (makeProgram(days: [day]), day)
    }

    // MARK: - Session lifecycle

    @Test func startWorkoutSeedsPlannedDefaults() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))

        store.startWorkout(program: program, day: day, week: 1)

        let active = store.activeWorkout
        #expect(active?.programId == "prog-1")
        #expect(active?.dayId == "day-1")
        #expect(active?.sets.count == 2)
        #expect(active?.sets[0].count == 3)
        #expect(active?.sets[1].count == 2)
        #expect(active?.sets[0][0].reps == 8)
        #expect(active?.sets[0][0].weight == 0)
        #expect(active?.sets[0][0].completed == false)
        #expect(active?.exerciseIds == ["ex-bench", "ex-squat"])
        #expect(store.appData.activeProgramId == "prog-1")
    }

    @Test func updateSetClampsAndEdits() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)

        store.updateSet(exerciseIndex: 0, setIndex: 1, weight: 22.5, reps: 10)
        #expect(store.activeWorkout?.sets[0][1].weight == 22.5)
        #expect(store.activeWorkout?.sets[0][1].reps == 10)

        store.updateSet(exerciseIndex: 0, setIndex: 1, weight: -5, reps: -3)
        #expect(store.activeWorkout?.sets[0][1].weight == 0)
        #expect(store.activeWorkout?.sets[0][1].reps == 0)

        // Out-of-range indices are no-ops, not crashes.
        store.updateSet(exerciseIndex: 9, setIndex: 0, weight: 100)
        #expect(store.activeWorkout?.sets.count == 2)
    }

    @Test func setCompletedArmsAndDisarmsRest() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)

        store.setCompleted(exerciseIndex: 0, setIndex: 0, completed: true, restSec: 90)
        #expect(store.activeWorkout?.sets[0][0].completed == true)
        #expect(store.activeWorkout?.restEndsAt != nil)
        #expect(store.activeWorkout?.restTotal == 90)

        store.setCompleted(exerciseIndex: 0, setIndex: 0, completed: false, restSec: 90)
        #expect(store.activeWorkout?.restEndsAt == nil)
    }

    @Test func endWorkoutDiscardsSession() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)
        store.endWorkout()
        #expect(store.activeWorkout == nil)
        #expect(store.appData.logs.isEmpty)
    }

    // MARK: - Rest timer controls

    @Test func adjustRestIncreasesAndDecreases() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)
        store.startRest(seconds: 60)
        let endAfterStart = store.activeWorkout?.restEndsAt ?? 0

        store.adjustRest(by: 5)
        let endAfterPlus = store.activeWorkout?.restEndsAt ?? 0
        #expect(endAfterPlus > endAfterStart)
        #expect(store.activeWorkout?.restTotal == 65)

        store.adjustRest(by: -5)
        #expect((store.activeWorkout?.restEndsAt ?? 0) < endAfterPlus)
    }

    @Test func adjustRestClampsAtZero() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)
        store.startRest(seconds: 5)

        store.adjustRest(by: -30)
        let now = Date().timeIntervalSince1970 * 1000
        #expect((store.activeWorkout?.restEndsAt ?? .infinity) <= now + 1000)
        #expect(store.activeWorkout?.restTotal == 1)
    }

    @Test func stopRestClearsTimer() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)
        store.startRest(seconds: 60)
        store.stopRest()
        #expect(store.activeWorkout?.restEndsAt == nil)
        #expect(store.activeWorkout?.restTotal == 0)
    }

    // MARK: - Session exercise swap

    @Test func swapKeepsOtherSlotsOnFallbackIds() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)
        // Simulate legacy session with no exerciseIds.
        store.activeWorkout?.exerciseIds = nil

        store.swapActiveExercise(exerciseIndex: 0, newExerciseId: "ex-row", fallbackIds: ["ex-bench", "ex-squat"])

        #expect(store.activeWorkout?.exerciseIds == ["ex-row", "ex-squat"])
    }

    @Test func freeTextSwapMatchesCatalogCaseInsensitive() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(
            programs: [program],
            exercises: [makeExercise("ex-row", "Barbell Row")]
        ))
        store.startWorkout(program: program, day: day)

        store.swapActiveExerciseFreeText(
            exerciseIndex: 0, text: "  barbell ROW ",
            fallbackIds: day.exercises.map(\.exerciseId)
        )

        #expect(store.activeWorkout?.exerciseIds?[0] == "ex-row")
        #expect(store.appData.customExercises.isEmpty)
    }

    @Test func freeTextSwapUnmatchedCreatesCustomAndKeepsSets() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)
        store.updateSet(exerciseIndex: 0, setIndex: 0, weight: 45, reps: 12)

        store.swapActiveExerciseFreeText(
            exerciseIndex: 0, text: "Band Floor Press",
            fallbackIds: day.exercises.map(\.exerciseId)
        )

        let newId = store.activeWorkout?.exerciseIds?[0]
        #expect(newId == "custom-swap-day-1-0")
        #expect(store.activeWorkout?.sets[0][0].weight == 45)
        let custom = store.appData.customExercises.first(where: { $0.id == newId })
        #expect(custom?.name == "Band Floor Press")
    }

    @Test func freeTextSwapEmptyInputIsNoOp() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)

        store.swapActiveExerciseFreeText(exerciseIndex: 0, text: "   ", fallbackIds: [])
        #expect(store.activeWorkout?.exerciseIds == ["ex-bench", "ex-squat"])
    }

    /// Regression: relinkExercisePlaceholders inside saveCustomExercise would
    /// rewrite matching planned-exercise names inside the program template.
    /// A session swap must never touch the template.
    @Test func freeTextSwapNeverMutatesProgramTemplate() {
        let template = ProgramDay(
            id: "day-1", name: "Push", focus: "Chest",
            exercises: [
                planned("ex-bench"),
                planned("ex-placeholder", name: "Band Floor Press")
            ]
        )
        let program = makeProgram(days: [template])
        let store = makeStore()
        store.appData.customPrograms = [program]
        store.startWorkout(program: program, day: template)

        store.swapActiveExerciseFreeText(
            exerciseIndex: 0, text: "Band Floor Press",
            fallbackIds: template.exercises.map(\.exerciseId)
        )

        #expect(store.appData.customPrograms[0].days[0].exercises[1].exerciseId == "ex-placeholder")
        #expect(store.appData.customPrograms[0].days[0].exercises[0].exerciseId == "ex-bench")
    }

    // MARK: - Finish + logging

    @Test func finishWorkoutLogsSwappedExerciseAndVolume() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)

        store.swapActiveExerciseFreeText(
            exerciseIndex: 0, text: "Ring Rows",
            fallbackIds: day.exercises.map(\.exerciseId)
        )
        store.updateSet(exerciseIndex: 0, setIndex: 0, weight: 100, reps: 10)
        store.setCompleted(exerciseIndex: 0, setIndex: 0, completed: true, restSec: 0)
        store.updateSet(exerciseIndex: 1, setIndex: 0, weight: 200, reps: 5)
        store.setCompleted(exerciseIndex: 1, setIndex: 0, completed: true, restSec: 0)

        let log = store.finishWorkout(program: program, day: day)

        #expect(log?.exercises[0].exerciseId == "custom-swap-day-1-0")
        #expect(log?.exercises[0].name == "Ring Rows")
        #expect(log?.exercises[1].exerciseId == "ex-squat")
        #expect(log?.totalVolume == 2000.0)
        #expect(log?.exercises[0].sets.count == 1) // uncompleted empty rows filtered
        #expect(store.activeWorkout == nil)
        #expect(store.appData.logs.first?.id == log?.id)
    }

    @Test func finishWorkoutRecordsSetMemoryBothFields() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)
        store.updateSet(exerciseIndex: 0, setIndex: 0, weight: 135, reps: 7)
        store.setCompleted(exerciseIndex: 0, setIndex: 0, completed: true, restSec: 0)

        _ = store.finishWorkout(program: program, day: day)

        #expect(store.appData.programSetMemory["prog-1"]?["ex-bench"]?.first?.reps == 7)
        #expect(store.appData.programWeightMemory["prog-1"]?["ex-bench"] == [135])
    }

    // MARK: - Carryover

    @Test func weekTwoPrefillsWeightAndRepsFromWeekOne() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))

        store.startWorkout(program: program, day: day, week: 1)
        store.updateSet(exerciseIndex: 0, setIndex: 0, weight: 135, reps: 8)
        store.setCompleted(exerciseIndex: 0, setIndex: 0, completed: true, restSec: 0)
        store.updateSet(exerciseIndex: 0, setIndex: 1, weight: 135, reps: 7)
        store.setCompleted(exerciseIndex: 0, setIndex: 1, completed: true, restSec: 0)
        _ = store.finishWorkout(program: program, day: day)

        store.startWorkout(program: program, day: day, week: 2)

        #expect(store.activeWorkout?.sets[0][0].weight == 135)
        #expect(store.activeWorkout?.sets[0][0].reps == 8)
        #expect(store.activeWorkout?.sets[0][1].weight == 135)
        #expect(store.activeWorkout?.sets[0][1].reps == 7)
    }

    @Test func rememberedSetsRepeatLastSetForExtraPlannedSets() {
        let day = ProgramDay(
            id: "day-1", name: "Push", focus: "",
            exercises: [planned("ex-bench", sets: 4)]
        )
        let program = makeProgram(days: [day])
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.appData.programSetMemory["prog-1"] = [
            "ex-bench": [
                SetLog(weight: 95, reps: 10, completed: true),
                SetLog(weight: 100, reps: 8, completed: true)
            ]
        ]

        store.startWorkout(program: program, day: day, week: 1)

        #expect(store.activeWorkout?.sets[0].map(\.weight) == [95, 100, 100, 100])
        #expect(store.activeWorkout?.sets[0].map(\.reps) == [10, 8, 8, 8])
    }

    @Test func migratedZeroRepsFallBackToPlanned() {
        let day = ProgramDay(
            id: "day-1", name: "Push", focus: "",
            exercises: [planned("ex-bench", sets: 2, reps: "8-10")]
        )
        let program = makeProgram(days: [day])
        let store = makeStore(catalog: Catalog(programs: [program]))
        // Simulates memory migrated from legacy weight-only data (reps = 0).
        store.appData.programSetMemory["prog-1"] = [
            "ex-bench": [
                SetLog(weight: 135, reps: 0, completed: true),
                SetLog(weight: 140, reps: 0, completed: true)
            ]
        ]

        store.startWorkout(program: program, day: day)

        #expect(store.activeWorkout?.sets[0][0].weight == 135)
        #expect(store.activeWorkout?.sets[0][0].reps == 8) // "8-10" -> 8, not 0
    }

    @Test func swapDoesNotContaminateTemplateCarryover() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))

        // Week 1: log bench at 135.
        store.startWorkout(program: program, day: day, week: 1)
        store.updateSet(exerciseIndex: 0, setIndex: 0, weight: 135, reps: 8)
        store.setCompleted(exerciseIndex: 0, setIndex: 0, completed: true, restSec: 0)
        _ = store.finishWorkout(program: program, day: day)

        // Week 2: swap the bench slot to a catalog row and log it instead.
        store.catalog = Catalog(
            programs: [program],
            exercises: [makeExercise("ex-row", "Barbell Row")]
        )
        store.startWorkout(program: program, day: day, week: 2)
        store.swapActiveExercise(exerciseIndex: 0, newExerciseId: "ex-row", fallbackIds: day.exercises.map(\.exerciseId))
        store.updateSet(exerciseIndex: 0, setIndex: 0, weight: 65, reps: 12)
        store.setCompleted(exerciseIndex: 0, setIndex: 0, completed: true, restSec: 0)
        _ = store.finishWorkout(program: program, day: day)

        // Week 3 (no swap): bench prefill comes from week 1's 135x8, not the row.
        store.startWorkout(program: program, day: day, week: 3)
        #expect(store.activeWorkout?.sets[0][0].weight == 135)
        #expect(store.activeWorkout?.sets[0][0].reps == 8)
    }

    // MARK: - Reset + stale handling

    @Test func resetProgramProgressKeepWeightsSeedsMemoryFromLogs() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)
        store.updateSet(exerciseIndex: 0, setIndex: 0, weight: 135, reps: 8)
        store.setCompleted(exerciseIndex: 0, setIndex: 0, completed: true, restSec: 0)
        _ = store.finishWorkout(program: program, day: day)

        store.resetProgramProgress(id: "prog-1", keepWeights: true)

        #expect(store.appData.programAnchors["prog-1"] != nil)
        #expect(store.appData.programSetMemory["prog-1"]?["ex-bench"]?.first?.weight == 135)
    }

    @Test func resetProgramProgressCleanWipesMemoryAndActive() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)
        store.appData.programSetMemory["prog-1"] = ["ex-bench": [SetLog(weight: 100, reps: 8, completed: true)]]

        store.resetProgramProgress(id: "prog-1", keepWeights: false)

        #expect(store.appData.programSetMemory["prog-1"] == nil)
        #expect(store.appData.programWeightMemory["prog-1"] == nil)
        #expect(store.activeWorkout == nil)
    }

    @Test func staleWorkoutAutoFinishesAndSaves() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)
        store.updateSet(exerciseIndex: 0, setIndex: 0, weight: 100, reps: 8)
        store.setCompleted(exerciseIndex: 0, setIndex: 0, completed: true, restSec: 0)

        // Fresh workout -> nothing happens.
        #expect(store.finishStaleWorkoutIfNeeded() == nil)
        #expect(store.activeWorkout != nil)

        // Push lastActivityAt beyond the 2h timeout.
        store.activeWorkout?.lastActivityAt =
            Date().timeIntervalSince1970 * 1000 - AppStore.staleWorkoutTimeout - 1000

        let log = store.finishStaleWorkoutIfNeeded()
        #expect(log != nil)
        #expect(store.activeWorkout == nil)
        #expect(store.appData.logs.first?.id == log?.id)
    }

    @Test func reconcileRemapsSetsByExerciseIdOnTemplateChange() {
        let (program, day) = twoExerciseProgram()
        let store = makeStore(catalog: Catalog(programs: [program]))
        store.startWorkout(program: program, day: day)
        store.updateSet(exerciseIndex: 1, setIndex: 0, weight: 200, reps: 5)

        // Template edited mid-workout: squat moved to position 0.
        let reordered = ProgramDay(
            id: "day-1", name: "Push", focus: "Chest",
            exercises: [planned("ex-squat", sets: 2, reps: "5"), planned("ex-bench")]
        )
        store.startWorkout(program: program, day: reordered)

        // The 200x5 set must follow the squat slot, not stay at index 1.
        #expect(store.activeWorkout?.sets[0][0].weight == 200)
        #expect(store.activeWorkout?.sets[0][0].reps == 5)
        #expect(store.activeWorkout?.exerciseIds == ["ex-squat", "ex-bench"])
    }

    // MARK: - Version gating

    @Test func versionComparisonHandlesShapes() {
        #expect(domainVersionIsOlder("1.0", than: "1.1"))
        #expect(domainVersionIsOlder("1.0", than: "1.0.1"))
        #expect(domainVersionIsOlder("1.9", than: "1.10"))
        #expect(!domainVersionIsOlder("1.1", than: "1.0"))
        #expect(!domainVersionIsOlder("1.0", than: "1.0"))
        #expect(!domainVersionIsOlder("2.0", than: "1.9"))
    }

    @Test func dismissUpdateNudgePersists() {
        let store = makeStore()
        store.updateAvailableVersion = "9.9.9"
        store.dismissUpdateNudge()
        #expect(store.updateAvailableVersion == nil)
        #expect(UserDefaults.standard.string(forKey: "nextrep.dismissedUpdateVersion") == "9.9.9")
        UserDefaults.standard.removeObject(forKey: "nextrep.dismissedUpdateVersion")
    }
}
