import SwiftUI

struct AdminCatalogView: View {
    @StateObject private var store = AppStore()
    @State private var programs: [Program] = []
    @State private var exercises: [Exercise] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""
    
    // Exercise form state
    @State private var editingExerciseId: String? = nil
    @State private var exerciseName: String = ""
    @State private var exercisePrimaryMuscle: String = ""
    @State private var exerciseEquipment: String = ""
    @State private var exerciseDifficulty: String = ""
    @State private var exerciseSecondaryMuscles: String = ""
    @State private var exerciseInstructions: String = ""
    @State private var exerciseTips: String = ""
    
    // Delete confirmation
    @State private var deletingProgramId: String? = nil
    @State private var deletingExerciseId: String? = nil
    
    // Program editor
    @State private var showingProgramEditor: Bool = false
    @State private var editingProgram: Program? = nil
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Back button
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                            Text("Back")
                                .font(Theme.body(14))
                        }
                        .foregroundColor(Theme.textDim)
                    }
                    
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🛡 Admin")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.accent)
                            .tracking(2)
                        
                        Text("Catalog")
                            .font(Theme.display(32))
                            .foregroundColor(Theme.text)
                            .tracking(1)
                        
                        Text("Edit the built-in programs and exercises everyone sees. Changes go live immediately.")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.textDim)
                    }
                    
                    // Loading line
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(20)
                    }
                    
                    // Error card
                    if !errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            
                            Text(errorMessage)
                                .font(Theme.body(12))
                                .foregroundColor(.red)
                        }
                        .padding(16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Success message
                    if !successMessage.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.accent)
                            
                            Text(successMessage)
                                .font(Theme.body(12))
                                .foregroundColor(Theme.accent)
                        }
                        .padding(16)
                        .background(Theme.accent.opacity(0.1))
                        .cornerRadius(12)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                successMessage = ""
                            }
                        }
                    }
                    
                    // Programs section
                    if !isLoading {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Programs · \(programs.count)")
                                    .font(Theme.body(12))
                                    .foregroundColor(Theme.textDim)
                                    .tracking(2)
                                
                                Spacer()
                                
                                Button(action: {
                                    editingProgram = nil
                                    showingProgramEditor = true
                                }) {
                                    Text("Add")
                                        .font(Theme.body(10))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(8)
                                        .background(Theme.accent)
                                        .cornerRadius(8)
                                }
                            }
                            
                            VStack(spacing: 8) {
                                ForEach(programs) { program in
                                    ProgramRow(
                                        program: program,
                                        onEdit: {
                                            editingProgram = program
                                            showingProgramEditor = true
                                        },
                                        onDelete: {
                                            deletingProgramId = program.id
                                        },
                                        onConfirmDelete: {
                                            Task {
                                                await deleteProgram(program)
                                            }
                                        }
                                    )
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
                    
                    // Exercises section
                    if !isLoading {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Exercises · \(exercises.count)")
                                .font(Theme.body(12))
                                .foregroundColor(Theme.textDim)
                                .tracking(2)
                            
                            ExerciseForm(
                                exerciseId: editingExerciseId,
                                name: $exerciseName,
                                primaryMuscle: $exercisePrimaryMuscle,
                                equipment: $exerciseEquipment,
                                difficulty: $exerciseDifficulty,
                                secondaryMuscles: $exerciseSecondaryMuscles,
                                instructions: $exerciseInstructions,
                                tips: $exerciseTips,
                                onSave: {
                                    Task {
                                        await saveExercise()
                                    }
                                },
                                onCancel: {
                                    resetExerciseForm()
                                }
                            )
                            
                            VStack(spacing: 8) {
                                ForEach(exercises) { exercise in
                                    AdminExerciseRow(
                                        exercise: exercise,
                                        onEdit: {
                                            populateExerciseForm(exercise)
                                        },
                                        onDelete: {
                                            deletingExerciseId = exercise.id
                                        },
                                        onConfirmDelete: {
                                            Task {
                                                await deleteExercise(exercise)
                                            }
                                        }
                                    )
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
                }
                .padding()
            }
        }
        .task {
            await loadCatalog()
        }
        .sheet(isPresented: $showingProgramEditor) {
            // Program editor would go here - simplified for now
            Text("Program Editor")
                .padding()
        }
    }
    
    private func loadCatalog() async {
        isLoading = true
        errorMessage = ""
        
        guard store.currentUser?.isAdmin == true else {
            errorMessage = "Access denied. Admin privileges required."
            isLoading = false
            return
        }
        
        do {
            let catalog = try await store.fetchCatalog()
            programs = catalog.programs
            exercises = catalog.exercises
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func deleteProgram(_ program: Program) async {
        do {
            var updatedPrograms = programs.filter { $0.id != program.id }
            let catalog = Catalog(programs: updatedPrograms, exercises: exercises)
            try await store.adminPutCatalog(catalog)
            programs = updatedPrograms
            successMessage = "Program deleted successfully."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func deleteExercise(_ exercise: Exercise) async {
        do {
            var updatedExercises = exercises.filter { $0.id != exercise.id }
            let catalog = Catalog(programs: programs, exercises: updatedExercises)
            try await store.adminPutCatalog(catalog)
            exercises = updatedExercises
            successMessage = "Exercise deleted successfully."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func saveExercise() async {
        let slug = slugify(exerciseName)
        let exercise = Exercise(
            id: slug,
            name: exerciseName,
            primaryMuscle: exercisePrimaryMuscle,
            secondaryMuscles: exerciseSecondaryMuscles.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
            equipment: exerciseEquipment,
            difficulty: exerciseDifficulty,
            instructions: exerciseInstructions.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
            tips: exerciseTips.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
            ownerId: nil,
            collaborative: nil
        )
        
        do {
            var updatedExercises = exercises.filter { $0.id != slug }
            updatedExercises.append(exercise)
            let catalog = Catalog(programs: programs, exercises: updatedExercises)
            try await store.adminPutCatalog(catalog)
            exercises = updatedExercises
            successMessage = "Exercise saved successfully."
            resetExerciseForm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func populateExerciseForm(_ exercise: Exercise) {
        editingExerciseId = exercise.id
        exerciseName = exercise.name
        exercisePrimaryMuscle = exercise.primaryMuscle
        exerciseEquipment = exercise.equipment
        exerciseDifficulty = exercise.difficulty
        exerciseSecondaryMuscles = exercise.secondaryMuscles.joined(separator: ", ")
        exerciseInstructions = exercise.instructions.joined(separator: "\n")
        exerciseTips = exercise.tips.joined(separator: "\n")
    }
    
    private func resetExerciseForm() {
        editingExerciseId = nil
        exerciseName = ""
        exercisePrimaryMuscle = ""
        exerciseEquipment = ""
        exerciseDifficulty = ""
        exerciseSecondaryMuscles = ""
        exerciseInstructions = ""
        exerciseTips = ""
    }
    
    private func slugify(_ text: String) -> String {
        return text.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

struct ProgramRow: View {
    let program: Program
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onConfirmDelete: () -> Void
    
    @State private var deleteTapCount: Int = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(program.name)
                    .font(Theme.body(14))
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.text)
                
                let totalExercises = program.days.reduce(0) { $0 + $1.exercises.count }
                Text("\(totalExercises) exercises · \(program.days.count) days")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Text("Edit")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.accent)
            }
            
            Button(action: {
                deleteTapCount += 1
                if deleteTapCount >= 2 {
                    onConfirmDelete()
                    deleteTapCount = 0
                }
            }) {
                Text(deleteTapCount == 0 ? "Delete" : "Confirm?")
                    .font(Theme.body(10))
                    .foregroundColor(deleteTapCount == 0 ? Theme.textDim : .red)
            }
        }
        .padding(12)
        .background(Theme.surface2)
        .cornerRadius(8)
    }
}

struct AdminExerciseRow: View {
    let exercise: Exercise
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onConfirmDelete: () -> Void
    
    @State private var deleteTapCount: Int = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(Theme.body(14))
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.text)
                
                Text("\(exercise.primaryMuscle) · \(exercise.equipment) · \(exercise.difficulty)")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Text("Edit")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.accent)
            }
            
            Button(action: {
                deleteTapCount += 1
                if deleteTapCount >= 2 {
                    onConfirmDelete()
                    deleteTapCount = 0
                }
            }) {
                Text(deleteTapCount == 0 ? "Delete" : "Confirm?")
                    .font(Theme.body(10))
                    .foregroundColor(deleteTapCount == 0 ? Theme.textDim : .red)
            }
        }
        .padding(12)
        .background(Theme.surface2)
        .cornerRadius(8)
    }
}

