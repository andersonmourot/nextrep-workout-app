import SwiftUI
import AVFoundation
import UserNotifications

struct ActiveWorkoutView: View {
    let program: Program
    let day: Day
    @EnvironmentObject var activeWorkoutStore: ActiveWorkoutStore
    @State private var showSummary = false
    @State private var workoutSummary: ActiveWorkoutSummary?
    
    var body: some View {
        print("🏋️ ActiveWorkoutView appeared - program: \(program.name), day: \(day.name ?? "Unknown")")
        return ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Spacer for sticky header
                    Color.clear.frame(height: 80)
                    
                    // Exercise cards
                    ForEach(Array(day.exercises.enumerated()), id: \.element) { index, exercise in
                        ExerciseCard(
                            exercise: exercise,
                            exerciseIndex: index,
                            totalExercises: day.exercises.count,
                            exercises: day.exercises
                        )
                    }
                    
                    // Finish button
                    Button(action: finishWorkout) {
                        Text("Finish Workout")
                    }
                    .buttonStyle(PrimaryButton())
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            
            // Sticky header
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        // Leave session live, dismiss the full-screen cover
                        activeWorkoutStore.currentSession = nil
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.textDim)
                            .frame(width: 36, height: 36)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(day.name ?? "Workout")
                            .font(Theme.display(20))
                            .foregroundColor(Theme.text)
                        
