import Foundation
import Observation

enum SharedProgramAddMode {
    case follow
    case duplicate
}

@MainActor
@Observable
final class AppStore {
    var user: SessionUser?
    var appData = AppData()
    var catalog = Catalog()
    var isLoading = false
    var authError: String?
    var isWorkoutPresented = false
    var workoutPresentationProgramId: String?
    var workoutPresentationDayId: String?
    var workoutPresentationWeek: Int?

    private let apiClient: APIClient
    private let keychain: KeychainStore
    @ObservationIgnored private var restNotifier: RestTimerNotifier
    private var sessionToken: String?
    private var hasAttemptedRestore = false
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    private static let trashTTLMilliseconds: Double = 7 * 24 * 60 * 60 * 1000

    init(
        apiClient: APIClient? = nil,
        keychain: KeychainStore? = nil,
        restNotifier: RestTimerNotifier? = nil
    ) {
        self.apiClient = apiClient ?? APIClient.production()
        self.keychain = keychain ?? KeychainStore()
        self.restNotifier = restNotifier ?? RestTimerNotifier()
    }

    var allPrograms: [Program] {
        let hidden = Set(appData.hiddenProgramIds)
        let trashed = Set(appData.trashedPrograms.map(\.program.id))
        let customIds = Set(appData.customPrograms.map(\.id))

        return (catalog.programs + appData.customPrograms)
            .filter { !hidden.contains($0.id) && !trashed.contains($0.id) }
            .sorted { lhs, rhs in
                let lhsCustom = customIds.contains(lhs.id)
                let rhsCustom = customIds.contains(rhs.id)

                if lhsCustom != rhsCustom {
                    return lhsCustom
                }

                let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if nameComparison != .orderedSame {
                    return nameComparison == .orderedAscending
                }

                return lhs.id < rhs.id
            }
    }

