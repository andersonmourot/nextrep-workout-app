import SwiftUI

struct DayView: View {
    let program: Program
    let day: Day
    @State private var isActive = false
    
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
                    // Navigate to active workout
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