import SwiftUI

struct PeopleSearchView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""
    @State private var results: [DiscoverUser] = []
    @State private var isSearching = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
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
        }
    }
}

struct SharedUserDetailView: View {
    @Environment(AppStore.self) private var store
    @State private var programs: [Program] = []
    @State private var exercises: [Exercise] = []
    @State private var isLoading = false
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
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: user.color))
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
                    SharedProgramCard(program: program, isAdded: store.allPrograms.contains(where: { $0.id == program.id })) {
                        Task { await store.addSharedProgram(id: program.id) }
                    }
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
                        Task { await store.addSharedExercise(id: exercise.id) }
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
}

private struct DiscoverUserRow: View {
    let user: DiscoverUser
    let onFollow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: user.color))
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
    let isAdded: Bool
    let onAdd: () -> Void

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

                Button(isAdded ? "Added" : "Add") {
                    if !isAdded { onAdd() }
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(isAdded ? Theme.textDim : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isAdded ? Theme.surface2 : Color(hex: program.accent))
                .clipShape(Capsule())
            }

            Text(program.summary)
                .font(.caption)
                .foregroundStyle(Theme.textDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }
}

private struct SharedExerciseCard: View {
    let exercise: Exercise
    let isAdded: Bool
    let onAdd: () -> Void

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

            Button(isAdded ? "Added" : "Add") {
                if !isAdded { onAdd() }
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(isAdded ? Theme.textDim : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isAdded ? Theme.surface2 : Theme.accent)
            .clipShape(Capsule())
        }
        .cardStyle()
    }
}
