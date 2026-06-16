import SwiftUI
import AVFoundation
import UserNotifications

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = AppStore()
    @State private var program: Program?
    @State private var day: ProgramDay?
    @State private var elapsedSeconds: Int = 0
    @State private var restRemainingSeconds: Int = 0
    @State private var restTotalSeconds: Int = 0
    @State private var showingSummary = false
    @State private var workoutLog: WorkoutLog?
    @State private var timer: Timer?
    @State private var restTimer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showingNotesSheet = false
    @State private var selectedExerciseForNotes: PlannedExercise?
    @State private var editingCueExerciseId: String?
    @State private var editingCueText: String = ""
    
    private var activeWorkout: ActiveWorkout {
        store.activeWorkout ?? ActiveWorkout(programId: "", dayId: "", dayIndex: 0, week: 1, startedAt: Date().timeIntervalSince1970, sets: [], exerciseIds: [])
    }
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Sticky top bar
                topBar
                    .background(Theme.bg)
                    .zIndex(10)
                
                // Progress bar
                progressBar
                    .background(Theme.bg)
                    .zIndex(9)
                
                // Exercise list
                ScrollView {
                    VStack(spacing: 16) {
                        let groups = supersetGroups(exercises: day?.exercises ?? [])
                        ForEach(Array(day?.exercises.enumerated() ?? [].enumerated()), id: \.element.id) { index, exercise in
                            if groups.count > 0 {
                                if let groupIndex = groups.firstIndex(where: { $0.indices.contains(index) }) {
                                    if groups[groupIndex].indices.first == index {
                                        supersetCard(group: groups[groupIndex], groupIndex: groupIndex)
                                    }
                                }
                            } else {
                                exerciseCard(exercise: exercise, index: index)
                            }
                        }
                        
                        // Finish Workout button
                        finishWorkoutButton
                    }
                    .padding()
                }
            }
            .background(Theme.bg)
            
            // Floating rest bar
            if restRemainingSeconds > 0 {
                restBar
                    .transition(.move(edge: .bottom))
            }
        }
        .navigationDestination(isPresented: $showingSummary) {
            if let log = workoutLog {
                WorkoutSummaryView(workoutLog: log, onDone: {
                    Task {
                        await store.endWorkout()
                        dismiss()
                    }
                })
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
        .task {
            await loadWorkoutData()
            startElapsedTimer()
            configureAudioSession()
            
            // Set accent from theme color
            if let themeColor = store.appData.themeColor {
                Theme.setAccent(from: themeColor)
            }
        }
        .onDisappear {
            stopElapsedTimer()
            stopRestTimer()
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Close button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(Theme.text)
            }
            
            Spacer()
            
            // Day name + program name
            VStack(spacing: 2) {
                if let day = day {
                    Text(day.name)
                        .font(Theme.display(16))
                        .foregroundColor(Theme.text)
                        .tracking(1)
                }
                if let program = program {
                    Text(program.name)
                        .font(Theme.body(12))
                        .foregroundColor(Theme.textDim)
                }
            }
            
            Spacer()
            
            // Timer pill
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundColor(Theme.text)
                
                Text(elapsedTimeString)
                    .font(Theme.body(12))
                    .foregroundColor(Theme.text)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.surface2)
            .cornerRadius(12)
        }
        .padding()
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        let progress = totalSetsCount > 0 ? Double(completedSetsCount) / Double(totalSetsCount) : 0.0
        
        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.surface2)
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }
    
    // MARK: - Exercise Card
    
    private func exerciseCard(exercise: PlannedExercise, index: Int) -> some View {
        let exerciseIndex = index
        let totalExercises = day?.exercises.count ?? 0
        let sets = activeWorkout.sets[safe: index] ?? []
        
        return VStack(alignment: .leading, spacing: 12) {
            // Eyebrow
            Text("Exercise \(exerciseIndex + 1) of \(totalExercises)")
                .font(Theme.body(11))
                .foregroundColor(Theme.placeholder)
                .tracking(2)
            
            // Title
            Text(exerciseLabel(for: exercise))
                .font(Theme.display(18))
                .foregroundColor(Theme.text)
                .tracking(1)
            
            // Subtitle
            Text("\(exercise.sets) sets × \(exercise.reps) reps")
                .font(Theme.body(12))
                .foregroundColor(Theme.textDim)
            
            // Cue line (green left-bar)
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
                // Cue button (only when no cue exists)
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
            
            // Notes line
            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(Theme.body(12))
                    .foregroundColor(Theme.textDim)
                    .italic()
            }
            
            // Cue subheader - not available in current model
            // if let cue = exercise.pe?.cue {
            
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
                    setRow(
                        exercise: exercise,
                        exerciseIndex: index,
                        setIndex: setIndex,
                        setLog: sets[safe: setIndex]
                    )
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Superset Card
    
    private func supersetCard(group: (groupId: String?, indices: [Int], isSuperset: Bool, label: String?), groupIndex: Int) -> some View {
        let exercises = group.indices.compactMap { day?.exercises[safe: $0] }
        let rounds = exercises.first?.sets ?? 3
        let accentColor = Theme.accent
        let groupLabel = group.label ?? "Superset"
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("\(groupLabel) \(groupIndex + 1) · no rest between")
                    .font(Theme.body(11))
                    .foregroundColor(accentColor)
                    .tracking(2)
                
                Spacer()
                
                Text("\(rounds) rounds")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
            }
            
            // Legend
            VStack(spacing: 8) {
                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("\(groupIndex + 1)\(index + 1)")
                                .font(Theme.body(10))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accentColor)
                                .cornerRadius(4)
                            
                            Text(exerciseLabel(for: exercise))
                                .font(Theme.body(10))
                                .foregroundColor(Theme.textDim)
                            
                            Spacer()
                            
                            // Cue button (only when no cue exists)
                            if store.appData.exerciseSubheaders[exercise.exerciseId] == nil || store.appData.exerciseSubheaders[exercise.exerciseId]?.isEmpty == true {
                                Button(action: {
                                    editingCueExerciseId = exercise.exerciseId
                                    editingCueText = ""
                                }) {
                                    Image(systemName: "list.bullet")
                                        .font(.caption2)
                                        .foregroundColor(Theme.textDim)
                                }
                            }
                            
                            // Notes button
                            Button(action: {
                                selectedExerciseForNotes = exercise
                                showingNotesSheet = true
                            }) {
                                Image(systemName: "note.text")
                                    .font(.caption2)
                                    .foregroundColor(Theme.textDim)
                            }
                        }
                        
                        // Cue line
                        if let cue = store.appData.exerciseSubheaders[exercise.exerciseId], !cue.isEmpty {
                            HStack(spacing: 4) {
                                Rectangle()
                                    .fill(accentColor)
                                    .frame(width: 3)
                                
                                Button(action: {
                                    editingCueExerciseId = exercise.exerciseId
                                    editingCueText = cue
                                }) {
                                    Text(cue)
                                        .font(Theme.body(10))
                                        .foregroundColor(accentColor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Inline cue editor
                        if let exerciseId = editingCueExerciseId, exerciseId == exercise.exerciseId {
                            HStack(spacing: 4) {
                                Rectangle()
                                    .fill(accentColor)
                                    .frame(width: 3)
                                
                                TextField("Add a cue...", text: $editingCueText)
                                    .font(Theme.body(10))
                                    .foregroundColor(accentColor)
                                    .textFieldStyle(.plain)
                                    .onSubmit {
                                        Task {
                                            await store.updateExerciseCue(exerciseId: exerciseId, cue: editingCueText)
                                            editingCueExerciseId = nil
                                            editingCueText = ""
                                        }
                                    }
                            }
                            .padding(.vertical, 4)
                            .background(Theme.surface2)
                            .cornerRadius(4)
                        }
                    }
                }
            }
            
            // Round-by-round rows
            ForEach(0..<rounds, id: \.self) { roundIndex in
                VStack(spacing: 0) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { exerciseIndex, exercise in
                        let dayExerciseIndex = day?.exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
                        let sets = activeWorkout.sets[safe: dayExerciseIndex] ?? []
                        let setLog = sets[safe: roundIndex]
                        let isLastInRound = exerciseIndex == exercises.count - 1
                        
                        supersetSetRow(
                            exercise: exercise,
                            roundIndex: roundIndex,
                            exerciseIndex: exerciseIndex,
                            groupIndex: groupIndex,
                            setLog: setLog,
                            isLastInRound: isLastInRound
                        )
                    }
                }
            }
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.5), lineWidth: 2)
        )
    }
    
    // MARK: - Set Row
    
    private func setRow(exercise: PlannedExercise, exerciseIndex: Int, setIndex: Int, setLog: SetLog?) -> some View {
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
            
            // Weight field
            TextField("0", value: Binding(
                get: { weight },
                set: { newValue in
                    updateSetLog(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: newValue, reps: reps, completed: isDone)
                }
            ), format: .number.precision(.fractionLength(1)))
            .keyboardType(.decimalPad)
            .font(Theme.body(14))
            .foregroundColor(Theme.text)
            .multilineTextAlignment(.center)
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(Theme.inputBg)
            .cornerRadius(8)
            
            Spacer()
            
            // Reps field
            TextField("0", value: Binding(
                get: { reps },
                set: { newValue in
                    updateSetLog(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight, reps: newValue, completed: isDone)
                }
            ), format: .number)
            .keyboardType(.numberPad)
            .font(Theme.body(14))
            .foregroundColor(Theme.text)
            .multilineTextAlignment(.center)
            .frame(width: 50)
            .padding(.vertical, 8)
            .background(Theme.inputBg)
            .cornerRadius(8)
            
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
    
    // MARK: - Superset Set Row
    
    private func supersetSetRow(exercise: PlannedExercise, roundIndex: Int, exerciseIndex: Int, groupIndex: Int, setLog: SetLog?, isLastInRound: Bool) -> some View {
        let isDone = setLog?.completed ?? false
        let weight = setLog?.weight ?? 0
        let reps = setLog?.reps ?? 0
        let label = "\(groupIndex + 1)\(exerciseIndex + 1)"
        
        return HStack {
            // Badge
            Text(label)
                .font(Theme.body(10))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Theme.accent)
                .cornerRadius(4)
            
            Spacer()
            
            // Weight field
            TextField("0", value: Binding(
                get: { weight },
                set: { newValue in
                    let dayExerciseIndex = day?.exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
                    updateSetLog(exerciseIndex: dayExerciseIndex, setIndex: roundIndex, weight: newValue, reps: reps, completed: isDone)
                }
            ), format: .number.precision(.fractionLength(1)))
            .keyboardType(.decimalPad)
            .font(Theme.body(12))
            .foregroundColor(Theme.text)
            .multilineTextAlignment(.center)
            .frame(width: 50)
            .padding(.vertical, 6)
            .background(Theme.inputBg)
            .cornerRadius(6)
            
            Spacer()
            
            // Reps field
            TextField("0", value: Binding(
                get: { reps },
                set: { newValue in
                    let dayExerciseIndex = day?.exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
                    updateSetLog(exerciseIndex: dayExerciseIndex, setIndex: roundIndex, weight: weight, reps: newValue, completed: isDone)
                }
            ), format: .number)
            .keyboardType(.numberPad)
            .font(Theme.body(12))
            .foregroundColor(Theme.text)
            .multilineTextAlignment(.center)
            .frame(width: 40)
            .padding(.vertical, 6)
            .background(Theme.inputBg)
            .cornerRadius(6)
            
            Spacer()
            
            // Done toggle
            Button(action: {
                let dayExerciseIndex = day?.exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
                updateSetLog(exerciseIndex: dayExerciseIndex, setIndex: roundIndex, weight: weight, reps: reps, completed: !isDone)
                
                // Start rest if this is the last set of a round with rest
                if isLastInRound && isDone == false {
                    // About to mark as done
                    if let day = day {
                        let exerciseIndexInDay = day.exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
                        let exerciseObj = day.exercises[exerciseIndexInDay]
                        if exerciseObj.restSec > 0 {
                            startRest(seconds: exerciseObj.restSec)
                        }
                    }
                }
            }) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isDone ? Theme.accent : Theme.textDim)
            }
        }
        .padding(.vertical, 6)
        .background(isDone ? Theme.accent.opacity(0.1) : Color.clear)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Trailing Buttons
    
    private var cueButton: some View {
        Button(action: {}) {
            Image(systemName: "lightbulb")
                .font(.caption)
                .foregroundColor(Theme.textDim)
        }
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
    
    // MARK: - Finish Workout Button
    
    private var finishWorkoutButton: some View {
        Button(action: {
            finishWorkout()
        }) {
            Text("Finish Workout")
        }
        .buttonStyle(PrimaryButton())
        .padding(.top, 20)
    }
    
    // MARK: - Rest Bar
    
    private var restBar: some View {
        VStack(spacing: 12) {
            // Eyebrow + timer
            HStack {
                Text("Rest")
                    .font(Theme.body(11))
                    .foregroundColor(Theme.placeholder)
                    .tracking(2)
                
                Spacer()
                
                Text(restTimeString)
                    .font(Theme.display(24))
                    .foregroundColor(Theme.accent)
                    .tracking(1)
            }
            
            // Buttons
            HStack(spacing: 12) {
                Button(action: {
                    add15Seconds()
                }) {
                    Text("+15s")
                        .font(Theme.body(12))
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.surface2)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    skipRest()
                }) {
                    Text("Skip")
                }
                .buttonStyle(PrimaryButton())
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.surface2)
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(width: geometry.size.width * (1 - Double(restRemainingSeconds) / Double(restTotalSeconds)), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(Theme.surface)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    // MARK: - Helpers
    
    private func loadWorkoutData() async {
        await store.loadAppData()
        await store.loadCatalog()
        
        // Resolve program
        program = store.mergedPrograms().first { $0.id == activeWorkout.programId }
        
        // Resolve day
        if let program = program {
            day = resolveProgramDay(program: program, dayLocalIdx: activeWorkout.dayIndex, week: activeWorkout.week ?? 1)
        }
        
        // Calculate elapsed time
        elapsedSeconds = Int(Date().timeIntervalSince(Date(timeIntervalSince1970: activeWorkout.startedAt)))
    }
    
    private func startElapsedTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }
    
    private func stopElapsedTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startRest(seconds: Int) {
        restRemainingSeconds = seconds
        restTotalSeconds = seconds
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if restRemainingSeconds > 0 {
                restRemainingSeconds -= 1
            } else {
                // Rest complete
                playRestBell()
                stopRestTimer()
            }
        }
    }
    
    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restRemainingSeconds = 0
        restTotalSeconds = 0
    }
    
    private func add15Seconds() {
        restRemainingSeconds += 15
        restTotalSeconds += 15
    }
    
    private func skipRest() {
        stopRestTimer()
    }
    
    private func playRestBell() {
        // Play bell sound
        if let url = Bundle.main.url(forResource: "bell", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                // Fallback: schedule local notification
                scheduleRestNotification()
            }
        } else {
            scheduleRestNotification()
        }
    }
    
    private func scheduleRestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Ready for your next set!"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: "rest-complete", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func updateSetLog(exerciseIndex: Int, setIndex: Int, weight: Double, reps: Int, completed: Bool) {
        var sets = activeWorkout.sets
        while sets.count <= exerciseIndex {
            sets.append([])
        }
        while sets[exerciseIndex].count <= setIndex {
            sets[exerciseIndex].append(SetLog(id: uid(), weight: 0, reps: 0, completed: false))
        }
        sets[exerciseIndex][setIndex] = SetLog(id: uid(), weight: weight, reps: reps, completed: completed)
        // Update in store
        Task {
            await store.updateActiveWorkoutSets(sets)
        }
    }
    
    private func finishWorkout() {
        var exerciseLogs: [ExerciseLog] = []
        var totalVolume: Double = 0
        
        for (exerciseIndex, exerciseSets) in activeWorkout.sets.enumerated() {
            var completedSets: [SetLog] = []
            for setLog in exerciseSets {
                if setLog.completed || setLog.weight > 0 {
                    completedSets.append(setLog)
                    totalVolume += setLog.weight * Double(setLog.reps)
                }
            }
            
            // Get exerciseId from the day's exercises
            let exerciseId = day?.exercises[safe: exerciseIndex]?.exerciseId ?? ""
            
            if !completedSets.isEmpty {
                exerciseLogs.append(ExerciseLog(id: uid(), exerciseId: exerciseId, sets: completedSets))
            }
        }
        
        let today = ISO8601DateFormatter().string(from: Date())
        
        let log = WorkoutLog(
            id: UUID().uuidString,
            programId: activeWorkout.programId,
            dayId: activeWorkout.dayId,
            week: activeWorkout.week ?? 1,
            date: today,
            totalVolume: totalVolume,
            exercises: exerciseLogs
        )
        
        workoutLog = log
        
        Task {
            await store.addLog(log)
            showingSummary = true
        }
    }
    
    private var completedSetsCount: Int {
        activeWorkout.sets.flatMap { $0 }.filter { $0.completed }.count
    }
    
    private var totalSetsCount: Int {
        day?.exercises.reduce(0) { $0 + $1.sets } ?? 0
    }
    
    private var elapsedTimeString: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var restTimeString: String {
        let minutes = restRemainingSeconds / 60
        let seconds = restRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func exerciseLabel(for exercise: PlannedExercise) -> String {
        if let libraryExercise = store.allExercises.first(where: { $0.id == exercise.exerciseId }) {
            return libraryExercise.name
        }
        return exercise.exerciseId
    }
}

