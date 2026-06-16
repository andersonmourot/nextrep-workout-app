import SwiftUI

struct ExercisesView: View {
    @StateObject private var store = AppStore()
    @State private var isManaging: Bool = false
    @State private var showingExerciseForm: Bool = false
    @State private var selectedExercise: Exercise?
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "All"
    @State private var selectedMuscle: String? = nil
    @State private var showingDetail: Bool = false
    @State private var detailExercise: Exercise?
    
    private let muscles = ["All", "Custom", "Chest", "Back", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Calves", "Core", "Forearms", "Full Body"]
    
    var filteredExercises: [Exercise] {
        let customExercises = store.appData.customExercises
        let builtInExercises = store.allExercises
        
        var allExercises = customExercises + builtInExercises
        
        // Filter out hidden and trashed
        let hiddenIds = Set(store.appData.hiddenProgramIds) // Using hiddenProgramIds for now, should be hiddenExerciseIds
        // Filter out trashed (not implemented yet)
        
        // Remove duplicates (custom overrides built-in)
        var uniqueExercises: [Exercise] = []
        var seenIds = Set<String>()
        for exercise in allExercises {
            if !seenIds.contains(exercise.id) {
                uniqueExercises.append(exercise)
                seenIds.insert(exercise.id)
            }
        }
        
        // Apply search
        if !searchText.isEmpty {
            uniqueExercises = uniqueExercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply filters
        if selectedFilter == "Custom" {
            uniqueExercises = uniqueExercises.filter { exercise in
                store.appData.customExercises.contains { $0.id == exercise.id }
            }
        } else if selectedFilter != "All" {
            uniqueExercises = uniqueExercises.filter { exercise in
                exercise.primaryMuscle == selectedFilter
            }
        }
        
        return uniqueExercises
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Search field
                searchField
                
                // Filter chips
                filterChips
                
                // Count line
                countLine
                
                // Exercise list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredExercises) { exercise in
                            exerciseCard(exercise: exercise)
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingExerciseForm) {
            ExerciseFormView(
                exercise: selectedExercise,
                onSave: { exercise in
                    Task {
                        await saveExercise(exercise)
                    }
                }
            )
        }
        .navigationDestination(isPresented: $showingDetail) {
            if let exercise = detailExercise {
                ExerciseDetailView(exerciseId: exercise.id)
            }
        }
        .task {
            await store.loadAppData()
            await store.loadCatalog()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Exercises")
                .font(Theme.display(28))
                .foregroundColor(Theme.text)
                .tracking(1)
            
            Spacer()
            
            if isManaging {
                if hiddenCount > 0 {
                    Button(action: {}) {
                        Text("Hidden (\(hiddenCount))")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.textDim)
                    }
                }
                
                Button(action: {}) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(Theme.textDim)
                }
            }
            
            Button(action: {
                isManaging.toggle()
            }) {
                Image(systemName: isManaging ? "checkmark" : "gearshape")
                    .font(.title3)
                    .foregroundColor(Theme.text)
            }
            
            Button(action: {
                selectedExercise = nil
                showingExerciseForm = true
            }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Theme.accent)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Theme.surface)
    }
    
    // MARK: - Search Field
    
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.body(14))
                .foregroundColor(Theme.textDim)
            
            TextField("Search", text: $searchText)
                .font(Theme.body(14))
                .foregroundColor(Theme.text)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surface2)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Filter Chips
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(muscles, id: \.self) { muscle in
                    Button(action: {
                        selectedFilter = muscle
                        if muscle == "All" {
                            selectedMuscle = nil
                        } else {
                            selectedMuscle = muscle
                        }
                    }) {
                        Text(muscle)
                            .font(Theme.body(12))
                            .foregroundColor(selectedFilter == muscle ? .white : Theme.text)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedFilter == muscle ? Theme.accent : Theme.surface2)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Count Line
    
    private var countLine: some View {
        Text("\(filteredExercises.count) exercises")
            .font(Theme.body(12))
            .foregroundColor(Theme.textDim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 4)
    }
    
    // MARK: - Exercise Card
    
    private func exerciseCard(exercise: Exercise) -> some View {
        let isCustom = store.appData.customExercises.contains { $0.id == exercise.id }
        
        return Button(action: {
            detailExercise = exercise
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(exercise.name)
                        .font(Theme.body(16))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.text)
                    
                    if isCustom {
                        Text("Custom")
                            .font(Theme.body(10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accent)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if isManaging {
                        Button(action: {}) {
                            Image(systemName: "eye.slash")
                                .font(.caption)
                                .foregroundColor(Theme.textDim)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Chip row
                HStack(spacing: 8) {
                    Text(exercise.primaryMuscle)
                        .font(Theme.body(10))
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accent.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text("·")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                    
                    Text(exercise.equipment)
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                    
                    Text("·")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                    
                    Text(exercise.difficulty)
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
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
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Properties
    
    private var hiddenCount: Int {
        // Using hiddenProgramIds as placeholder - should be hiddenExerciseIds
        return store.appData.hiddenProgramIds.count
    }
    
    // MARK: - Save Exercise
    
    private func saveExercise(_ exercise: Exercise) async {
        if store.appData.customExercises.contains(where: { $0.id == exercise.id }) {
            // Update existing
            if let index = store.appData.customExercises.firstIndex(where: { $0.id == exercise.id }) {
                store.appData.customExercises[index] = exercise
            }
        } else {
            // Add new
            store.appData.customExercises.append(exercise)
        }
        await store.saveAppData()
    }
}

// MARK: - Exercise Detail View

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = AppStore()
    let exerciseId: String
    
    @State private var exercise: Exercise?
    @State private var note: String = ""
    @State private var showingEditForm: Bool = false
    @State private var deleteConfirmStep: Int = 0 // 0 = show Delete, 1 = show Confirm/Cancel
    @State private var isLoading: Bool = true
    
    private var resolvedExercise: Exercise? {
        // Try to find in custom exercises first
        if let custom = store.appData.customExercises.first(where: { $0.id == exerciseId }) {
            return custom
        }
        // Try to find in catalog (built-ins)
        if let builtIn = store.allExercises.first(where: { $0.id == exerciseId }) {
            return builtIn
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .foregroundColor(Theme.text)
            } else if let exercise = resolvedExercise {
                VStack(spacing: 0) {
                    // Top bar
                    topBar(exercise: exercise)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Title block
                            titleBlock(exercise: exercise)
                            
                            // Notes section
                            notesSection(exercise: exercise)
                            
                            // Muscle visual card
                            muscleVisualCard(exercise: exercise)
                            
                            // How to perform
                            if !exercise.instructions.isEmpty {
                                instructionsSection(exercise: exercise)
                            }
                            
                            // Coaching cues
                            if !exercise.tips.isEmpty {
                                cuesSection(exercise: exercise)
                            }
                            
                            // Photos
                            // Placeholder - would need photo storage
                        }
                        .padding()
                    }
                }
            } else {
                // Not found
                VStack(spacing: 16) {
                    Text("Exercise not found")
                        .font(Theme.body(18))
                        .foregroundColor(Theme.text)
                    
                    Button("Back to Library") {
                        dismiss()
                    }
                    .font(Theme.body(14))
                    .foregroundColor(Theme.accent)
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            ExerciseFormView(
                exercise: resolvedExercise,
                onSave: { updatedExercise in
                    Task {
                        await saveExercise(updatedExercise)
                    }
                }
            )
        }
        .task {
            await loadData()
        }
    }
    
    // MARK: - Top Bar
    
    private func topBar(exercise: Exercise) -> some View {
        HStack {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundColor(Theme.text)
            }
            
            Spacer()
            
            // Edit button
            Button(action: {
                showingEditForm = true
            }) {
                Text("Edit")
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
            }
            
            // Delete button
            Button(action: {
                if deleteConfirmStep == 0 {
                    deleteConfirmStep = 1
                } else {
                    // Confirm delete
                    Task {
                        await deleteExercise()
                    }
                }
            }) {
                if deleteConfirmStep == 0 {
                    Text("Delete")
                        .font(Theme.body(14))
                        .foregroundColor(Theme.text)
                } else {
                    HStack(spacing: 8) {
                        Text("Confirm")
                            .font(Theme.body(14))
                            .foregroundColor(.red)
                        
                        Button(action: {
                            deleteConfirmStep = 0
                        }) {
                            Text("Cancel")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.textDim)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Theme.surface)
    }
    
    // MARK: - Title Block
    
    private func titleBlock(exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Eyebrow
            Text(exercise.primaryMuscle)
                .font(Theme.body(12))
                .foregroundColor(Theme.accent)
                .tracking(1)
            
            // Title
            Text(exercise.name)
                .font(Theme.display(36))
                .foregroundColor(Theme.text)
                .tracking(1)
            
            // Chip row
            HStack(spacing: 6) {
                Text(exercise.equipment)
                    .font(Theme.body(12))
                    .foregroundColor(Theme.textDim)
                
                Text("·")
                    .font(Theme.body(12))
                    .foregroundColor(Theme.textDim)
                
                Text(exercise.difficulty)
                    .font(Theme.body(12))
                    .foregroundColor(Theme.textDim)
                
                for muscle in exercise.secondaryMuscles {
                    Text("·")
                        .font(Theme.body(12))
                        .foregroundColor(Theme.textDim)
                    
                    Text(muscle)
                        .font(Theme.body(12))
                        .foregroundColor(Theme.textDim)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Notes Section
    
    private func notesSection(exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(Theme.body(14))
                .fontWeight(.semibold)
                .foregroundColor(Theme.text)
            
            TextEditor(text: $note)
                .font(Theme.body(14))
                .foregroundColor(Theme.text)
                .frame(minHeight: 120)
                .padding(12)
                .background(Theme.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .onChange(of: note) { _, newValue in
                    Task {
                        await store.updateExerciseNote(exerciseId: exercise.id, note: newValue)
                    }
                }
                .overlay(
                    Group {
                        if note.isEmpty {
                            Text("Add notes for this exercise — form cues, weights to try, reminders…")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.placeholder)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
    }
    
    // MARK: - Muscle Visual Card
    
    private func muscleVisualCard(exercise: Exercise) -> some View {
        VStack(spacing: 16) {
            ZStack {
                // Radial gradient circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.accent.opacity(0.3),
                                Theme.accent.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                // Muscle name
                Text(exercise.primaryMuscle)
                    .font(Theme.display(24))
                    .foregroundColor(Theme.accent)
                    .tracking(1)
            }
            .frame(height: 220)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Instructions Section
    
    private func instructionsSection(exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to perform")
                .font(Theme.body(16))
                .fontWeight(.semibold)
                .foregroundColor(Theme.text)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        // Accent number badge
                        Text("\(index + 1)")
                            .font(Theme.body(12))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Theme.accent)
                            .cornerRadius(8)
                        
                        Text(instruction)
                            .font(Theme.body(14))
                            .foregroundColor(Theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
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
    
    // MARK: - Cues Section
    
    private func cuesSection(exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Coaching cues")
                .font(Theme.body(16))
                .fontWeight(.semibold)
                .foregroundColor(Theme.text)
            
            VStack(spacing: 12) {
                ForEach(Array(exercise.tips.enumerated()), id: \.offset) { index, tip in
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb")
                            .font(.title3)
                            .foregroundColor(Theme.accent)
                        
                        Text(tip)
                            .font(Theme.body(14))
                            .foregroundColor(Theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(Theme.surface2)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        await store.loadAppData()
        await store.loadCatalog()
        
        exercise = resolvedExercise
        note = store.appData.exerciseNotes[exerciseId] ?? ""
        
        isLoading = false
    }
    
    // MARK: - Save Exercise
    
    private func saveExercise(_ updatedExercise: Exercise) async {
        if store.appData.customExercises.contains(where: { $0.id == updatedExercise.id }) {
            // Update existing
            if let index = store.appData.customExercises.firstIndex(where: { $0.id == updatedExercise.id }) {
                store.appData.customExercises[index] = updatedExercise
            }
        } else {
            // Add new
            store.appData.customExercises.append(updatedExercise)
        }
        await store.saveAppData()
        exercise = updatedExercise
    }
    
    // MARK: - Delete Exercise
    
    private func deleteExercise() async {
        store.appData.customExercises.removeAll { $0.id == exerciseId }
        await store.saveAppData()
        dismiss()
    }
}

// MARK: - Exercise Form Sheet

struct ExerciseFormView: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise?
    let onSave: (Exercise) -> Void
    
    @State private var name: String = ""
    @State private var primaryMuscle: String = "Chest"
    @State private var equipment: String = "Barbell"
    @State private var difficulty: String = "Intermediate"
    @State private var secondaryMuscles: Set<String> = []
    @State private var instructions: String = ""
    @State private var tips: String = ""
    @State private var photo1: Data?
    @State private var photo2: Data?
    
    private let primaryMuscles = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Calves", "Core", "Forearms", "Full Body"]
    private let equipmentOptions = ["Barbell", "Dumbbell", "Machine", "Cable", "Bodyweight", "Kettlebell", "Bands"]
    private let difficultyOptions = ["Beginner", "Intermediate", "Advanced"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                    
                    Picker("Primary Muscle", selection: $primaryMuscle) {
                        ForEach(primaryMuscles, id: \.self) { muscle in
                            Text(muscle).tag(muscle)
                        }
                    }
                    
                    Picker("Equipment", selection: $equipment) {
                        ForEach(equipmentOptions, id: \.self) { equip in
                            Text(equip).tag(equip)
                        }
                    }
                    
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(difficultyOptions, id: \.self) { diff in
                            Text(diff).tag(diff)
                        }
                    }
                }
                
                Section {
                    Text("Secondary Muscles")
                        .font(Theme.body(12))
                        .foregroundColor(Theme.placeholder)
                    
                    ForEach(primaryMuscles.filter { $0 != primaryMuscle }, id: \.self) { muscle in
                        Button(action: {
                            if secondaryMuscles.contains(muscle) {
                                secondaryMuscles.remove(muscle)
                            } else {
                                secondaryMuscles.insert(muscle)
                            }
                        }) {
                            HStack {
                                if secondaryMuscles.contains(muscle) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.accent)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(Theme.textDim)
                                }
                                Text(muscle)
                                    .foregroundColor(Theme.text)
                            }
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Instructions (one step per line)")
                            .font(Theme.body(10))
                            .foregroundColor(Theme.placeholder)
                        TextEditor(text: $instructions)
                            .frame(minHeight: 100)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coaching cues/tips (one per line)")
                            .font(Theme.body(10))
                            .foregroundColor(Theme.placeholder)
                        TextEditor(text: $tips)
                            .frame(minHeight: 100)
                    }
                }
                
                Section {
                    Text("Photos (up to two)")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.placeholder)
                    
                    // Photo 1
                    Button(action: {}) {
                        Text("Add Photo 1")
                            .font(Theme.body(14))
                            .foregroundColor(Theme.accent)
                    }
                    
                    // Photo 2
                    Button(action: {}) {
                        Text("Add Photo 2")
                            .font(Theme.body(14))
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .navigationTitle(exercise == nil ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExercise()
                    }
                }
            }
        }
    }
    
    private func saveExercise() {
        let newExercise = Exercise(
            id: exercise?.id ?? UUID().uuidString,
            name: name,
            primaryMuscle: primaryMuscle,
            secondaryMuscles: Array(secondaryMuscles),
            equipment: equipment,
            difficulty: difficulty,
            instructions: instructions.components(separatedBy: .newlines).filter { !$0.isEmpty },
            tips: tips.components(separatedBy: .newlines).filter { !$0.isEmpty },
            ownerId: nil,
            collaborative: nil,
            version: nil,
            goal: nil,
            accent: nil,
            summary: nil,
            tags: nil
        )
        onSave(newExercise)
        dismiss()
    }
}