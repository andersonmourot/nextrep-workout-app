import SwiftUI

struct ProgramEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Program
    @State private var showingDeleteConfirm = false
    @State private var saveMessage: String?
    @State private var isSaving = false
    @State private var exerciseQueries: [String: String] = [:]
    @State private var collapsedDayIds: Set<String> = []
    @State private var selectedWeek = 1
    @State private var showingCopyWeekConfirm = false
    @FocusState private var focusedExerciseKey: String?
    private let catalogMode: Bool
    private let isEditingExistingProgram: Bool

    private let categories = ["Bodybuilding", "Strength", "HIIT", "Powerlifting", "Functional", "Bodyweight"]
    private let levels = ["Beginner", "Intermediate", "Advanced"]
    private let accentColors = ["#e9b949", "#b91c1c", "#3b82f6", "#22c55e", "#a855f7", "#f97316", "#14b8a6", "#ec4899"]

    init(program: Program? = nil, catalogMode: Bool = false) {
        _draft = State(initialValue: program ?? Self.blankProgram())
        self.catalogMode = catalogMode
        self.isEditingExistingProgram = program != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let saveMessage {
                    Text(saveMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(saveMessage.contains("saved") ? Theme.accentLight : .red.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                }
                basics
                daysEditor
            }
            .padding(16)
            .padding(.bottom, 92)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(draft.name.isEmpty ? "New Program" : draft.name)
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .safeAreaInset(edge: .bottom) {
            saveBar
        }
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
            Text("This moves the custom program to Trash. You can restore it from the Programs screen.")
        }
        .alert("Copy Week to All Weeks?", isPresented: $showingCopyWeekConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Copy", role: .destructive) {
                copySelectedWeekToAllWeeks()
            }
        } message: {
            Text("This makes every week match Week \(currentWeek) and clears week-specific edits.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(headerTitle)
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text(catalogMode ? "Edit the built-in program catalog for every user." : "Build a simple custom plan you can run natively.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
    }

    private var headerTitle: String {
        if catalogMode {
            return isEditingExistingProgram ? "Edit Catalog Program" : "New Catalog Program"
        }
        return store.isCustomProgram(draft) ? "Edit Program" : "Create Program"
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

            weekControls

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

    private var weekControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Button {
                    selectedWeek = max(1, currentWeek - 1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(currentWeek <= 1)

                Text("Week \(currentWeek) / \(totalWeeks)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity)

                Button {
                    selectedWeek = min(totalWeeks, currentWeek + 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(currentWeek >= totalWeeks)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Theme.accentLight)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 8) {
                Text(currentWeek == 1 ? "Editing base week" : "Editing week-specific plan")
                    .font(.caption)
                    .foregroundStyle(Theme.textFaint)

                Spacer()

                if totalWeeks > 1 {
                    Button("Copy Week to All") {
                        showingCopyWeekConfirm = true
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.accentLight)
                }
            }
        }
    }

    private func dayEditor(dayIndex: Int) -> some View {
        let dayId = draft.days[dayIndex].id
        let isCollapsed = collapsedDayIds.contains(dayId)
        let day = resolvedDay(dayIndex: dayIndex)

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
                    removeDay(at: dayIndex)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.red.opacity(0.85))
            }

            if !isCollapsed {
                field("Day Name", text: Binding(
                    get: { resolvedDay(dayIndex: dayIndex).name },
                    set: { newValue in
                        updateDay(dayIndex: dayIndex) { day in
                            day.name = newValue
                        }
                    }
                ))
                field("Focus", text: Binding(
                    get: { resolvedDay(dayIndex: dayIndex).focus },
                    set: { newValue in
                        updateDay(dayIndex: dayIndex) { day in
                            day.focus = newValue
                        }
                    }
                ))

                ForEach(day.exercises.indices, id: \.self) { exerciseIndex in
                    exerciseEditor(dayIndex: dayIndex, exerciseIndex: exerciseIndex)
                }

                Button {
                    addExercise(dayIndex: dayIndex)
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
                .buttonStyle(GhostButtonStyle())
            } else {
                Text("\(day.exercises.count) exercise\(day.exercises.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }
        }
        .cardStyle()
    }

    private func exerciseEditor(dayIndex: Int, exerciseIndex: Int) -> some View {
        let planned = plannedExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) ?? blankPlannedExercise()

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
                    removeExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.red.opacity(0.85))
            }

            exerciseSelector(dayIndex: dayIndex, exerciseIndex: exerciseIndex)

            numericField(
                "Sets",
                value: Binding(
                    get: { plannedExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex)?.sets ?? planned.sets },
                    set: { newValue in
                        updateExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) { exercise in
                            exercise.sets = newValue
                        }
                    }
                ),
                emptyWhenZero: true
            )
            field("Reps", text: Binding(
                get: { plannedExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex)?.reps ?? planned.reps },
                set: { newValue in
                    updateExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) { exercise in
                        exercise.reps = newValue
                    }
                }
            ))
            numericField(
                "Rest",
                value: Binding(
                    get: { plannedExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex)?.restSec ?? planned.restSec },
                    set: { newValue in
                        updateExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) { exercise in
                            exercise.restSec = newValue
                        }
                    }
                ),
                emptyWhenZero: true
            )
            field("Superset Group (optional)", text: Binding(
                get: { plannedExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex)?.groupId ?? "" },
                set: { newValue in
                    updateExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) { exercise in
                        let clean = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        exercise.groupId = clean.isEmpty ? nil : clean
                    }
                }
            ))
            field("Notes", text: Binding(
                get: { plannedExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex)?.notes ?? "" },
                set: { newValue in
                    updateExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) { exercise in
                        exercise.notes = newValue.isEmpty ? nil : newValue
                    }
                }
            ))

            if !planned.exerciseId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ExerciseNotesCuePanel(
                    exerciseId: planned.exerciseId,
                    exerciseName: exerciseDisplayName(for: planned)
                )
            }
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
            .disabled(exerciseIndex >= resolvedDay(dayIndex: dayIndex).exercises.count - 1)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(Theme.textDim)
        .frame(width: 28)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func exerciseSelector(dayIndex: Int, exerciseIndex: Int) -> some View {
        let key = exerciseKey(dayIndex: dayIndex, exerciseIndex: exerciseIndex)
        let planned = plannedExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) ?? blankPlannedExercise()
        let query = exerciseQueries[key] ?? exerciseDisplayName(for: planned)
        let isFocused = focusedExerciseKey == key
        let matches = isFocused ? Array(filteredExercises(query: query).prefix(5)) : []

        return VStack(alignment: .leading, spacing: 8) {
            TextField("", text: Binding(
                get: { exerciseQueries[key] ?? exerciseDisplayName(for: plannedExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) ?? planned) },
                set: { newValue in
                    exerciseQueries[key] = newValue
                    if let exact = store.allExercises.first(where: { $0.name.localizedCaseInsensitiveCompare(newValue) == .orderedSame }) {
                        updateExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) { exercise in
                            exercise.exerciseId = exact.id
                            exercise.name = nil
                        }
                    } else {
                        updateExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) { exercise in
                            exercise.exerciseId = "custom-\(key)"
                            exercise.name = newValue
                        }
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
                            updateExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) { planned in
                                planned.exerciseId = exercise.id
                                planned.name = nil
                            }
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

    private var totalWeeks: Int {
        max(1, draft.durationWeeks)
    }

    private var currentWeek: Int {
        min(max(1, selectedWeek), totalWeeks)
    }

    private func resolvedDay(dayIndex: Int) -> ProgramDay {
        domainResolveProgramDay(draft, dayIndex: dayIndex, week: currentWeek) ?? draft.days[dayIndex]
    }

    private func plannedExercise(dayIndex: Int, exerciseIndex: Int) -> PlannedExercise? {
        let day = resolvedDay(dayIndex: dayIndex)
        guard day.exercises.indices.contains(exerciseIndex) else {
            return nil
        }
        return day.exercises[exerciseIndex]
    }

    private func updateDay(dayIndex: Int, mutate: (inout ProgramDay) -> Void) {
        guard draft.days.indices.contains(dayIndex) else { return }
        var day = resolvedDay(dayIndex: dayIndex)
        mutate(&day)
        commitDay(day, dayIndex: dayIndex)
    }

    private func commitDay(_ day: ProgramDay, dayIndex: Int) {
        guard draft.days.indices.contains(dayIndex) else { return }
        let baseId = draft.days[dayIndex].id
        var normalized = day
        normalized.id = baseId

        if currentWeek <= 1 {
            draft.days[dayIndex] = normalized
            return
        }

        var overrides = draft.weekOverrides ?? [:]
        var list = overrides[baseId] ?? []
        list.removeAll { $0.fromWeek == currentWeek }
        list.append(ProgramWeekOverride(fromWeek: currentWeek, day: normalized))
        list.sort { $0.fromWeek < $1.fromWeek }
        overrides[baseId] = list
        draft.weekOverrides = overrides
    }

    private func updateExercise(dayIndex: Int, exerciseIndex: Int, mutate: (inout PlannedExercise) -> Void) {
        updateDay(dayIndex: dayIndex) { day in
            guard day.exercises.indices.contains(exerciseIndex) else { return }
            mutate(&day.exercises[exerciseIndex])
        }
    }

    private func addExercise(dayIndex: Int) {
        updateDay(dayIndex: dayIndex) { day in
            day.exercises.append(blankPlannedExercise())
        }
    }

    private func removeExercise(dayIndex: Int, exerciseIndex: Int) {
        updateDay(dayIndex: dayIndex) { day in
            guard day.exercises.indices.contains(exerciseIndex) else { return }
            day.exercises.remove(at: exerciseIndex)
        }
    }

    private func removeDay(at index: Int) {
        guard draft.days.indices.contains(index) else { return }
        let id = draft.days[index].id
        draft.days.remove(at: index)
        draft.daysPerWeek = max(1, draft.days.count)
        draft.weekOverrides?[id] = nil
        if draft.weekOverrides?.isEmpty == true {
            draft.weekOverrides = nil
        }
        selectedWeek = min(selectedWeek, totalWeeks)
    }

    private func copySelectedWeekToAllWeeks() {
        guard !draft.days.isEmpty else { return }
        let baseIds = draft.days.map(\.id)
        let copiedDays = draft.days.indices.map { index in
            var day = resolvedDay(dayIndex: index)
            day.id = baseIds[index]
            return day
        }
        draft.days = copiedDays
        draft.weekOverrides = nil
        selectedWeek = 1
    }

    private var saveBar: some View {
        VStack(spacing: 10) {
            Button {
                Task { await saveProgram() }
            } label: {
                Text(isSaving ? "Saving..." : catalogMode ? "Save Catalog Program" : "Save Program")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canSave || isSaving)
            .opacity(!canSave || isSaving ? 0.5 : 1)

            if !catalogMode && store.isCustomProgram(draft) {
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Text("Delete Program")
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !draft.days.isEmpty
    }

    private func saveProgram() async {
        saveMessage = nil
        normalizeDraft()
        guard canSave else {
            saveMessage = "Give the program a name and at least one day."
            return
        }

        if catalogMode {
            await saveCatalogProgram()
        } else {
            store.saveCustomProgram(draft)
            dismiss()
        }
    }

    private func saveCatalogProgram() async {
        let previousCatalog = store.catalog
        isSaving = true
        draft.version = Int(Date().timeIntervalSince1970 * 1000)
        draft.ownerId = nil
        draft.ownerName = nil
        draft.collaborative = false
        store.catalog.programs.removeAll { $0.id == draft.id }
        store.catalog.programs.append(draft)
        store.catalog.programs.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let ok = await store.adminPublishCatalog()
        isSaving = false

        if ok {
            saveMessage = "\(draft.name) saved to catalog."
            dismiss()
        } else {
            store.catalog = previousCatalog
            saveMessage = store.authError ?? "Could not save catalog program."
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
            draft.days[dayIndex].name = draft.days[dayIndex].name.trimmingCharacters(in: .whitespacesAndNewlines)
            draft.days[dayIndex].focus = draft.days[dayIndex].focus.trimmingCharacters(in: .whitespacesAndNewlines)
            for exerciseIndex in draft.days[dayIndex].exercises.indices {
                draft.days[dayIndex].exercises[exerciseIndex].sets = max(1, draft.days[dayIndex].exercises[exerciseIndex].sets)
                draft.days[dayIndex].exercises[exerciseIndex].restSec = max(0, draft.days[dayIndex].exercises[exerciseIndex].restSec)
            }
        }

        if var overrides = draft.weekOverrides {
            for (dayId, list) in overrides {
                let normalizedList = list.map { override in
                    var updated = override
                    updated.day.name = updated.day.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    updated.day.focus = updated.day.focus.trimmingCharacters(in: .whitespacesAndNewlines)
                    for exerciseIndex in updated.day.exercises.indices {
                        updated.day.exercises[exerciseIndex].sets = max(1, updated.day.exercises[exerciseIndex].sets)
                        updated.day.exercises[exerciseIndex].restSec = max(0, updated.day.exercises[exerciseIndex].restSec)
                    }
                    return updated
                }
                .filter { $0.fromWeek > 1 && $0.fromWeek <= totalWeeks }

                if normalizedList.isEmpty {
                    overrides.removeValue(forKey: dayId)
                } else {
                    overrides[dayId] = normalizedList
                }
            }
            draft.weekOverrides = overrides.isEmpty ? nil : overrides
        }
    }

    private func blankPlannedExercise() -> PlannedExercise {
        PlannedExercise(exerciseId: "", name: nil, sets: 0, reps: "", restSec: 0, notes: nil, groupId: nil)
    }

    private func duplicateDay(at index: Int) {
        guard draft.days.indices.contains(index) else { return }
        var copy = resolvedDay(dayIndex: index)
        copy.id = "day-\(UUID().uuidString)"
        copy.name = copy.name.isEmpty ? "Day \(draft.days.count + 1)" : "\(copy.name) Copy"
        draft.days.insert(copy, at: index + 1)
        draft.daysPerWeek = max(1, draft.days.count)
    }

    private func duplicateExercise(dayIndex: Int, exerciseIndex: Int) {
        guard draft.days.indices.contains(dayIndex),
              resolvedDay(dayIndex: dayIndex).exercises.indices.contains(exerciseIndex) else {
            return
        }

        updateDay(dayIndex: dayIndex) { day in
            guard day.exercises.indices.contains(exerciseIndex) else { return }
            let copy = day.exercises[exerciseIndex]
            day.exercises.insert(copy, at: exerciseIndex + 1)
        }
    }

    private func moveExercise(dayIndex: Int, exerciseIndex: Int, direction: Int) {
        guard draft.days.indices.contains(dayIndex) else { return }
        let target = exerciseIndex + direction
        updateDay(dayIndex: dayIndex) { day in
            guard day.exercises.indices.contains(exerciseIndex),
                  day.exercises.indices.contains(target) else {
                return
            }
            day.exercises.swapAt(exerciseIndex, target)
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
              resolvedDay(dayIndex: indices.dayIndex).exercises.indices.contains(indices.exerciseIndex) else {
            return
        }

        let dayIndex = indices.dayIndex
        let exerciseIndex = indices.exerciseIndex
        let planned = plannedExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) ?? blankPlannedExercise()
        let value = (exerciseQueries[key] ?? exerciseDisplayName(for: planned))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let exact = store.allExercises.first(where: { $0.name.localizedCaseInsensitiveCompare(value) == .orderedSame }) {
            updateExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) { exercise in
                exercise.exerciseId = exact.id
                exercise.name = nil
            }
            exerciseQueries[key] = exact.name
        } else if !value.isEmpty {
            updateExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex) { exercise in
                exercise.exerciseId = "custom-\(key)"
                exercise.name = value
            }
            exerciseQueries[key] = value
        }
    }

    private func exerciseIndices(for key: String) -> (dayIndex: Int, exerciseIndex: Int)? {
        for dayIndex in draft.days.indices {
            for exerciseIndex in resolvedDay(dayIndex: dayIndex).exercises.indices where exerciseKey(dayIndex: dayIndex, exerciseIndex: exerciseIndex) == key {
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
