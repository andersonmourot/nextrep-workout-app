import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case missingToken

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .requestFailed(_, let message):
            return message
        case .missingToken:
            return "You are not signed in."
        }
    }
}

struct APIMessageResponse: Codable, Equatable {
    var ok: Bool?
}

struct APIErrorPayload: Codable, Equatable {
    var detail: String?
}

struct DataPutRequest: Encodable {
    var data: AppData
}

struct PasswordResetRequest: Encodable {
    var newPassword: String

    enum CodingKeys: String, CodingKey {
        case newPassword = "new_password"
    }
}

struct ProgramPutRequest: Encodable {
    var program: Program
}

struct ExercisePutRequest: Encodable {
    var exercise: Exercise
}

private struct EmptyRequest: Encodable {}

final class APIClient {
    let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    static func production() -> APIClient {
        APIClient(baseURL: URL(string: "https://smellis-api.fly.dev")!)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await request(
            "/auth/login",
            method: "POST",
            body: ["email": email, "password": password]
        )
    }

    func signup(name: String, email: String, password: String) async throws -> AuthResponse {
        try await request(
            "/auth/signup",
            method: "POST",
            body: ["name": name, "email": email, "password": password]
        )
    }

    func forgotPassword(email: String) async throws {
        let _: APIMessageResponse = try await request(
            "/auth/forgot-password",
            method: "POST",
            body: ["email": email]
        )
    }

    func resetPassword(token: String, newPassword: String) async throws {
        let _: APIMessageResponse = try await request(
            "/auth/reset-password",
            method: "POST",
            body: ["token": token, "new_password": newPassword]
        )
    }

    func me(token: String) async throws -> SessionUser {
        try await request("/me", token: token)
    }

    func catalog() async throws -> Catalog {
        try await request("/api/catalog")
    }

    func adminUsers(token: String) async throws -> [AdminUser] {
        try await request("/api/admin/users", token: token)
    }

    func adminResetPassword(token: String, userId: String, newPassword: String) async throws {
        let _: APIMessageResponse = try await request(
            "/api/admin/users/\(userId)/reset-password",
            method: "POST",
            token: token,
            body: PasswordResetRequest(newPassword: newPassword)
        )
    }

    func adminPutCatalog(token: String, catalog: Catalog) async throws -> Catalog {
        try await request(
            "/api/admin/catalog",
            method: "PUT",
            token: token,
            body: catalog
        )
    }

    func appData(token: String) async throws -> AppData {
        try await request("/api/data", token: token)
    }

    func putData(_ data: AppData, token: String) async throws {
        let _: APIMessageResponse = try await request(
            "/api/data",
            method: "PUT",
            token: token,
            body: DataPutRequest(data: data)
        )
    }

    func changePassword(token: String, currentPassword: String, newPassword: String) async throws {
        let _: APIMessageResponse = try await request(
            "/auth/password",
            method: "POST",
            token: token,
            body: ["current_password": currentPassword, "new_password": newPassword]
        )
    }

    func searchUsers(token: String, query: String) async throws -> [DiscoverUser] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await request("/api/users/search?q=\(encoded)", token: token)
    }

    func followUser(token: String, userId: String) async throws {
        let _: APIMessageResponse = try await request(
            "/api/users/\(userId)/follow",
            method: "POST",
            token: token
        )
    }

    func unfollowUser(token: String, userId: String) async throws {
        let _: APIMessageResponse = try await request(
            "/api/users/\(userId)/follow",
            method: "DELETE",
            token: token
        )
    }

    func following(token: String) async throws -> [FollowUser] {
        try await request("/api/following", token: token)
    }

    func userPrograms(token: String, userId: String) async throws -> SharedPrograms {
        try await request("/api/users/\(userId)/programs", token: token)
    }

    func userExercises(token: String, userId: String) async throws -> SharedExercises {
        try await request("/api/users/\(userId)/exercises", token: token)
    }

    func addProgram(token: String, programId: String) async throws -> Program {
        let response: ProgramResponse = try await request(
            "/api/programs/\(programId)/add",
            method: "POST",
            token: token
        )
        return response.program
    }

    func removeProgramMember(token: String, programId: String) async throws {
        let _: APIMessageResponse = try await request(
            "/api/programs/\(programId)/member",
            method: "DELETE",
            token: token
        )
    }

    func addExercise(token: String, exerciseId: String) async throws -> Exercise {
        let response: ExerciseResponse = try await request(
            "/api/exercises/\(exerciseId)/add",
            method: "POST",
            token: token
        )
        return response.exercise
    }

    func removeExerciseMember(token: String, exerciseId: String) async throws {
        let _: APIMessageResponse = try await request(
            "/api/exercises/\(exerciseId)/member",
            method: "DELETE",
            token: token
        )
    }

    func upsertProgram(token: String, program: Program) async throws -> Program {
        let response: ProgramResponse = try await request(
            "/api/programs/\(program.id)",
            method: "PUT",
            token: token,
            body: ProgramPutRequest(program: program)
        )
        return response.program
    }

    func upsertExercise(token: String, exercise: Exercise) async throws -> Exercise {
        let response: ExerciseResponse = try await request(
            "/api/exercises/\(exercise.id)",
            method: "PUT",
            token: token,
            body: ExercisePutRequest(exercise: exercise)
        )
        return response.exercise
    }

    private func request<Response: Decodable>(
        _ path: String,
        method: String = "GET",
        token: String? = nil
    ) async throws -> Response {
        try await request(path, method: method, token: token, body: Optional<EmptyRequest>.none)
    }

    private func request<Response: Decodable, Body: Encodable>(
        _ path: String,
        method: String = "GET",
        token: String? = nil,
        body: Body? = nil
    ) async throws -> Response {
        let url = makeURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        }

        if let body {
            request.httpBody = try JSONEncoder.backend.encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let payload = try? JSONDecoder.backend.decode(APIErrorPayload.self, from: data)
            let message = payload?.detail ?? "Request failed (\(http.statusCode))."
            throw APIError.requestFailed(statusCode: http.statusCode, message: message)
        }

        if Response.self == APIMessageResponse.self, data.isEmpty {
            return APIMessageResponse(ok: true) as! Response
        }

        return try JSONDecoder.backend.decode(Response.self, from: data)
    }

    private func makeURL(_ path: String) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = trimmed.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let requestPath = String(parts.first ?? "")
        components.path = "/" + [basePath, requestPath].filter { !$0.isEmpty }.joined(separator: "/")
        if parts.count > 1 {
            components.percentEncodedQuery = String(parts[1])
        }
        return components.url!
    }
}
