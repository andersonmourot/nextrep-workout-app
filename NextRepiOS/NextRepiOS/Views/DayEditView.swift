import SwiftUI

struct DayEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = AppStore()
    let program: Program
    let globalDayIndex: Int
    
    @State private var isEditMode: Bool = false
    @State private var editingWeek: Int = 1
    @State private var draftExercises: [DraftExercise] = []
    @State private var setLogs: [[SetLog]] = []
    @State private var isSaving: Bool = false
    @State private var saveSuccess: Bool = false
    @State private var showingNotesSheet: Bool = false
    @State private var selectedExerciseForNotes: PlannedExercise?
    @State private var editingCueExerciseId: String?
    @State private var editingCueText: String = ""
    @State private var showingExercisePicker: Bool = false
    @State private var addingExerciseIndex: Int = 0
    
    private var dayLocalIdx: Int { globalDayIndex % program.days.count }
    private var weekNum: Int { globalDayIndex / program.days.count + 1 }
    private var day: ProgramDay? { program.days[safe: dayLocalIdx] }
    
    private var isProgramEditable: Bool {
        program.isCustom == true && (program.isOwner == true || program.collaborative == true)
    }
    
    private var hasCompletedSet: Bool {
        setLogs.flatMap { $0 }.contains { $0.completed }
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                topBar
                
                ScrollView {
                    VStack(spacing: 16) {
                        if isEditMode {
                            editModeContent
                        } else {
                            loggingModeContent
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingNotesSheet) {
            if let exercise = selectedExerciseForNotes {
                NotesSheetView(
                    exercise: exercise,
                    note: store.appData.exerciseNotes[exercise.exerciseId] ?? "",
                    onSave: { newNote in
                        Task {
                            await store.updateExerciseNote(exerciseId: exercise.exerciseId, note: newNote)
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(
                exercises: store.allExercises,
                onSelect: { exercise in
                    addExerciseFromLibrary(exercise: exercise)
                    showingExercisePicker = false
                }
            )
        }
        .task {
            await loadExercises()
            loadSetLogs()
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Back button (icon only)
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(Theme.text)
            }
            
            Spacer()
            
            // Header
            VStack(spacing: 2) {
                Text("Week \(weekNum) · Day \(dayLocalIdx + 1)")
                    .font(Theme.body(11))
                    .foregroundColor(program.accent ?? Theme.accent)
                    .tracking(1)
                
                if let day = day {
                    Text(day.name)
                        .font(Theme.display(20))
                        .foregroundColor(Theme.text)
                    
                    Text(day.focus)
                        .font(Theme.body(12))
                        .foregroundColor(Theme.textDim)
                }
            }
            
            Spacer()
            
            // Edit button (only when editable)
            if isProgramEditable {
                Button(action: {
                    enterEditMode()
                }) {
                    Text(isEditMode ? "Cancel" : "Edit")
                        .font(Theme.body(14))
                        .foregroundColor(isEditMode ? Theme.textDim : program.accent ?? Theme.accent)
                }
            } else {
                // Spacer to balance layout
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.clear)
            }
        }
        .padding()
        .background(Theme.surface)
    }
    
    // MARK: - Logging Mode Content
    
    private var loggingModeContent: some View {
        VStack(spacing: 16) {
            if let day = day {
                ForEach(Array(day.exercises.enumerated()), id: \.element.id) { index, exercise in
                    exerciseCard(exercise: exercise, index: index)
                }
                
                // Save button
                if hasCompletedSet {
                    Button(action: saveWorkout) {
                        Text(isSaving ? "Saving..." : saveButtonText)
                            .font(Theme.body(14))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(saveSuccess || isSaving ? Theme.textDim : program.accent ?? Theme.accent)
                            .cornerRadius(12)
                    }
                    .disabled(isSaving || saveSuccess)
                }
            }
        }
    }
    
    private var saveButtonText: String {
        let existingLog = existingLogForSlot
        return existingLog != nil ? "Update Workout" : "Save Workout"
    }
    
    private var existingLogForSlot: WorkoutLog? {
        let slots = programLogSlots(program: program, logs: store.appData.logs)
        return slots[safe: globalDayIndex]
    }
    
    // MARK: - Edit Mode Content
    
    private var editModeContent: some View {
        VStack(spacing: 16) {
            // Edit this day card
            VStack(alignment: .leading, spacing: 12) {
                Text("Edit this day")
                    .font(Theme.body(16))
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.text)
                
                let scopeNote = editingWeek == 1 
                    ? "Week 1 edits the whole program"
                    : "From Week \(editingWeek) onward"
                Text(scopeNote)
                    .font(Theme.body(12))
                    .foregroundColor(Theme.textDim)
                
                // Week selector
                Picker("Week", selection: $editingWeek) {
                    ForEach(1...12, id: \.self) { week in
                        Text("Week \(week)").tag(week)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(16)
            .background(Theme.surface)
            .cornerRadius(16)
            
            // Exercise drafts
            ForEach(Array(draftExercises.enumerated()), id: \.id) { index, draft in
                draftExerciseCard(draft: draft, index: index)
            }
            
            // Add exercise button
            Button(action: {
                addingExerciseIndex = draftExercises.count
                showingExercisePicker = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add exercise")
                }
                .font(Theme.body(14))
                .foregroundColor(program.accent ?? Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundColor(program.accent ?? Theme.accent)
                )
            }
            
            // Footer buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    exitEditMode()
                }
                .font(Theme.body(14))
                .foregroundColor(Theme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.textDim, lineWidth: 1)
                )
                
                Button("Save") {
                    saveDayEdit()
                }
                .font(Theme.body(14))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(program.accent ?? Theme.accent)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Exercise Card (Logging Mode)
    
    private func exerciseCard(exercise: PlannedExercise, index: Int) -> some View {
        let sets = setLogs[safe: index] ?? []
        
        return VStack(alignment: .leading, spacing: 12) {
            // Eyebrow
            Text("Exercise \(index + 1) of \(day?.exercises.count ?? 0)")
                .font(Theme.body(10))
                .foregroundColor(Theme.placeholder)
            
            // Title
            Text(exerciseLabel(for: exercise))
                .font(Theme.body(18))
                .fontWeight(.semibold)
                .foregroundColor(Theme.text)
                .tracking(1)
            
            // Subtitle
            Text("\(exercise.sets) sets × \(exercise.reps) reps")
                .font(Theme.body(12))
                .foregroundColor(Theme.textDim)
            
            // Cue line
            if let cue = store.appData.exerciseSubheaders[exercise.exerciseId], !cue.isEmpty {
                Button(action: {
                    editingCueExerciseId = exercise.exerciseId
                    editingCueText = cue
                }) {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Theme.accent)
                            .frame(width: 4)
                        
                        Text(cue)
                            .font(Theme.body(12))
                            .foregroundColor(Theme.accent)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Trailing buttons
            HStack(spacing: 8) {
                if store.appData.exerciseSubheaders[exercise.exerciseId] == nil || store.appData.exerciseSubheaders[exercise.exerciseId]?.isEmpty == true {
                    Button(action: {
                        editingCueExerciseId = exercise.exerciseId
                        editingCueText = ""
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                            .foregroundColor(Theme.textDim)
                    }
                }
                
                notesButton(exercise: exercise)
                infoButton
            }
            
            // Inline cue editor
            if let exerciseId = editingCueExerciseId, exerciseId == exercise.exerciseId {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(width: 4)
                    
                    TextField("Add a cue...", text: $editingCueText)
                        .font(Theme.body(12))
                        .foregroundColor(Theme.accent)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            Task {
                                await store.updateExerciseCue(exerciseId: exerciseId, cue: editingCueText)
                                editingCueExerciseId = nil
                                editingCueText = ""
                            }
                        }
                }
                .padding(.vertical, 8)
                .background(Theme.surface2)
                .cornerRadius(8)
            }
            
            // Sets table
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Set")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.placeholder)
                        .frame(width: 40, alignment: .leading)
                    Spacer()
                    Text("Weight (\(store.unit))")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.placeholder)
                    Spacer()
                    Text("Reps")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.placeholder)
                    Spacer()
                    Text("Done")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.placeholder)
                        .frame(width: 50, alignment: .trailing)
                }
                .padding(.vertical, 8)
                
                // Set rows
                ForEach(0..<exercise.sets, id: \.self) { setIndex in
                    loggingSetRow(exercise: exercise, exerciseIndex: index, setIndex: setIndex, setLog: sets[safe: setIndex])
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func loggingSetRow(exercise: PlannedExercise, exerciseIndex: Int, setIndex: Int, setLog: SetLog?) -> some View {
        let isDone = setLog?.completed ?? false
        let weight = setLog?.weight ?? 0
        let reps = setLog?.reps ?? 0
        
        return HStack {
            // Set number badge
            Text("\(setIndex + 1)")
                .font(Theme.body(12))
                .foregroundColor(isDone ? .white : Theme.text)
                .frame(width: 40)
                .padding(.vertical, 6)
                .background(isDone ? Theme.accent : Theme.surface2)
                .cornerRadius(8)
            
            Spacer()
            
            // Weight stepper
            HStack(spacing: 4) {
                Button(action: {
                    updateSetLog(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: max(0, weight - 5), reps: reps, completed: isDone)
                }) {
                    Image(systemName: "minus")
                        .font(.caption)
                        .foregroundColor(Theme.text)
                }
                
                Text(String(format: "%.0f", weight))
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
                    .frame(width: 40)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    updateSetLog(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight + 5, reps: reps, completed: isDone)
                }) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundColor(Theme.text)
                }
            }
            
            Spacer()
            
            // Reps stepper
            HStack(spacing: 4) {
                Button(action: {
                    updateSetLog(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight, reps: max(0, reps - 1), completed: isDone)
                }) {
                    Image(systemName: "minus")
                        .font(.caption)
                        .foregroundColor(Theme.text)
                }
                
                Text("\(reps)")
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
                    .frame(width: 30)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    updateSetLog(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight, reps: reps + 1, completed: isDone)
                }) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundColor(Theme.text)
                }
            }
            
            Spacer()
            
            // Done toggle
            Button(action: {
                updateSetLog(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight, reps: reps, completed: !isDone)
            }) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isDone ? Theme.accent : Theme.textDim)
            }
            .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .background(isDone ? Theme.accent.opacity(0.1) : Color.clear)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Draft Exercise Card (Edit Mode)
    
    private func draftExerciseCard(draft: DraftExercise, index: Int) -> some View {
        let canMoveUp = index > 0
        let canMoveDown = index < draftExercises.count - 1
        let canDelete = draftExercises.count > 1
        
        return VStack(alignment: .leading, spacing: 12) {
            // Name field with caption
            VStack(alignment: .leading, spacing: 4) {
                TextField("Exercise name", text: Binding(
                    get: { draft.name },
                    set: { draft.name = $0 }
                ))
                .font(Theme.body(14))
                .foregroundColor(Theme.text)
                .textFieldStyle(.roundedBorder)
                
                if let libraryExercise = store.allExercises.first(where: { $0.name.lowercased() == draft.name.lowercased() }) {
                    Text("\(libraryExercise.primaryMuscle) · \(libraryExercise.equipment)")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                } else {
                    Text("Custom exercise")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                }
            }
            
            // Action buttons
            HStack(spacing: 8) {
                // Reorder
                Button(action: { moveExercise(index: index, direction: -1) }) {
                    Image(systemName: "arrow.up")
                        .font(.caption)
                        .foregroundColor(canMoveUp ? Theme.text : Theme.textDim)
                }
                .disabled(!canMoveUp)
                
                Button(action: { moveExercise(index: index, direction: 1) }) {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(canMoveDown ? Theme.text : Theme.textDim)
                }
                .disabled(!canMoveDown)
                
                Spacer()
                
                // Cue button (placeholder)
                Button(action: {}) {
                    Image(systemName: "list.bullet")
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                }
                
                // Delete
                Button(action: { deleteExercise(index: index) }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(canDelete ? .red : Theme.textDim)
                }
                .disabled(!canDelete)
            }
            
            // 3-up row: Sets / Reps / Rest
            HStack(spacing: 8) {
                // Sets
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sets")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.placeholder)
                    
                    TextField("3", value: Binding(
                        get: { draft.sets },
                        set: { draft.sets = $0 }
                    ), format: .number)
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                }
                
                // Reps
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.placeholder)
                    
                    TextField("8-12", text: Binding(
                        get: { draft.reps },
                        set: { draft.reps = $0 }
                    ))
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
                    .textFieldStyle(.roundedBorder)
                }
                
                // Rest
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest (s)")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.placeholder)
                    
                    TextField("90", value: Binding(
                        get: { draft.restSec },
                        set: { draft.restSec = $0 }
                    ), format: .number)
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Functions
    
    private func loadExercises() async {
        await store.loadCatalog()
        if let day = day {
            draftExercises = day.exercises.map { exercise in
                DraftExercise(
                    id: UUID().uuidString,
                    exerciseId: exercise.exerciseId,
                    name: exercise.name ?? "",
                    sets: exercise.sets,
                    reps: exercise.reps,
                    restSec: exercise.restSec,
                    notes: exercise.notes
                )
            }
        }
    }
    
    private func loadSetLogs() {
        guard let day = day else { return }
        
        // Try to load from existing log
        if let existingLog = existingLogForSlot {
            setLogs = existingLog.exercises.map { exerciseLog in
                exerciseLog.sets
            }
        } else {
            // Load from day template
            setLogs = day.exercises.map { exercise in
                let repCount = parseReps(exercise.reps)
                return (0..<exercise.sets).map { _ in
                    SetLog(id: uid(), weight: 0, reps: repCount, completed: false)
                }
            }
        }
    }
    
    private func parseReps(_ reps: String) -> Int {
        let numericPrefix = reps.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(numericPrefix) ?? 8
    }
    
    private func updateSetLog(exerciseIndex: Int, setIndex: Int, weight: Double, reps: Int, completed: Bool) {
        while setLogs.count <= exerciseIndex {
            setLogs.append([])
        }
        while setLogs[exerciseIndex].count <= setIndex {
            setLogs[exerciseIndex].append(SetLog(id: uid(), weight: 0, reps: 0, completed: false))
        }
        setLogs[exerciseIndex][setIndex] = SetLog(id: uid(), weight: weight, reps: reps, completed: completed)
    }
    
    private func notesButton(exercise: PlannedExercise) -> some View {
        Button(action: {
            selectedExerciseForNotes = exercise
            showingNotesSheet = true
        }) {
            Image(systemName: "note.text")
                .font(.caption)
                .foregroundColor(Theme.textDim)
        }
    }
    
    private var infoButton: some View {
        Button(action: {}) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundColor(Theme.textDim)
        }
    }
    
    private func enterEditMode() {
        isEditMode = true
        editingWeek = weekNum
    }
    
    private func exitEditMode() {
        isEditMode = false
        loadSetLogs() // Reset to original state
    }
    
    private func moveExercise(index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < draftExercises.count else { return }
        draftExercises.swapAt(index, newIndex)
    }
    
    private func deleteExercise(index: Int) {
        guard draftExercises.count > 1 else { return }
        draftExercises.remove(at: index)
    }
    
    private func addExerciseFromLibrary(exercise: Exercise) {
        let draft = DraftExercise(
            id: UUID().uuidString,
            exerciseId: exercise.id,
            name: exercise.name,
            sets: 3,
            reps: "8-12",
            restSec: 90,
            notes: nil
        )
        draftExercises.append(draft)
    }
    
    private func saveWorkout() {
        isSaving = true
        
        Task {
            var exerciseLogs: [ExerciseLog] = []
            var totalVolume: Double = 0
            
            for (exerciseIndex, exerciseSets) in setLogs.enumerated() {
                var completedSets: [SetLog] = []
                for setLog in exerciseSets {
                    if setLog.completed || setLog.weight > 0 {
                        completedSets.append(setLog)
                        totalVolume += setLog.weight * Double(setLog.reps)
                    }
                }
                
                let exerciseId = day?.exercises[safe: exerciseIndex]?.exerciseId ?? ""
                
                if !completedSets.isEmpty {
                    exerciseLogs.append(ExerciseLog(id: uid(), exerciseId: exerciseId, sets: completedSets))
                }
            }
            
            let today = ISO8601DateFormatter().string(from: Date())
            
            let log = WorkoutLog(
                id: UUID().uuidString,
                programId: program.id,
                dayId: day?.id ?? "",
                week: weekNum,
                date: today,
                totalVolume: totalVolume,
                exercises: exerciseLogs
            )
            
            await store.addLog(log)
            
            await MainActor.run {
                isSaving = false
                saveSuccess = true
                
                // Reset success state after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    saveSuccess = false
                }
            }
        }
    }
    
    private func saveDayEdit() {
        // Validation
        guard !draftExercises.isEmpty else { return }
        for draft in draftExercises {
            guard !draft.name.isEmpty else { return }
        }
        
        // Convert drafts to PlannedExercise
        let updatedExercises = draftExercises.map { draft in
            PlannedExercise(
                exerciseId: draft.exerciseId.isEmpty ? UUID().uuidString : draft.exerciseId,
                name: draft.name.isEmpty ? nil : draft.name,
                sets: draft.sets,
                reps: draft.reps,
                restSec: draft.restSec,
                notes: draft.notes,
                groupId: nil
            )
        }
        
        // Apply override
        let updatedProgram = withDayOverride(program: program, dayId: day?.id ?? "", weekNum: editingWeek, exercises: updatedExercises)
        
        Task {
            // Update program
            if program.isOwner == true || program.collaborative == true {
                await store.apiUpsertProgram(updatedProgram)
            }
            await store.updateProgram(updatedProgram)
            
            await MainActor.run {
                exitEditMode()
            }
        }
    }
}

