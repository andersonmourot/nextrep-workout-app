import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.text)
                    
                    if let primaryMuscle = exercise.primaryMuscle {
                        Text(primaryMuscle)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardStyle()
                
                // Details
                VStack(alignment: .leading, spacing: 16) {
                    if let equipment = exercise.equipment {
                        DetailRow(label: "Equipment", value: equipment)
                    }
                    
                    if let difficulty = exercise.difficulty {
                        DetailRow(label: "Difficulty", value: difficulty)
                    }
                    
                    if let secondaryMuscles = exercise.secondaryMuscles, !secondaryMuscles.isEmpty {
                        DetailRow(label: "Secondary Muscles", value: secondaryMuscles.joined(separator: ", "))
                    }
                }
                .padding()
                .cardStyle()
                
                // Instructions
                if let instructions = exercise.instructions, !instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.text)
                        
                        ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1).")
                                    .foregroundColor(Theme.textDim)
                                    .frame(width: 24)
                                
                                Text(instruction)
                                    .foregroundColor(Theme.text)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .cardStyle()
                }
                
                // Tips
                if let tips = exercise.tips, !tips.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.text)
                        
                        ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(Theme.accent)
                                
                                Text(tip)
                                    .foregroundColor(Theme.text)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .cardStyle()
                }
                
                Spacer()
            }
            .padding()
            .background(Theme.bg)
        }
        .navigationTitle("Exercise Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Theme.textDim)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.text)
        }
    }
}