struct ExerciseForm: View {
    let exerciseId: String?
    @Binding var name: String
    @Binding var primaryMuscle: String
    @Binding var equipment: String
    @Binding var difficulty: String
    @Binding var secondaryMuscles: String
    @Binding var instructions: String
    @Binding var tips: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    private let primaryMuscles = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core", "Cardio"]
    private let equipmentOptions = ["Barbell", "Dumbbell", "Machine", "Bodyweight", "Cable", "Kettlebell", "Band", "Other"]
    private let difficultyOptions = ["Beginner", "Intermediate", "Advanced"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exerciseId == nil ? "New exercise" : "Edit exercise")
                .font(Theme.body(12))
                .foregroundColor(Theme.accent)
            
            TextField("Name", text: $name)
                .font(Theme.body(12))
                .foregroundColor(Theme.text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(10)
                .background(Theme.inputBg)
                .cornerRadius(8)
            
            Picker("Primary muscle", selection: $primaryMuscle) {
                ForEach(primaryMuscles, id: \.self) { muscle in
                    Text(muscle).tag(muscle)
                }
            }
                .pickerStyle(MenuPickerStyle())
                .font(Theme.body(12))
            
            Picker("Equipment", selection: $equipment) {
                ForEach(equipmentOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
                .pickerStyle(MenuPickerStyle())
                .font(Theme.body(12))
            
            Picker("Difficulty", selection: $difficulty) {
                ForEach(difficultyOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
                .pickerStyle(MenuPickerStyle())
                .font(Theme.body(12))
            
            TextField("Secondary muscles (comma-separated)", text: $secondaryMuscles)
                .font(Theme.body(12))
                .foregroundColor(Theme.text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(10)
                .background(Theme.inputBg)
                .cornerRadius(8)
            
            TextField("Instructions (one per line)", text: $instructions, axis: .vertical)
                .font(Theme.body(12))
                .foregroundColor(Theme.text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(10)
                .background(Theme.inputBg)
                .cornerRadius(8)
                .frame(minHeight: 80)
            
            TextField("Tips (one per line)", text: $tips, axis: .vertical)
                .font(Theme.body(12))
                .foregroundColor(Theme.text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(10)
                .background(Theme.inputBg)
                .cornerRadius(8)
                .frame(minHeight: 60)
            
            HStack(spacing: 8) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Theme.surface2)
                        .cornerRadius(8)
                }
                
                Button(action: onSave) {
                    Text("Save")
                        .font(Theme.body(10))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Theme.accent)
                        .cornerRadius(8)
                }
                .disabled(name.isEmpty)
            }
        }
        .padding(12)
        .background(Theme.surface2)
        .cornerRadius(8)
    }
}