import SwiftUI

@Observable
class ProgramEditorViewModel {
    var program: Program
    var isEditing = false
    
    init(program: Program) {
        self.program = program
    }
    
    func updateProgramName(_ name: String) {
        program.name = name
    }
    
    func updateProgramCoach(_ coach: String) {
        program.coach = coach
    }
    
    func updateProgramCategory(_ category: String) {
        program.category = category
    }
    
    func updateProgramLevel(_ level: String) {
        program.level = level
    }
    
    func updateDurationWeeks(_ weeks: Int) {
        program.durationWeeks = weeks
    }
    
    func updateDaysPerWeek(_ days: Int) {
        program.daysPerWeek = days
    }
    
    func addDay() {
        let newDay = ProgramDay(
            id: UUID().uuidString,
            name: "Day \(program.days.count + 1)",
            focus: "New Focus",
            exercises: []
        )
        program.days.append(newDay)
    }
    
    func deleteDay(_ day: ProgramDay) {
        program.days.removeAll { $0.id == day.id }
    }
    
    func updateDay(_ day: ProgramDay, name: String) {
        if let index = program.days.firstIndex(where: { $0.id == day.id }) {
            program.days[index].name = name
        }
    }
    
    func updateDayFocus(_ day: ProgramDay, focus: String) {
        if let index = program.days.firstIndex(where: { $0.id == day.id }) {
            program.days[index].focus = focus
        }
    }
    
    func addExercise(to day: ProgramDay) {
        if let index = program.days.firstIndex(where: { $0.id == day.id }) {
            let newExercise = PlannedExercise(
                exerciseId: UUID().uuidString,
                name: "New Exercise",
                sets: 3,
                reps: "10-12",
                restSec: 60,
                notes: nil
            )
            program.days[index].exercises.append(newExercise)
        }
    }
    
    func deleteExercise(_ exercise: PlannedExercise, from day: ProgramDay) {
        if let dayIndex = program.days.firstIndex(where: { $0.id == day.id }) {
            program.days[dayIndex].exercises.removeAll { $0.exerciseId == exercise.exerciseId }
        }
    }
    
    func updateExercise(_ exercise: PlannedExercise, in day: ProgramDay, name: String) {
        if let dayIndex = program.days.firstIndex(where: { $0.id == day.id }),
           let exerciseIndex = program.days[dayIndex].exercises.firstIndex(where: { $0.exerciseId == exercise.exerciseId }) {
            program.days[dayIndex].exercises[exerciseIndex].name = name
        }
    }
    
    func updateExerciseSets(_ exercise: PlannedExercise, in day: ProgramDay, sets: Int) {
        if let dayIndex = program.days.firstIndex(where: { $0.id == day.id }),
           let exerciseIndex = program.days[dayIndex].exercises.firstIndex(where: { $0.exerciseId == exercise.exerciseId }) {
            program.days[dayIndex].exercises[exerciseIndex].sets = sets
        }
    }
    
    func updateExerciseReps(_ exercise: PlannedExercise, in day: ProgramDay, reps: String) {
        if let dayIndex = program.days.firstIndex(where: { $0.id == day.id }),
           let exerciseIndex = program.days[dayIndex].exercises.firstIndex(where: { $0.exerciseId == exercise.exerciseId }) {
            program.days[dayIndex].exercises[exerciseIndex].reps = reps
        }
    }
    
    func updateExerciseRest(_ exercise: PlannedExercise, in day: ProgramDay, restSec: Int) {
        if let dayIndex = program.days.firstIndex(where: { $0.id == day.id }),
           let exerciseIndex = program.days[dayIndex].exercises.firstIndex(where: { $0.exerciseId == exercise.exerciseId }) {
            program.days[dayIndex].exercises[exerciseIndex].restSec = restSec
        }
    }
    
    func updateExerciseNotes(_ exercise: PlannedExercise, in day: ProgramDay, notes: String) {
        if let dayIndex = program.days.firstIndex(where: { $0.id == day.id }),
           let exerciseIndex = program.days[dayIndex].exercises.firstIndex(where: { $0.exerciseId == exercise.exerciseId }) {
            program.days[dayIndex].exercises[exerciseIndex].notes = notes.isEmpty ? nil : notes
        }
    }
    
    func linkExercises(_ exercise1: PlannedExercise, _ exercise2: PlannedExercise, in day: ProgramDay) {
        let groupId = UUID().uuidString
        if let dayIndex = program.days.firstIndex(where: { $0.id == day.id }) {
            for index in program.days[dayIndex].exercises.indices {
                if program.days[dayIndex].exercises[index].exerciseId == exercise1.exerciseId ||
                   program.days[dayIndex].exercises[index].exerciseId == exercise2.exerciseId {
                    program.days[dayIndex].exercises[index].groupId = groupId
                }
            }
        }
    }
    
    func unlinkExercise(_ exercise: PlannedExercise, in day: ProgramDay) {
        if let dayIndex = program.days.firstIndex(where: { $0.id == day.id }),
           let exerciseIndex = program.days[dayIndex].exercises.firstIndex(where: { $0.exerciseId == exercise.exerciseId }) {
            program.days[dayIndex].exercises[exerciseIndex].groupId = nil
        }
    }
}

