import SwiftUI

struct DayDetailView: View {
    @Environment(AppStore.self) private var store
    let program: Program
    let day: ProgramDay
    let dayNumber: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero

                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercise Plan")
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    if day.exercises.isEmpty {
                        Text("No exercises have been added to this day.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textDim)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                    } else {
                        ForEach(Array(day.exercises.enumerated()), id: \.offset) { index, planned in
                            DayExerciseCard(
                                index: index + 1,
                                planned: planned,
                                exercise: exercise(for: planned),
                                fallbackName: exerciseName(for: planned)
                            )
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(day.name)
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Day \(dayNumber) · \(program.name)")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .foregroundStyle(accent)

                Text(day.name)
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundStyle(Theme.text)

                if !day.focus.isEmpty {
                    Text(day.focus)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                }
            }

            HStack(spacing: 10) {
                DayMetricTile(value: "\(day.exercises.count)", label: "Exercises", accent: accent)
                DayMetricTile(value: "\(plannedSetCount)", label: "Sets", accent: accent)
                DayMetricTile(value: "\(loggedSetCount)", label: "Logged", accent: accent)
            }

            NavigationLink {
                ActiveWorkoutView(program: program, day: day)
            } label: {
                Text(loggedSetCount > 0 ? "Repeat Workout" : "Start Workout")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(18)
        .background {
            LinearGradient(
                colors: [accent.opacity(0.22), Theme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        }
    }

    private var accent: Color {
        Color(hex: program.accent)
    }

    private var plannedSetCount: Int {
        day.exercises.reduce(0) { total, planned in
            total + planned.sets
        }
    }

    private var loggedSetCount: Int {
        latestLog?.exercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        } ?? 0
    }

    private var latestLog: WorkoutLog? {
        store.appData.logs
            .filter { $0.programId == program.id && $0.dayId == day.id }
            .sorted { dayDetailLogDate($0) > dayDetailLogDate($1) }
            .first
    }

    private func exercise(for planned: PlannedExercise) -> Exercise? {
        store.allExercises.first(where: { $0.id == planned.exerciseId })
    }

    private func exerciseName(for planned: PlannedExercise) -> String {
        if let name = planned.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }

        return exercise(for: planned)?.name ?? planned.exerciseId
    }
}

private struct DayMetricTile: View {
    let value: String
    let label: String
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.text)

            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.1)
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface2.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DayExerciseCard: View {
    let index: Int
    let planned: PlannedExercise
    let exercise: Exercise?
    let fallbackName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(index)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textFaint)
                    .frame(width: 22, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    if let exercise {
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            HStack(spacing: 6) {
                                Text(exercise.name)
                                    .font(.headline)
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.bold))
                            }
                            .foregroundStyle(Theme.text)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(fallbackName)
                            .font(.headline)
                            .foregroundStyle(Theme.text)
                    }

                    Text("\(planned.sets) x \(planned.reps) · \(planned.restSec)s rest")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)

                    if let groupId = planned.groupId, !groupId.isEmpty {
                        Text("Superset \(groupId)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.accentLight)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accent.opacity(0.14))
                            .clipShape(Capsule())
                    }
                }

                Spacer(minLength: 0)
            }

            if let notes = planned.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(Theme.textFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardStyle()
    }
}

private func dayDetailLogDate(_ log: WorkoutLog) -> Date {
    ISO8601DateFormatter().date(from: log.date) ?? .distantPast
}