// MARK: - Workout Summary View

struct WorkoutSummaryView: View {
    let workoutLog: WorkoutLog
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Check badge
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Theme.accent)
            
            // Title
            Text("Workout Complete")
                .font(Theme.display(28))
                .foregroundColor(Theme.text)
                .tracking(1)
            
            // Day + program name
            if let dayName = workoutLog.dayId.isEmpty ? nil : workoutLog.dayId {
                Text(dayName)
                    .font(Theme.body(14))
                    .foregroundColor(Theme.textDim)
            }
            
            // Stat cards
            HStack(spacing: 12) {
                statCard(title: "Sets", value: "\(completedSetsCount)")
                statCard(title: "Vol", value: volumeString)
                statCard(title: "Date", value: dateString)
            }
            
            Spacer()
            
            // Done button
            Button(action: onDone) {
                Text("Done")
            }
            .buttonStyle(PrimaryButton())
        }
        .padding()
        .background(Theme.bg)
    }
    
    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.display(20))
                .foregroundColor(Theme.text)
            
            Text(title)
                .font(Theme.body(10))
                .foregroundColor(Theme.textDim)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(12)
    }
    
    private var completedSetsCount: Int {
        workoutLog.exercises.flatMap { $0.sets }.count
    }
    
    private var volumeString: String {
        if workoutLog.totalVolume >= 1000 {
            return String(format: "%.1fk", workoutLog.totalVolume / 1000)
        }
        return String(format: "%.0f", workoutLog.totalVolume)
    }
    
    private var dateString: String {
        // Format the ISO date string to a more readable format
        if let date = ISO8601DateFormatter().date(from: workoutLog.date) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        return workoutLog.date
    }
}

// MARK: - Notes Sheet View

struct NotesSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: PlannedExercise
    let note: String
    let onSave: (String) -> Void
    
    @State private var editedNote: String
    
    init(exercise: PlannedExercise, note: String, onSave: @escaping (String) -> Void) {
        self.exercise = exercise
        self.note = note
        self.onSave = onSave
        self._editedNote = State(initialValue: note)
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Exercise name
                Text(exerciseLabel(for: exercise))
                    .font(Theme.body(18))
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.text)
                
                // Note editor
                TextEditor(text: $editedNote)
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
                    .padding(8)
                    .background(Theme.inputBg)
                    .cornerRadius(8)
                    .frame(minHeight: 200)
                
                Spacer()
                
                // Save button
                Button(action: {
                    onSave(editedNote)
                    dismiss()
                }) {
                    Text("Save")
                        .font(Theme.body(14))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent)
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Theme.bg)
            .navigationTitle("Notes")
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

// MARK: - Helpers

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ActiveWorkoutView()
        .background(Theme.bg)
}