                        Text(program.name)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textDim)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.accent)
                        Text(elapsedTimeString)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.text)
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.surface2)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .background(Theme.bg.opacity(0.95))
                
                // Progress bar
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle(tint: Theme.accent))
                    .padding(.horizontal)
            }
            
            // Floating rest bar
            if activeWorkoutStore.isResting {
                VStack(spacing: 8) {
                    Text("Rest")
                        .font(.system(size: 11, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundColor(Theme.accent)
                    
                    Text(restTimeString)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Theme.text)
                        .monospacedDigit()
                    
                    HStack(spacing: 12) {
                        Button(action: { addRestTime(15) }) {
                            Text("+15s")
                        }
                        .buttonStyle(GhostButton())
                        
                        Button(action: skipRest) {
                            Text("Skip")
                        }
                        .buttonStyle(PrimaryButton())
                    }
                    
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle(tint: Theme.accent))
                }
                .padding()
                .background(Theme.surface2)
                .cornerRadius(16)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .onAppear {
            setupAudioSession()
            requestNotificationPermission()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .sheet(isPresented: $showSummary) {
            if let summary = workoutSummary {
                WorkoutSummaryView(summary: summary) {
                    // Clear session and dismiss
                    activeWorkoutStore.currentSession = nil
                }
            }
        }
        .screenBackground()
    }
    
    private var progress: Double {
        let totalSets = activeWorkoutStore.totalSets
        guard totalSets > 0 else { return 0 }
        let completedSets = activeWorkoutStore.completedSets
        return Double(completedSets) / Double(totalSets)
    }
    
    private var elapsedTimeString: String {
        guard let session = activeWorkoutStore.currentSession else {
            return "0:00"
        }
        let start = session.startedAt
        let raw = Date().timeIntervalSince1970 - start
        let elapsed = (raw.isFinite && raw > 0) ? Int(raw) : 0
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var restTimeString: String {
        let raw = activeWorkoutStore.restEndsAt - Date().timeIntervalSince1970
        let remaining = (raw.isFinite && raw > 0) ? Int(raw) : 0
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var restProgress: Double {
        guard activeWorkoutStore.restDuration > 0 else { return 0 }
        let raw = activeWorkoutStore.restEndsAt - Date().timeIntervalSince1970
        let remaining = (raw.isFinite && raw > 0) ? Int(raw) : 0
        let elapsed = activeWorkoutStore.restDuration - remaining
        return Double(elapsed) / Double(activeWorkoutStore.restDuration)
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            activeWorkoutStore.tick()
            if activeWorkoutStore.isResting && Date().timeIntervalSince1970 >= activeWorkoutStore.restEndsAt {
                playBell()
                activeWorkoutStore.clearRest()
            }
        }
    }
    
    private func stopTimer() {
        // Timer is handled by ActiveWorkoutStore
    }
    
    private func playBell() {
        // Play bell sound
        // Fallback to local notification
        let content = UNMutableNotificationContent()
        content.title = "Rest Over"
        content.body = "Ready for your next set!"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func addRestTime(_ seconds: Int) {
        activeWorkoutStore.restEndsAt += Double(seconds)
        activeWorkoutStore.restDuration += seconds
    }
    
    private func skipRest() {
        activeWorkoutStore.clearRest()
    }
    
    private func finishWorkout() {
        guard let session = activeWorkoutStore.currentSession else {
            print("❌ No session available to finish workout")
            return
        }
        
        let totalVolume = activeWorkoutStore.sets.flatMap { $0 }.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        
        let now = Date().timeIntervalSince1970
        let rawDuration = now - session.startedAt
        let durationSeconds = (rawDuration.isFinite && rawDuration > 0) ? Int(rawDuration) : 0
        
        let log = ActiveWorkoutSummary(
            programId: session.programId,
            programName: session.program.name,
            dayId: session.dayId,
            dayName: session.day.name ?? "Workout",
            startedAt: session.startedAt,
            completedAt: now,
            durationSeconds: durationSeconds,
            setsCompleted: activeWorkoutStore.completedSets,
            totalSets: activeWorkoutStore.totalSets,
            totalVolume: totalVolume,
            sets: activeWorkoutStore.sets
        )
        
        // TODO: Save to API using the existing WorkoutLog structure
        // For now, just show the summary
        workoutSummary = log
        showSummary = true
    }
}

struct ActiveWorkoutSession: Identifiable {
    let id = UUID()
    let programId: String
    let dayId: String
    let week: Int?
    let startedAt: Double
    let program: Program
    let day: Day
}

class ActiveWorkoutStore: ObservableObject {
    static let shared = ActiveWorkoutStore()
    
    @Published var currentSession: ActiveWorkoutSession?
    @Published var sets: [[SetLog]] = []
    @Published var isResting = false
    @Published var restEndsAt: Double = 0
    @Published var restDuration: Int = 0
    private var timer: Timer?
    
    private init() {}
    
    func startWorkout(program: Program, day: Day, dayIndex: Int, week: Int? = nil) {
        print("🏋️ startWorkout called - program: \(program.name), day: \(day.name ?? "Unknown"), dayIndex: \(dayIndex)")
        
        let now = Date().timeIntervalSince1970
        
        // Initialize sets for each exercise in the day
        self.sets = day.exercises.map { exercise in
            let setCount = exercise.sets ?? 3
            return (0..<setCount).map { _ in
                SetLog(weight: 0, reps: 0, completed: false)
            }
        }
        
        print("🏋️ Workout initialized with \(day.exercises.count) exercises and \(self.sets.flatMap { $0 }.count) total sets")
        
        // Create the session with real timestamp
        self.currentSession = ActiveWorkoutSession(
            programId: program.id,
            dayId: day.id,
            week: week,
            startedAt: now,
            program: program,
            day: day
        )
        
        print("🏋️ Session created with startedAt: \(now)")
    }
    
    func tick() {
        // Called every second
    }
    
    func startRest(duration: Int) {
        isResting = true
        restDuration = duration
        restEndsAt = Date().timeIntervalSince1970 + Double(duration)
    }
    
    func clearRest() {
        isResting = false
        restEndsAt = 0
        restDuration = 0
    }
    
    var completedSets: Int {
        sets.flatMap { $0 }.filter { $0.completed }.count
    }
    
    var totalSets: Int {
        sets.flatMap { $0 }.count
    }
    
    var isActive: Bool {
        currentSession != nil
    }
}

struct ExerciseCard: View {
    let exercise: DayExercise
    let exerciseIndex: Int
    let totalExercises: Int
    let exercises: [DayExercise]
    @EnvironmentObject var activeWorkoutStore: ActiveWorkoutStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Eyebrow
            Text("Exercise \(exerciseIndex + 1) of \(totalExercises)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.accent)
            
            // Title
            Text(exerciseIdToName(exercise.exerciseId))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.text)
            
            // Sets × Reps
            if let sets = exercise.sets {
                Text("\(sets) sets × \(exercise.reps) reps")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textDim)
            }
            
            // Set table
            VStack(spacing: 0) {
                HStack {
                    Text("Set")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textDim)
                        .frame(maxWidth: .infinity)
                    Text("Weight (lbs)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textDim)
                        .frame(maxWidth: .infinity)
                    Text("Reps")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textDim)
                        .frame(maxWidth: .infinity)
                    Text("Done")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textDim)
                        .frame(width: 60)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.surface2)
                
                ForEach(Array(activeWorkoutStore.sets[exerciseIndex].enumerated()), id: \.element.id) { index, setLog in
                    SetRow(
                        setLog: Binding(
                            get: { activeWorkoutStore.sets[exerciseIndex][index] },
                            set: { activeWorkoutStore.sets[exerciseIndex][index] = $0 }
                        ),
                        setNumber: index + 1,
                        exerciseIndex: exerciseIndex,
                        restSec: exercise.restSec,
                        isLastInRound: index == (activeWorkoutStore.sets[exerciseIndex].count - 1)
                    )
                }
            }
        }
        .padding(16)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(exercise.groupId != nil ? Theme.accent : Color.clear, lineWidth: 1)
        )
    }
    
    private func exerciseIdToName(_ id: String) -> String {
        // TODO: Resolve exercise name from catalog
        return "Exercise"
    }
    
    private func isLastInRound(_ exerciseIndex: Int, _ setIndex: Int) -> Bool {
        // Check if this is the last exercise in a superset round
        if exerciseIndex < exercises.count - 1 {
            let currentGroup = exercises[exerciseIndex].groupId
            let nextGroup = exercises[exerciseIndex + 1].groupId
            return currentGroup != nil && currentGroup == nextGroup
        }
        return true
    }
}

