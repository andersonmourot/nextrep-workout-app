import SwiftUI

struct AuthView: View {
    @StateObject private var store = AppStore()
    @State private var mode: AuthMode = .login
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var isAuthenticated: Bool = false
    @State private var showingForgotPassword: Bool = false
    
    enum AuthMode {
        case login
        case signup
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
            
                if isAuthenticated {
                    // Will be handled by navigation
                    EmptyView()
                } else {
                    VStack(spacing: 40) {
                        // Brand block
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
                            Text(mode == .signup ? "Create your account to start training." : "Welcome back. Log in to continue.")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.textDim)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Form card
                        VStack(spacing: 20) {
                            // Name field (signup only)
                            if mode == .signup {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Name")
                                        .font(Theme.body(12))
                                        .foregroundColor(Theme.textDim)
                                    
                                    TextField("Your name", text: $name)
                                        .font(Theme.body(14))
                                        .foregroundColor(Theme.text)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(12)
                                        .background(Theme.inputBg)
                                        .cornerRadius(12)
                                }
                            }
                            
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
                                
                                // Forgot password link (login only)
                                if mode == .login {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            showingForgotPassword = true
                                        }) {
                                            Text("Forgot password?")
                                                .font(Theme.body(12))
                                                .foregroundColor(Theme.accent)
                                        }
                                    }
                                }
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
                                    Text(mode == .signup ? "Create account" : "Log in")
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
                        Button(action: {
                            mode = mode == .login ? .signup : .login
                            errorMessage = ""
                            name = ""
                            email = ""
                            password = ""
                        }) {
                            Text(mode == .login ? "New here? Create an account" : "Already have an account? Log in")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.accent)
                        }
                    }
                    .padding()
                }
            }
            .navigationDestination(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        }
        .task {
            isAuthenticated = store.isAuthenticated
            if isAuthenticated {
                // Navigation will be handled by the app
            }
        }
    }
    
    private var passwordHints: some View {
        VStack(alignment: .leading, spacing: 4) {
            passwordHint(text: "At least 8 characters", valid: password.count >= 8)
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
    
    private func handleSubmit() async {
        isLoading = true
        errorMessage = ""
        
        // Validation
        if email.isEmpty {
            errorMessage = "Please enter your email"
            isLoading = false
            return
        }
        
        if password.isEmpty {
            errorMessage = "Please enter your password"
            isLoading = false
            return
        }
        
        if password.count < 8 {
            errorMessage = "Password must be at least 8 characters"
            isLoading = false
            return
        }
        
        if mode == .signup && name.isEmpty {
            errorMessage = "Please enter your name"
            isLoading = false
            return
        }
        
        do {
            if mode == .signup {
                try await store.signUp(name: name, email: email, password: password)
            } else {
                try await store.login(email: email, password: password)
            }
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}