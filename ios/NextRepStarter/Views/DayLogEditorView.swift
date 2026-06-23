import SwiftUI

struct DayLogEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let program: Program
    let day: ProgramDay
    let week: Int
    let existingLog: WorkoutLog?

    @State private var sets: [[SetLog]]
    @State private var savedMessage: String?

    init(program: Program, day: ProgramDay, week: Int, existingLog: WorkoutLog?) {
        self.program = program
        self.day = day
        self.week = week
        self.existingLog = existingLog
        _sets = State(initialValue: Self.initialSets(day: day, existingLog: existingLog))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                exerciseLogs
                saveButton
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(existingLog == nil ? "Log Day" : "Edit Log")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .overlay(alignment: .bottom) {
            if let savedMessage {
                Text(savedMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.accent)
                    .clipShape(Capsule())
                    .padding(.bottom, 18)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.savedMessage = nil
                            dismiss()
                        }
                    }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Week \(week) · \(program.name)")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundStyle(Theme.accentLight)

            Text(day.name)
                .font(.system(size: 32, weight: .bold, design: .default))
                .foregroundStyle(Theme.text)

            if !day.focus.isEmpty {
                Text(day.focus)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            }
        }
    }

    private var exerciseLogs: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(day.exercises.enumerated()), id: \.offset) { exerciseIndex, planned in
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exerciseName(for: planned))
                            .font(.headline)
                            .foregroundStyle(Theme.text)

                        Text("\(planned.sets) x \(planned.reps) · \(planned.restSec)s rest")
                            .font(.caption)
                            .foregroundStyle(Theme.textDim)
                    }

                    ForEach(Array((sets.indices.contains(exerciseIndex) ? sets[exerciseIndex] : []).enumerated()), id: \.offset) { setIndex, set in
                        DaySetLogRow(
                            index: setIndex,
                            set: set,
                            unit: store.appData.unit,
                            onWeight: { updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: $0) },
                            onReps: { updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: $0) },
                            onCompleted: { updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, completed: $0) }
                        )
                    }
                }
                .cardStyle()
            }
        }
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text(existingLog == nil ? "Save Workout Log" : "Update Workout Log")
        }
        .buttonStyle(PrimaryButtonStyle())
    }

    private func updateSet(exerciseIndex: Int, setIndex: Int, weight: Double? = nil, reps: Int? = nil, completed: Bool? = nil) {
        guard sets.indices.contains(exerciseIndex), sets[exerciseIndex].indices.contains(setIndex) else {
            return
        }

        if let weight { sets[exerciseIndex][setIndex].weight = max(0, weight) }
        if let reps { sets[exerciseIndex][setIndex].reps = max(0, reps) }
        if let completed { sets[exerciseIndex][setIndex].completed = completed }
    }

    private func save() {
        let loggedExercises = day.exercises.enumerated().map { index, planned in
            LoggedExercise(
                exerciseId: planned.exerciseId,
                sets: (sets.indices.contains(index) ? sets[index] : []).filter(\.completed)
            )
        }

        let totalVolume = loggedExercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { subtotal, set in
                subtotal + set.weight * Double(set.reps)
            }
        }

        let log = WorkoutLog(
            id: existingLog?.id ?? UUID().uuidString,
            date: existingLog?.date ?? ISO8601DateFormatter().string(from: Date()),
            programId: program.id,
            programName: program.name,
            dayId: day.id,
            dayName: day.name,
            week: week,
            durationSec: existingLog?.durationSec ?? 0,
            exercises: loggedExercises,
            totalVolume: totalVolume,
            notes: existingLog?.notes
        )

        store.upsertWorkoutLog(log, program: program)
        savedMessage = "Workout log saved"
    }

    private func exerciseName(for planned: PlannedExercise) -> String {
        if let name = planned.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        return store.allExercises.first(where: { $0.id == planned.exerciseId })?.name ?? planned.exerciseId
    }

    private static func initialSets(day: ProgramDay, existingLog: WorkoutLog?) -> [[SetLog]] {
        day.exercises.enumerated().map { index, planned in
            if let logged = existingLog?.exercises[safe: index], !logged.sets.isEmpty {
                var rows = Array(logged.sets.prefix(planned.sets))
                while rows.count < planned.sets {
                    rows.append(SetLog(weight: 0, reps: parseReps(planned.reps), completed: false))
                }
                return rows
            }

            return (0..<planned.sets).map { _ in
                SetLog(weight: 0, reps: parseReps(planned.reps), completed: false)
            }
        }
    }

    private static func parseReps(_ reps: String) -> Int {
        let digits = reps.prefix { $0.isNumber }
        return Int(digits) ?? 10
    }
}

private struct DaySetLogRow: View {
    let index: Int
    let set: SetLog
    let unit: String
    let onWeight: (Double) -> Void
    let onReps: (Int) -> Void
    let onCompleted: (Bool) -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Set \(index + 1)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Spacer()
                Button {
                    onCompleted(!set.completed)
                } label: {
                    Label(set.completed ? "Done" : "Mark Done", systemImage: set.completed ? "checkmark.circle.fill" : "circle")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(set.completed ? Theme.accentLight : Theme.textDim)
            }

            HStack(spacing: 10) {
                dayNumberField("Weight", value: set.weight == 0 ? "" : formatDayLogWeight(set.weight), unit: unit, keyboard: .decimalPad) {
                    onWeight(Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0)
                }
                dayNumberField("Reps", value: set.reps == 0 ? "" : "\(set.reps)", unit: "", keyboard: .numberPad) {
                    onReps(Int($0.filter(\.isNumber)) ?? 0)
                }
            }
        }
        .padding(12)
        .background(set.completed ? Theme.accent.opacity(0.14) : Theme.inputBg.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(set.completed ? Theme.accent.opacity(0.45) : .white.opacity(0.06), lineWidth: 1)
        }
    }

    private func dayNumberField(_ title: String, value: String, unit: String, keyboard: UIKeyboardType, onChange: @escaping (String) -> Void) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Theme.textFaint)
            TextField(title, text: Binding(get: { value }, set: onChange))
                .keyboardType(keyboard)
                .multilineTextAlignment(.center)
                .font(.headline.monospacedDigit())
                .foregroundStyle(Theme.text)
                .padding(.vertical, 8)
                .background(Theme.inputBg)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Theme.textFaint)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private func formatDayLogWeight(_ weight: Double) -> String {
    if weight.rounded() == weight {
        return "\(Int(weight))"
    }
    return String(format: "%.1f", weight)
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
