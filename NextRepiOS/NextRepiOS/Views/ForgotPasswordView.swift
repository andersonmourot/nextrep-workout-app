import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var store = AppStore()
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var showConfirmation: Bool = false
    @State private var errorMessage: String = ""
    @State private var isAuthenticated: Bool = false
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            if isAuthenticated {
                EmptyView()
            } else if showConfirmation {
                confirmationView
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
            brandBlock(subtitle: "Reset your password.")
            
            // Form card
            VStack(spacing: 20) {
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(Theme.body(12))
                        .foregroundColor(Theme.textDim)
                    
                    TextField("your@email.com", text: $email)
                        .font(Theme.body(14))
                        .foregroundColor(Theme.text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Theme.inputBg)
                        .cornerRadius(12)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
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
                        Text("Send reset link")
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
            
            // Footer link
            Button(action: {}) {
                Text("Remembered it? Log in")
                    .font(Theme.body(14))
                    .foregroundColor(Theme.accent)
            }
        }
        .padding()
    }
    
    private var confirmationView: some View {
        VStack(spacing: 40) {
            // Brand block
            brandBlock(subtitle: "Reset your password.")
            
            // Confirmation card
            VStack(spacing: 20) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.accent)
                
                Text("If an account exists for \(email), we've sent a link to reset your password. Check your inbox (and spam folder). The link expires in 1 hour.")
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
        if email.isEmpty {
            errorMessage = "Please enter your email"
            isLoading = false
            return
        }
        
        do {
            try await store.forgotPassword(email: email)
            showConfirmation = true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}