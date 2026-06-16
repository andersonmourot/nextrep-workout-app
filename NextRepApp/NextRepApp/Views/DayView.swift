import SwiftUI

struct DayView: View {
    let program: Program
    let day: Day
    @State private var isActive = false
    @EnvironmentObject var activeWorkoutStore: ActiveWorkoutStore
    @State private var selectedRoute: AppRoute?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(day.name ?? "Workout")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.text)
                    
                    if let focus = day.focus {
                        Text(focus)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textDim)
                    }
                    
                    Text(program.name)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardStyle()
                
                // Start workout button
                Button(action: {
                    print("🏋️ Start button tapped for day: \(day.name ?? "Unknown")")
                    
                    // Find the day index in the program
                    if let dayIndex = program.days.firstIndex(where: { $0.id == day.id }) {
                        print("🏋️ Day index found: \(dayIndex)")
                        
                        // Start the workout in the store
                        activeWorkoutStore.startWorkout(
                            program: program,
                            day: day,
                            dayIndex: dayIndex,
                            week: nil
                        )
                        
                        // Navigate to active workout using path-based navigation
                        selectedRoute = .activeWorkout(program: program, day: day)
                        print("🏋️ Set selectedRoute to .activeWorkout")
                    } else {
                        print("❌ Day index not found")
                    }
                }) {
                    Text("Start Workout")
                }
                .buttonStyle(PrimaryButton())
                .padding(.horizontal)
                
                // Exercises list
                VStack(alignment: .leading, spacing: 16) {
                    Text("Exercises")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.text)
                    
                    ForEach(day.exercises) { exercise in
                        ExerciseRowView(dayExercise: exercise)
                    }
                }
                .padding()
                
                Spacer()
            }
            .background(Theme.bg)
        }
        .navigationTitle("Day Detail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedRoute) { route in
            switch route {
            case .activeWorkout(let program, let day):
                if let day = day {
                    ActiveWorkoutView(program: program, day: day)
                } else {
                    EmptyView()
                }
            default:
                EmptyView()
            }
        }
        .screenBackground()
    }
}

struct ExerciseRowView: View {
    let dayExercise: DayExercise
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Exercise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.text)
                
                Text("\(dayExercise.sets ?? 0) sets × \(dayExercise.reps)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textDim)
            }
            
            Spacer()
            
            if let rest = dayExercise.restSec {
                Text("\(rest)s rest")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textDim)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.surface2)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .cardStyle()
    }
}