import Foundation
import SwiftUI

@MainActor
class AppStore: ObservableObject {
    @Published var appData: AppData
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var currentUser: PublicUser?
    @Published var builtInPrograms: [Program] = []
    @Published var builtInExercises: [Exercise] = []
    
    private let apiClient: APIClient
    private let keychain: KeychainStore
    
    init(apiClient: APIClient = .shared, keychain: KeychainStore = .shared) {
        self.apiClient = apiClient
        self.keychain = keychain
        self.appData = AppData()
        // Set accent from theme color
        if let themeColor = appData.themeColor {
            Theme.setAccent(from: themeColor)
        }
    }
    
    func loadAppData() async {
        isLoading = true
        errorMessage = ""
        
        do {
            let data = try await apiClient.getAppData()
            self.appData = data
            // Set accent from theme color
            if let themeColor = data.themeColor {
                Theme.setAccent(from: themeColor)
            }
        } catch {
            errorMessage = error.localizedDescription
            NSLog("Failed to load app data: \(error)")
        }
        
        isLoading = false
    }
    
    func loadCatalog() async {
        do {
            let catalog = try await apiClient.fetchCatalog()
            self.builtInPrograms = catalog.programs
            self.builtInExercises = catalog.exercises
        } catch {
            NSLog("Failed to load catalog: \(error)")
        }
    }
    
    func saveAppData() async {
        isLoading = true
        errorMessage = ""
        
        do {
            let _ = try await apiClient.saveAppData(appData)
        } catch {
            errorMessage = error.localizedDescription
            NSLog("Failed to save app data: \(error)")
        }
        
        isLoading = false
    }
    
    func startWorkout(programId: String, dayId: String, week: Int, dayIndex: Int = 0) async {
        let activeWorkout = ActiveWorkout(
            programId: programId,
            dayId: dayId,
            dayIndex: dayIndex,
            week: week,
            startedAt: Date().timeIntervalSince1970,
            sets: [],
            exerciseIds: []
        )
        
        appData.activeWorkout = activeWorkout
        await saveAppData()
    }
    
    func updateActiveWorkoutSets(_ sets: [[SetLog]]) async {
        appData.activeWorkout?.sets = sets
        await saveAppData()
    }
    
    func setActiveProgram(_ programId: String) async {
        appData.activeProgramId = programId
        appData.programAnchors[programId] = todayISO()
        await saveAppData()
    }
    
    func addLog(_ log: WorkoutLog) async {
        appData.logs.append(log)
        await saveAppData()
    }
    
    func endWorkout() async {
        appData.activeWorkout = nil
        await saveAppData()
    }
    
    func updateExerciseNote(exerciseId: String, note: String) async {
        if note.isEmpty {
            appData.exerciseNotes.removeValue(forKey: exerciseId)
        } else {
            appData.exerciseNotes[exerciseId] = note
        }
        await saveAppData()
    }
    
    func updateExerciseCue(exerciseId: String, cue: String) async {
        if cue.isEmpty {
            appData.exerciseSubheaders.removeValue(forKey: exerciseId)
        } else {
            appData.exerciseSubheaders[exerciseId] = cue
        }
        await saveAppData()
    }
    
    func updateProgram(_ program: Program) async {
        if let index = appData.customPrograms.firstIndex(where: { $0.id == program.id }) {
            appData.customPrograms[index] = program
        } else {
            appData.customPrograms.append(program)
        }
        await saveAppData()
    }
    
    func apiUpsertProgram(_ program: Program) async {
        do {
            try await apiClient.upsertProgram(program)
        } catch {
            NSLog("Failed to upsert program: \(error)")
        }
    }
    
    func addBodyWeight(weight: Double) async {
        let entry = BodyWeightEntry(
            id: UUID().uuidString,
            date: ISO8601DateFormatter().string(from: Date()),
            weight: weight
        )
        appData.bodyWeightEntries.append(entry)
        await saveAppData()
    }
    
