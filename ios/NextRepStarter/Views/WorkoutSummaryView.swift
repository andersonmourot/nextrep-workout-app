import SwiftUI

struct WorkoutSummaryView: View {
    @Environment(AppStore.self) private var store
    let log: WorkoutLog
    let unit: String
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero

                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises Logged")
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    ForEach(Array(nonEmptyExercises.enumerated()), id: \.offset) { _, exercise in
                        SummaryExerciseRow(
                            name: exerciseName(for: exercise.exerciseId),
                            setCount: exercise.sets.count,
                            volume: exerciseVolume(exercise),
                            unit: unit
                        )
                    }

                    if nonEmptyExercises.isEmpty {
                        Text("No completed sets were saved.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textDim)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                    }
                }

                Button {
                    onDone()
                } label: {
                    Text("Done")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .screenBackground()
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Workout Complete")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .foregroundStyle(Theme.accentLight)

                Text(log.dayName)
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundStyle(Theme.text)

                Text(log.programName)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            }

            HStack(spacing: 10) {
                SummaryMetricTile(value: formatDuration(log.durationSec), label: "Time")
                SummaryMetricTile(value: "\(completedSetCount)", label: "Sets")
                SummaryMetricTile(value: formatNumber(log.totalVolume), label: "Vol \(unit)")
            }
        }
        .cardStyle()
    }

    private var nonEmptyExercises: [LoggedExercise] {
        log.exercises.filter { !$0.sets.isEmpty }
    }

    private var completedSetCount: Int {
        log.exercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }

    private func exerciseName(for exerciseId: String) -> String {
        let allExercises = store.catalog.exercises + store.appData.customExercises
        return allExercises.first(where: { $0.id == exerciseId })?.name ?? exerciseId
    }

    private func exerciseVolume(_ exercise: LoggedExercise) -> Double {
        exercise.sets.reduce(0) { total, set in
            total + (set.weight * Double(set.reps))
        }
    }
}

private struct SummaryMetricTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.bold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.1)
                .foregroundStyle(Theme.accentLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface2.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SummaryExerciseRow: View {
    let name: String
    let setCount: Int
    let volume: Double
    let unit: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.accentLight)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)

                Text("\(setCount) set\(setCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }

            Spacer()

            Text("\(formatNumber(volume)) \(unit)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(Theme.accentLight)
        }
        .cardStyle()
    }
}

private func formatDuration(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainder = seconds % 60
    return "\(minutes)m \(remainder)s"
}

private func formatNumber(_ value: Double) -> String {
    if value.rounded() == value {
        return "\(Int(value))"
    }

    return String(format: "%.1f", value)
}