// MARK: - Draft Exercise

struct DraftExercise: Identifiable {
    let id: String
    var exerciseId: String
    var name: String
    var sets: Int
    var reps: String
    var restSec: Int
    var notes: String?
}

// MARK: - Exercise Picker View

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void
    
    @State private var searchText: String = ""
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("Search exercises...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                // Exercise list
                List(filteredExercises) { exercise in
                    Button(action: {
                        onSelect(exercise)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(Theme.body(14))
                                .foregroundColor(Theme.text)
                            
                            Text("\(exercise.primaryMuscle) · \(exercise.equipment)")
                                .font(Theme.body(10))
                                .foregroundColor(Theme.textDim)
                        }
                    }
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Functions (to be moved to Utils.swift)

func programLogSlots(program: Program, logs: [WorkoutLog]) -> [WorkoutLog?] {
    let weeks = 12 // Default to 12 weeks
    let totalDays = program.days.count * weeks
    var slots: [WorkoutLog?] = Array(repeating: nil, count: totalDays)
    
    for log in logs where log.programId == program.id {
        if let dayIndex = program.days.firstIndex(where: { $0.id == log.dayId }) {
            let globalIndex = dayIndex + ((log.week ?? 1) - 1) * program.days.count
            if globalIndex < totalDays {
                slots[globalIndex] = log
            }
        }
    }
    
    return slots
}

func withDayOverride(program: Program, dayId: String, weekNum: Int, exercises: [PlannedExercise]) -> Program {
    // This is a simplified version - in a real implementation, you'd need to handle
    // week-specific overrides properly
    var updatedProgram = program
    if let dayIndex = updatedProgram.days.firstIndex(where: { $0.id == dayId }) {
        updatedProgram.days[dayIndex].exercises = exercises
    }
    return updatedProgram
}