    func deleteBodyWeight(id: String) async {
        appData.bodyWeightEntries.removeAll { $0.id == id }
        await saveAppData()
    }
    
    func removeCompletedProgram(id: String) async {
        appData.completedPrograms.removeAll { $0.id == id }
        await saveAppData()
    }
    
    // MARK: - Max Trackers
    
    func addMaxTracker(name: String) async {
        let tracker = MaxTracker(id: uid(), name: name, records: [])
        appData.maxTrackers.append(tracker)
        await saveAppData()
    }
    
    func addMaxRecord(trackerId: String, weight: Double, reps: Int) async {
        if let index = appData.maxTrackers.firstIndex(where: { $0.id == trackerId }) {
            let record = MaxRecord(id: uid(), date: ISO8601DateFormatter().string(from: Date()), weight: weight, reps: reps)
            var updatedTracker = appData.maxTrackers[index]
            var records = updatedTracker.records
            records.append(record)
            appData.maxTrackers[index] = MaxTracker(id: updatedTracker.id, name: updatedTracker.name, records: records)
            await saveAppData()
        }
    }
    
    func deleteMaxRecord(trackerId: String, recordId: String) async {
        if let index = appData.maxTrackers.firstIndex(where: { $0.id == trackerId }) {
            var updatedTracker = appData.maxTrackers[index]
            let records = updatedTracker.records.filter { $0.id != recordId }
            appData.maxTrackers[index] = MaxTracker(id: updatedTracker.id, name: updatedTracker.name, records: records)
            await saveAppData()
        }
    }
    
    func deleteMaxTracker(id: String) async {
        appData.maxTrackers.removeAll { $0.id == id }
        await saveAppData()
    }
    
    // MARK: - People/Search
    
    func searchUsers(query: String) async throws -> [DiscoverUser] {
        return try await APIClient.shared.searchUsers(query: query)
    }
    
    func followUser(userId: String) async throws {
        try await APIClient.shared.followUser(userId: userId)
        // Update local state optimistically
        if let index = appData.followingUsers.firstIndex(where: { $0.id == userId }) {
            appData.followingUsers[index] = DiscoverUser(id: appData.followingUsers[index].id, name: appData.followingUsers[index].name, following: true, sharedProgramCount: appData.followingUsers[index].sharedProgramCount, sharedExerciseCount: appData.followingUsers[index].sharedExerciseCount)
        }
        await saveAppData()
    }
    
    func unfollowUser(userId: String) async throws {
        try await APIClient.shared.unfollowUser(userId: userId)
        // Update local state
        appData.followingUsers.removeAll { $0.id == userId }
        await saveAppData()
    }
    
    func getUserContent(userId: String) async throws -> UserSharedContent {
        let programs = try await APIClient.shared.getUserPrograms(userId: userId)
        let exercises = try await APIClient.shared.getUserExercises(userId: userId)
        return UserSharedContent(programs: programs, exercises: exercises)
    }
    
    func addSharedProgram(programId: String) async throws {
        try await APIClient.shared.addProgram(programId: programId)
        await loadAppData()
    }
    
    func favoriteUser(userId: String) async throws {
        try await APIClient.shared.favoriteUser(userId: userId)
        if !appData.favoriteUserIds.contains(userId) && appData.favoriteUserIds.count < 5 {
            appData.favoriteUserIds.append(userId)
            await saveAppData()
        }
    }
    
    func unfavoriteUser(userId: String) async throws {
        try await APIClient.shared.unfavoriteUser(userId: userId)
        appData.favoriteUserIds.removeAll { $0 == userId }
        await saveAppData()
    }
    
