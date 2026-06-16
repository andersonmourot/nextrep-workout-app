import SwiftUI

struct AuthFlowView: View {
    @Binding var isAuthenticated: Bool
    @State private var isLoginMode = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        Theme.accent.opacity(0.12),
                        Theme.accent.opacity(0.05),
                        Color.clear
                    ]),
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .frame(height: 300)
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Logo/Title
                    Text("NEXTREP")
                        .font(Theme.display(32))
                        .foregroundColor(Theme.accent)
                        .tracking(2)
                    
                    Text(isLoginMode ? "WELCOME BACK" : "CREATE ACCOUNT")
                        .font(Theme.display(24))
                        .foregroundColor(Theme.text)
                        .tracking(1)
                    
                    // Help text
                    if isLoginMode {
                        Text("Don't have an account? Sign up first to create one")
                            .font(Theme.body(14))
                            .foregroundColor(Theme.textDim)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Form Card
                    VStack(spacing: 16) {
                        if !isLoginMode {
                            TextField("Name", text: $name)
                                .font(Theme.body(16))
                                .foregroundColor(Theme.text)
                                .padding()
                                .background(Theme.inputBg)
                                .cornerRadius(12)
                                .autocapitalization(.words)
                        }
                        
                        TextField("Email", text: $email)
                            .font(Theme.body(16))
                            .foregroundColor(Theme.text)
                            .padding()
                            .background(Theme.inputBg)
                            .cornerRadius(12)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .font(Theme.body(16))
                            .foregroundColor(Theme.text)
                            .padding()
                            .background(Theme.inputBg)
                            .cornerRadius(12)
                    }
                    .padding(20)
                    .background(Theme.surface)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 8)
                    .padding(.horizontal)
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(Theme.body(12))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    // Action button
                    Button(action: authenticate) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.text))
                        } else {
                            Text(isLoginMode ? "LOGIN" : "SIGN UP")
                                .font(Theme.body(14))
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(PrimaryButton())
                    .disabled(isLoading)
                    
                    // Toggle mode
                    Button(action: { isLoginMode.toggle() }) {
                        Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Login")
                            .font(Theme.body(14))
                            .foregroundColor(Theme.accentLt)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func authenticate() {
        errorMessage = ""
        isLoading = true
        
        Task {
            do {
                if isLoginMode {
                    _ = try await APIClient.shared.login(email: email, password: password)
                } else {
                    _ = try await APIClient.shared.signup(name: name, email: email, password: password)
                }
                
                await MainActor.run {
                    isAuthenticated = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AuthFlowView(isAuthenticated: .constant(false))
}