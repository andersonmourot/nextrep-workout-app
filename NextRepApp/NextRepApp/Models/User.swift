import Foundation

struct User: Codable {
    let id: String
    let name: String
    let email: String
    let isAdmin: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, email
        case isAdmin = "is_admin"
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}