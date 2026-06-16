import Foundation
import Observation

@MainActor
@Observable
final class AppStore {
    var user: SessionUser?
    var appData = AppData()
    var catalog = Catalog()
    var isLoading = false
    var authError: String?

    private let apiClient: APIClient
    private let keychain: KeychainStore
    @ObservationIgnored private var restNotifier: RestTimerNotifier
    private var sessionToken: String?
    private var hasAttemptedRestore = false
    @ObservationIgnored private var syncTask: Task<Void, Never>?

    init(
        apiClient: APIClient = .production(),
        keychain: KeychainStore = KeychainStore(),
        restNotifier: RestTimerNotifier = RestTimerNotifier()
    ) {
        self.apiClient = apiClient
        self.keychain = keychain
        self.restNotifier = restNotifier
    }

    var allPrograms: [Program] {
        let hidden = Set(appData.hiddenProgramIds)
        let trashed = Set(appData.trashedPrograms.map(\.program.id))
        let favorites = appData.favoriteProgramIds
        let activeId = appData.activeProgramId

        return (catalog.programs + appData.customPrograms)
            .filter { !hidden.contains($0.id) && !trashed.contains($0.id) }
            .sorted { lhs, rhs in
                if lhs.id == activeId { return true }
                if rhs.id == activeId { return false }

                let leftFavorite = favorites.firstIndex(of: lhs.id)
                let rightFavorite = favorites.firstIndex(of: rhs.id)

                switch (leftFavorite, rightFavorite) {
                case let (left?, right?):
                    return left < right
                case (.some(_), .none):
                    return true
                case (.none, .some(_)):
                    return false
                case (.none, .none):
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
            }
    }

    var allExercises: [Exercise] {
        let hidden = Set(appData.hiddenExerciseIds)
        let trashed = Set(appData.trashedExercises.map(\.exercise.id))

        return (catalog.exercises + appData.customExercises)
            .filter { !hidden.contains($0.id) && !trashed.contains($0.id) }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    func restoreSession() async {
        guard !hasAttemptedRestore else { return }
        hasAttemptedRestore = true

        do {
            guard let token = try keychain.loadToken() else {
                return
            }

            isLoading = true
            defer { isLoading = false }

            let restoredUser = try await apiClient.me(token: token)
            sessionToken = token
            user = restoredUser
            try await loadInitialData(token: token)
        } catch {
            try? keychain.deleteToken()
            sessionToken = nil
            user = nil
            authError = error.localizedDescription
        }
    }

    func login(email: String, password: String) async {
        await authenticate {
            try await apiClient.login(email: email, password: password)
        }
    }

    func signup(name: String, email: String, password: String) async {
        await authenticate {
            try await apiClient.signup(name: name, email: email, password: password)
        }
    }

    func logout() {
        syncTask?.cancel()
        restNotifier.cancelRestComplete()
        try? keychain.deleteToken()
        sessionToken = nil
        user = nil
        appData = AppData()
        catalog = Catalog()
    }

    func reload() async {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return
        }

        do {
            isLoading = true
            defer { isLoading = false }
            try await loadInitialData(token: token)
        } catch {
            authError = error.localizedDescription
        }
    }

    func searchUsers(query: String) async -> [DiscoverUser] {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return []
        }

        do {
            authError = nil
            return try await apiClient.searchUsers(token: token, query: query)
        } catch {
            authError = error.localizedDescription
            return []
        }
    }

    func follow(userId: String) async {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return
        }

