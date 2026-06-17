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
                Text("System").tag("system")
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
            Last updated: June 2026

            This Privacy Policy explains how NextRep ("we", "us") collects, uses, and protects your information when you use the NextRep application and website (the "Service"). By using the Service you agree to this policy.

            1. Information we collect

            We collect only what's needed to run the Service:

            - Account information: your name, email address, and a securely hashed password.
            - App data you create: programs, exercises, workout logs, max-tracker entries, nutrition and hydration entries, body-weight entries, timers, and settings.
            - Basic technical data: standard request information (such as timestamps) needed to operate and secure the Service.

            We do not knowingly collect payment card numbers, government IDs, or sensitive categories of data beyond the fitness information you choose to enter.

            2. How we use your information

            - To provide, maintain, and improve the Service.
            - To authenticate you and keep your account secure.
            - To send transactional emails such as password resets.
            - To respond to support requests.

            We do not sell your personal information.

            3. Email

            We use a third-party email provider to deliver transactional messages (for example, password reset links). Your email address is shared with that provider solely to deliver those messages.

            4. Data retention

            We retain your account and app data for as long as your account is active. You may request deletion of your account and associated data at any time (see "Your rights").

            5. Security

            Passwords are stored as salted hashes, never in plain text, and the Service is served over encrypted connections (HTTPS). No method of transmission or storage is 100% secure, but we take reasonable measures to protect your information.

            6. Your rights

            Depending on where you live (for example, under GDPR or CCPA), you may have the right to access, correct, export, or delete your personal data, and to object to certain processing. To exercise these rights, contact us at andersonmourot@aol.com.

            7. Children

            The Service is not directed to children under 13 (or the minimum age required in your jurisdiction), and we do not knowingly collect their data.

            8. Changes

            We may update this policy from time to time. Material changes will be reflected by updating the "Last updated" date above.

            9. Contact

            Questions about this policy? Email andersonmourot@aol.com.
            """
        case .terms:
            return """
            Last updated: June 2026

            These Terms of Service ("Terms") govern your access to and use of NextRep (the "Service"). By creating an account or using the Service, you agree to these Terms.

            1. Eligibility & accounts

            You must be at least 13 years old (or the minimum age in your jurisdiction) to use the Service. You are responsible for keeping your login credentials secure and for all activity under your account.

            2. Acceptable use

            You agree not to:

            - Use the Service for any unlawful purpose or in violation of these Terms.
            - Attempt to gain unauthorized access to the Service or other users' accounts.
            - Interfere with, disrupt, or overload the Service or its infrastructure.
            - Reverse engineer or copy the Service except as permitted by law.

            3. Your content

            You retain ownership of the data you create in the Service. You grant us a limited license to store and process that data solely to operate the Service for you.

            4. Health & fitness

            The Service provides general fitness and nutrition tracking tools and information. It does not provide medical advice. See the Health & Fitness Disclaimer, which is incorporated into these Terms by reference.

            5. Service availability

            The Service is provided on an "as is" and "as available" basis. We may modify, suspend, or discontinue any part of the Service at any time, and we do not guarantee uninterrupted or error-free operation.

            6. Disclaimer of warranties

            To the maximum extent permitted by law, we disclaim all warranties, express or implied, including merchantability, fitness for a particular purpose, and non-infringement.

            7. Limitation of liability

            To the maximum extent permitted by law, NextRep and its operators will not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of data, arising from your use of (or inability to use) the Service.

            8. Termination

            You may stop using the Service at any time. We may suspend or terminate your access if you violate these Terms.

            9. Changes to these Terms

            We may update these Terms from time to time. Continued use of the Service after changes become effective constitutes acceptance of the revised Terms.

            10. Contact

            Questions about these Terms? Email andersonmourot@aol.com.
            """
        case .disclaimer:
            return """
            Last updated: June 2026

            Please read this carefully before using NextRep for any exercise, training, or nutrition activity.

            Not medical advice

            NextRep provides general fitness, training, and nutrition information and tracking tools for informational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. The Service does not create a doctor-patient, trainer-client, or other professional relationship.

            Consult a professional first

            Always consult a qualified physician or healthcare provider before beginning any exercise program, changing your diet, or starting any nutrition or supplementation plan — especially if you are pregnant, have an injury, or have any medical condition. Never disregard professional medical advice or delay seeking it because of something you read or tracked in the Service.

            Assumption of risk

            Physical exercise carries inherent risks, including the risk of serious injury. By using NextRep and performing any exercises or programs referenced in it, you do so voluntarily and at your own risk. Stop immediately and seek medical attention if you experience pain, dizziness, shortness of breath, or any other symptom.

            No guarantee of results

            Individual results vary. NextRep makes no guarantee regarding fitness, weight, strength, or health outcomes from using the Service.

            Limitation of liability

            To the maximum extent permitted by law, NextRep and its operators are not responsible or liable for any injury, loss, or damage of any kind arising from your use of the Service or reliance on any information it provides.

            Contact

            Questions? Email andersonmourot@aol.com.
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
