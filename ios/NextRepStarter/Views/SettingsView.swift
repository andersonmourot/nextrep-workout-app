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
    @State private var showingPasswordFields = false

    private let themeColors = ["#355e3b", "#e9b949", "#7f1d1d", "#3b82f6", "#22c55e", "#a855f7", "#f97316", "#14b8a6", "#ec4899"]

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
            VStack(alignment: .leading, spacing: 10) {
                Label("Admin", systemImage: "shield.checkered")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                NavigationLink {
                    AdminUsersView()
                } label: {
                    settingsRow(title: "Users", subtitle: "View accounts and reset passwords", systemImage: "person.2")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AdminCatalogView()
                } label: {
                    settingsRow(title: "Catalog", subtitle: "Review and publish built-in catalog", systemImage: "list.bullet.rectangle")
                }
                .buttonStyle(.plain)
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

            if showingPasswordFields {
                SecureField("Current password", text: $currentPassword)
                    .settingsSecureFieldStyle()
                SecureField("New password", text: $newPassword)
                    .settingsSecureFieldStyle()
                SecureField("Confirm new password", text: $confirmPassword)
                    .settingsSecureFieldStyle()
            }

            if let passwordMessage {
                Text(passwordMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(passwordMessage.contains("updated") ? Theme.accentLight : .red.opacity(0.9))
            }

            Button(showingPasswordFields ? "Update Password" : "Change Password") {
                if showingPasswordFields {
                    Task { await changePassword() }
                } else {
                    showingPasswordFields = true
                    passwordMessage = nil
                }
            }
            .buttonStyle(GhostButtonStyle())

            if showingPasswordFields {
                Button("Cancel Password Change") {
                    resetPasswordFields()
                    showingPasswordFields = false
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textDim)
            }

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

    private func settingsRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(Theme.accentLight)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textFaint)
        }
        .padding(.vertical, 6)
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
            resetPasswordFields()
            showingPasswordFields = false
            passwordMessage = "Password updated."
        } else {
            passwordMessage = store.authError ?? "Could not change password."
        }
    }

    private func resetPasswordFields() {
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
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

struct AdminUsersView: View {
    @Environment(AppStore.self) private var store
    @State private var users: [AdminUser] = []
    @State private var isLoading = false
    @State private var resetPasswords: [String: String] = [:]
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let message {
                    Text(message)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(message.contains("updated") ? Theme.accentLight : .red.opacity(0.9))
                        .cardStyle()
                }

                if isLoading {
                    ProgressView()
                        .tint(Theme.accentLight)
                        .frame(maxWidth: .infinity)
                        .cardStyle()
                } else if users.isEmpty {
                    Text("No users found.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                        .cardStyle()
                } else {
                    ForEach(users) { user in
                        userCard(user)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Admin Users")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await loadUsers() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .tint(Theme.accentLight)
            }
        }
        .screenBackground()
        .task {
            await loadUsers()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Users")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("\(users.count) registered accounts")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
    }

    private func userCard(_ user: AdminUser) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(user.name)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
                Text("Created \(shortDate(user.createdAt)) · Active \(shortDate(user.lastActive))")
                    .font(.caption2)
                    .foregroundStyle(Theme.textFaint)
            }

            HStack(spacing: 10) {
                SecureField("New password", text: Binding(
                    get: { resetPasswords[user.id] ?? "" },
                    set: { resetPasswords[user.id] = $0 }
                ))
                .settingsSecureFieldStyle()

                Button("Reset") {
                    Task { await resetPassword(for: user) }
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .cardStyle()
    }

    private func loadUsers() async {
        isLoading = true
        users = await store.adminUsers()
        isLoading = false
    }

    private func resetPassword(for user: AdminUser) async {
        let password = resetPasswords[user.id] ?? ""
        guard password.count >= 8 else {
            message = "Password must be at least 8 characters."
            return
        }

        if await store.adminResetPassword(userId: user.id, newPassword: password) {
            resetPasswords[user.id] = ""
            message = "Password updated for \(user.name)."
        } else {
            message = store.authError ?? "Could not reset password."
        }
    }
}

struct AdminCatalogView: View {
    @Environment(AppStore.self) private var store
    @State private var message: String?
    @State private var isPublishing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                catalogStats

                if let message {
                    Text(message)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(message.contains("published") ? Theme.accentLight : .red.opacity(0.9))
                        .cardStyle()
                }

                Button(isPublishing ? "Publishing..." : "Publish Current Catalog") {
                    Task { await publishCatalog() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isPublishing)

                Text("This replaces the built-in backend catalog with the currently loaded catalog. Detailed native catalog item editing can be added as a follow-up; use the existing Program and Exercise editors for user-created content.")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
                    .cardStyle()
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Admin Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Catalog")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("Admin built-in program and exercise catalog.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
    }

    private var catalogStats: some View {
        HStack(spacing: 10) {
            AdminCatalogStatTile(icon: "square.grid.2x2", value: "\(store.catalog.programs.count)", label: "Programs")
            AdminCatalogStatTile(icon: "figure.strengthtraining.traditional", value: "\(store.catalog.exercises.count)", label: "Exercises")
        }
    }

    private func publishCatalog() async {
        isPublishing = true
        let ok = await store.adminPublishCatalog()
        isPublishing = false
        message = ok ? "Catalog published." : (store.authError ?? "Could not publish catalog.")
    }
}

private struct AdminCatalogStatTile: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Theme.accentLight)

            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(Theme.text)

            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.0)
                .foregroundStyle(Theme.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.05), lineWidth: 1)
        }
    }
}

private func shortDate(_ value: String) -> String {
    if let date = ISO8601DateFormatter().date(from: value) {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    return value
}
