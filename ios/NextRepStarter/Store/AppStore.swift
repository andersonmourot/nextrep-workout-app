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
    private var sessionToken: String?
    private var hasAttemptedRestore = false

    init(apiClient: APIClient = .production(), keychain: KeychainStore = KeychainStore()) {
        self.apiClient = apiClient
        self.keychain = keychain
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

    func syncNow() async {
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
}