struct SetRow: View {
    @EnvironmentObject var activeWorkoutStore: ActiveWorkoutStore
    @Binding var setLog: SetLog
    let setNumber: Int
    let exerciseIndex: Int
    let restSec: Int?
    let isLastInRound: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Set number badge
            Text("\(setNumber)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(setLog.completed ? Theme.bg : Theme.text)
                .frame(width: 28, height: 28)
                .background(setLog.completed ? Theme.accent : Theme.surface2)
                .cornerRadius(6)
            
            // Weight field
            TextField("", text: Binding(
                get: { String(format: "%.0f", setLog.weight) },
                set: { setLog.weight = Double($0) ?? 0 }
            ))
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: .infinity)
            
            // Reps field
            TextField("", text: Binding(
                get: { String(setLog.reps) },
                set: { setLog.reps = Int($0) ?? 0 }
            ))
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: .infinity)
            
            // Done toggle
            Button(action: {
                setLog.completed.toggle()
                if setLog.completed && isLastInRound, let rest = restSec, rest > 0 {
                    activeWorkoutStore.startRest(duration: rest)
                }
            }) {
                Image(systemName: setLog.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(setLog.completed ? Theme.accent : Theme.textDim)
            }
            .frame(width: 60)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(setLog.completed ? Theme.accent.opacity(0.1) : Color.clear)
    }
}

struct WorkoutSummaryView: View {
    let summary: ActiveWorkoutSummary
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Check mark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Theme.accent)
            
            Text("Workout Complete!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.text)
            
            // Stats
            HStack(spacing: 12) {
                StatCard(title: "Time", value: formatDuration(summary.durationSeconds))
                StatCard(title: "Sets", value: "\(summary.setsCompleted)")
                StatCard(title: "Volume", value: formatVolume(summary.totalVolume))
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button("Done") {
                onDone()
            }
            .buttonStyle(PrimaryButton())
            .padding(.horizontal)
        }
        .padding()
        .screenBackground()
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}