        do {
            try await apiClient.followUser(token: token, userId: userId)
        } catch {
            authError = error.localizedDescription
        }
    }

    func unfollow(userId: String) async {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return
        }

        do {
            try await apiClient.unfollowUser(token: token, userId: userId)
        } catch {
            authError = error.localizedDescription
        }
    }

    func sharedPrograms(for userId: String) async -> [Program] {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return []
        }

        do {
            authError = nil
            return try await apiClient.userPrograms(token: token, userId: userId).programs
        } catch {
            authError = error.localizedDescription
            return []
        }
    }

    func sharedExercises(for userId: String) async -> [Exercise] {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return []
        }

        do {
            authError = nil
            return try await apiClient.userExercises(token: token, userId: userId).exercises
        } catch {
            authError = error.localizedDescription
            return []
        }
    }

    func addSharedProgram(id: String) async {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return
        }

        do {
            let program = try await apiClient.addProgram(token: token, programId: id)
            upsertCustomProgram(program)
            scheduleSync()
        } catch {
            authError = error.localizedDescription
        }
    }

    func addSharedExercise(id: String) async {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return
        }

        do {
            let exercise = try await apiClient.addExercise(token: token, exerciseId: id)
            upsertCustomExercise(exercise)
            scheduleSync()
        } catch {
            authError = error.localizedDescription
        }
    }

    func startWorkout(program: Program, day: ProgramDay, week: Int = 1) {
        if let active = appData.activeWorkout,
           active.programId == program.id,
           active.dayId == day.id,
           (active.week ?? 1) == week {
            reconcileActiveWorkout(day: day)
            return
        }

        appData.activeProgramId = program.id
        appData.activeWorkout = ActiveWorkout(
            programId: program.id,
            dayId: day.id,
            week: week,
            startedAt: Date().timeIntervalSince1970 * 1000,
            sets: day.exercises.map { planned in
                (0..<planned.sets).map { _ in
                    SetLog(weight: 0, reps: Self.parseReps(planned.reps), completed: false)
                }
            },
            exerciseIds: day.exercises.map(\.exerciseId),
            restEndsAt: nil,
            restTotal: 0
        )
        scheduleSync()
    }

    func updateSet(exerciseIndex: Int, setIndex: Int, weight: Double? = nil, reps: Int? = nil) {
        guard var active = appData.activeWorkout,
              active.sets.indices.contains(exerciseIndex),
              active.sets[exerciseIndex].indices.contains(setIndex) else {
            return
        }

        if let weight {
            active.sets[exerciseIndex][setIndex].weight = max(0, weight)
        }

        if let reps {
            active.sets[exerciseIndex][setIndex].reps = max(0, reps)
        }

        appData.activeWorkout = active
        scheduleSync()
    }

    func setCompleted(
        exerciseIndex: Int,
        setIndex: Int,
        completed: Bool,
        restSec: Int,
        exerciseName: String? = nil
    ) {
        guard var active = appData.activeWorkout,
              active.sets.indices.contains(exerciseIndex),
              active.sets[exerciseIndex].indices.contains(setIndex) else {
            return
        }

        active.sets[exerciseIndex][setIndex].completed = completed
        if completed && restSec > 0 {
            active.restEndsAt = Date().timeIntervalSince1970 * 1000 + Double(restSec * 1000)
            active.restTotal = restSec
            scheduleRestNotification(seconds: restSec, exerciseName: exerciseName)
        } else if !completed {
            restNotifier.cancelRestComplete()
        }

        appData.activeWorkout = active
        scheduleSync()
    }

    func startRest(seconds: Int, exerciseName: String? = nil) {
        guard seconds > 0, var active = appData.activeWorkout else {
            return
        }

        active.restEndsAt = Date().timeIntervalSince1970 * 1000 + Double(seconds * 1000)
        active.restTotal = seconds
        appData.activeWorkout = active
        scheduleRestNotification(seconds: seconds, exerciseName: exerciseName)
        scheduleSync()
    }

    func stopRest() {
        guard var active = appData.activeWorkout else {
            return
        }

        active.restEndsAt = nil
        active.restTotal = 0
        appData.activeWorkout = active
        restNotifier.cancelRestComplete()
        scheduleSync()
    }

    func endWorkout() {
        appData.activeWorkout = nil
        restNotifier.cancelRestComplete()
        scheduleSync()
    }

    @discardableResult
    func finishWorkout(program: Program, day: ProgramDay) -> WorkoutLog? {
        guard let active = appData.activeWorkout else {
            return nil
        }

        let loggedExercises = day.exercises.enumerated().map { index, planned in
            let rows = active.sets.indices.contains(index) ? active.sets[index] : []
            let loggedSets = rows
                .filter { $0.completed || $0.weight > 0 }
                .map { set in
                    SetLog(weight: set.weight, reps: set.reps, completed: true)
                }

            return LoggedExercise(exerciseId: planned.exerciseId, sets: loggedSets)
        }

        let totalVolume = loggedExercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { subtotal, set in
                subtotal + (set.weight * Double(set.reps))
            }
        }

        let startedAt = Date(timeIntervalSince1970: active.startedAt / 1000)
        let durationSec = max(0, Int(Date().timeIntervalSince(startedAt)))
        let log = WorkoutLog(
            id: UUID().uuidString,
            date: ISO8601DateFormatter().string(from: Date()),
            programId: program.id,
            programName: program.name,
            dayId: day.id,
            dayName: day.name,
            week: active.week,
            durationSec: durationSec,
            exercises: loggedExercises,
            totalVolume: totalVolume,
            notes: nil
        )

        appData.activeProgramId = program.id
        appData.logs.append(log)
        appData.activeWorkout = nil
        restNotifier.cancelRestComplete()
        scheduleSync()
        return log
    }

    func requestTimerNotificationPermission() async {
        await restNotifier.requestAuthorizationIfNeeded()
    }

    func syncNow() async {
        syncTask?.cancel()
        syncTask = nil
        await uploadCurrentData()
    }

    private func uploadCurrentData() async {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return
        }

        do {
            try await apiClient.putData(appData, token: token)
        } catch {
            authError = error.localizedDescription
        }
    }

    private func authenticate(_ operation: () async throws -> AuthResponse) async {
        do {
            isLoading = true
            authError = nil
            defer { isLoading = false }

            let response = try await operation()
            try keychain.saveToken(response.token)
            sessionToken = response.token
            user = response.user
            try await loadInitialData(token: response.token)
        } catch {
            authError = error.localizedDescription
        }
    }

    private func loadInitialData(token: String) async throws {
        catalog = try await apiClient.catalog()
        appData = try await apiClient.appData(token: token)
    }

    private func reconcileActiveWorkout(day: ProgramDay) {
        guard var active = appData.activeWorkout else {
            return
        }

        var queuedSets: [String: [[SetLog]]] = [:]
        let oldIds = active.exerciseIds ?? day.exercises.map(\.exerciseId)
        for (index, exerciseId) in oldIds.enumerated() {
            queuedSets[exerciseId, default: []].append(active.sets.indices.contains(index) ? active.sets[index] : [])
        }

        active.sets = day.exercises.map { planned in
            var rows: [SetLog] = []
            if var queued = queuedSets[planned.exerciseId], !queued.isEmpty {
                rows = queued.removeFirst()
                queuedSets[planned.exerciseId] = queued
            }

            if rows.count > planned.sets {
                rows = Array(rows.prefix(planned.sets))
            }

            while rows.count < planned.sets {
                rows.append(SetLog(weight: 0, reps: Self.parseReps(planned.reps), completed: false))
            }

            return rows
        }
        active.exerciseIds = day.exercises.map(\.exerciseId)
        appData.activeWorkout = active
        scheduleSync()
    }

    private func scheduleSync() {
        guard sessionToken != nil else {
            return
        }

        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else {
                return
            }
            await self?.uploadCurrentData()
        }
    }

    private func scheduleRestNotification(seconds: Int, exerciseName: String?) {
        Task {
            await restNotifier.scheduleRestComplete(after: seconds, exerciseName: exerciseName)
        }
    }

    private func upsertCustomProgram(_ program: Program) {
        appData.customPrograms.removeAll { $0.id == program.id }
        appData.customPrograms.append(program)
    }

    private func upsertCustomExercise(_ exercise: Exercise) {
        appData.customExercises.removeAll { $0.id == exercise.id }
        appData.customExercises.append(exercise)
    }

    private static func parseReps(_ reps: String) -> Int {
        let digits = reps.prefix { $0.isNumber }
        return Int(digits) ?? 10
    }
}
