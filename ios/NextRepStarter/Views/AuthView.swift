import SwiftUI

struct AuthView: View {
    @Environment(AppStore.self) private var store
    @State private var isSignup = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

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

                    SecureField("Password", text: $password)
                        .textContentType(isSignup ? .newPassword : .password)
                        .fieldStyle()

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
