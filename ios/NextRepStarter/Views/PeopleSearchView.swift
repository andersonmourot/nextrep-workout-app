import SwiftUI

struct PeopleSearchView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""
    @State private var results: [DiscoverUser] = []
    @State private var followingUsers: [FollowUser] = []
    @State private var isSearching = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                followingSection
                searchField

                if let error = store.authError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                }

                if isSearching {
                    ProgressView()
                        .tint(Theme.accentLight)
                        .frame(maxWidth: .infinity)
                        .cardStyle()
                } else if results.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(results) { user in
                            NavigationLink {
                                SharedUserDetailView(user: user)
                            } label: {
                                DiscoverUserRow(user: user) {
                                    toggleFollow(user)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .task {
            await loadFollowing()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Find People")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("Search users, follow creators, and add shared training.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textFaint)

            TextField("Search by name", text: $query)
                .foregroundStyle(Theme.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit {
                    Task { await runSearch() }
                }

            Button("Search") {
                Task { await runSearch() }
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Theme.accentLight)
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

    @ViewBuilder
    private var followingSection: some View {
        if !followingUsers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Following")
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Button {
                        Task { await loadFollowing() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.accentLight)
                }

                ForEach(followingUsers) { follow in
                    let user = discoverUser(from: follow)
                    NavigationLink {
                        SharedUserDetailView(user: user)
                    } label: {
                        DiscoverUserRow(user: user) {
                            toggleFollow(user)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Search for users" : "No users found", systemImage: "person.2")
                .font(.headline)
                .foregroundStyle(Theme.text)

            Text("Enter a name to discover people and their shared programs or exercises.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            return
        }

        isSearching = true
        results = await store.searchUsers(query: trimmed)
        isSearching = false
    }

    private func toggleFollow(_ user: DiscoverUser) {
        Task {
            if user.following {
                await store.unfollow(userId: user.id)
            } else {
                await store.follow(userId: user.id)
            }
            await runSearch()
            await loadFollowing()
        }
    }

    private func loadFollowing() async {
        followingUsers = await store.following()
    }

    private func discoverUser(from follow: FollowUser) -> DiscoverUser {
        DiscoverUser(
            id: follow.id,
            name: follow.name,
            color: follow.color,
            following: true,
            programCount: follow.programCount,
            exerciseCount: follow.exerciseCount
        )
    }
}

struct SharedUserDetailView: View {
    @Environment(AppStore.self) private var store
    @State private var programs: [Program] = []
    @State private var exercises: [Exercise] = []
    @State private var isLoading = false
    @State private var addedProgramLocalIds: [String: String] = [:]
    @State private var choosingProgram: Program?
    @State private var isChoosingProgramMode = false
    @State private var removingProgramId: String?
    let user: DiscoverUser

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                sharedProgramsSection
                sharedExercisesSection
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(user.name)
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .task {
            await loadSharedContent()
        }
        .sheet(item: $choosingProgram) { program in
            SharedProgramAddChoiceView(
                program: program,
                ownerName: user.name,
                isChoosing: isChoosingProgramMode,
                onChoose: { mode in
                    Task { await chooseSharedProgram(program, mode: mode) }
                },
                onCancel: {
                    choosingProgram = nil
                }
            )
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(String(user.name.prefix(1)).uppercased())
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.text)

                    Text("\(programs.count) programs · \(exercises.count) exercises")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                }

                Spacer()
            }
        }
        .cardStyle()
    }

    private var sharedProgramsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared Programs")
                .font(.headline)
                .foregroundStyle(Theme.text)

            if isLoading {
                ProgressView()
                    .tint(Theme.accentLight)
                    .frame(maxWidth: .infinity)
                    .cardStyle()
            } else if programs.isEmpty {
                Text("No shared programs yet.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                ForEach(programs) { program in
                    let localId = addedProgramLocalId(for: program)
                    let isOwner = program.ownerId != nil && program.ownerId == store.user?.id
                    SharedProgramCard(
                        program: program,
                        localId: localId,
                        isOwner: isOwner,
                        isRemoving: removingProgramId == program.id,
                        onAdd: {
                            choosingProgram = program
                        },
                        onRemove: {
                            Task { await removeSharedProgram(program) }
                        }
                    )
                }
            }
        }
    }

    private var sharedExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared Exercises")
                .font(.headline)
                .foregroundStyle(Theme.text)

            if exercises.isEmpty {
                Text("No shared exercises yet.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                ForEach(exercises) { exercise in
                    SharedExerciseCard(exercise: exercise, isAdded: store.allExercises.contains(where: { $0.id == exercise.id })) {
                        Task {
                            if store.allExercises.contains(where: { $0.id == exercise.id }) {
                                await store.removeSharedExercise(id: exercise.id)
                            } else {
                                await store.addSharedExercise(exercise, ownerName: user.name)
                            }
                        }
                    }
                }
            }
        }
    }

    private func loadSharedContent() async {
        isLoading = true
        programs = await store.sharedPrograms(for: user.id)
        exercises = await store.sharedExercises(for: user.id)
        isLoading = false
    }

    private func addedProgramLocalId(for program: Program) -> String? {
        if let localId = addedProgramLocalIds[program.id] {
            return localId
        }
        if store.allPrograms.contains(where: { $0.id == program.id }) {
            return program.id
        }
        return nil
    }

    private func chooseSharedProgram(_ program: Program, mode: SharedProgramAddMode) async {
        isChoosingProgramMode = true
        defer {
            isChoosingProgramMode = false
            choosingProgram = nil
        }

        guard let saved = await store.addSharedProgram(
            program,
            ownerName: user.name,
            ownerExercises: exercises,
            mode: mode
        ) else {
            return
        }
        addedProgramLocalIds[program.id] = saved.id
    }

    private func removeSharedProgram(_ program: Program) async {
        guard let localId = addedProgramLocalId(for: program) else {
            return
        }

        removingProgramId = program.id
        await store.removeSharedProgram(sharedId: program.id, localId: localId)
        addedProgramLocalIds.removeValue(forKey: program.id)
        removingProgramId = nil
    }
}

