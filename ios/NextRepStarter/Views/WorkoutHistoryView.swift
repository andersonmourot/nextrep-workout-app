import Foundation
import SwiftUI

struct WorkoutHistoryView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                profileStats

                if sortedLogs.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedLogs) { log in
                            NavigationLink {
                                WorkoutLogDetailView(log: log)
                            } label: {
                                WorkoutLogRow(log: log, unit: store.appData.unit)
                            }
                            .buttonStyle(.plain)
                        }
                    }

    private var profileStats: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            ProfileStatTile(
                icon: "dumbbell.fill",
                value: "\(store.appData.logs.count)",
                label: "Workouts"
            )
            ProfileStatTile(
                icon: "chart.line.uptrend.xyaxis",
                value: formatVolume(totalVolume),
                label: "Volume \(store.appData.unit)"
            )
            ProfileStatTile(
                icon: "checkmark.circle.fill",
                value: "\(completedSetTotal)",
                label: "Sets"
            )
            ProfileStatTile(
                icon: "flame.fill",
                value: "\(profileStreak)",
                label: "Streak"
            )
        }
    }

    private var totalVolume: Double {
        store.appData.logs.reduce(0) { total, log in
            total + log.totalVolume
        }
    }

    private var completedSetTotal: Int {
        store.appData.logs.reduce(0) { total, log in
            total + completedSetCount(log)
        }
    }

    private var profileStreak: Int {
        computeProfileStreak(logs: store.appData.logs)
    }
                }

private struct ProfileStatTile: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Theme.accentLight)

            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.0)
                .foregroundStyle(Theme.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.05), lineWidth: 1)
        }
    }
}
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var sortedLogs: [WorkoutLog] {
        store.appData.logs.sorted { lhs, rhs in
            logDate(lhs) > logDate(rhs)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Workout History")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("\(store.appData.logs.count) completed")
                .font(.caption)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Theme.accentLight)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No workouts yet", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(Theme.text)

            Text("Finished workouts will appear here with the weight and reps you logged.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct WorkoutLogDetailView: View {
    @Environment(AppStore.self) private var store
    let log: WorkoutLog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("Logged Exercises")
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    ForEach(Array(log.exercises.enumerated()), id: \.offset) { _, exercise in
                        LoggedExerciseCard(
                            exercise: exercise,
                            name: exerciseName(for: exercise.exerciseId),
                            unit: store.appData.unit
                        )
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(log.dayName)
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(log.programName)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.3)
                    .foregroundStyle(Theme.accentLight)

                Text(log.dayName)
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .foregroundStyle(Theme.text)

                Text(formatDate(log.date))
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            }

            HStack(spacing: 10) {
                HistoryMetricTile(value: formatDuration(log.durationSec), label: "Time")
                HistoryMetricTile(value: "\(completedSetCount(log))", label: "Sets")
                HistoryMetricTile(value: formatVolume(log.totalVolume), label: "Vol \(store.appData.unit)")
            }
        }
        .cardStyle()
    }

    private func exerciseName(for exerciseId: String) -> String {
        let allExercises = store.catalog.exercises + store.appData.customExercises
        return allExercises.first(where: { $0.id == exerciseId })?.name ?? exerciseId
    }
}

private struct WorkoutLogRow: View {
    let log: WorkoutLog
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.dayName)
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    Text("\(log.programName) · \(formatDate(log.date))")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textFaint)
            }

            HStack(spacing: 10) {
                chip(systemImage: "timer", text: formatDuration(log.durationSec))
                chip(systemImage: "list.bullet", text: "\(completedSetCount(log)) sets")
                chip(systemImage: "chart.line.uptrend.xyaxis", text: "\(formatVolume(log.totalVolume)) \(unit)")
            }
        }
        .cardStyle()
    }

    private func chip(systemImage: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Theme.textDim)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Theme.surface2)
        .clipShape(Capsule())
    }
}

private struct LoggedExerciseCard: View {
    let exercise: LoggedExercise
    let name: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name)
                .font(.headline)
                .foregroundStyle(Theme.text)

            if exercise.sets.isEmpty {
                Text("No completed sets were saved for this exercise.")
                    .font(.caption)
                    .foregroundStyle(Theme.textFaint)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.text)

                            Spacer()

                            Text("\(formatWeight(set.weight)) \(unit) x \(set.reps)")
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .foregroundStyle(Theme.accentLight)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)

                        if index < exercise.sets.count - 1 {
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
}

private struct HistoryMetricTile: View {
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

private func completedSetCount(_ log: WorkoutLog) -> Int {
    log.exercises.reduce(0) { total, exercise in
        total + exercise.sets.count
    }
}

private func computeProfileStreak(logs: [WorkoutLog]) -> Int {
    guard !logs.isEmpty else {
        return 0
    }

    let days = Set(logs.compactMap { localDayKey($0.date) })
    var cursor = Calendar.current.startOfDay(for: Date())

    if !days.contains(dayKey(cursor)) {
        cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
    }

    var streak = 0
    while days.contains(dayKey(cursor)) {
        streak += 1
        cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
    }

    return streak
}

private func localDayKey(_ value: String) -> String? {
    parseDate(value).map(dayKey)
}

private func dayKey(_ date: Date) -> String {
    DayKeyFormatter.shared.string(from: date)
}

private func logDate(_ log: WorkoutLog) -> Date {
    parseDate(log.date) ?? .distantPast
}

private func parseDate(_ value: String) -> Date? {
    if let date = ISO8601DateFormatter().date(from: value) {
        return date
    }

    return SelfDateFormatter.shared.date(from: value)
}

private func formatDate(_ value: String) -> String {
    guard let date = parseDate(value) else {
        return value
    }

    return DisplayDateFormatter.shared.string(from: date)
}

private func formatDuration(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainder = seconds % 60
    return "\(minutes)m \(remainder)s"
}

private func formatVolume(_ volume: Double) -> String {
    if volume.rounded() == volume {
        return "\(Int(volume))"
    }

    return String(format: "%.1f", volume)
}

private func formatWeight(_ weight: Double) -> String {
    if weight.rounded() == weight {
        return "\(Int(weight))"
    }

    return String(format: "%.1f", weight)
}

private enum DisplayDateFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private enum DayKeyFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private enum SelfDateFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
