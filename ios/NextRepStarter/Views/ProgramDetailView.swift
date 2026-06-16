import SwiftUI

struct ProgramDetailView: View {
    @Environment(AppStore.self) private var store
    @State private var shareMessage: String?
    let program: Program

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("Workout Days")
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    if program.days.isEmpty {
                        Text("No days have been added to this program yet.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textDim)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                    } else {
                        ForEach(Array(program.days.enumerated()), id: \.element.id) { index, day in
                            ProgramDayCard(
                                program: program,
                                day: day,
                                dayNumber: index + 1,
                                loggedSetCount: loggedSetCount(for: day),
                                exerciseName: exerciseName
                            )
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if store.isCustomProgram(program) {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 13) {
                        NavigationLink {
                            ProgramEditorView(program: program)
                        } label: {
                            Image(systemName: "pencil")
                        }

                        Button {
                            Task {
                                await store.shareProgram(program)
                                shareMessage = "Program shared"
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .tint(Theme.accentLight)
                }
            }
        }
        .screenBackground()
        .overlay(alignment: .bottom) {
            if let shareMessage {
                Text(shareMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.accent)
                    .clipShape(Capsule())
                    .padding(.bottom, 18)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            self.shareMessage = nil
                        }
                    }
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(program.category) · \(program.level)")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .foregroundStyle(accent)

                Text(program.name)
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(program.summary)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !program.description.isEmpty {
                Text(program.description)
                    .font(.footnote)
                    .foregroundStyle(Theme.textDim)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                MetricTile(label: "Weeks", value: "\(program.durationWeeks)", accent: accent)
                MetricTile(label: "Days/wk", value: "\(program.daysPerWeek)", accent: accent)
                MetricTile(label: "Days", value: "\(program.days.count)", accent: accent)
            }
        }
        .padding(18)
        .background {
            LinearGradient(
                colors: [accent.opacity(0.24), Theme.surface],
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

    private func exerciseName(for planned: PlannedExercise) -> String {
        if let name = planned.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }

        let allExercises = store.catalog.exercises + store.appData.customExercises
        return allExercises.first(where: { $0.id == planned.exerciseId })?.name ?? planned.exerciseId
    }

    private func latestLog(for day: ProgramDay) -> WorkoutLog? {
        store.appData.logs
            .filter { $0.programId == program.id && $0.dayId == day.id }
            .sorted { programDetailLogDate($0) > programDetailLogDate($1) }
            .first
    }

    private func loggedSetCount(for day: ProgramDay) -> Int {
        latestLog(for: day).map(completedSetCount) ?? 0
    }

    private func completedSetCount(_ log: WorkoutLog) -> Int {
        log.exercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }
}

private struct MetricTile: View {
    let label: String
    let value: String
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

private struct ProgramDayCard: View {
    let program: Program
    let day: ProgramDay
    let dayNumber: Int
    let loggedSetCount: Int
    let exerciseName: (PlannedExercise) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(dayNumber)")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1.3)
                        .foregroundStyle(accent)

                    Text(day.name)
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    if !day.focus.isEmpty {
                        Text(day.focus)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textDim)
                    }
                }

                Spacer()

                NavigationLink {
                    DayDetailView(program: program, day: day, dayNumber: dayNumber)
                } label: {
                    Text("View")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(accent.opacity(0.14))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ActiveWorkoutView(program: program, day: day)
                } label: {
                    Text(loggedSetCount > 0 ? "Repeat" : "Start")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if loggedSetCount > 0 {
                Label("\(loggedSetCount) set\(loggedSetCount == 1 ? "" : "s") logged", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
            }

            if day.exercises.isEmpty {
                Text("No exercises added.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textFaint)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(day.exercises.enumerated()), id: \.offset) { index, planned in
                        ExercisePlanRow(index: index + 1, planned: planned, name: exerciseName(planned))

                        if index < day.exercises.count - 1 {
                            Divider()
                                .overlay(.white.opacity(0.08))
                        }
                    }
                }
                .background(Theme.inputBg.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .cardStyle()
    }

    private var accent: Color {
        Color(hex: program.accent)
    }
}

private func programDetailLogDate(_ log: WorkoutLog) -> Date {
    ISO8601DateFormatter().date(from: log.date) ?? .distantPast
}

private struct ExercisePlanRow: View {
    let index: Int
    let planned: PlannedExercise
    let name: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textFaint)
                .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)

                Text("\(planned.sets) x \(planned.reps) · \(planned.restSec)s rest")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)

                if let notes = planned.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Theme.textFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
