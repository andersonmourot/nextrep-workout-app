import SwiftUI

struct ResetPasswordView: View {
    @StateObject private var store = AppStore()
    let token: String
    
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String = ""
    @State private var isAuthenticated: Bool = false
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            if isAuthenticated {
                EmptyView()
            } else if showSuccess {
                successView
            } else {
                formView
            }
        }
        .task {
            isAuthenticated = store.isAuthenticated
        }
    }
    
    private var formView: some View {
        VStack(spacing: 40) {
            // Brand block
            brandBlock(subtitle: "Choose a new password.")
            
            // Form card
            VStack(spacing: 20) {
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Password")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.textDim)
                        
                        Spacer()
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Text(showPassword ? "Hide" : "Show")
                                .font(Theme.body(10))
                                .foregroundColor(Theme.accent)
                        }
                    }
                    
                    HStack {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .font(Theme.body(14))
                        .foregroundColor(Theme.text)
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(Theme.textDim)
                        }
                    }
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Theme.inputBg)
                    .cornerRadius(12)
                    
                    // Password hints
                    passwordHints
                }
                
                // Confirm password field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Confirm Password")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.textDim)
                        
                        Spacer()
                        
                        Button(action: {
                            showConfirmPassword.toggle()
                        }) {
                            Text(showConfirmPassword ? "Hide" : "Show")
                                .font(Theme.body(10))
                                .foregroundColor(Theme.accent)
                        }
                    }
                    
                    HStack {
                        Group {
                            if showConfirmPassword {
                                TextField("Confirm Password", text: $confirmPassword)
                            } else {
                                SecureField("Confirm Password", text: $confirmPassword)
                            }
                        }
                        .font(Theme.body(14))
                        .foregroundColor(Theme.text)
                        
                        Button(action: {
                            showConfirmPassword.toggle()
                        }) {
                            Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                .foregroundColor(Theme.textDim)
                        }
                    }
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Theme.inputBg)
                    .cornerRadius(12)
                }
                
                // Error banner
                if !errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(Theme.body(12))
                            .foregroundColor(.red)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Submit button
                Button(action: {
                    Task {
                        await handleSubmit()
                    }
                }) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            
                            Text("Please wait…")
                                .font(Theme.body(14))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Theme.accent.opacity(0.5))
                        .cornerRadius(12)
                    } else {
                        Text("Reset Password")
                            .font(Theme.body(14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Theme.accent)
                            .cornerRadius(12)
                    }
                }
                .disabled(isLoading)
            }
            .padding(24)
            .background(Theme.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .padding()
    }
    
    private var successView: some View {
        VStack(spacing: 40) {
            // Brand block
            brandBlock(subtitle: "Choose a new password.")
            
            // Success card
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.accent)
                
                Text("Your password has been reset. You can now log in with your new password.")
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
                    .multilineTextAlignment(.center)
                
                Button(action: {}) {
                    Text("Back to log in")
                        .font(Theme.body(14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Theme.accent)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(Theme.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .padding()
    }
    
    private var passwordHints: some View {
        VStack(alignment: .leading, spacing: 4) {
            passwordHint(text: "At least 6 characters", valid: password.count >= 6)
            passwordHint(text: "Contains uppercase letter", valid: password.range(of: "A-Z") != nil)
            passwordHint(text: "Contains lowercase letter", valid: password.range(of: "a-z") != nil)
            passwordHint(text: "Contains number", valid: password.range(of: "0-9") != nil)
        }
    }
    
    private func passwordHint(text: String, valid: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: valid ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(valid ? Theme.accent : Theme.textDim)
            
            Text(text)
                .font(Theme.body(10))
                .foregroundColor(valid ? Theme.accent : Theme.textDim)
        }
    }
    
    private func brandBlock(subtitle: String) -> some View {
        VStack(spacing: 16) {
            // Dumbbell tile
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.accent)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title)
                        .foregroundColor(.white)
                )
            
            // Wordmark
            HStack(spacing: 2) {
                Text("Next")
                    .font(Theme.display(32))
                    .foregroundColor(Theme.text)
                
                Text("Rep")
                    .font(Theme.display(32))
                    .foregroundColor(Theme.accent)
            }
            .tracking(4)
            
            // Subtitle
            Text(subtitle)
                .font(Theme.body(14))
                .foregroundColor(Theme.textDim)
                .multilineTextAlignment(.center)
        }
    }
    
    private func handleSubmit() async {
        isLoading = true
        errorMessage = ""
        
        // Validation
        if password.isEmpty {
            errorMessage = "Please enter your password"
            isLoading = false
            return
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        if confirmPassword.isEmpty {
            errorMessage = "Please confirm your password"
            isLoading = false
            return
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            isLoading = false
            return
        }
        
        do {
            try await store.resetPassword(token: token, password: password)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}