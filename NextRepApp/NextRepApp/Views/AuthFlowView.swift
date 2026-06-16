import SwiftUI

struct AuthFlowView: View {
    @Binding var isAuthenticated: Bool
    @State private var isLoginMode = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo/Title
                VStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .imageScale(.large)
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    Text("NextRep")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Workout Tracker")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 40)
                
                // Form
                VStack(spacing: 16) {
                    if !isLoginMode {
                        TextField("Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Action button
                Button(action: authenticate) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isLoginMode ? "Login" : "Sign Up")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
                .disabled(isLoading)
                .padding(.horizontal)
                
                // Toggle between login and signup
                Button(action: { isLoginMode.toggle() }) {
                    Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Login")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(isLoginMode ? "Login" : "Sign Up")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func authenticate() {
        isLoading = true
        errorMessage = nil
        
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