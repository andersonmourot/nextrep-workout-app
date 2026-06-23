import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AppStore.self) private var store
    @State private var email = ""
    @State private var sent = false
    @State private var isBusy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                authHeader(title: "Reset Password", subtitle: "Enter your account email and we'll send a reset link.")

                if sent {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.badge")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Theme.accentLight)

                        Text("If an account exists for \(email.trimmingCharacters(in: .whitespacesAndNewlines)), we've sent a reset link. Check your inbox and spam folder.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textDim)
                            .multilineTextAlignment(.center)

                        NavigationLink {
                            ResetPasswordView()
                        } label: {
                            Text("I Have a Reset Token")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .cardStyle()
                } else {
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .authFieldStyle()

                        if let error = store.authError {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            Text(isBusy ? "Sending..." : "Send Reset Link")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isBusy)
                        .opacity(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isBusy ? 0.5 : 1)
                    }
                    .cardStyle()
                }

                NavigationLink {
                    ResetPasswordView()
                } label: {
                    Text("Already have a token?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accentLight)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private func submit() async {
        isBusy = true
        let ok = await store.forgotPassword(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
        isBusy = false
        if ok {
            sent = true
        }
    }
}

struct ResetPasswordView: View {
    @Environment(AppStore.self) private var store
    @State private var token = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var done = false
    @State private var localError: String?
    @State private var isBusy = false
    @State private var passwordVisible = false
    @State private var confirmPasswordVisible = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                authHeader(title: "Choose New Password", subtitle: "Paste the token from your email link and set a new password.")

                if done {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(Theme.accentLight)

                        Text("Your password has been reset. You can now log in with your new password.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textDim)
                            .multilineTextAlignment(.center)
                    }
                    .cardStyle()
                } else {
                    VStack(spacing: 16) {
                        TextField("Reset token", text: $token, axis: .vertical)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .authFieldStyle()

                        PasswordVisibilityField(
                            placeholder: "New password",
                            text: $password,
                            isVisible: $passwordVisible,
                            textContentType: .newPassword
                        )

                        PasswordHintsView(password: password, showWhenEmpty: true)

                        PasswordVisibilityField(
                            placeholder: "Confirm new password",
                            text: $confirmPassword,
                            isVisible: $confirmPasswordVisible,
                            textContentType: .newPassword
                        )

                        if !confirmPassword.isEmpty {
                            Label(password == confirmPassword ? "Passwords match" : "Passwords do not match", systemImage: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle")
                                .font(.caption)
                                .foregroundStyle(password == confirmPassword ? Theme.accentLight : .red.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let error = localError ?? store.authError {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            Text(isBusy ? "Resetting..." : "Reset Password")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!canSubmit || isBusy)
                        .opacity(!canSubmit || isBusy ? 0.5 : 1)
                    }
                    .cardStyle()
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var canSubmit: Bool {
        !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            password.count >= 6 &&
            password == confirmPassword
    }

    private func submit() async {
        localError = nil
        guard password.count >= 6 else {
            localError = "Password must be at least 6 characters."
            return
        }
        guard password == confirmPassword else {
            localError = "Passwords do not match."
            return
        }

        isBusy = true
        let ok = await store.resetPassword(
            token: token.trimmingCharacters(in: .whitespacesAndNewlines),
            newPassword: password
        )
        isBusy = false
        if ok {
            done = true
            token = ""
            password = ""
            confirmPassword = ""
        }
    }
}

private func authHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("NextRep")
            .font(.system(size: 42, weight: .bold, design: .default))
            .textCase(.uppercase)
            .foregroundStyle(Theme.text)

        Text(title)
            .font(.title3.weight(.bold))
            .foregroundStyle(Theme.accentLight)

        Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(Theme.textDim)
    }
}

private extension View {
    func authFieldStyle() -> some View {
        padding(.horizontal, 14)
            .padding(.vertical, 12)
            .foregroundStyle(Theme.text)
            .tint(Theme.accentLight)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }
}