    // MARK: - Settings
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        try await APIClient.shared.changePassword(currentPassword: currentPassword, newPassword: newPassword)
    }
    
    func resetAllData() async throws {
        try await APIClient.shared.resetAllData()
        await loadAppData()
    }
    
    func logout() {
        keychain.deleteToken()
        currentUser = nil
        appData = AppData()
    }
    
    func setDisplayName(_ name: String) async {
        appData.name = name
        await saveAppData()
    }
    
    func setThemeColor(_ color: String) async {
        appData.themeColor = color
        Theme.setAccent(from: color)
        await saveAppData()
    }
    
    func setThemeMode(_ mode: String) async {
        appData.themeMode = mode
        await saveAppData()
    }
    
    func setUnit(_ unit: String) async {
        appData.unit = unit
        await saveAppData()
    }
    
    // MARK: - Nutrition
    
    func setNutritionEntry(_ entry: NutritionEntry) async throws {
        try await APIClient.shared.setNutritionEntry(entry)
        appData.nutritionLog[entry.date] = entry
        await saveAppData()
    }
    
    func setNutritionGoals(_ goals: NutritionGoals) async throws {
        try await APIClient.shared.setNutritionGoals(goals)
        appData.nutritionGoals = goals
        await saveAppData()
    }
    
    func getNutritionEntry(for date: String) -> NutritionEntry {
        if let entry = appData.nutritionLog[date] {
            return entry
        }
        return NutritionEntry(
            id: UUID().uuidString,
            date: date,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            water: 0,
            photos: []
        )
    }
    
    // MARK: - Auth
    
    func login(email: String, password: String) async throws {
        let authResponse = try await APIClient.shared.login(email: email, password: password)
        currentUser = authResponse.user
    }
    
    func signUp(name: String, email: String, password: String) async throws {
        let authResponse = try await APIClient.shared.signup(name: name, email: email, password: password)
        currentUser = authResponse.user
    }
    
    var isAuthenticated: Bool {
        keychain.getToken() != nil
    }
    
    func forgotPassword(email: String) async throws {
        try await APIClient.shared.forgotPassword(email: email)
    }
    
    func resetPassword(token: String, password: String) async throws {
        try await APIClient.shared.resetPassword(token: token, password: password)
    }
    
    // MARK: - Admin
    
    func adminUsers() async throws -> [AdminUser] {
        guard let token = keychain.getToken() else {
            throw APIError.keychainError
        }
        return try await APIClient.shared.adminUsers(token: token)
    }
    
    func adminResetPassword(userId: String, password: String) async throws {
        guard let token = keychain.getToken() else {
            throw APIError.keychainError
        }
        try await APIClient.shared.adminResetPassword(token: token, userId: userId, password: password)
    }
    
    // MARK: - Catalog
    
    func fetchCatalog() async throws -> Catalog {
        return try await APIClient.shared.fetchCatalog()
    }
    
    func adminPutCatalog(_ catalog: Catalog) async throws {
        guard let token = keychain.getToken() else {
            throw APIError.keychainError
        }
        try await APIClient.shared.adminPutCatalog(token: token, catalog: catalog)
        // Update built-ins in memory
        builtInPrograms = catalog.programs
        builtInExercises = catalog.exercises
    }
    
    // Computed properties
    var allPrograms: [Program] {
        appData.customPrograms + builtInPrograms
    }
    
    var allExercises: [Exercise] {
        appData.customExercises + builtInExercises
    }
    
    var activeProgram: Program? {
        guard let activeProgramId = appData.activeProgramId else { return nil }
        return allPrograms.first { $0.id == activeProgramId }
    }
    
    var activeWorkout: ActiveWorkout? {
        return appData.activeWorkout
    }
    
    var userLogs: [WorkoutLog] {
        return appData.logs
    }
    
    var unit: String {
        return appData.unit
    }
    
    var userName: String {
        return appData.name ?? "Athlete"
    }
    
    // Helper to get merged programs (catalog + custom, excluding hidden)
    func mergedPrograms() -> [Program] {
        let hiddenIds = Set(appData.hiddenProgramIds)
        let catalogFiltered = allPrograms.filter { !hiddenIds.contains($0.id) }
        return appData.customPrograms + catalogFiltered
    }
}

// MARK: - Catalog Response
struct CatalogResponse: Codable {
    let programs: [Program]
    let exercises: [Exercise]
}