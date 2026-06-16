import Foundation
import os.log

class APIClient {
    static let shared = APIClient()
    
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        // Use production URL for now since local backend is not running
        self.baseURL = "https://smellis-api.fly.dev"
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        // Configure decoder with snake_case conversion
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Configure encoder with snake_case conversion
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    private func getAuthToken() -> String? {
        return KeychainStore.shared.getToken()
    }
    
    private func createRequest(endpoint: String, method: String = "GET", body: Data? = nil) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = getAuthToken() {
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    // MARK: - Auth
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = ["email": email, "password": password]
        let bodyData = try encoder.encode(body)
        
        guard let request = createRequest(endpoint: "/auth/login", method: "POST", body: bodyData) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        // Check if data is empty
        if data.isEmpty {
            NSLog("❌ LOGIN: Empty response data")
            throw APIError.decodingError
        }
        
        do {
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            
            // Save token to keychain
            if KeychainStore.shared.saveToken(authResponse.token) {
                NSLog("✅ LOGIN: Successfully decoded AuthResponse")
                return authResponse
            } else {
                throw APIError.keychainError
            }
        } catch {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode as UTF-8"
            NSLog("❌ LOGIN DECODING ERROR:")
            NSLog("   Error: \(error)")
            NSLog("   Raw response: \(responseString)")
            NSLog("   Data length: \(data.count) bytes")
            throw APIError.decodingError
        }
    }
    
    func signup(name: String, email: String, password: String) async throws -> AuthResponse {
        let body = ["name": name, "email": email, "password": password]
        let bodyData = try encoder.encode(body)
        
        guard let request = createRequest(endpoint: "/auth/signup", method: "POST", body: bodyData) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let authResponse = try decoder.decode(AuthResponse.self, from: data)
        
        // Save token to keychain
        if KeychainStore.shared.saveToken(authResponse.token) {
            return authResponse
        } else {
            throw APIError.keychainError
        }
    }
    
