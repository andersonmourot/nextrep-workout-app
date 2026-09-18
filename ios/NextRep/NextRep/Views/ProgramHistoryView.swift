import SwiftUI

struct CompletedProgramHistoryView: View {
    @Environment(AppStore.self) private var store
    @State private var pendingDelete: CompletedProgram?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if sortedPrograms.isEmpty {
                    emptyState
                } else {
                    ForEach(sortedPrograms) { entry in
                        NavigationLink {
                            CompletedProgramArchiveDetailView(entry: entry)
                        } label: {
                            CompletedProgramRow(entry: entry) {
                                pendingDelete = entry
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Program History")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .alert("Delete Archived Program?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let pendingDelete {
                    store.removeCompletedProgram(id: pendingDelete.id)
                }
                pendingDelete = nil
            }
        } message: {
            Text("This removes the completed program archive from your synced data.")
        }
    }

    private var sortedPrograms: [CompletedProgram] {
        store.appData.completedPrograms.sorted { lhs, rhs in
            domainParseStoredDate(lhs.completedAt) > domainParseStoredDate(rhs.completedAt)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Program History")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("Completed programs are saved here.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No completed programs yet", systemImage: "archivebox")
                .font(.headline)
                .foregroundStyle(Theme.text)
            Text("Finish every scheduled day of a program and it will be archived here.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
        .cardStyle()
    }
}

private struct CompletedProgramRow: View {
    let entry: CompletedProgram
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Completed")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(Color(hex: entry.accent))

                Text(entry.name)
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Text("\(formatProgramHistoryDate(entry.completedAt)) · \(entry.durationWeeks) weeks · \(entry.logs.count) workouts")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }

            Spacer()

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red.opacity(0.8))

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textFaint)
        }
        .padding(16)
        .background {
            LinearGradient(
                colors: [Color(hex: entry.accent).opacity(0.18), Theme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.05), lineWidth: 1)
        }
    }
}

struct CompletedProgramArchiveDetailView: View {
    @Environment(AppStore.self) private var store
    let entry: CompletedProgram

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero

                ForEach(Array(entry.logs.enumerated()), id: \.element.id) { index, log in
                    completedLogCard(index: index, log: log)
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed · \(formatProgramHistoryDate(entry.completedAt))")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.3)
                .foregroundStyle(Color(hex: entry.accent))

            Text(entry.name)
                .font(.system(size: 30, weight: .bold, design: .default))
                .foregroundStyle(Theme.text)

            HStack(spacing: 10) {
                historyMetric("Weeks", "\(entry.durationWeeks)")
                historyMetric("Workouts", "\(entry.logs.count)")
                historyMetric("Days/wk", "\(entry.daysPerWeek)")
            }
        }
        .cardStyle()
    }

    private func completedLogCard(index: Int, log: WorkoutLog) -> some View {
        let daysLength = max(1, entry.program.days.count)
        let week = log.week ?? (index / daysLength) + 1
        let dayIndex = entry.program.days.firstIndex(where: { $0.id == log.dayId }) ?? (index % daysLength)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(week) · Day \(dayIndex + 1)")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundStyle(Color(hex: entry.accent))

                    Text(log.dayName)
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                }

                Spacer()

                Text(formatProgramHistoryDate(log.date))
                    .font(.caption)
                    .foregroundStyle(Theme.textFaint)
            }

            if log.exercises.isEmpty {
                Text("No sets logged.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            } else {
                ForEach(Array(log.exercises.enumerated()), id: \.offset) { _, exercise in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exerciseName(for: exercise))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.text)

                        if exercise.sets.isEmpty {
                            Text("-")
                                .font(.caption)
                                .foregroundStyle(Theme.textFaint)
                        } else {
                            FlowSetChips(sets: exercise.sets, unit: store.appData.unit)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private func historyMetric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.text)
            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Theme.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func exerciseName(for exercise: LoggedExercise) -> String {
        if let name = exercise.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        let exerciseId = exercise.exerciseId
        let plannedNames = entry.program.days
            .flatMap { $0.exercises }
            .reduce(into: [String: String]()) { map, planned in
                if let name = planned.name, !name.isEmpty {
                    map[planned.exerciseId] = name
                }
            }

        if let plannedName = plannedNames[exerciseId] {
            return plannedName
        }

        return store.allExercises.first(where: { $0.id == exerciseId })?.name ?? exerciseId
    }
}

private struct FlowSetChips: View {
    let sets: [SetLog]
    let unit: String

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 6)], alignment: .leading, spacing: 6) {
            ForEach(Array(sets.enumerated()), id: \.offset) { _, set in
                Text("\(formatProgramHistoryWeight(set.weight))\(unit) x \(set.reps)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textDim)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

private func formatProgramHistoryDate(_ value: String) -> String {
    let date = domainParseStoredDate(value)
    guard date != .distantPast else { return value }
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

private func formatProgramHistoryWeight(_ weight: Double) -> String {
    if weight.rounded() == weight {
        return "\(Int(weight))"
    }
    return String(format: "%.1f", weight)
}
