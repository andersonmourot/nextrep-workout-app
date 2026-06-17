import SwiftUI

struct ProgramEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Program
    @State private var showingDeleteConfirm = false
    @State private var exerciseQueries: [String: String] = [:]
    @State private var collapsedDayIds: Set<String> = []
    @FocusState private var focusedExerciseKey: String?

    private let categories = ["Bodybuilding", "Strength", "HIIT", "Powerlifting", "Functional", "Bodyweight"]
    private let levels = ["Beginner", "Intermediate", "Advanced"]
    private let accentColors = ["#e9b949", "#b91c1c", "#3b82f6", "#22c55e", "#a855f7", "#f97316", "#14b8a6", "#ec4899"]

    init(program: Program? = nil) {
        _draft = State(initialValue: program ?? Self.blankProgram())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                basics
                daysEditor
                actions
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(draft.name.isEmpty ? "New Program" : draft.name)
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .onChange(of: focusedExerciseKey) { oldValue, newValue in
            if newValue == nil, let oldValue {
                commitExerciseQuery(for: oldValue)
            }
        }
        .alert("Delete Program?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deleteCustomProgram(id: draft.id)
                dismiss()
            }
        } message: {
            Text("This removes the custom program from your synced data.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(store.isCustomProgram(draft) ? "Edit Program" : "Create Program")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("Build a simple custom plan you can run natively.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
    }

    private var basics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basics")
                .font(.headline)
                .foregroundStyle(Theme.text)

            field("Name", text: $draft.name)
            field("Coach", text: $draft.coach)
            field("Summary", text: $draft.summary)
            field("Description", text: $draft.description)

            HStack(spacing: 10) {
                menuPicker("Category", selection: $draft.category, options: categories)
                menuPicker("Level", selection: $draft.level, options: levels)
            }

            HStack(spacing: 10) {
                numericField("Weeks", value: $draft.durationWeeks)
                numericField("Days / week", value: $draft.daysPerWeek)
            }

            accentPicker
            collaborativePicker
        }
        .cardStyle()
        .foregroundStyle(Theme.text)
    }

    private func menuPicker(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        return Menu {
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
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.text)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textFaint)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var accentPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accent color")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textDim)

            HStack(spacing: 10) {
                ForEach(accentColors, id: \.self) { color in
                    Button {
                        draft.accent = color
                    } label: {
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 30, height: 30)
                            .overlay {
                                if draft.accent.lowercased() == color.lowercased() {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay {
                                Circle()
                                    .stroke(.white.opacity(draft.accent.lowercased() == color.lowercased() ? 0.9 : 0), lineWidth: 2)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var collaborativePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Collaborative")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textDim)

            HStack(spacing: 10) {
                togglePill("Yes", isSelected: draft.collaborative == true) {
                    draft.collaborative = true
                }
                togglePill("No", isSelected: draft.collaborative != true) {
                    draft.collaborative = false
                }
            }

            Text(draft.collaborative == true ? "Anyone who adds this program can edit it." : "Only you can edit this program.")
                .font(.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }

    private func togglePill(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        return Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Theme.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Theme.accent : Theme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var daysEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Days")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Spacer()

                Button("Add Day") {
                    draft.days.append(Self.blankDay(number: draft.days.count + 1))
                    draft.daysPerWeek = max(1, draft.days.count)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.accentLight)
            }

            if draft.days.isEmpty {
                Text("Add at least one day to start using this program.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .cardStyle()
            } else {
                ForEach(draft.days.indices, id: \.self) { dayIndex in
                    dayEditor(dayIndex: dayIndex)
                }
            }
        }
    }

    private func dayEditor(dayIndex: Int) -> some View {
        let dayId = draft.days[dayIndex].id
        let isCollapsed = collapsedDayIds.contains(dayId)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    if isCollapsed {
                        collapsedDayIds.remove(dayId)
                    } else {
                        collapsedDayIds.insert(dayId)
                    }
                } label: {
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textDim)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Text("Day \(dayIndex + 1)")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(Theme.accentLight)

                Spacer()

                Button("Duplicate") {
                    duplicateDay(at: dayIndex)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.accentLight)

                Button("Remove") {
                    draft.days.remove(at: dayIndex)
                    draft.daysPerWeek = max(1, draft.days.count)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.red.opacity(0.85))
            }

            if !isCollapsed {
                field("Day Name", text: $draft.days[dayIndex].name)
                field("Focus", text: $draft.days[dayIndex].focus)

                ForEach(draft.days[dayIndex].exercises.indices, id: \.self) { exerciseIndex in
                    exerciseEditor(dayIndex: dayIndex, exerciseIndex: exerciseIndex)
                }

                Button {
                    draft.days[dayIndex].exercises.append(blankPlannedExercise())
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
                .buttonStyle(GhostButtonStyle())
            } else {
                Text("\(draft.days[dayIndex].exercises.count) exercise\(draft.days[dayIndex].exercises.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }
        }
        .cardStyle()
    }

    private func exerciseEditor(dayIndex: Int, exerciseIndex: Int) -> some View {
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Exercise \(exerciseIndex + 1)")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .foregroundStyle(Theme.textFaint)

                Spacer()

                moveExerciseControls(dayIndex: dayIndex, exerciseIndex: exerciseIndex)

                Button("Duplicate") {
                    duplicateExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.accentLight)

                Button("Remove") {
                    draft.days[dayIndex].exercises.remove(at: exerciseIndex)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.red.opacity(0.85))
            }

            exerciseSelector(dayIndex: dayIndex, exerciseIndex: exerciseIndex)

            numericField(
                "Sets",
                value: $draft.days[dayIndex].exercises[exerciseIndex].sets,
                emptyWhenZero: true
            )
            field("Reps", text: $draft.days[dayIndex].exercises[exerciseIndex].reps)
            numericField(
                "Rest",
                value: $draft.days[dayIndex].exercises[exerciseIndex].restSec,
                emptyWhenZero: true
            )
            field("Superset Group (optional)", text: Binding(
                get: { draft.days[dayIndex].exercises[exerciseIndex].groupId ?? "" },
                set: { draft.days[dayIndex].exercises[exerciseIndex].groupId = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
            ))
            supersetControls(dayIndex: dayIndex, exerciseIndex: exerciseIndex)
            field("Notes", text: Binding(
                get: { draft.days[dayIndex].exercises[exerciseIndex].notes ?? "" },
                set: { draft.days[dayIndex].exercises[exerciseIndex].notes = $0.isEmpty ? nil : $0 }
            ))
        }
        .padding(12)
        .background(Theme.inputBg.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func moveExerciseControls(dayIndex: Int, exerciseIndex: Int) -> some View {
        return VStack(spacing: 0) {
            Button {
                moveExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex, direction: -1)
            } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(exerciseIndex == 0)

            Divider().overlay(.white.opacity(0.08))

            Button {
                moveExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex, direction: 1)
            } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(exerciseIndex >= draft.days[dayIndex].exercises.count - 1)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(Theme.textDim)
        .frame(width: 28)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private func supersetControls(dayIndex: Int, exerciseIndex: Int) -> some View {
        HStack(spacing: 10) {
            if exerciseIndex < draft.days[dayIndex].exercises.count - 1 {
                Button {
                    supersetWithNext(dayIndex: dayIndex, exerciseIndex: exerciseIndex)
                } label: {
                    Text("Superset with next")
                }
                .buttonStyle(GhostButtonStyle())
            }

            if let groupId = draft.days[dayIndex].exercises[exerciseIndex].groupId,
               !groupId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    unlinkSuperset(dayIndex: dayIndex, groupId: groupId)
                } label: {
                    Text("Unlink group")
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
    }

    private func exerciseSelector(dayIndex: Int, exerciseIndex: Int) -> some View {
        let key = exerciseKey(dayIndex: dayIndex, exerciseIndex: exerciseIndex)
        let planned = draft.days[dayIndex].exercises[exerciseIndex]
        let query = exerciseQueries[key] ?? exerciseDisplayName(for: planned)
        let isFocused = focusedExerciseKey == key
        let matches = isFocused ? Array(filteredExercises(query: query).prefix(5)) : []

        return VStack(alignment: .leading, spacing: 8) {
            TextField("", text: Binding(
                get: { exerciseQueries[key] ?? exerciseDisplayName(for: draft.days[dayIndex].exercises[exerciseIndex]) },
                set: { newValue in
                    exerciseQueries[key] = newValue
                    if let exact = store.allExercises.first(where: { $0.name.localizedCaseInsensitiveCompare(newValue) == .orderedSame }) {
                        draft.days[dayIndex].exercises[exerciseIndex].exerciseId = exact.id
                        draft.days[dayIndex].exercises[exerciseIndex].name = nil
                    } else {
                        draft.days[dayIndex].exercises[exerciseIndex].exerciseId = "custom-\(key)"
                        draft.days[dayIndex].exercises[exerciseIndex].name = newValue
                    }
                }
            ))
            .programEditorInputStyle(placeholder: "Exercise", isEmpty: query.isEmpty)
            .foregroundStyle(Theme.text)
            .tint(Theme.accentLight)
            .focused($focusedExerciseKey, equals: key)
            .submitLabel(.done)
            .onSubmit {
                commitExerciseQuery(dayIndex: dayIndex, exerciseIndex: exerciseIndex)
                focusedExerciseKey = nil
            }

            if !matches.isEmpty {
                VStack(spacing: 0) {
                    ForEach(matches) { exercise in
                        Button {
                            draft.days[dayIndex].exercises[exerciseIndex].exerciseId = exercise.id
                            draft.days[dayIndex].exercises[exerciseIndex].name = nil
                            exerciseQueries[key] = exercise.name
                            focusedExerciseKey = nil
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.text)
                                    Text("\(exercise.primaryMuscle) · \(exercise.equipment)")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textDim)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                        }
                        .buttonStyle(.plain)

                        if exercise.id != matches.last?.id {
                            Divider().overlay(.white.opacity(0.08))
                        }
                    }
                }
                .background(Theme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if planned.name != nil {
                Text("Custom exercise name")
                    .font(.caption2)
                    .foregroundStyle(Theme.textFaint)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                normalizeDraft()
                store.saveCustomProgram(draft)
                dismiss()
            } label: {
                Text("Save Program")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.days.isEmpty)
            .opacity(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.days.isEmpty ? 0.5 : 1)

            if store.isCustomProgram(draft) {
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Text("Delete Program")
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        return TextField("", text: text, axis: .vertical)
            .programEditorInputStyle(placeholder: placeholder, isEmpty: text.wrappedValue.isEmpty)
            .foregroundStyle(Theme.text)
            .tint(Theme.accentLight)
    }

    private func numericField(_ label: String, value: Binding<Int>, emptyWhenZero: Bool = false) -> some View {
        let isEmpty = emptyWhenZero && value.wrappedValue == 0

        return TextField("", text: Binding(
            get: {
                if emptyWhenZero && value.wrappedValue == 0 {
                    return ""
                }
                return "\(value.wrappedValue)"
            },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                value.wrappedValue = Int(digits) ?? 0
            }
        ))
        .programEditorInputStyle(placeholder: label, isEmpty: isEmpty)
        .keyboardType(.numberPad)
        .foregroundStyle(Theme.text)
        .tint(Theme.accentLight)
    }

    private func normalizeDraft() {
        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.coach = draft.coach.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.summary = draft.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.description = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.daysPerWeek = max(1, draft.days.count)
        for dayIndex in draft.days.indices {
            for exerciseIndex in draft.days[dayIndex].exercises.indices {
                draft.days[dayIndex].exercises[exerciseIndex].sets = max(1, draft.days[dayIndex].exercises[exerciseIndex].sets)
                draft.days[dayIndex].exercises[exerciseIndex].restSec = max(0, draft.days[dayIndex].exercises[exerciseIndex].restSec)
            }
        }
    }

    private func blankPlannedExercise() -> PlannedExercise {
        PlannedExercise(exerciseId: "", name: nil, sets: 0, reps: "", restSec: 0, notes: nil, groupId: nil)
    }

    private func duplicateDay(at index: Int) {
        guard draft.days.indices.contains(index) else { return }
        var copy = draft.days[index]
        copy.id = "day-\(UUID().uuidString)"
        copy.name = copy.name.isEmpty ? "Day \(draft.days.count + 1)" : "\(copy.name) Copy"
        draft.days.insert(copy, at: index + 1)
        draft.daysPerWeek = max(1, draft.days.count)
    }

    private func duplicateExercise(dayIndex: Int, exerciseIndex: Int) {
        guard draft.days.indices.contains(dayIndex),
              draft.days[dayIndex].exercises.indices.contains(exerciseIndex) else {
            return
        }

        let copy = draft.days[dayIndex].exercises[exerciseIndex]
        draft.days[dayIndex].exercises.insert(copy, at: exerciseIndex + 1)
    }

    private func moveExercise(dayIndex: Int, exerciseIndex: Int, direction: Int) {
        guard draft.days.indices.contains(dayIndex) else { return }
        let target = exerciseIndex + direction
        guard draft.days[dayIndex].exercises.indices.contains(exerciseIndex),
              draft.days[dayIndex].exercises.indices.contains(target) else {
            return
        }
        draft.days[dayIndex].exercises.swapAt(exerciseIndex, target)
    }

    private func supersetWithNext(dayIndex: Int, exerciseIndex: Int) {
        guard draft.days.indices.contains(dayIndex),
              draft.days[dayIndex].exercises.indices.contains(exerciseIndex),
              draft.days[dayIndex].exercises.indices.contains(exerciseIndex + 1) else {
            return
        }

        let current = draft.days[dayIndex].exercises[exerciseIndex].groupId
        let next = draft.days[dayIndex].exercises[exerciseIndex + 1].groupId
        let groupId = [current, next]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "A"

        draft.days[dayIndex].exercises[exerciseIndex].groupId = groupId
        draft.days[dayIndex].exercises[exerciseIndex + 1].groupId = groupId

        let sets = max(1, draft.days[dayIndex].exercises[exerciseIndex].sets)
        draft.days[dayIndex].exercises[exerciseIndex + 1].sets = sets
    }

    private func unlinkSuperset(dayIndex: Int, groupId: String) {
        guard draft.days.indices.contains(dayIndex) else { return }
        for exerciseIndex in draft.days[dayIndex].exercises.indices where draft.days[dayIndex].exercises[exerciseIndex].groupId == groupId {
            draft.days[dayIndex].exercises[exerciseIndex].groupId = nil
        }
    }

    private static func blankProgram() -> Program {
        Program(
            id: "ios-\(UUID().uuidString)",
            name: "",
            category: "Strength",
            level: "Beginner",
            goal: nil,
            coach: "",
            durationWeeks: 4,
            daysPerWeek: 1,
            accent: "#355E3B",
            summary: "",
            description: "",
            tags: nil,
            days: [blankDay(number: 1)],
            weekOverrides: nil,
            ownerId: nil,
            ownerName: nil,
            collaborative: false,
            version: nil
        )
    }

    private static func blankDay(number: Int) -> ProgramDay {
        ProgramDay(id: "day-\(UUID().uuidString)", name: "", focus: "", exercises: [])
    }

    private func exerciseKey(dayIndex: Int, exerciseIndex: Int) -> String {
        "\(draft.days[dayIndex].id)-\(exerciseIndex)"
    }

    private func exerciseDisplayName(for planned: PlannedExercise) -> String {
        if let name = planned.name, !name.isEmpty {
            return name
        }

        return store.allExercises.first(where: { $0.id == planned.exerciseId })?.name ?? ""
    }

    private func filteredExercises(query: String) -> [Exercise] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return []
        }

        return store.allExercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(trimmed) ||
                exercise.primaryMuscle.localizedCaseInsensitiveContains(trimmed) ||
                exercise.equipment.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func commitExerciseQuery(dayIndex: Int, exerciseIndex: Int) {
        let key = exerciseKey(dayIndex: dayIndex, exerciseIndex: exerciseIndex)
        commitExerciseQuery(for: key)
    }

    private func commitExerciseQuery(for key: String) {
        guard let indices = exerciseIndices(for: key),
              draft.days.indices.contains(indices.dayIndex),
              draft.days[indices.dayIndex].exercises.indices.contains(indices.exerciseIndex) else {
            return
        }

        let dayIndex = indices.dayIndex
        let exerciseIndex = indices.exerciseIndex
        let value = (exerciseQueries[key] ?? exerciseDisplayName(for: draft.days[dayIndex].exercises[exerciseIndex]))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let exact = store.allExercises.first(where: { $0.name.localizedCaseInsensitiveCompare(value) == .orderedSame }) {
            draft.days[dayIndex].exercises[exerciseIndex].exerciseId = exact.id
            draft.days[dayIndex].exercises[exerciseIndex].name = nil
            exerciseQueries[key] = exact.name
        } else if !value.isEmpty {
            draft.days[dayIndex].exercises[exerciseIndex].exerciseId = "custom-\(key)"
            draft.days[dayIndex].exercises[exerciseIndex].name = value
            exerciseQueries[key] = value
        }
    }

    private func exerciseIndices(for key: String) -> (dayIndex: Int, exerciseIndex: Int)? {
        for dayIndex in draft.days.indices {
            for exerciseIndex in draft.days[dayIndex].exercises.indices where exerciseKey(dayIndex: dayIndex, exerciseIndex: exerciseIndex) == key {
                return (dayIndex, exerciseIndex)
            }
        }
        return nil
    }
}

private extension View {
    func programEditorInputStyle(placeholder: String, isEmpty: Bool) -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .topLeading) {
                if isEmpty {
                    Text(placeholder)
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
}
