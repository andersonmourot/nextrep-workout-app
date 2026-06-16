import SwiftUI

struct WorkoutHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = AppStore()
    
    private var recentWorkouts: [WorkoutLog] {
        store.userLogs.sorted { $0.date > $1.date }.prefix(20).map { $0 }
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
                            Text("Progress")
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
                            Text("Workout History")
                                .font(Theme.display(28))
                                .foregroundColor(Theme.text)
                                .tracking(1)
                            
                            Text("Your 20 most recent finished workouts.")
                                .font(Theme.body(12))
                                .foregroundColor(Theme.textDim)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Workout list
                        if recentWorkouts.isEmpty {
                            Text("No workouts yet")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.placeholder)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 80)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(recentWorkouts) { log in
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
        let program = store.allPrograms.first { $0.id == log.programId }
        let day = program?.days.first { $0.id == log.dayId }
        let setCount = log.exercises.reduce(0) { $0 + $1.sets.count }
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day?.name ?? "Workout")
                    .font(Theme.body(14))
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.text)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await deleteLog(log)
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Text("\(program?.name ?? "Program") · \(formatDate(log.date))")
                .font(Theme.body(10))
                .foregroundColor(Theme.textDim)
            
            HStack(spacing: 8) {
                Text("\(setCount) sets")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
                
                Image(systemName: "arrow.up")
                    .font(.caption)
                    .foregroundColor(Theme.accent)
                
                Text(String(format: "%.0f", log.totalVolume))
                    .font(Theme.body(10))
                    .foregroundColor(Theme.accent)
            }
        }
        .padding(12)
        .background(Theme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func deleteLog(_ log: WorkoutLog) async {
        store.appData.logs.removeAll { $0.id == log.id }
        await store.saveAppData()
    }
}