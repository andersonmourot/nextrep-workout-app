import Foundation

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "https://smellis-api.fly.dev"
    
    private init() {}
    
    private func createRequest(endpoint: String, method: String = "GET", body: Data? = nil, requiresAuth: Bool = true) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth, let token = KeychainStore.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    private func performRequestWithoutResponse(_ request: URLRequest) async throws {
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Auth Endpoints
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let loginRequest = LoginRequest(email: email, password: password)
        let body = try JSONEncoder().encode(loginRequest)
        
        guard let request = createRequest(endpoint: "/auth/login", method: "POST", body: body, requiresAuth: false) else {
            throw APIError.invalidURL
        }
        
        let response: AuthResponse = try await performRequest(request, responseType: AuthResponse.self)
        
        // Save the token
        if KeychainStore.shared.saveToken(response.token) {
            return response
        } else {
            throw APIError.keychainError
        }
    }
    
    func signup(name: String, email: String, password: String) async throws -> AuthResponse {
        let signupRequest = SignupRequest(name: name, email: email, password: password)
        let body = try JSONEncoder().encode(signupRequest)
        
        guard let request = createRequest(endpoint: "/auth/signup", method: "POST", body: body, requiresAuth: false) else {
            throw APIError.invalidURL
        }
        
        let response: AuthResponse = try await performRequest(request, responseType: AuthResponse.self)
        
        // Save the token
        if KeychainStore.shared.saveToken(response.token) {
            return response
        } else {
            throw APIError.keychainError
        }
    }
    
    func logout() {
        _ = KeychainStore.shared.deleteToken()
    }
    
    // MARK: - Data Endpoints
    
    func getAppData() async throws -> AppData {
        guard let request = createRequest(endpoint: "/api/data", method: "GET") else {
            throw APIError.invalidURL
        }
        
        return try await performRequest(request, responseType: AppData.self)
    }
    
    func saveAppData(_ data: AppData) async throws {
        let requestBody = ["data": data]
        let body = try JSONEncoder().encode(requestBody)
        
        guard let request = createRequest(endpoint: "/api/data", method: "PUT", body: body) else {
            throw APIError.invalidURL
        }
        
        try await performRequestWithoutResponse(request)
    }
    
    // MARK: - User Endpoints
    
    func getCurrentUser() async throws -> User {
        guard let request = createRequest(endpoint: "/api/users/me", method: "GET") else {
            throw APIError.invalidURL
        }
        
        return try await performRequest(request, responseType: User.self)
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case keychainError
    case decodingError
    case encodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .keychainError:
            return "Keychain error"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        }
    }
}