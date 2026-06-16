import SwiftUI

struct ProgramHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = AppStore()
    @State private var selectedCompletedProgram: CompletedProgram?
    @State private var showingDetail: Bool = false
    @State private var deleteConfirmId: String? = nil
    
    private var completedPrograms: [CompletedProgram] {
        store.appData.completedPrograms.sorted { $0.completedAt > $1.completedAt }
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(Theme.text)
                            Text("Programs")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.text)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Theme.surface)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title + subtitle
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Program History")
                                .font(Theme.display(28))
                                .foregroundColor(Theme.text)
                                .tracking(1)
                            
                            Text("Completed programs are saved here.")
                                .font(Theme.body(12))
                                .foregroundColor(Theme.textDim)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Completed programs list
                        if completedPrograms.isEmpty {
                            Text("No completed programs yet")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.placeholder)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 80)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(completedPrograms) { completed in
                                    completedProgramCard(completed: completed)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationDestination(isPresented: $showingDetail) {
            if let completed = selectedCompletedProgram {
                ProgramHistoryDetailView(completedProgram: completed)
            }
        }
        .task {
            await store.loadAppData()
        }
    }
    
    private func completedProgramCard(completed: CompletedProgram) -> some View {
        let isDeleting = deleteConfirmId == completed.id
        let accentColor = hexToColor(completed.accent ?? Theme.accentHex)
        
        return Button(action: {
            if !isDeleting {
                selectedCompletedProgram = completed
                showingDetail = true
            }
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(completed.name)
                        .font(Theme.body(14))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.text)
                    
                    HStack(spacing: 4) {
                        Text(formatDate(completed.completedAt))
                            .font(Theme.body(10))
                            .foregroundColor(Theme.textDim)
                        
                        Text("·")
                            .font(Theme.body(10))
                            .foregroundColor(Theme.textDim)
                        
                        Text("\(completed.loggedWorkoutCount) workouts")
                            .font(Theme.body(10))
                            .foregroundColor(Theme.textDim)
                    }
                }
                
                Spacer()
                
                if isDeleting {
                    HStack(spacing: 8) {
                        Button(action: {
                            Task {
                                await store.removeCompletedProgram(id: completed.id)
                                deleteConfirmId = nil
                            }
                        }) {
                            Text("Confirm")
                                .font(Theme.body(12))
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            deleteConfirmId = nil
                        }) {
                            Text("Cancel")
                                .font(Theme.body(12))
                                .foregroundColor(Theme.textDim)
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        Button(action: {
                            deleteConfirmId = completed.id
                        }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Theme.textDim)
                    }
                }
            }
            .padding(12)
            .background(Theme.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Program History Detail View

struct ProgramHistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let completedProgram: CompletedProgram
    @StateObject private var store = AppStore()
    
    private var programLogs: [WorkoutLog] {
        let filtered = store.appData.logs.filter { $0.programId == completedProgram.program.id }
        return filtered.sorted { $0.date > $1.date }
    }
    
    private var accentColor: Color {
        hexToColor(completedProgram.accent ?? Theme.accentHex)
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(Theme.text)
                            Text("History")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.text)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Theme.surface)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Program name + completed date
                        VStack(alignment: .leading, spacing: 8) {
                            Text(completedProgram.program.name)
                                .font(Theme.display(28))
                                .foregroundColor(Theme.text)
                                .tracking(1)
                            
                            HStack(spacing: 4) {
                                Text("Completed")
                                    .font(Theme.body(12))
                                    .foregroundColor(Theme.textDim)
                                
                                Text("·")
                                    .font(Theme.body(12))
                                    .foregroundColor(Theme.textDim)
                                
                                Text(formatDate(completedProgram.completedAt))
                                    .font(Theme.body(12))
                                    .foregroundColor(accentColor)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Archived workout logs by day
                        if programLogs.isEmpty {
                            Text("No workout logs found")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.placeholder)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(programLogs) { log in
                                    workoutLogCard(log: log)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await store.loadAppData()
        }
    }
    
    private func workoutLogCard(log: WorkoutLog) -> some View {
        let day = completedProgram.program.days.first { $0.id == log.dayId }
        
        let dayName = day?.name ?? "Workout"
        let dateStr = formatDate(log.date)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Day name + date
            HStack {
                Text(dayName)
                    .font(Theme.body(14))
                    .fontWeight(.semibold)
                    .foregroundColor(accentColor)
                
                Spacer()
                
                Text(dateStr)
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
            }
            
            // Exercise logs with weights × reps
            VStack(spacing: 8) {
                ForEach(log.exercises) { exerciseLog in
                    exerciseLogRow(exerciseLog: exerciseLog)
                }
            }
        }
        .padding(12)
        .background(Theme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func exerciseLogRow(exerciseLog: ExerciseLog) -> some View {
        let exercise = store.allExercises.first { $0.id == exerciseLog.exerciseId }
        let exerciseName = exercise?.name ?? "Exercise"
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(exerciseName)
                .font(Theme.body(12))
                .fontWeight(.semibold)
                .foregroundColor(Theme.text)
            
            HStack(spacing: 8) {
                ForEach(exerciseLog.sets) { set in
                    Text("\(Int(set.weight))×\(set.reps)")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                }
            }
        }
        .padding(8)
        .background(Theme.surface2)
        .cornerRadius(8)
    }
}