    var allExercises: [Exercise] {
        let hidden = Set(appData.hiddenExerciseIds)
        let trashed = Set(appData.trashedExercises.map(\.exercise.id))
        let overriddenCatalog = catalog.exercises.map { exercise in
            appData.exerciseOverrides[exercise.id] ?? exercise
        }

        return (overriddenCatalog + appData.customExercises)
            .filter { !hidden.contains($0.id) && !trashed.contains($0.id) }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    func isCustomProgram(_ program: Program) -> Bool {
        appData.customPrograms.contains(where: { $0.id == program.id })
    }

    func isCustomExercise(_ exercise: Exercise) -> Bool {
        appData.customExercises.contains(where: { $0.id == exercise.id })
    }

    func isExerciseOverride(_ exercise: Exercise) -> Bool {
        appData.exerciseOverrides[exercise.id] != nil
    }

    func hideExercise(id: String) {
        if !appData.hiddenExerciseIds.contains(id) {
            appData.hiddenExerciseIds.append(id)
        }
        scheduleSync()
    }

    func restoreHiddenExercises() {
        appData.hiddenExerciseIds = []
        scheduleSync()
    }

    func restoreHiddenExercise(id: String) {
        appData.hiddenExerciseIds.removeAll { $0 == id }
        scheduleSync()
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

    func forgotPassword(email: String) async -> Bool {
        do {
            authError = nil
            try await apiClient.forgotPassword(email: email)
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func resetPassword(token: String, newPassword: String) async -> Bool {
        do {
            authError = nil
            try await apiClient.resetPassword(token: token, newPassword: newPassword)
            return true
        } catch {
            authError = error.localizedDescription
            return false
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

    func adminUsers() async -> [AdminUser] {
        guard user?.isAdmin == true else {
            authError = "Admin access required."
            return []
        }
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return []
        }

        do {
            authError = nil
            return try await apiClient.adminUsers(token: token)
        } catch {
            authError = error.localizedDescription
            return []
        }
    }

    func adminResetPassword(userId: String, newPassword: String) async -> Bool {
        guard user?.isAdmin == true else {
            authError = "Admin access required."
            return false
        }
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return false
        }

        do {
            try await apiClient.adminResetPassword(token: token, userId: userId, newPassword: newPassword)
            authError = nil
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func adminPublishCatalog() async -> Bool {
        guard user?.isAdmin == true else {
            authError = "Admin access required."
            return false
        }
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return false
        }

        do {
            catalog = try await apiClient.adminPutCatalog(token: token, catalog: catalog)
            authError = nil
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func setDisplayName(_ name: String) {
        appData.name = name
        if var currentUser = user {
            currentUser.name = name
            user = currentUser
        }
        scheduleSync()
    }

    func setUnit(_ unit: String) {
        appData.unit = unit
        scheduleSync()
    }

    func setTimerMode(_ mode: String) {
        appData.timerMode = mode
        scheduleSync()
    }

    func setTimerSound(_ sound: String) {
        appData.timerSound = sound
        scheduleSync()
    }

    func addSavedTimer(seconds: Int) {
        guard seconds > 0 else { return }
        let timer = SavedTimer(id: UUID().uuidString, label: formatClock(seconds), seconds: seconds)
        appData.savedTimers.removeAll { $0.seconds == seconds }
        appData.savedTimers.insert(timer, at: 0)
        appData.savedTimers = Array(appData.savedTimers.prefix(8))
        scheduleSync()
    }

    func removeSavedTimer(id: String) {
        appData.savedTimers.removeAll { $0.id == id }
        scheduleSync()
    }

    func setIntervalSettings(_ settings: IntervalSettings) {
        appData.intervalSettings = settings
        scheduleSync()
    }

    func setIntervalFormat(_ format: String?) {
        appData.intervalFormat = format
        scheduleSync()
    }

    func setThemeColor(_ color: String) {
        UserDefaults.standard.set(color, forKey: Theme.accentStorageKey)
        appData.themeColor = color
        scheduleSync()
    }

    func setThemeMode(_ mode: String) {
        appData.themeMode = mode
        scheduleSync()
    }

    func clearActiveProgram() {
        appData.activeProgramId = nil
        scheduleSync()
    }

    func resetProgramProgress(id: String) {
        appData.programAnchors[id] = ISO8601DateFormatter().string(from: Date())
        if appData.activeWorkout?.programId == id {
            appData.activeWorkout = nil
        }
        scheduleSync()
    }

    func presentWorkout() {
        if workoutPresentationProgramId == nil, let active = appData.activeWorkout {
            setWorkoutPresentationContext(
                programId: active.programId,
                dayId: active.dayId,
                week: active.week ?? 1
            )
        }
        isWorkoutPresented = true
    }

    func dismissWorkout() {
        isWorkoutPresented = false
        workoutPresentationProgramId = nil
        workoutPresentationDayId = nil
        workoutPresentationWeek = nil
    }

    func resetAllData() {
        let preservedName = user?.name ?? appData.name
        let preservedUnit = appData.unit
        let preservedThemeColor = appData.themeColor
        let preservedThemeMode = appData.themeMode
        appData = AppData(
            name: preservedName,
            unit: preservedUnit,
            themeColor: preservedThemeColor,
            themeMode: preservedThemeMode
        )
        scheduleSync()
    }

    func changePassword(currentPassword: String, newPassword: String) async -> Bool {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return false
        }

        do {
            try await apiClient.changePassword(
                token: token,
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            authError = nil
            return true
        } catch {
            authError = error.localizedDescription
            return false
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

    func following() async -> [FollowUser] {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return []
        }

        do {
            authError = nil
            return try await apiClient.following(token: token)
        } catch {
            authError = error.localizedDescription
            return []
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

    @discardableResult
    func addSharedProgram(id: String) async -> Bool {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return false
        }

        do {
            let program = try await apiClient.addProgram(token: token, programId: id)
            upsertCustomProgram(program)
            scheduleSync()
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func addSharedProgram(
        _ program: Program,
        ownerName: String,
        ownerExercises: [Exercise],
        mode: SharedProgramAddMode
    ) async -> Program? {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return nil
        }

        do {
            let baseProgram: Program
            switch mode {
            case .follow:
                baseProgram = try await apiClient.addProgram(token: token, programId: program.id)
            case .duplicate:
                baseProgram = program
            }

            let prepared = makeSharedProgramSelfContained(
                baseProgram,
                ownerName: ownerName,
                ownerExercises: ownerExercises
            )
            importReferencedSharedExercises(prepared.referencedExercises, ownerName: ownerName)

            var savedProgram = prepared.program
            if mode == .duplicate {
                savedProgram.id = "ios-\(UUID().uuidString)"
                savedProgram.ownerId = user?.id
                savedProgram.ownerName = user?.name ?? appData.name
                if let name = user?.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    savedProgram.coach = name
                }
                savedProgram.collaborative = false
                savedProgram.version = Int(Date().timeIntervalSince1970 * 1000)
                savedProgram = try await apiClient.upsertProgram(token: token, program: savedProgram)
            }

            upsertCustomProgram(savedProgram)
            scheduleSync()
            return savedProgram
        } catch {
            authError = error.localizedDescription
            return nil
        }
    }

    @discardableResult
    func addSharedExercise(id: String) async -> Bool {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return false
        }

        do {
            let exercise = try await apiClient.addExercise(token: token, exerciseId: id)
            upsertCustomExercise(exercise)
            scheduleSync()
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func addSharedExercise(_ exercise: Exercise, ownerName: String) async -> Bool {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return false
        }

        do {
            var saved = try await apiClient.addExercise(token: token, exerciseId: exercise.id)
            saved.shared = false
            let savedOwnerName = saved.ownerName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if savedOwnerName.isEmpty {
                saved.ownerName = ownerName
            }
            upsertCustomExercise(saved)
            scheduleSync()
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func removeSharedProgram(id: String) async {
        await removeSharedProgram(sharedId: id, localId: id)
    }

    func removeSharedProgram(sharedId: String, localId: String) async {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return
        }

        do {
            if sharedId == localId {
                try await apiClient.removeProgramMember(token: token, programId: sharedId)
            }
            appData.customPrograms.removeAll { $0.id == localId }
            if appData.activeProgramId == localId {
                appData.activeProgramId = nil
            }
            scheduleSync()
        } catch {
            authError = error.localizedDescription
        }
    }

    func removeSharedExercise(id: String) async {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return
        }

        do {
            try await apiClient.removeExerciseMember(token: token, exerciseId: id)
            appData.customExercises.removeAll { $0.id == id }
            scheduleSync()
        } catch {
            authError = error.localizedDescription
        }
    }

    func saveCustomProgram(_ program: Program) {
        upsertCustomProgram(program)
        scheduleSync()
    }

    @discardableResult
    func duplicateProgram(_ program: Program) -> Program {
        var copy = program
        copy.id = "ios-copy-\(UUID().uuidString)"
        copy.name = "\(program.name) Copy"
        copy.ownerId = nil
        copy.ownerName = nil
        copy.collaborative = false
        copy.version = nil
        upsertCustomProgram(copy)
        scheduleSync()
        return copy
    }

    func deleteCustomProgram(id: String) {
        if let program = appData.customPrograms.first(where: { $0.id == id }) {
            appData.trashedPrograms.removeAll { $0.program.id == id }
            appData.trashedPrograms.append(TrashedProgram(program: program, deletedAt: Date().timeIntervalSince1970 * 1000))
        }
        appData.customPrograms.removeAll { $0.id == id }
        if appData.activeProgramId == id {
            appData.activeProgramId = nil
        }
        appData.favoriteProgramIds.removeAll { $0 == id }
        scheduleSync()
    }

    func restoreTrashedProgram(id: String) {
        guard let trashed = appData.trashedPrograms.first(where: { $0.program.id == id }) else { return }
        appData.customPrograms.removeAll { $0.id == id }
        appData.customPrograms.append(trashed.program)
        appData.trashedPrograms.removeAll { $0.program.id == id }
        scheduleSync()
    }

    func purgeTrashedProgram(id: String) {
        appData.trashedPrograms.removeAll { $0.program.id == id }
        scheduleSync()
    }

    func deleteWorkoutLog(id: String) {
        appData.logs.removeAll { $0.id == id }
        scheduleSync()
    }

    func upsertWorkoutLog(_ log: WorkoutLog, program: Program) {
        addWorkoutLog(log, program: program)
        scheduleSync()
    }

    func removeCompletedProgram(id: String) {
        appData.completedPrograms.removeAll { $0.id == id }
        scheduleSync()
    }

    func setActiveProgram(id: String) {
        appData.activeProgramId = id
        scheduleSync()
    }

    func toggleFavoriteProgram(id: String) {
        if appData.favoriteProgramIds.contains(id) {
            appData.favoriteProgramIds.removeAll { $0 == id }
        } else if appData.favoriteProgramIds.count < 5 {
            appData.favoriteProgramIds.append(id)
        }
        scheduleSync()
    }

    func toggleFavoriteUser(id: String) {
        if appData.favoriteUserIds.contains(id) {
            appData.favoriteUserIds.removeAll { $0 == id }
        } else if appData.favoriteUserIds.count < 3 {
            appData.favoriteUserIds.append(id)
        }
        scheduleSync()
    }

    func hideProgram(id: String) {
        if !appData.hiddenProgramIds.contains(id) {
            appData.hiddenProgramIds.append(id)
        }
        if appData.activeProgramId == id {
            appData.activeProgramId = nil
        }
        appData.favoriteProgramIds.removeAll { $0 == id }
        scheduleSync()
    }

    func restoreHiddenPrograms() {
        appData.hiddenProgramIds = []
        scheduleSync()
    }

    func restoreHiddenProgram(id: String) {
        appData.hiddenProgramIds.removeAll { $0 == id }
        scheduleSync()
    }

    func saveCustomExercise(_ exercise: Exercise) {
        upsertCustomExercise(exercise)
        relinkExercisePlaceholders(to: exercise)
        scheduleSync()
    }

    func saveExerciseOverride(_ exercise: Exercise) {
        appData.exerciseOverrides[exercise.id] = exercise
        scheduleSync()
    }

    func restoreExerciseOverride(id: String) {
        appData.exerciseOverrides.removeValue(forKey: id)
        scheduleSync()
    }

    func deleteCustomExercise(id: String) {
        if let exercise = appData.customExercises.first(where: { $0.id == id }) {
            appData.trashedExercises.removeAll { $0.exercise.id == id }
            appData.trashedExercises.append(TrashedExercise(exercise: exercise, deletedAt: Date().timeIntervalSince1970 * 1000))
        }
        appData.customExercises.removeAll { $0.id == id }
        scheduleSync()
    }

    func restoreTrashedExercise(id: String) {
        guard let trashed = appData.trashedExercises.first(where: { $0.exercise.id == id }) else { return }
        appData.customExercises.removeAll { $0.id == id }
        appData.customExercises.append(trashed.exercise)
        appData.trashedExercises.removeAll { $0.exercise.id == id }
        scheduleSync()
    }

    func purgeTrashedExercise(id: String) {
        appData.trashedExercises.removeAll { $0.exercise.id == id }
        scheduleSync()
    }

    func setExerciseNote(exerciseId: String, note: String) {
        let clean = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            appData.exerciseNotes.removeValue(forKey: exerciseId)
        } else {
            appData.exerciseNotes[exerciseId] = clean
        }
        scheduleSync()
    }

    func setExerciseCue(exerciseId: String, cue: String) {
        let clean = cue.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            appData.exerciseSubheaders.removeValue(forKey: exerciseId)
        } else {
            appData.exerciseSubheaders[exerciseId] = clean
        }
        scheduleSync()
    }

    func addBodyWeight(_ weight: Double) {
        let entry = BodyWeightEntry(
            id: UUID().uuidString,
            date: Self.dateOnlyFormatter.string(from: Date()),
            weight: weight,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        appData.bodyWeight.removeAll { $0.date == entry.date }
        appData.bodyWeight.append(entry)
        appData.bodyWeight.sort { $0.date < $1.date }
        scheduleSync()
    }

    func deleteBodyWeight(id: String) {
        appData.bodyWeight.removeAll { $0.id == id }
        scheduleSync()
    }

    func setTodayNutrition(calories: Int, protein: Int, carbs: Int, fat: Int, water: Int) {
        setNutritionEntry(
            date: Self.dateOnlyFormatter.string(from: Date()),
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            water: water
        )
    }

    func setNutritionEntry(date: String, calories: Int, protein: Int, carbs: Int, fat: Int, water: Int) {
        let existingPhotos = appData.nutritionLog.first { $0.date == date }?.photos
        let entry = NutritionEntry(
            date: date,
            calories: max(0, calories),
            protein: max(0, protein),
            carbs: max(0, carbs),
            fat: max(0, fat),
            water: max(0, water),
            photos: existingPhotos
        )
        appData.nutritionLog.removeAll { $0.date == entry.date }
        appData.nutritionLog.append(entry)
        appData.nutritionLog.sort { $0.date < $1.date }
        scheduleSync()
    }

    func setNutritionPhotos(date: String, photos: [String]) {
        let existing = appData.nutritionLog.first { $0.date == date }
        let entry = NutritionEntry(
            date: date,
            calories: existing?.calories ?? 0,
            protein: existing?.protein ?? 0,
            carbs: existing?.carbs ?? 0,
            fat: existing?.fat ?? 0,
            water: existing?.water ?? 0,
            photos: Array(photos.prefix(3))
        )
        appData.nutritionLog.removeAll { $0.date == date }
        appData.nutritionLog.append(entry)
        appData.nutritionLog.sort { $0.date < $1.date }
        scheduleSync()
    }

    func setNutritionGoals(_ goals: NutritionGoals) {
        appData.nutritionGoals = NutritionGoals(
            calories: max(0, goals.calories),
            protein: max(0, goals.protein),
            carbs: max(0, goals.carbs),
            fat: max(0, goals.fat),
            water: max(0, goals.water)
        )
        scheduleSync()
    }

    func addMaxRecord(name: String, weight: Double, reps: Int) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            return
        }

        let record = MaxRecord(
            id: UUID().uuidString,
            date: Self.dateOnlyFormatter.string(from: Date()),
            weight: max(0, weight),
            reps: max(0, reps)
        )

        if let index = appData.maxTrackers.firstIndex(where: { $0.name.localizedCaseInsensitiveCompare(cleanName) == .orderedSame }) {
            appData.maxTrackers[index].records.append(record)
        } else {
            appData.maxTrackers.insert(MaxTracker(id: UUID().uuidString, name: cleanName, records: [record]), at: 0)
        }
        scheduleSync()
    }

    func addMaxRecordToTracker(trackerId: String, weight: Double, reps: Int) {
        guard let index = appData.maxTrackers.firstIndex(where: { $0.id == trackerId }) else {
            return
        }

        let record = MaxRecord(
            id: UUID().uuidString,
            date: Self.dateOnlyFormatter.string(from: Date()),
            weight: max(0, weight),
            reps: max(0, reps)
        )
        appData.maxTrackers[index].records.append(record)
        scheduleSync()
    }

    func deleteMaxRecord(trackerId: String, recordId: String) {
        guard let index = appData.maxTrackers.firstIndex(where: { $0.id == trackerId }) else {
            return
        }

        appData.maxTrackers[index].records.removeAll { $0.id == recordId }
        scheduleSync()
    }

    func deleteMaxTracker(id: String) {
        appData.maxTrackers.removeAll { $0.id == id }
        scheduleSync()
    }

    func shareProgram(_ program: Program) async {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return
        }

        do {
            var publish = program
            publish.ownerName = user?.name ?? appData.name
            publish.version = Int(Date().timeIntervalSince1970 * 1000)
            let shared = try await apiClient.upsertProgram(token: token, program: publish)
            upsertCustomProgram(shared)
            scheduleSync()
        } catch {
            authError = error.localizedDescription
        }
    }

    func shareExercise(_ exercise: Exercise) async {
        guard let token = sessionToken else {
            authError = APIError.missingToken.localizedDescription
            return
        }

        do {
            var publish = exercise
            publish.ownerName = user?.name ?? appData.name
            publish.shared = true
            publish.version = Int(Date().timeIntervalSince1970 * 1000)
            let shared = try await apiClient.upsertExercise(token: token, exercise: publish)
            upsertCustomExercise(shared)
            scheduleSync()
        } catch {
            authError = error.localizedDescription
        }
    }

    func unshareExercise(_ exercise: Exercise) {
        var updated = exercise
        updated.shared = false
        upsertCustomExercise(updated)
        scheduleSync()
    }

    func startWorkout(program: Program, day: ProgramDay, week: Int = 1) {
        if let active = appData.activeWorkout,
           active.programId == program.id,
           active.dayId == day.id,
           (active.week ?? 1) == week {
            setWorkoutPresentationContext(programId: program.id, dayId: day.id, week: week)
            reconcileActiveWorkout(day: day)
            return
        }

        let dayIndex = program.days.firstIndex(where: { $0.id == day.id }) ?? 0
        let globalIndex = (max(1, week) - 1) * max(1, program.days.count) + dayIndex
        let previousWeights = domainPreviousWeekWeights(
            program: program,
            logs: appData.logs,
            since: appData.programAnchors[program.id],
            globalIndex: globalIndex
        )

        appData.activeProgramId = program.id
        setWorkoutPresentationContext(programId: program.id, dayId: day.id, week: week)
        appData.activeWorkout = ActiveWorkout(
            programId: program.id,
            dayId: day.id,
            week: week,
            startedAt: Date().timeIntervalSince1970 * 1000,
            sets: day.exercises.map { planned in
                let weights = previousWeights[planned.exerciseId] ?? []
                return (0..<planned.sets).map { setIndex in
                    let fallbackWeight = weights.last ?? 0
                    let weight = weights.indices.contains(setIndex) ? weights[setIndex] : fallbackWeight
                    return SetLog(weight: weight, reps: Self.parseReps(planned.reps), completed: false)
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

    func extendRest(by seconds: Int) {
        guard seconds > 0, var active = appData.activeWorkout else {
            return
        }

        let now = Date().timeIntervalSince1970 * 1000
        let currentEnd = active.restEndsAt ?? now
        active.restEndsAt = max(currentEnd, now) + Double(seconds * 1000)
        active.restTotal += seconds
        appData.activeWorkout = active
        scheduleSync()
    }

    func endWorkout() {
        appData.activeWorkout = nil
        isWorkoutPresented = false
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
        appData.activeWorkout = nil
        addWorkoutLog(log, program: program)
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

    private func setWorkoutPresentationContext(programId: String, dayId: String, week: Int) {
        workoutPresentationProgramId = programId
        workoutPresentationDayId = dayId
        workoutPresentationWeek = week
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
        purgeExpiredTrash()
        await refreshSharedContent(token: token)
        UserDefaults.standard.set(appData.themeColor, forKey: Theme.accentStorageKey)
    }

    private func addWorkoutLog(_ log: WorkoutLog, program: Program) {
        appData.logs.removeAll { $0.id == log.id }
        appData.logs.insert(log, at: 0)

        let anchor = appData.programAnchors[program.id]
        let run = domainProgramRun(program: program, logs: appData.logs, since: anchor)
        let slots = domainProgramLogSlots(program: program, logs: appData.logs, since: anchor)
        let totalSlots = run.totalSlots
        var runLogs: [WorkoutLog] = []

        for index in 0..<totalSlots {
            guard slots.indices.contains(index), let slot = slots[index] else {
                continue
            }
            runLogs.append(slot)
        }

        guard runLogs.count >= totalSlots else {
            return
        }

        let runStartId = runLogs.first?.id ?? "run"
        let archiveId = "\(program.id)-\(runStartId)"
        guard !appData.completedPrograms.contains(where: { $0.id == archiveId }) else {
            return
        }

        let completed = CompletedProgram(
            id: archiveId,
            programId: program.id,
            name: program.name,
            accent: program.accent,
            durationWeeks: program.durationWeeks,
            daysPerWeek: program.daysPerWeek,
            completedAt: runLogs.last?.date ?? ISO8601DateFormatter().string(from: Date()),
            program: program,
            logs: runLogs
        )
        appData.completedPrograms.insert(completed, at: 0)
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

    private func refreshSharedContent(token: String) async {
        let currentUserId = user?.id
        let linkedProgramIdSet = Set<String>(appData.customPrograms.compactMap { program -> String? in
            guard let ownerId = program.ownerId, ownerId != currentUserId else { return nil }
            return program.id
        })
        let linkedExerciseIdSet = Set<String>(appData.customExercises.compactMap { exercise -> String? in
            guard let ownerId = exercise.ownerId, ownerId != currentUserId else { return nil }
            return exercise.id
        })
        let linkedProgramIds = Array(linkedProgramIdSet)
        let linkedExerciseIds = Array(linkedExerciseIdSet)

        do {
            if !linkedProgramIds.isEmpty {
                let remotePrograms = try await apiClient.programsBatch(token: token, ids: linkedProgramIds)
                let remoteById = Dictionary(uniqueKeysWithValues: remotePrograms.map { ($0.id, $0) })
                appData.customPrograms = appData.customPrograms.map { local in
                    guard let remote = remoteById[local.id],
                          (remote.version ?? 0) > (local.version ?? 0) else {
                        return local
                    }
                    return remote
                }
            }

            if !linkedExerciseIds.isEmpty {
                let remoteExercises = try await apiClient.exercisesBatch(token: token, ids: linkedExerciseIds)
                let remoteById = Dictionary(uniqueKeysWithValues: remoteExercises.map { ($0.id, $0) })
                appData.customExercises = appData.customExercises.map { local in
                    guard var remote = remoteById[local.id],
                          (remote.version ?? 0) > (local.version ?? 0) else {
                        return local
                    }
                    remote.shared = local.shared
                    return remote
                }
            }
        } catch {
            authError = error.localizedDescription
        }
    }

    private func purgeExpiredTrash() {
        let cutoff = Date().timeIntervalSince1970 * 1000 - Self.trashTTLMilliseconds
        let oldProgramCount = appData.trashedPrograms.count
        let oldExerciseCount = appData.trashedExercises.count
        appData.trashedPrograms.removeAll { $0.deletedAt <= cutoff }
        appData.trashedExercises.removeAll { $0.deletedAt <= cutoff }
        if oldProgramCount != appData.trashedPrograms.count || oldExerciseCount != appData.trashedExercises.count {
            scheduleSync()
        }
    }

    private func relinkExercisePlaceholders(to exercise: Exercise) {
        let targetName = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !targetName.isEmpty else { return }

        var idMap: [String: String] = [:]

        func relink(_ planned: PlannedExercise) -> PlannedExercise {
            guard let plannedName = planned.name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  plannedName == targetName,
                  planned.exerciseId != exercise.id else {
                return planned
            }

            var updated = planned
            idMap[planned.exerciseId] = exercise.id
            updated.exerciseId = exercise.id
            updated.name = exercise.name
            return updated
        }

        func relink(_ day: ProgramDay) -> ProgramDay {
            var updated = day
            updated.exercises = day.exercises.map(relink)
            return updated
        }

        appData.customPrograms = appData.customPrograms.map { program in
            var updated = program
            updated.days = program.days.map(relink)
            if let weekOverrides = program.weekOverrides {
                var overrides: [String: [ProgramWeekOverride]] = [:]
                for (dayId, list) in weekOverrides {
                    overrides[dayId] = list.map { item in
                        var updatedItem = item
                        updatedItem.day = relink(item.day)
                        return updatedItem
                    }
                }
                updated.weekOverrides = overrides
            }
            return updated
        }

        guard !idMap.isEmpty, var active = appData.activeWorkout, let ids = active.exerciseIds else {
            return
        }
        active.exerciseIds = ids.map { idMap[$0] ?? $0 }
        appData.activeWorkout = active
    }

    private func makeSharedProgramSelfContained(
        _ program: Program,
        ownerName: String,
        ownerExercises: [Exercise]
    ) -> (program: Program, referencedExercises: [Exercise]) {
        var prepared = program
        if prepared.coach.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            prepared.coach = ownerName
        }

        var ownerExerciseById: [String: Exercise] = [:]
        for exercise in ownerExercises {
            ownerExerciseById[exercise.id] = exercise
        }

        var referencedExerciseIds = Set<String>()

        func fixPlannedExercise(_ planned: PlannedExercise) -> PlannedExercise {
            var updated = planned
            if let ownerExercise = ownerExerciseById[planned.exerciseId] {
                let isCatalogExercise = catalog.exercises.contains { $0.id == planned.exerciseId }
                if !isCatalogExercise {
                    referencedExerciseIds.insert(planned.exerciseId)
                }
                let plannedName = updated.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if plannedName.isEmpty {
                    updated.name = ownerExercise.name
                }
            }
            return updated
        }

        prepared.days = prepared.days.map { day in
            var updated = day
            updated.exercises = day.exercises.map(fixPlannedExercise)
            return updated
        }

        if let weekOverrides = prepared.weekOverrides {
            var updatedOverrides: [String: [ProgramWeekOverride]] = [:]
            for (week, overrides) in weekOverrides {
                updatedOverrides[week] = overrides.map { override in
                    var updatedOverride = override
                    var updatedDay = override.day
                    updatedDay.exercises = override.day.exercises.map(fixPlannedExercise)
                    updatedOverride.day = updatedDay
                    return updatedOverride
                }
            }
            prepared.weekOverrides = updatedOverrides
        }

        let referencedExercises = referencedExerciseIds.compactMap { ownerExerciseById[$0] }
        return (prepared, referencedExercises)
    }

    private func importReferencedSharedExercises(_ exercises: [Exercise], ownerName: String) {
        for exercise in exercises {
            let alreadyKnown = catalog.exercises.contains { $0.id == exercise.id }
                || appData.customExercises.contains { $0.id == exercise.id }
            guard !alreadyKnown else { continue }

            var imported = exercise
            imported.shared = false
            let importedOwnerName = imported.ownerName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if importedOwnerName.isEmpty {
                imported.ownerName = ownerName
            }
            upsertCustomExercise(imported)
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

    private func formatClock(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
