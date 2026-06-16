import SwiftUI

struct DayDetailView: View {
    let program: Program
    let day: ProgramDay
    @Environment(\.dismiss) private var dismiss
    @State private var showActiveWorkout = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Day header
                VStack(alignment: .leading, spacing: 8) {
                    Text(day.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(day.focus)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("\(day.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Exercises list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ForEach(Array(day.exercises.enumerated()), id: \.element.exerciseId) { index, exercise in
                        ExerciseRow(exercise: exercise, index: index + 1)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Start Workout") {
                    showActiveWorkout = true
                }
                .foregroundColor(.green)
            }
        }
        .sheet(isPresented: $showActiveWorkout) {
            // TODO: Navigate to ActiveWorkoutView via store
            Text("Active Workout")
        }
    }
}

struct ExerciseRow: View {
    let exercise: PlannedExercise
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index).")
                    .font(.headline)
                    .foregroundColor(.green)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name ?? "Custom Exercise")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        Label("\(exercise.sets) sets", systemImage: "repeat")
                        Label(exercise.reps, systemImage: "chart.bar.fill")
                        Label("\(exercise.restSec)s rest", systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 40)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationView {
        DayDetailView(
            program: Program(
                id: "1",
                name: "Full Body Blast",
                category: "Bodybuilding",
                level: "Intermediate",
                coach: "Coach Smith",
                durationWeeks: 8,
                daysPerWeek: 3,
                days: []
            ),
            day: ProgramDay(
                id: "1",
                name: "Day 1",
                focus: "Chest & Back",
                exercises: [
                    PlannedExercise(
                        exerciseId: "ex1",
                        name: "Bench Press",
                        sets: 3,
                        reps: "8-12",
                        restSec: 90,
                        notes: "Keep form strict"
                    ),
                    PlannedExercise(
                        exerciseId: "ex2",
                        name: "Rows",
                        sets: 3,
                        reps: "10-12",
                        restSec: 60,
                        notes: nil
                    )
                ]
            )
        )
    }
}