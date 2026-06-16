import SwiftUI

struct AuthView: View {
    @Binding var isAuthenticated: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isSignup = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accent)
                
                Text("NextRep")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Theme.text)
                
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .padding(.horizontal)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        if isSignup {
                            signup()
                        } else {
                            login()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignup ? "Sign Up" : "Login")
                        }
                    }
                    .buttonStyle(PrimaryButton())
                    .padding(.horizontal)
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }
                
                Button(action: {
                    isSignup.toggle()
                }) {
                    Text(isSignup ? "Already have an account? Login" : "Don't have an account? Sign Up")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Theme.bg)
        .navigationTitle(isSignup ? "Sign Up" : "Login")
    }
    
    private func login() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await APIClient.shared.login(email: email, password: password)
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
    
    private func signup() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await APIClient.shared.signup(name: email, email: email, password: password)
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