    func forgotPassword(email: String) async throws {
        let body = ["email": email]
        let bodyData = try encoder.encode(body)
        
        guard let request = createRequest(endpoint: "/auth/forgot-password", method: "POST", body: bodyData) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func resetPassword(token: String, password: String) async throws {
        let body = ["token": token, "password": password]
        let bodyData = try encoder.encode(body)
        
        guard let request = createRequest(endpoint: "/auth/reset-password", method: "POST", body: bodyData) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Admin
    
    func adminUsers(token: String) async throws -> [AdminUser] {
        guard let request = createRequest(endpoint: "/admin/users", method: "GET") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let users = try decoder.decode([AdminUser].self, from: data)
        return users
    }
    
    func adminResetPassword(token: String, userId: String, password: String) async throws {
        let body = ["userId": userId, "password": password]
        let bodyData = try encoder.encode(body)
        
        guard let request = createRequest(endpoint: "/admin/reset-password", method: "POST", body: bodyData) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func fetchCatalog() async throws -> Catalog {
        guard let request = createRequest(endpoint: "/api/catalog", method: "GET") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let catalog = try decoder.decode(Catalog.self, from: data)
        return catalog
    }
    
    func adminPutCatalog(token: String, catalog: Catalog) async throws {
        let bodyData = try encoder.encode(catalog)
        
        guard let request = createRequest(endpoint: "/admin/catalog", method: "PUT", body: bodyData) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func logout() {
        _ = KeychainStore.shared.deleteToken()
    }
    
    // MARK: - App Data
    
    func getAppData() async throws -> AppData {
        guard let request = createRequest(endpoint: "/api/data", method: "GET") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let appData = try decoder.decode(AppData.self, from: data)
            NSLog("✅ GET /api/data decoded successfully")
            return appData
        } catch {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode as UTF-8"
            NSLog("❌ GET /api/data DECODING ERROR:")
            NSLog("   Error: \(error)")
            NSLog("   Raw response: \(responseString)")
            NSLog("   Data length: \(data.count) bytes")
            throw APIError.decodingError
        }
    }
    
    func saveAppData(_ data: AppData) async throws {
        let wrapper = ["data": data]
        let bodyData = try encoder.encode(wrapper)
        
        guard let request = createRequest(endpoint: "/api/data", method: "PUT", body: bodyData) else {
            throw APIError.invalidURL
        }
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: responseData, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Social / Discovery
    
    func searchUsers(query: String) async throws -> [PublicUser] {
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        components.path = "/api/users/search"
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getAuthToken() {
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try decoder.decode([PublicUser].self, from: data)
    }
    
    func followUser(_ userId: String) async throws {
        guard let request = createRequest(endpoint: "/api/users/\(userId)/follow", method: "POST") else {
            throw APIError.invalidURL
        }
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: responseData, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func unfollowUser(_ userId: String) async throws {
        guard let request = createRequest(endpoint: "/api/users/\(userId)/follow", method: "DELETE") else {
            throw APIError.invalidURL
        }
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: responseData, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Catalog
    
    func getCatalog() async throws -> CatalogResponse {
        guard let request = createRequest(endpoint: "/api/catalog", method: "GET") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to show error message from response if available
            if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try decoder.decode(CatalogResponse.self, from: data)
    }
    
    func upsertProgram(_ program: Program) async throws {
        let bodyData = try encoder.encode(program)
        
        guard let request = createRequest(endpoint: "/api/programs", method: "POST", body: bodyData) else {
            throw APIError.invalidURL
        }
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            // Try to show error message from response if available
            if let errorString = String(data: responseData, encoding: .utf8), !errorString.isEmpty {
                throw APIError.serverError(httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - People/Search
    
    func searchUsers(query: String) async throws -> [DiscoverUser] {
        guard let token = getAuthToken() else {
            throw APIError.keychainError
        }
        
        guard var components = URLComponents(string: "\(baseURL)/api/users/search") else {
            throw APIError.invalidURL
        }
        
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try decoder.decode([DiscoverUser].self, from: data)
    }
    
    func followUser(userId: String) async throws {
        guard let token = getAuthToken() else {
            throw APIError.keychainError
        }
        
        guard let request = createRequest(endpoint: "/api/users/\(userId)/follow", method: "POST") else {
            throw APIError.invalidURL
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func unfollowUser(userId: String) async throws {
        guard let token = getAuthToken() else {
            throw APIError.keychainError
        }
        
        guard let request = createRequest(endpoint: "/api/users/\(userId)/unfollow", method: "POST") else {
            throw APIError.invalidURL
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func getUserPrograms(userId: String) async throws -> [Program] {
        guard let token = getAuthToken() else {
            throw APIError.keychainError
        }
        
        guard let request = createRequest(endpoint: "/api/users/\(userId)/programs") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try decoder.decode([Program].self, from: data)
    }
    
    func getUserExercises(userId: String) async throws -> [Exercise] {
        guard let token = getAuthToken() else {
            throw APIError.keychainError
        }
        
        guard let request = createRequest(endpoint: "/api/users/\(userId)/exercises") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try decoder.decode([Exercise].self, from: data)
    }
    
    func addProgram(programId: String) async throws {
        guard let token = getAuthToken() else {
            throw APIError.keychainError
        }
        
        guard let request = createRequest(endpoint: "/api/programs/\(programId)/add", method: "POST") else {
            throw APIError.invalidURL
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func favoriteUser(userId: String) async throws {
        guard let token = getAuthToken() else {
            throw APIError.keychainError
        }
        
        guard let request = createRequest(endpoint: "/api/users/\(userId)/favorite", method: "POST") else {
            throw APIError.invalidURL
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func unfavoriteUser(userId: String) async throws {
        guard let token = getAuthToken() else {
            throw APIError.keychainError
        }
        
        guard let request = createRequest(endpoint: "/api/users/\(userId)/unfavorite", method: "POST") else {
            throw APIError.invalidURL
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Settings
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let token = getAuthToken() else {
            throw APIError.keychainError
        }
        
        let body: [String: Any] = [
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            throw APIError.encodingError
        }
        
        guard let request = createRequest(endpoint: "/api/change-password", method: "POST", body: bodyData) else {
            throw APIError.invalidURL
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func resetAllData() async throws {
        guard let token = getAuthToken() else {
            throw APIError.keychainError
        }
        
        guard let request = createRequest(endpoint: "/api/reset-data", method: "POST") else {
            throw APIError.invalidURL
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Nutrition
    
    func setNutritionEntry(_ entry: NutritionEntry) async throws {
        guard let token = getAuthToken() else {
            throw APIError.keychainError
        }
        
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(entry)
        
        guard let request = createRequest(endpoint: "/api/nutrition/entry", method: "POST", body: bodyData) else {
            throw APIError.invalidURL
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func setNutritionGoals(_ goals: NutritionGoals) async throws {
        guard let token = getAuthToken() else {
            throw APIError.keychainError
        }
        
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(goals)
        
        guard let request = createRequest(endpoint: "/api/nutrition/goals", method: "POST", body: bodyData) else {
            throw APIError.invalidURL
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int, message: String? = nil)
    case keychainError
    case decodingError
    case encodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code, let message):
            if let message = message {
                return "Server error (\(code)): \(message)"
            }
            return "Server error with code: \(code)"
        case .keychainError:
            return "Failed to access keychain"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        }
    }
}