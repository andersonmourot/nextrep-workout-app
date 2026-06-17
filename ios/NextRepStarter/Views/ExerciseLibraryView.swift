import SwiftUI

struct ExerciseLibraryView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""
    @State private var selectedMuscle = "All"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                searchField
                muscleFilters

                if filteredExercises.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredExercises) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                ExerciseCard(exercise: exercise)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ExerciseEditorView()
                } label: {
                    Image(systemName: "plus")
                }
                .tint(Theme.accentLight)
            }
        }
        .screenBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Exercise Library")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("\(filteredExercises.count) exercises")
                .font(.caption)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Theme.accentLight)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textFaint)

            TextField("Search exercises", text: $query)
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

    private var muscleFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(muscles, id: \.self) { muscle in
                    Button {
                        selectedMuscle = muscle
                    } label: {
                        Text(muscle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selectedMuscle == muscle ? .white : Theme.textDim)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedMuscle == muscle ? Theme.accent : Theme.surface2)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No exercises found", systemImage: "magnifyingglass")
                .font(.headline)
                .foregroundStyle(Theme.text)

            Text("Try a different search or muscle filter.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var muscles: [String] {
        let values = Set(store.allExercises.map(\.primaryMuscle))
        return ["All"] + values.sorted()
    }

    private var filteredExercises: [Exercise] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        return store.allExercises.filter { exercise in
            let matchesMuscle = selectedMuscle == "All" ||
                exercise.primaryMuscle == selectedMuscle ||
                exercise.secondaryMuscles.contains(selectedMuscle)

            guard matchesMuscle else {
                return false
            }

            guard !trimmed.isEmpty else {
                return true
            }

            let haystack = ([exercise.name, exercise.primaryMuscle, exercise.equipment, exercise.difficulty] +
                exercise.secondaryMuscles +
                exercise.instructions +
                exercise.tips)
                .joined(separator: " ")

            return haystack.localizedCaseInsensitiveContains(trimmed)
        }
    }
}

struct ExerciseDetailView: View {
    @Environment(AppStore.self) private var store
    @State private var shareMessage: String?
    let exercise: Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                instructionsSection
                tipsSection
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if store.isCustomExercise(exercise) {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 13) {
                        NavigationLink {
                            ExerciseEditorView(exercise: exercise)
                        } label: {
                            Image(systemName: "pencil")
                        }

                        Button {
                            Task {
                                await store.shareExercise(exercise)
                                shareMessage = "Exercise shared"
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .tint(Theme.accentLight)
                }
            }
        }
        .screenBackground()
        .overlay(alignment: .bottom) {
            if let shareMessage {
                Text(shareMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.accent)
                    .clipShape(Capsule())
                    .padding(.bottom, 18)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            self.shareMessage = nil
                        }
                    }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(exercise.primaryMuscle)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundStyle(Theme.accentLight)

            Text(exercise.name)
                .font(.system(size: 32, weight: .bold, design: .default))
                .foregroundStyle(Theme.text)

            HStack(spacing: 8) {
                chip(exercise.equipment)
                chip(exercise.difficulty)
            }

            if !exercise.secondaryMuscles.isEmpty {
                Text("Secondary: \(exercise.secondaryMuscles.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            }
        }
        .cardStyle()
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Instructions")
                .font(.headline)
                .foregroundStyle(Theme.text)

            if exercise.instructions.isEmpty {
                Text("No instructions available.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .cardStyle()
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                        numberedRow(index: index + 1, text: step)
                    }
                }
            }
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tips")
                .font(.headline)
                .foregroundStyle(Theme.text)

            if exercise.tips.isEmpty {
                Text("No tips available.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .cardStyle()
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(exercise.tips.enumerated()), id: \.offset) { _, tip in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(Theme.accentLight)
                            Text(tip)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textDim)
                            Spacer(minLength: 0)
                        }
                        .cardStyle()
                    }
                }
            }
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.textDim)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.surface2)
            .clipShape(Capsule())
    }

    private func numberedRow(index: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.accentLight)
                .frame(width: 22, alignment: .leading)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)

            Spacer(minLength: 0)
        }
        .cardStyle()
    }
}

private struct ExerciseCard: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.primaryMuscle)
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundStyle(Theme.accentLight)

                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textFaint)
            }

            HStack(spacing: 8) {
                chip(exercise.equipment)
                chip(exercise.difficulty)
            }
        }
        .cardStyle()
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Theme.textDim)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Theme.surface2)
            .clipShape(Capsule())
    }
}
