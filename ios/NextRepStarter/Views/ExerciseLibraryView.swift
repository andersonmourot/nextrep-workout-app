import SwiftUI
import UIKit

struct ExerciseLibraryView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""
    @State private var selectedMuscle = "All"
    @State private var showingHidden = false
    @State private var showingTrash = false
    @State private var pendingHide: Exercise?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                searchField
                muscleFilters
                managementControls

                if filteredExercises.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredExercises) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                ExerciseCard(exercise: exercise) {
                                    if store.isCustomExercise(exercise) {
                                        store.deleteCustomExercise(id: exercise.id)
                                    } else {
                                        pendingHide = exercise
                                    }
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
        .navigationDestination(isPresented: $showingHidden) {
            HiddenExercisesView()
        }
        .navigationDestination(isPresented: $showingTrash) {
            TrashedExercisesView()
        }
        .alert("Hide Exercise?", isPresented: Binding(
            get: { pendingHide != nil },
            set: { if !$0 { pendingHide = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingHide = nil }
            Button("Hide", role: .destructive) {
                if let pendingHide {
                    store.hideExercise(id: pendingHide.id)
                }
                pendingHide = nil
            }
        } message: {
            Text("This hides the built-in exercise from your library. You can restore hidden exercises later.")
        }
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
        return ["All", "Custom"] + values.sorted()
    }

    private var filteredExercises: [Exercise] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        return store.allExercises.filter { exercise in
            let matchesMuscle = selectedMuscle == "All" ||
                (selectedMuscle == "Custom" && store.isCustomExercise(exercise)) ||
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

    private var managementControls: some View {
        HStack(spacing: 10) {
            if !store.appData.hiddenExerciseIds.isEmpty {
                Button {
                    showingHidden = true
                } label: {
                    Label("Hidden", systemImage: "eye.slash")
                }
                .buttonStyle(GhostButtonStyle())
            }

            if !store.appData.trashedExercises.isEmpty {
                Button {
                    showingTrash = true
                } label: {
                    Label("Trash", systemImage: "trash")
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
    }
}

struct ExerciseDetailView: View {
    @Environment(AppStore.self) private var store
    @State private var shareMessage: String?
    @State private var noteText = ""
    @State private var cueText = ""
    let exercise: Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                photosSection
                personalSection
                usageSection
                instructionsSection
                tipsSection
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            noteText = store.appData.exerciseNotes[exercise.id] ?? ""
            cueText = store.appData.exerciseSubheaders[exercise.id] ?? ""
        }
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
                            if exercise.shared == true {
                                store.unshareExercise(exercise)
                                shareMessage = "Exercise unshared"
                            } else {
                                Task {
                                    await store.shareExercise(exercise)
                                    shareMessage = "Exercise shared"
                                }
                            }
                        } label: {
                            Image(systemName: exercise.shared == true ? "xmark.circle" : "square.and.arrow.up")
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

    @ViewBuilder
    private var photosSection: some View {
        if let photos = exercise.photos, !photos.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(photos.prefix(2).enumerated()), id: \.offset) { _, photo in
                        if let image = imageFromDataURL(photo) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 190, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(.white.opacity(0.08), lineWidth: 1)
                                }
                        }
                    }
                }
            }
        }
    }

    private var personalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Notes & Cues")
                .font(.headline)
                .foregroundStyle(Theme.text)

            TextField("Cue shown under exercise name", text: $cueText, axis: .vertical)
                .exerciseDetailFieldStyle()
            TextField("Private notes", text: $noteText, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .exerciseDetailFieldStyle()

            Button("Save Notes & Cues") {
                store.setExerciseCue(exerciseId: exercise.id, cue: cueText)
                store.setExerciseNote(exerciseId: exercise.id, note: noteText)
                shareMessage = "Notes saved"
            }
            .buttonStyle(GhostButtonStyle())
        }
        .cardStyle()
    }

    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appears In")
                .font(.headline)
                .foregroundStyle(Theme.text)

            if programsUsingExercise.isEmpty {
                Text("This exercise is not currently in any visible program.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            } else {
                ForEach(programsUsingExercise.prefix(6)) { program in
                    NavigationLink {
                        ProgramDetailView(program: program)
                    } label: {
                        HStack {
                            Text(program.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.text)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.textFaint)
                        }
                        .padding(10)
                        .background(Theme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }

    private var programsUsingExercise: [Program] {
        store.allPrograms.filter { program in
            program.days.contains { day in
                day.exercises.contains { planned in
                    planned.exerciseId == exercise.id
                }
            }
        }
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

    private func imageFromDataURL(_ value: String) -> UIImage? {
        let base64 = value.components(separatedBy: ",").last ?? value
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        return UIImage(data: data)
    }
}

private extension View {
    func exerciseDetailFieldStyle() -> some View {
        self
            .foregroundStyle(Theme.text)
            .tint(Theme.accentLight)
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

private struct ExerciseCard: View {
    let exercise: Exercise
    let onManage: () -> Void

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

                Button {
                    onManage()
                } label: {
                    Image(systemName: exercise.id.hasPrefix("ios-ex-") ? "trash" : "eye.slash")
                        .font(.caption)
                }
                .foregroundStyle(.red.opacity(0.8))
                .buttonStyle(.plain)

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

private struct HiddenExercisesView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if hiddenExercises.isEmpty {
                    Text("No hidden exercises.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                        .cardStyle()
                } else {
                    Button("Restore All Hidden") {
                        store.restoreHiddenExercises()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    ForEach(hiddenExercises) { exercise in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .foregroundStyle(Theme.text)
                                Text("\(exercise.primaryMuscle) · \(exercise.equipment)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textDim)
                            }
                            Spacer()
                            Button("Restore") {
                                store.restoreHiddenExercise(id: exercise.id)
                            }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.accentLight)
                        }
                        .cardStyle()
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Hidden Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var hiddenExercises: [Exercise] {
        store.catalog.exercises
            .filter { store.appData.hiddenExerciseIds.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

private struct TrashedExercisesView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if store.appData.trashedExercises.isEmpty {
                    Text("No deleted custom exercises.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                        .cardStyle()
                } else {
                    ForEach(store.appData.trashedExercises) { trashed in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trashed.exercise.name)
                                    .font(.headline)
                                    .foregroundStyle(Theme.text)
                                Text("\(trashed.exercise.primaryMuscle) · \(trashed.exercise.equipment)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textDim)
                            }
                            Spacer()
                            Button("Restore") {
                                store.restoreTrashedExercise(id: trashed.exercise.id)
                            }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.accentLight)
                            Button {
                                store.purgeTrashedExercise(id: trashed.exercise.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .foregroundStyle(.red.opacity(0.8))
                        }
                        .cardStyle()
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Trash")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }
}
