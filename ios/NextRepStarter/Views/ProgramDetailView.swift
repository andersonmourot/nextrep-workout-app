import SwiftUI

struct ProgramDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var shareMessage: String?
    @State private var showingDeleteConfirm = false
    @State private var showingHideConfirm = false
    @State private var selectedWeek: Int?
    @State private var pendingStart: (dayId: String, week: Int)?
    let program: Program

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                managementActions

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Workout Days")
                            .font(.headline)
                            .foregroundStyle(Theme.text)
                        Spacer()
                        weekPager
                    }

                    if resolvedDays.isEmpty {
                        Text("No days have been added to this program yet.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textDim)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                    } else {
                        ForEach(Array(resolvedDays.enumerated()), id: \.element.id) { index, day in
                            ProgramDayCard(
                                program: program,
                                day: day,
                                dayNumber: index + 1,
                                selectedWeek: currentWeek,
                                isUpNext: isUpNext(dayIndex: index),
                                log: slotLog(dayIndex: index),
                                loggedSetCount: slotLog(dayIndex: index).map(completedSetCount) ?? 0,
                                exerciseName: exerciseName,
                                loggedSummary: { planned, log in
                                    loggedSummary(for: planned, in: log)
                                },
                                onStart: {
                                    startDay(dayId: program.days[index].id, week: currentWeek)
                                }
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
        .alert("Delete Program?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deleteCustomProgram(id: program.id)
                dismiss()
            }
        } message: {
            Text("This moves the custom program to Trash. You can restore it from the Programs screen.")
        }
        .alert("Hide Program?", isPresented: $showingHideConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Hide", role: .destructive) {
                store.hideProgram(id: program.id)
                dismiss()
            }
        } message: {
            Text("This hides the program from your Programs list. You can restore hidden programs from the Programs screen.")
        }
        .alert("Switch active program?", isPresented: Binding(
            get: { pendingStart != nil },
            set: { if !$0 { pendingStart = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingStart = nil }
            Button("Switch") {
                if let pendingStart {
                    startDay(dayId: pendingStart.dayId, week: pendingStart.week, force: true)
                }
                pendingStart = nil
            }
        } message: {
            Text("Starting this day will make \(program.name) your active program. Existing workout history is kept.")
        }
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
            HStack(alignment: .top) {
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

                Spacer()

                Button {
                    store.toggleFavoriteProgram(id: program.id)
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title3)
                }
                .foregroundStyle(isFavorite ? Theme.accentLight : Theme.textDim)
                .disabled(!isFavorite && store.appData.favoriteProgramIds.count >= 5)
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
                MetricTile(label: "Done", value: "\(completedDayCount)", accent: accent)
            }

            MetricProgressBar(
                label: "Program progress",
                value: Double(completedDayCount),
                target: Double(max(1, program.days.count * max(1, program.durationWeeks))),
                suffix: "",
                color: accent
            )

            Button {
                store.setActiveProgram(id: program.id)
                shareMessage = "Active program set"
            } label: {
                Label(
                    store.appData.activeProgramId == program.id ? "Active Program" : "Set Active Program",
                    systemImage: store.appData.activeProgramId == program.id ? "checkmark.circle.fill" : "checkmark.circle"
                )
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(store.appData.activeProgramId == program.id)
            .opacity(store.appData.activeProgramId == program.id ? 0.65 : 1)
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
        Theme.accent
    }

    private var isFavorite: Bool {
        store.appData.favoriteProgramIds.contains(program.id)
    }

    private var run: ProgramRun {
        domainProgramRun(
            program: program,
            logs: store.appData.logs,
            since: store.appData.programAnchors[program.id]
        )
    }

    private var currentWeek: Int {
        min(max(1, selectedWeek ?? run.week), max(1, program.durationWeeks))
    }

    private var resolvedDays: [ProgramDay] {
        program.days.indices.compactMap { index in
            domainResolveProgramDay(program, dayIndex: index, week: currentWeek)
        }
    }

    private var slots: [WorkoutLog?] {
        domainProgramLogSlots(
            program: program,
            logs: store.appData.logs,
            since: store.appData.programAnchors[program.id]
        )
    }

    private var completedDayCount: Int {
        run.completedSlots
    }

    private var weekPager: some View {
        HStack(spacing: 6) {
            Button {
                selectedWeek = max(1, currentWeek - 1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(currentWeek <= 1)

            Text("Week \(currentWeek)/\(max(1, program.durationWeeks))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textDim)

            Button {
                selectedWeek = min(max(1, program.durationWeeks), currentWeek + 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(currentWeek >= max(1, program.durationWeeks))
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(Theme.accentLight)
    }

    private var managementActions: some View {
        HStack(spacing: 10) {
            Button {
                _ = store.duplicateProgram(program)
                shareMessage = "Program duplicated"
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            .buttonStyle(GhostButtonStyle())

            if store.isCustomProgram(program) {
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(GhostButtonStyle())
            } else {
                Button(role: .destructive) {
                    showingHideConfirm = true
                } label: {
                    Label("Hide", systemImage: "eye.slash")
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
    }

    private func exerciseName(for planned: PlannedExercise) -> String {
        if let name = planned.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }

        let allExercises = store.catalog.exercises + store.appData.customExercises
        return allExercises.first(where: { $0.id == planned.exerciseId })?.name ?? planned.exerciseId
    }

    private func slotIndex(dayIndex: Int) -> Int {
        (currentWeek - 1) * max(1, program.days.count) + dayIndex
    }

    private func slotLog(dayIndex: Int) -> WorkoutLog? {
        let index = slotIndex(dayIndex: dayIndex)
        guard slots.indices.contains(index) else { return nil }
        return slots[index]
    }

    private func isUpNext(dayIndex: Int) -> Bool {
        !run.isComplete && run.week == currentWeek && run.dayIndex == dayIndex
    }

    private func loggedSummary(for planned: PlannedExercise, in log: WorkoutLog?) -> String? {
        guard let log,
              let logged = log.exercises.first(where: { $0.exerciseId == planned.exerciseId }),
              !logged.sets.isEmpty else {
            return nil
        }

        return logged.sets.map { "\(formatDetailWeight($0.weight))x\($0.reps)" }.joined(separator: " · ")
    }

    private func startDay(dayId: String, week: Int, force: Bool = false) {
        if !force, switchingActiveWithData {
            pendingStart = (dayId, week)
            return
        }

        guard let dayIndex = program.days.firstIndex(where: { $0.id == dayId }),
              let day = domainResolveProgramDay(program, dayIndex: dayIndex, week: week) else {
            return
        }
        store.startWorkout(program: program, day: day, week: week)
        store.presentWorkout()
    }

    private var switchingActiveWithData: Bool {
        guard let activeProgramId = store.appData.activeProgramId, activeProgramId != program.id else {
            return false
        }

        return store.appData.logs.contains { $0.programId == activeProgramId } ||
            store.appData.activeWorkout?.programId == activeProgramId
    }

    private func latestLog(for day: ProgramDay) -> WorkoutLog? {
        store.appData.logs
            .filter { $0.programId == program.id && $0.dayId == day.id }
            .sorted { programDetailLogDate($0) > programDetailLogDate($1) }
            .first
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
    let selectedWeek: Int
    let isUpNext: Bool
    let log: WorkoutLog?
    let loggedSetCount: Int
    let exerciseName: (PlannedExercise) -> String
    let loggedSummary: (PlannedExercise, WorkoutLog?) -> String?
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(dayNumber)")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1.3)
                        .foregroundStyle(accent)

                    HStack(spacing: 6) {
                        Text(day.name)
                            .font(.headline)
                            .foregroundStyle(Theme.text)

                        if loggedSetCount > 0 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(accent)
                        }

                        if isUpNext {
                            Text("Up next")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(accent.opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }

                    if !day.focus.isEmpty {
                        Text(day.focus)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textDim)
                    }
                }

                Spacer()

                NavigationLink {
                    DayDetailView(program: program, day: day, dayNumber: dayNumber, week: selectedWeek)
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

                Button {
                    onStart()
                } label: {
                    Text(log != nil ? "Repeat" : "Start")
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
                        ExercisePlanRow(
                            index: index + 1,
                            planned: planned,
                            name: exerciseName(planned),
                            loggedSummary: loggedSummary(planned, log)
                        )

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
        .overlay {
            if isUpNext {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accent.opacity(0.65), lineWidth: 1.5)
            }
        }
    }

    private var accent: Color {
        Theme.accent
    }
}

private func programDetailLogDate(_ log: WorkoutLog) -> Date {
    ISO8601DateFormatter().date(from: log.date) ?? .distantPast
}

private func formatDetailWeight(_ weight: Double) -> String {
    if weight.rounded() == weight {
        return "\(Int(weight))"
    }

    return String(format: "%.1f", weight)
}

private struct ExercisePlanRow: View {
    let index: Int
    let planned: PlannedExercise
    let name: String
    let loggedSummary: String?

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

                Text(loggedSummary.map { "\($0)" } ?? "\(planned.sets) x \(planned.reps) · \(planned.restSec)s rest")
                    .font(.caption)
                    .foregroundStyle(loggedSummary == nil ? Theme.textDim : Theme.accentLight)

                if let groupId = planned.groupId, !groupId.isEmpty {
                    Text("Superset \(groupId)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.accentLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accent.opacity(0.14))
                        .clipShape(Capsule())
                }

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
