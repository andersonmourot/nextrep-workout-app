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
    @State private var currentPasswordVisible = false
    @State private var newPasswordVisible = false
    @State private var confirmPasswordVisible = false

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
                PasswordVisibilityField(
                    placeholder: "Current password",
                    text: $currentPassword,
                    isVisible: $currentPasswordVisible,
                    textContentType: .password
                )
                PasswordVisibilityField(
                    placeholder: "New password",
                    text: $newPassword,
                    isVisible: $newPasswordVisible,
                    textContentType: .newPassword
                )
                PasswordHintsView(password: newPassword, showWhenEmpty: true)
                PasswordVisibilityField(
                    placeholder: "Confirm new password",
                    text: $confirmPassword,
                    isVisible: $confirmPasswordVisible,
                    textContentType: .newPassword
                )
                if !confirmPassword.isEmpty {
                    Label(newPassword == confirmPassword ? "Passwords match" : "Passwords do not match", systemImage: newPassword == confirmPassword ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.caption)
                        .foregroundStyle(newPassword == confirmPassword ? Theme.accentLight : .red.opacity(0.9))
                }
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
        guard newPassword.count >= 6 else {
            passwordMessage = "New password must be at least 6 characters."
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
        currentPasswordVisible = false
        newPasswordVisible = false
        confirmPasswordVisible = false
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
    @State private var visibleResetPasswordIds: Set<String> = []
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

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    PasswordVisibilityField(
                        placeholder: "New password",
                        text: Binding(
                            get: { resetPasswords[user.id] ?? "" },
                            set: { resetPasswords[user.id] = $0 }
                        ),
                        isVisible: Binding(
                            get: { visibleResetPasswordIds.contains(user.id) },
                            set: { isVisible in
                                if isVisible {
                                    visibleResetPasswordIds.insert(user.id)
                                } else {
                                    visibleResetPasswordIds.remove(user.id)
                                }
                            }
                        ),
                        textContentType: .newPassword
                    )

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

                PasswordHintsView(password: resetPasswords[user.id] ?? "")
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
        guard password.count >= 6 else {
            message = "Password must be at least 6 characters."
            return
        }

        if await store.adminResetPassword(userId: user.id, newPassword: password) {
            resetPasswords[user.id] = ""
            visibleResetPasswordIds.remove(user.id)
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
    @State private var selectedKind = "Programs"
    @State private var searchQuery = ""
    @State private var pendingRemoval: AdminCatalogRemoval?
    @State private var editingExercise: AdminCatalogExerciseEditorState?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                catalogStats
                catalogControls

                if let message {
                    Text(message)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(message.contains("published") || message.contains("removed") || message.contains("saved") ? Theme.accentLight : .red.opacity(0.9))
                        .cardStyle()
                }

                Button(isPublishing ? "Publishing..." : "Publish Current Catalog") {
                    Task { await publishCatalog() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isPublishing)

                catalogList
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Admin Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .alert("Remove Catalog Item?", isPresented: Binding(
            get: { pendingRemoval != nil },
            set: { if !$0 { pendingRemoval = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingRemoval = nil }
            Button("Remove", role: .destructive) {
                if let pendingRemoval {
                    Task { await remove(pendingRemoval) }
                }
            }
        } message: {
            if let pendingRemoval {
                Text("Remove \(pendingRemoval.name) from the built-in \(pendingRemoval.kind.lowercased()) catalog for everyone?")
            }
        }
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

    private var catalogControls: some View {
        VStack(spacing: 12) {
            Picker("Catalog type", selection: $selectedKind) {
                Text("Programs").tag("Programs")
                Text("Exercises").tag("Exercises")
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textFaint)

                TextField("Search catalog", text: $searchQuery)
                    .foregroundStyle(Theme.text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private var catalogList: some View {
        if selectedKind == "Programs" {
            VStack(alignment: .leading, spacing: 12) {
                Text("Programs")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                if filteredPrograms.isEmpty {
                    Text(emptyCatalogMessage)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                        .cardStyle()
                } else {
                    ForEach(filteredPrograms) { program in
                        AdminCatalogProgramRow(program: program) {
                            pendingRemoval = AdminCatalogRemoval(kind: "Program", id: program.id, name: program.name)
                        }
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Exercises")
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    Spacer()

                    Button {
                        editingExercise = AdminCatalogExerciseEditorState(exercise: blankCatalogExercise(), isNew: true)
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.accentLight)
                }

                if let editingExercise {
                    AdminCatalogExerciseForm(
                        initial: editingExercise.exercise,
                        isNew: editingExercise.isNew,
                        isSaving: isPublishing,
                        onCancel: {
                            self.editingExercise = nil
                        },
                        onSave: { exercise in
                            Task { await saveExercise(exercise, isNew: editingExercise.isNew) }
                        }
                    )
                }

                if filteredExercises.isEmpty {
                    Text(emptyCatalogMessage)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                        .cardStyle()
                } else {
                    ForEach(filteredExercises) { exercise in
                        AdminCatalogExerciseRow(
                            exercise: exercise,
                            onEdit: {
                                editingExercise = AdminCatalogExerciseEditorState(exercise: exercise, isNew: false)
                            },
                            onRemove: {
                                pendingRemoval = AdminCatalogRemoval(kind: "Exercise", id: exercise.id, name: exercise.name)
                            }
                        )
                    }
                }
            }
        }
    }

    private var filteredPrograms: [Program] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = store.catalog.programs.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        guard !trimmed.isEmpty else { return sorted }
        return sorted.filter { program in
            [
                program.name,
                program.category,
                program.level,
                program.coach,
                program.summary
            ]
            .joined(separator: " ")
            .localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var filteredExercises: [Exercise] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = store.catalog.exercises.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        guard !trimmed.isEmpty else { return sorted }
        return sorted.filter { exercise in
            [
                exercise.name,
                exercise.primaryMuscle,
                exercise.equipment,
                exercise.difficulty
            ]
            .joined(separator: " ")
            .localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var emptyCatalogMessage: String {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "No \(selectedKind.lowercased()) in the catalog."
        }
        return "No \(selectedKind.lowercased()) match \"\(trimmed)\"."
    }

    private func publishCatalog() async {
        isPublishing = true
        let ok = await store.adminPublishCatalog()
        isPublishing = false
        message = ok ? "Catalog published." : (store.authError ?? "Could not publish catalog.")
    }

    private func remove(_ removal: AdminCatalogRemoval) async {
        pendingRemoval = nil
        isPublishing = true
        let previousCatalog = store.catalog
        if removal.kind == "Program" {
            store.catalog.programs.removeAll { $0.id == removal.id }
        } else {
            store.catalog.exercises.removeAll { $0.id == removal.id }
        }
        let ok = await store.adminPublishCatalog()
        isPublishing = false
        if ok {
            message = "\(removal.name) removed and catalog published."
        } else {
            store.catalog = previousCatalog
            message = store.authError ?? "Could not update catalog."
        }
    }

    private func saveExercise(_ exercise: Exercise, isNew: Bool) async {
        let cleanName = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            message = "Give the exercise a name."
            return
        }

        var updated = exercise
        updated.name = cleanName
        if updated.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updated.id = slugifyCatalogId(cleanName)
        }
        updated.version = Int(Date().timeIntervalSince1970 * 1000)

        let previousCatalog = store.catalog
        isPublishing = true
        store.catalog.exercises.removeAll { $0.id == updated.id }
        if isNew {
            store.catalog.exercises.insert(updated, at: 0)
        } else {
            store.catalog.exercises.append(updated)
            store.catalog.exercises.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        let ok = await store.adminPublishCatalog()
        isPublishing = false
        if ok {
            editingExercise = nil
            selectedKind = "Exercises"
            message = "\(updated.name) saved and catalog published."
        } else {
            store.catalog = previousCatalog
            message = store.authError ?? "Could not save exercise."
        }
    }

    private func blankCatalogExercise() -> Exercise {
        Exercise(
            id: "",
            name: "",
            primaryMuscle: "Chest",
            secondaryMuscles: [],
            equipment: "Barbell",
            difficulty: "Beginner",
            instructions: [],
            tips: [],
            photos: nil,
            shared: nil,
            ownerName: nil,
            ownerId: nil,
            collaborative: nil,
            version: nil
        )
    }
}

private struct AdminCatalogRemoval {
    let kind: String
    let id: String
    let name: String
}

private struct AdminCatalogExerciseEditorState {
    var exercise: Exercise
    var isNew: Bool
}

private func slugifyCatalogId(_ name: String) -> String {
    let lower = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let allowed = CharacterSet.alphanumerics
    let replaced = lower.unicodeScalars.map { scalar in
        allowed.contains(scalar) ? String(scalar) : "-"
    }.joined()
    let collapsed = replaced
        .split(separator: "-", omittingEmptySubsequences: true)
        .joined(separator: "-")
    return collapsed.isEmpty ? "exercise-\(UUID().uuidString)" : collapsed
}

private struct AdminCatalogProgramRow: View {
    let program: Program
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(program.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text("\(program.category) · \(program.level) · \(program.daysPerWeek) days/week")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
                Text(program.summary)
                    .font(.caption2)
                    .foregroundStyle(Theme.textFaint)
                    .lineLimit(2)
            }

            Spacer()

            Button(role: .destructive) {
                onRemove()
            } label: {
                Image(systemName: "trash")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(.red.opacity(0.85))
        }
        .cardStyle()
    }
}

private struct AdminCatalogExerciseRow: View {
    let exercise: Exercise
    let onEdit: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text("\(exercise.primaryMuscle) · \(exercise.equipment) · \(exercise.difficulty)")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
                if !exercise.secondaryMuscles.isEmpty {
                    Text("Secondary: \(exercise.secondaryMuscles.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundStyle(Theme.textFaint)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(Theme.accentLight)

                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.red.opacity(0.85))
            }
        }
        .cardStyle()
    }
}

private struct AdminCatalogExerciseForm: View {
    let initial: Exercise
    let isNew: Bool
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: (Exercise) -> Void

    @State private var name: String
    @State private var primaryMuscle: String
    @State private var secondaryText: String
    @State private var equipment: String
    @State private var difficulty: String
    @State private var instructionsText: String
    @State private var tipsText: String

    private let muscles = [
        "Chest", "Back", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings",
        "Glutes", "Calves", "Core", "Forearms", "Full Body"
    ]
    private let equipmentOptions = ["Barbell", "Dumbbell", "Machine", "Cable", "Bodyweight", "Kettlebell", "Bands"]
    private let difficulties = ["Beginner", "Intermediate", "Advanced"]

    init(
        initial: Exercise,
        isNew: Bool,
        isSaving: Bool,
        onCancel: @escaping () -> Void,
        onSave: @escaping (Exercise) -> Void
    ) {
        self.initial = initial
        self.isNew = isNew
        self.isSaving = isSaving
        self.onCancel = onCancel
        self.onSave = onSave
        _name = State(initialValue: initial.name)
        _primaryMuscle = State(initialValue: initial.primaryMuscle)
        _secondaryText = State(initialValue: initial.secondaryMuscles.joined(separator: ", "))
        _equipment = State(initialValue: initial.equipment)
        _difficulty = State(initialValue: initial.difficulty)
        _instructionsText = State(initialValue: initial.instructions.joined(separator: "\n"))
        _tipsText = State(initialValue: initial.tips.joined(separator: "\n"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isNew ? "New Exercise" : "Edit Exercise")
                .font(.headline)
                .foregroundStyle(Theme.text)

            catalogField("Name", text: $name)

            HStack(spacing: 10) {
                catalogMenu("Primary", selection: $primaryMuscle, options: muscles)
                catalogMenu("Equipment", selection: $equipment, options: equipmentOptions)
            }

            HStack(spacing: 10) {
                catalogMenu("Difficulty", selection: $difficulty, options: difficulties)
                catalogField("Secondary, comma separated", text: $secondaryText)
            }

            catalogField("Instructions, one per line", text: $instructionsText, minHeight: 90)
            catalogField("Tips, one per line", text: $tipsText, minHeight: 72)

            HStack(spacing: 10) {
                Button(isSaving ? "Saving..." : "Save Exercise") {
                    onSave(normalizedExercise)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(GhostButtonStyle())
                .disabled(isSaving)
            }
        }
        .cardStyle()
    }

    private var normalizedExercise: Exercise {
        var exercise = initial
        exercise.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        exercise.primaryMuscle = primaryMuscle
        exercise.secondaryMuscles = commaList(secondaryText)
        exercise.equipment = equipment
        exercise.difficulty = difficulty
        exercise.instructions = lineList(instructionsText)
        exercise.tips = lineList(tipsText)
        return exercise
    }

    private func catalogMenu(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    selection.wrappedValue = option
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.textFaint)
                    Text(selection.wrappedValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.text)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.textFaint)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func catalogField(_ placeholder: String, text: Binding<String>, minHeight: CGFloat = 44) -> some View {
        TextField("", text: text, axis: .vertical)
            .foregroundStyle(Theme.text)
            .tint(Theme.accentLight)
            .frame(minHeight: minHeight, alignment: .topLeading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.caption)
                        .foregroundStyle(Theme.textDim.opacity(0.95))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }

    private func commaList(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func lineList(_ value: String) -> [String] {
        value
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
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
