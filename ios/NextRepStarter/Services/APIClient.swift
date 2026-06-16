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

    func me(token: String) async throws -> SessionUser {
        try await request("/me", token: token)
    }

    func catalog() async throws -> Catalog {
        try await request("/api/catalog")
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
        let requestPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + [basePath, requestPath].filter { !$0.isEmpty }.joined(separator: "/")
        return components.url!
    }
}
