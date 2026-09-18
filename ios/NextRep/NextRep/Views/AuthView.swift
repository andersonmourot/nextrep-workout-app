import SwiftUI

struct AuthView: View {
    @Environment(AppStore.self) private var store
    @State private var isSignup = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordVisible = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NextRep")
                        .font(.system(size: 42, weight: .bold, design: .default))
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.text)

                    Text("Sign in to sync programs, workouts, timers, and progress with the existing backend.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                }

                VStack(spacing: 16) {
                    Picker("Mode", selection: $isSignup) {
                        Text("Log in").tag(false)
                        Text("Sign up").tag(true)
                    }
                    .pickerStyle(.segmented)

                    if isSignup {
                        TextField("Name", text: $name)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .fieldStyle()
                    }

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .fieldStyle()

                    PasswordVisibilityField(
                        placeholder: isSignup ? "At least 6 characters" : "Password",
                        text: $password,
                        isVisible: $passwordVisible,
                        textContentType: isSignup ? .newPassword : .password
                    )

                    PasswordHintsView(password: password, showWhenEmpty: isSignup)

                    if !isSignup {
                        NavigationLink {
                            ForgotPasswordView()
                        } label: {
                            Text("Forgot password?")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.accentLight)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }

                    if let error = store.authError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task {
                            if isSignup {
                                await store.signup(name: name, email: email, password: password)
                            } else {
                                await store.login(email: email, password: password)
                            }
                        }
                    } label: {
                        Text(isSignup ? "Create Account" : "Log In")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)
                }
                .cardStyle()

                NavigationLink {
                    ResetPasswordView()
                } label: {
                    Text("Have a reset token?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accentLight)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
    }

    private var canSubmit: Bool {
        let hasAuth = !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasName = !isSignup || !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasAuth && hasName && !store.isLoading
    }
}

private extension View {
    func fieldStyle() -> some View {
        padding(.horizontal, 14)
            .padding(.vertical, 12)
            .foregroundStyle(Theme.text)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }
}

struct PasswordVisibilityField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    var textContentType: UITextContentType? = .password

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .textContentType(textContentType)
                } else {
                    SecureField(placeholder, text: $text)
                        .textContentType(textContentType)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(Theme.text)
            .tint(Theme.accentLight)

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textDim)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isVisible ? "Hide password" : "Show password")
        }
        .fieldStyle()
    }
}

struct PasswordHintsView: View {
    let password: String
    var showWhenEmpty = false

    var body: some View {
        if showWhenEmpty || !password.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                passwordHint("At least 6 characters", isMet: password.count >= 6)
                passwordHint("Contains a letter", isMet: password.rangeOfCharacter(from: .letters) != nil)
                passwordHint("Contains a number", isMet: password.rangeOfCharacter(from: .decimalDigits) != nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func passwordHint(_ text: String, isMet: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption2.weight(.bold))
                .foregroundStyle(isMet ? Theme.accentLight : Theme.textFaint)
            Text(text)
                .font(.caption)
                .foregroundStyle(isMet ? Theme.textDim : Theme.textFaint)
        }
    }
}
