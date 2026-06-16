import SwiftUI

struct AdminUsersView: View {
    @StateObject private var store = AppStore()
    @State private var users: [AdminUser] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""
    
    // Reset password state per user
    @State private var resettingPasswordForUserId: String? = nil
    @State private var newPassword: String = ""
    @State private var newPasswordErrorMessage: String = ""
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Back button
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                            Text("Back")
                                .font(Theme.body(14))
                        }
                        .foregroundColor(Theme.textDim)
                    }
                    
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🛡 Admin")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.accent)
                            .tracking(2)
                        
                        Text("Users")
                            .font(Theme.display(32))
                            .foregroundColor(Theme.text)
                            .tracking(1)
                        
                        if !isLoading {
                            Text("\(users.count) registered users")
                                .font(Theme.body(12))
                                .foregroundColor(Theme.textDim)
                        }
                    }
                    
                    // Loading line
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(20)
                    }
                    
                    // Error card
                    if !errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            
                            Text(errorMessage)
                                .font(Theme.body(12))
                                .foregroundColor(.red)
                        }
                        .padding(16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Success message
                    if !successMessage.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.accent)
                            
                            Text(successMessage)
                                .font(Theme.body(12))
                                .foregroundColor(Theme.accent)
                        }
                        .padding(16)
                        .background(Theme.accent.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // User cards
                    if !isLoading {
                        VStack(spacing: 12) {
                            ForEach(users) { user in
                                UserCard(
                                    user: user,
                                    isResetting: resettingPasswordForUserId == user.id,
                                    newPassword: $newPassword,
                                    newPasswordErrorMessage: newPasswordErrorMessage,
                                    onResetTap: {
                                        resettingPasswordForUserId = user.id
                                        newPassword = ""
                                        newPasswordErrorMessage = ""
                                    },
                                    onCancel: {
                                        resettingPasswordForUserId = nil
                                        newPassword = ""
                                        newPasswordErrorMessage = ""
                                    },
                                    onSetPassword: {
                                        Task {
                                            await handleResetPassword(user: user)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .task {
            await loadUsers()
        }
    }
    
    private func loadUsers() async {
        isLoading = true
        errorMessage = ""
        
        guard store.currentUser?.isAdmin == true else {
            errorMessage = "Access denied. Admin privileges required."
            isLoading = false
            return
        }
        
        do {
            users = try await store.adminUsers()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func handleResetPassword(user: AdminUser) async {
        newPasswordErrorMessage = ""
        
        guard newPassword.count >= 6 else {
            newPasswordErrorMessage = "Password must be at least 6 characters"
            return
        }
        
        do {
            try await store.adminResetPassword(userId: user.id, password: newPassword)
            successMessage = "Password updated for \(user.name)."
            resettingPasswordForUserId = nil
            newPassword = ""
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                successMessage = ""
            }
        } catch {
            newPasswordErrorMessage = error.localizedDescription
        }
    }
}

struct UserCard: View {
    let user: AdminUser
    let isResetting: Bool
    @Binding var newPassword: String
    let newPasswordErrorMessage: String
    let onResetTap: () -> Void
    let onCancel: () -> Void
    let onSetPassword: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(Theme.body(16))
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.text)
                
                Text("Joined \(formatDate(user.joinedAt))")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
                
                Text(user.email)
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
                
                if let lastActive = user.lastActive {
                    Text("Last active: \(formatDate(lastActive))")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                } else {
                    Text("Last active: Never")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                }
            }
            
            // Reset password section
            if isResetting {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reset password")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                    
                    SecureField("New password", text: $newPassword)
                        .font(Theme.body(12))
                        .foregroundColor(Theme.text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(Theme.inputBg)
                        .cornerRadius(8)
                    
                    if !newPasswordErrorMessage.isEmpty {
                        Text(newPasswordErrorMessage)
                            .font(Theme.body(10))
                            .foregroundColor(.red)
                    }
                    
                    HStack(spacing: 8) {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(Theme.body(10))
                                .foregroundColor(Theme.textDim)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(Theme.surface2)
                                .cornerRadius(8)
                        }
                        
                        Button(action: onSetPassword) {
                            Text("Set password")
                                .font(Theme.body(10))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(Theme.accent)
                                .cornerRadius(8)
                        }
                        .disabled(newPassword.count < 6)
                    }
                }
                .padding(12)
                .background(Theme.surface2)
                .cornerRadius(8)
            } else {
                Button(action: onResetTap) {
                    Text("Reset password")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        
        return dateString
    }
}