private struct DiscoverUserRow: View {
    let user: DiscoverUser
    let onFollow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.accent)
                .frame(width: 44, height: 44)
                .overlay {
                    Text(String(user.name.prefix(1)).uppercased())
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Text("\(user.programCount) programs · \(user.exerciseCount) exercises")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }

            Spacer()

            Button {
                onFollow()
            } label: {
                Text(user.following ? "Following" : "Follow")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(user.following ? Theme.textDim : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(user.following ? Theme.surface2 : Theme.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Theme.textFaint)
        }
        .cardStyle()
    }
}

private struct SharedProgramCard: View {
    let program: Program
    let localId: String?
    let isOwner: Bool
    let isRemoving: Bool
    let onAdd: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(program.category) · \(program.level)")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundStyle(Color(hex: program.accent))

                    Text(program.name)
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                }

                Spacer()

                if isOwner {
                    Text("Yours")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textDim)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.surface2)
                        .clipShape(Capsule())
                } else if localId != nil {
                    Button(isRemoving ? "Removing..." : "Remove") {
                        onRemove()
                    }
                    .disabled(isRemoving)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.surface2)
                    .clipShape(Capsule())
                } else {
                    Button("Add") {
                        onAdd()
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: program.accent))
                    .clipShape(Capsule())
                }
            }

            Text(program.summary)
                .font(.caption)
                .foregroundStyle(Theme.textDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }
}

private struct SharedProgramAddChoiceView: View {
    let program: Program
    let ownerName: String
    let isChoosing: Bool
    let onChoose: (SharedProgramAddMode) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Add \(program.name)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.text)

                Text("Choose how you want to add \(ownerName)'s program.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            }

            VStack(spacing: 10) {
                Button {
                    onChoose(.duplicate)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "doc.on.doc")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.accentLight)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Duplicate")
                                .font(.headline)
                                .foregroundStyle(Theme.text)
                            Text("Make your own editable copy. Future changes by the original creator will not affect it.")
                                .font(.caption)
                                .foregroundStyle(Theme.textDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(Theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isChoosing)

                Button {
                    onChoose(.follow)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.accentLight)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Follow")
                                .font(.headline)
                                .foregroundStyle(Theme.text)
                            Text("Save it to your Programs and stay linked to creator updates. Only the creator can edit it unless it is collaborative.")
                                .font(.caption)
                                .foregroundStyle(Theme.textDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(Theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isChoosing)
            }

            Button(isChoosing ? "Adding..." : "Cancel") {
                onCancel()
            }
            .buttonStyle(GhostButtonStyle())
            .disabled(isChoosing)
        }
        .padding(20)
        .frame(maxWidth: 448)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.bg)
        .screenBackground()
    }
}

private struct SharedExerciseCard: View {
    let exercise: Exercise
    let isAdded: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.primaryMuscle)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(Theme.accentLight)

                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Text("\(exercise.equipment) · \(exercise.difficulty)")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }

            Spacer()

            Button(isAdded ? "Remove" : "Add") {
                onToggle()
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(isAdded ? .red.opacity(0.9) : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isAdded ? Theme.surface2 : Theme.accent)
            .clipShape(Capsule())
        }
        .cardStyle()
    }
}