struct ProgramEditorView: View {
    @Bindable var viewModel: ProgramEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDayEditor = false
    @State private var selectedDay: ProgramDay?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Program Details") {
                    TextField("Program Name", text: Binding(
                        get: { viewModel.program.name },
                        set: { viewModel.updateProgramName($0) }
                    ))
                    
                    TextField("Coach", text: Binding(
                        get: { viewModel.program.coach },
                        set: { viewModel.updateProgramCoach($0) }
                    ))
                    
                    Picker("Category", selection: Binding(
                        get: { viewModel.program.category },
                        set: { viewModel.updateProgramCategory($0) }
                    )) {
                        Text("Bodybuilding").tag("Bodybuilding")
                        Text("Strength").tag("Strength")
                        Text("HIIT").tag("HIIT")
                        Text("Powerlifting").tag("Powerlifting")
                        Text("Functional").tag("Functional")
                        Text("Bodyweight").tag("Bodyweight")
                    }
                    
                    Picker("Level", selection: Binding(
                        get: { viewModel.program.level },
                        set: { viewModel.updateProgramLevel($0) }
                    )) {
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                    
                    Stepper("Duration: \(viewModel.program.durationWeeks) weeks", value: Binding(
                        get: { viewModel.program.durationWeeks },
                        set: { viewModel.updateDurationWeeks($0) }
                    ), in: 1...52)
                    
                    Stepper("Days per week: \(viewModel.program.daysPerWeek)", value: Binding(
                        get: { viewModel.program.daysPerWeek },
                        set: { viewModel.updateDaysPerWeek($0) }
                    ), in: 1...7)
                }
                
                Section("Workout Days") {
                    ForEach(viewModel.program.days) { day in
                        NavigationLink(destination: DayEditorView(
                            program: viewModel.program,
                            day: day,
                            viewModel: viewModel
                        )) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(day.name)
                                        .font(.headline)
                                    Text("\(day.exercises.count) exercises")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteDay(viewModel.program.days[index])
                        }
                    }
                    
                    Button(action: viewModel.addDay) {
                        Label("Add Day", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Edit Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save logic would go here
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DayEditorView: View {
    let program: Program
    let day: ProgramDay
    @Bindable var viewModel: ProgramEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingExerciseEditor = false
    @State private var selectedExercise: PlannedExercise?
    
    var body: some View {
        Form {
            Section("Day Details") {
                TextField("Day Name", text: Binding(
                    get: { day.name },
                    set: { viewModel.updateDay(day, name: $0) }
                ))
                
                TextField("Focus", text: Binding(
                    get: { day.focus },
                    set: { viewModel.updateDayFocus(day, focus: $0) }
                ))
            }
            
            Section("Exercises") {
                ForEach(day.exercises) { exercise in
                    NavigationLink(destination: ExerciseEditorView(
                        program: program,
                        day: day,
                        exercise: exercise,
                        viewModel: viewModel
                    )) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exercise.name ?? "Custom Exercise")
                                    .font(.headline)
                                HStack {
                                    Text("\(exercise.sets) sets")
                                    Text("•")
                                    Text(exercise.reps)
                                    Text("•")
                                    Text("\(exercise.restSec)s rest")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            if exercise.groupId != nil {
                                Image(systemName: "link.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteExercise(day.exercises[index], from: day)
                    }
                }
                
                Button(action: { viewModel.addExercise(to: day) }) {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Edit Day")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct ExerciseEditorView: View {
    let program: Program
    let day: ProgramDay
    let exercise: PlannedExercise
    @Bindable var viewModel: ProgramEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCueEditor = false
    
    var body: some View {
        Form {
            Section("Exercise Details") {
                TextField("Exercise Name", text: Binding(
                    get: { exercise.name ?? "" },
                    set: { viewModel.updateExercise(exercise, in: day, name: $0) }
                ))
                
                Stepper("Sets: \(exercise.sets)", value: Binding(
                    get: { exercise.sets },
                    set: { viewModel.updateExerciseSets(exercise, in: day, sets: $0) }
                ), in: 1...10)
                
                TextField("Reps", text: Binding(
                    get: { exercise.reps },
                    set: { viewModel.updateExerciseReps(exercise, in: day, reps: $0) }
                ))
                
                Stepper("Rest: \(exercise.restSec)s", value: Binding(
                    get: { exercise.restSec },
                    set: { viewModel.updateExerciseRest(exercise, in: day, restSec: $0) }
                ), in: 0...300)
            }
            
            Section("Notes") {
                TextField("Notes", text: Binding(
                    get: { exercise.notes ?? "" },
                    set: { viewModel.updateExerciseNotes(exercise, in: day, notes: $0) }
                ), axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("Superset") {
                if exercise.groupId != nil {
                    Button("Remove from Superset", role: .destructive) {
                        viewModel.unlinkExercise(exercise, in: day)
                    }
                } else {
                    Text("Link with another exercise to create a superset")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ProgramEditorView(viewModel: ProgramEditorViewModel(program: Program(
            id: "1",
            name: "Full Body Blast",
            category: "Bodybuilding",
            level: "Intermediate",
            coach: "Coach Smith",
            durationWeeks: 8,
            daysPerWeek: 3,
            days: []
        )))
    }
}