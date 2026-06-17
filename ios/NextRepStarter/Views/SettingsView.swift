import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var displayName = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var passwordMessage: String?
    @State private var showingResetConfirm = false
    @State private var showingLogoutConfirm = false

    private let themeColors = ["#355E3B", "#2563EB", "#7C3AED", "#DC2626", "#EA580C", "#0D9488", "#CA8A04"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                displayNameSection
                adminSection
                appearanceSection
                activeProgramSection
                accountSection
                resetSection
                legalSection
                footer
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .onAppear {
            displayName = store.user?.name ?? store.appData.name
        }
        .alert("Reset All Data?", isPresented: $showingResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                store.resetAllData()
            }
        } message: {
            Text("This clears your active program, workouts, custom data, body-weight, nutrition, and max trackers. This cannot be undone.")
        }
        .alert("Log Out?", isPresented: $showingLogoutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                store.logout()
            }
        } message: {
            Text("You can log back in with your account email and password.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("Manage account, display, program, and data options.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
    }

    private var displayNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Display Name")
                .font(.headline)
                .foregroundStyle(Theme.text)

            settingsField("Your name", text: $displayName)

            Button("Save Name") {
                store.setDisplayName(displayName.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .buttonStyle(GhostButtonStyle())
        }
        .cardStyle()
    }

    @ViewBuilder
    private var adminSection: some View {
        if store.user?.isAdmin == true {
            VStack(alignment: .leading, spacing: 8) {
                Label("Admin", systemImage: "shield.checkered")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Text("Admin user/catalog management is available in the web app. Native admin screens can be added later.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            }
            .cardStyle()
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Appearance")
                .font(.headline)
                .foregroundStyle(Theme.text)

            VStack(alignment: .leading, spacing: 8) {
                Text("Theme color")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textDim)

                HStack(spacing: 10) {
                    ForEach(themeColors, id: \.self) { color in
                        Button {
                            store.setThemeColor(color)
                        } label: {
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if store.appData.themeColor.lowercased() == color.lowercased() {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .overlay {
                                    Circle()
                                        .stroke(.white.opacity(store.appData.themeColor.lowercased() == color.lowercased() ? 0.9 : 0), lineWidth: 2)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Picker("Theme", selection: Binding(
                get: { store.appData.themeMode },
                set: { store.setThemeMode($0) }
            )) {
                Text("Dark").tag("dark")
                Text("Light").tag("light")
            }
            .pickerStyle(.segmented)

            Picker("Weight Unit", selection: Binding(
                get: { store.appData.unit },
                set: { store.setUnit($0) }
            )) {
                Text("lb").tag("lb")
                Text("kg").tag("kg")
            }
            .pickerStyle(.segmented)
        }
        .cardStyle()
    }

    private var activeProgramSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Program")
                .font(.headline)
                .foregroundStyle(Theme.text)

            if let program = activeProgram {
                Text(program.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text("\(program.daysPerWeek) days / week · \(program.durationWeeks) weeks")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)

                HStack(spacing: 10) {
                    NavigationLink {
                        ProgramDetailView(program: program)
                    } label: {
                        Text("View")
                    }
                    .buttonStyle(GhostButtonStyle())

                    Button("Clear") {
                        store.clearActiveProgram()
                    }
                    .buttonStyle(GhostButtonStyle())
                }
            } else {
                Text("No active program selected.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)

                NavigationLink {
                    ProgramsListView()
                } label: {
                    Text("Browse Programs")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .cardStyle()
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.headline)
                .foregroundStyle(Theme.text)

            if let user = store.user {
                Text(user.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }

            SecureField("Current password", text: $currentPassword)
                .settingsSecureFieldStyle()
            SecureField("New password", text: $newPassword)
                .settingsSecureFieldStyle()
            SecureField("Confirm new password", text: $confirmPassword)
                .settingsSecureFieldStyle()

            if let passwordMessage {
                Text(passwordMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(passwordMessage.contains("updated") ? Theme.accentLight : .red.opacity(0.9))
            }

            Button("Change Password") {
                Task { await changePassword() }
            }
            .buttonStyle(GhostButtonStyle())

            Button(role: .destructive) {
                showingLogoutConfirm = true
            } label: {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(GhostButtonStyle())
        }
        .cardStyle()
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Data Reset")
                .font(.headline)
                .foregroundStyle(.red.opacity(0.9))

            Text("Reset clears active program, workout history, custom data, body-weight, nutrition, max trackers, and timers.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)

            Button(role: .destructive) {
                showingResetConfirm = true
            } label: {
                Text("Reset All Data")
            }
            .buttonStyle(GhostButtonStyle())
        }
        .cardStyle()
    }

    private var legalSection: some View {
        VStack(spacing: 8) {
            legalLink("Privacy Policy", doc: .privacy)
            legalLink("Terms of Service", doc: .terms)
            legalLink("Health & Fitness Disclaimer", doc: .disclaimer)
        }
        .cardStyle()
    }

    private var footer: some View {
        Text("NextRep · Train with intent.")
            .font(.caption)
            .foregroundStyle(Theme.textFaint)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
    }

    private var activeProgram: Program? {
        guard let activeProgramId = store.appData.activeProgramId else {
            return nil
        }
        return store.allPrograms.first { $0.id == activeProgramId }
    }

    private func legalLink(_ title: String, doc: LegalDocument) -> some View {
        NavigationLink {
            LegalDocumentView(document: doc)
        } label: {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textFaint)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func settingsField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }

    private func changePassword() async {
        guard newPassword.count >= 8 else {
            passwordMessage = "New password must be at least 8 characters."
            return
        }
        guard newPassword == confirmPassword else {
            passwordMessage = "New passwords do not match."
            return
        }

        let ok = await store.changePassword(currentPassword: currentPassword, newPassword: newPassword)
        if ok {
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            passwordMessage = "Password updated."
        } else {
            passwordMessage = store.authError ?? "Could not change password."
        }
    }
}

private extension View {
    func settingsSecureFieldStyle() -> some View {
        self
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }
}

enum LegalDocument: String {
    case privacy
    case terms
    case disclaimer

    var title: String {
        switch self {
        case .privacy: return "Privacy Policy"
        case .terms: return "Terms of Service"
        case .disclaimer: return "Health & Fitness Disclaimer"
        }
    }

    var body: String {
        switch self {
        case .privacy:
            return """
            NextRep collects account information and the fitness data you choose to enter, including programs, exercises, workout logs, max tracker entries, nutrition, hydration, body-weight entries, timers, and settings.

            We use this information to provide, maintain, and improve the app, authenticate your account, sync your data, and respond to support requests. We do not sell your personal information.

            Data is stored by the existing NextRep backend. You can request account or data deletion by contacting support.
            """
        case .terms:
            return """
            By using NextRep, you agree to use the service lawfully and to keep your login credentials secure.

            You retain ownership of the programs, exercises, logs, and other content you create. NextRep stores and processes that content so the app can operate and sync across clients.

            The app may change over time as features are added or improved.
            """
        case .disclaimer:
            return """
            NextRep provides general fitness and nutrition tracking tools. It is not medical advice.

            Always consult a qualified professional before beginning a new exercise or nutrition program, especially if you have a medical condition, injury, or health concern.

            Stop exercising if you feel pain, dizziness, shortness of breath, or other concerning symptoms.
            """
        }
    }
}

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(document.title)
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundStyle(Theme.text)

                Text(document.body)
                    .font(.body)
                    .foregroundStyle(Theme.textDim)
                    .lineSpacing(5)
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }
}
