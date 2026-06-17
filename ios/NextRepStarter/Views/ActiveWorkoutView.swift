import AudioToolbox
import Foundation
import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showingFinishConfirm = false
    @State private var finishedLog: WorkoutLog?
    @State private var hasPreparedWorkout = false
    let program: Program
    let day: ProgramDay
    var week: Int = 1

    var body: some View {
        ScrollView {
            if let active = store.appData.activeWorkout {
                VStack(alignment: .leading, spacing: 20) {
                    header(active: active)

                    exercisesList(active: active)

                    Button {
                        showingFinishConfirm = true
                    } label: {
                        Text("Finish Workout")
                    }
                    .buttonStyle(GhostButtonStyle())
                }
                .padding(16)
                .frame(maxWidth: 448)
                .frame(maxWidth: .infinity)
            } else {
                emptySession
                    .padding(16)
                    .frame(maxWidth: 448)
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.dismissWorkout()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .tint(Theme.textDim)
            }
        }
        .screenBackground()
        .navigationDestination(isPresented: summaryIsPresented) {
            if let finishedLog {
                WorkoutSummaryView(log: finishedLog, unit: store.appData.unit) {
                    closeSummaryAndWorkout()
                }
            }
        }
        .onAppear {
            if !hasPreparedWorkout {
                hasPreparedWorkout = true
                store.startWorkout(program: program, day: day, week: week)
                Task {
                    await store.requestTimerNotificationPermission()
                }
            }
        }
        .alert("Finish Workout?", isPresented: $showingFinishConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Finish", role: .destructive) {
                if let log = store.finishWorkout(program: program, day: day) {
                    finishedLog = log
                    Task {
                        await store.syncNow()
                    }
                }
            }
        } message: {
            Text("This will save completed sets to workout history and clear the active session.")
        }
        .safeAreaInset(edge: .bottom) {
            if let active = store.appData.activeWorkout, active.restEndsAt != nil {
                FloatingRestBar(
                    active: active,
                    accent: accent,
                    onAddTime: { store.extendRest(by: 15) },
                    onSkip: { store.stopRest() }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private var accent: Color {
        Theme.accent
    }

    private var summaryIsPresented: Binding<Bool> {
        Binding(
            get: { finishedLog != nil },
            set: { isPresented in
                if !isPresented {
                    finishedLog = nil
                }
            }
        )
    }

    private func closeSummaryAndWorkout() {
        finishedLog = nil
        store.dismissWorkout()
        DispatchQueue.main.async {
            dismiss()
        }
    }

    private func header(active: ActiveWorkout) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Active Workout")
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.text)

                    Text(program.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accent)

                    Text(day.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.text)

                    if !day.focus.isEmpty {
                        Text(day.focus)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textDim)
                    }
                }

                Spacer()

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "timer")
                            .foregroundStyle(accent)
                        Text(elapsedText(active: active, now: context.date))
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(Theme.textDim)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            Text("\(completedSets(active)) of \(totalSets(active)) sets complete")
                .font(.footnote)
                .foregroundStyle(Theme.textDim)

            MetricProgressBar(
                label: "Set progress",
                value: Double(completedSets(active)),
                target: Double(max(1, totalSets(active))),
                suffix: "",
                color: accent
            )
        }
    }

    private func exercisesList(active: ActiveWorkout) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(day.exercises.enumerated()), id: \.offset) { exerciseIndex, planned in
                let restAfterSet = restSecondsAfterSet(exerciseIndex: exerciseIndex, planned: planned)
                let startsRestAfterSet = restAfterSet > 0
                WorkoutExerciseCard(
                    accent: accent,
                    name: exerciseName(for: planned),
                    planned: planned,
                    unit: store.appData.unit,
                    previousHint: previousSetHint(for: planned),
                    startsRestAfterSet: startsRestAfterSet,
                    cueText: Binding(
                        get: { store.appData.exerciseSubheaders[planned.exerciseId] ?? "" },
                        set: { store.setExerciseCue(exerciseId: planned.exerciseId, cue: $0) }
                    ),
                    noteText: Binding(
                        get: { store.appData.exerciseNotes[planned.exerciseId] ?? "" },
                        set: { store.setExerciseNote(exerciseId: planned.exerciseId, note: $0) }
                    ),
                    rows: active.sets.indices.contains(exerciseIndex) ? active.sets[exerciseIndex] : [],
                    onWeightSet: { setIndex, weight in
                        guard active.sets.indices.contains(exerciseIndex),
                              active.sets[exerciseIndex].indices.contains(setIndex) else {
                            return
                        }
                        store.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight)
                    },
                    onRepsSet: { setIndex, reps in
                        guard active.sets.indices.contains(exerciseIndex),
                              active.sets[exerciseIndex].indices.contains(setIndex) else {
                            return
                        }
                        store.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: reps)
                    },
                    onToggleCompleted: { setIndex, completed in
                        store.setCompleted(
                            exerciseIndex: exerciseIndex,
                            setIndex: setIndex,
                            completed: completed,
                            restSec: restAfterSet,
                            exerciseName: exerciseName(for: planned)
                        )
                    },
                    onStartRest: {
                        store.startRest(seconds: max(planned.restSec, restAfterSet), exerciseName: exerciseName(for: planned))
                    }
                )
            }
        }
    }

    private var emptySession: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("No active session", systemImage: "exclamationmark.circle")
                .font(.headline)
                .foregroundStyle(Theme.text)

            Text("Go back and tap Start again to create a workout session.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
        .cardStyle()
    }

    private func exerciseName(for planned: PlannedExercise) -> String {
        if let name = planned.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }

        let allExercises = store.catalog.exercises + store.appData.customExercises
        return allExercises.first(where: { $0.id == planned.exerciseId })?.name ?? planned.exerciseId
    }

    private func restSecondsAfterSet(exerciseIndex: Int, planned: PlannedExercise) -> Int {
        guard let groupId = planned.groupId, !groupId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return planned.restSec
        }

        let nextIndex = exerciseIndex + 1
        if day.exercises.indices.contains(nextIndex),
           day.exercises[nextIndex].groupId == groupId {
            return 0
        }

        return planned.restSec
    }

    private func previousSetHint(for planned: PlannedExercise) -> String? {
        for log in store.appData.logs.sorted(by: { $0.date > $1.date }) {
            guard let exercise = log.exercises.first(where: { $0.exerciseId == planned.exerciseId }),
                  let set = exercise.sets.last else {
                continue
            }
            return "Previous: \(formatWeight(set.weight)) \(store.appData.unit) x \(set.reps)"
        }
        return nil
    }

    private func completedSets(_ active: ActiveWorkout) -> Int {
        active.sets.flatMap { $0 }.filter(\.completed).count
    }

    private func totalSets(_ active: ActiveWorkout) -> Int {
        active.sets.reduce(0) { $0 + $1.count }
    }

    private func elapsedText(active: ActiveWorkout, now: Date) -> String {
        let startedAt = Date(timeIntervalSince1970: active.startedAt / 1000)
        let elapsed = max(0, Int(now.timeIntervalSince(startedAt)))
        return formatClock(elapsed)
    }
}

private struct RestTimerCard: View {
    let active: ActiveWorkout
    let accent: Color
    let onStop: () -> Void
    @State private var didSignalCompletion = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = remainingSeconds(now: context.date)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Rest Timer", systemImage: "bell")
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    Spacer()

                    if active.restEndsAt != nil {
                        Button("Stop") {
                            onStop()
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accent)
                    }
                }

                if active.restEndsAt == nil {
                    Text("Complete a set or tap Start Rest on an exercise to begin.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                } else {
                    Text(remaining > 0 ? formatClock(remaining) : "Rest complete")
                        .font(.system(size: 30, weight: .bold, design: .default).monospacedDigit())
                        .foregroundStyle(remaining > 0 ? Theme.text : accent)

                    ProgressView(value: progress(remaining: remaining))
                        .tint(accent)
                }
            }
            .cardStyle()
            .onAppear {
                signalCompletionIfNeeded(remaining: remaining)
            }
            .onChange(of: active.restEndsAt) { _ in
                didSignalCompletion = false
            }
            .onChange(of: remaining) { newValue in
                signalCompletionIfNeeded(remaining: newValue)
            }
        }
    }

    private func remainingSeconds(now: Date) -> Int {
        guard let restEndsAt = active.restEndsAt else {
            return 0
        }

        let seconds = (restEndsAt / 1000) - now.timeIntervalSince1970
        return max(0, Int(ceil(seconds)))
    }

    private func progress(remaining: Int) -> Double {
        guard active.restTotal > 0 else {
            return 0
        }

        return 1 - (Double(remaining) / Double(active.restTotal))
    }

    private func signalCompletionIfNeeded(remaining: Int) {
        guard active.restEndsAt != nil, active.restTotal > 0, remaining == 0, !didSignalCompletion else {
            return
        }

        didSignalCompletion = true
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

private struct WorkoutExerciseCard: View {
    let accent: Color
    let name: String
    let planned: PlannedExercise
    let unit: String
    let previousHint: String?
    let startsRestAfterSet: Bool
    @Binding var cueText: String
    @Binding var noteText: String
    let rows: [SetLog]
    let onWeightSet: (Int, Double) -> Void
    let onRepsSet: (Int, Int) -> Void
    let onToggleCompleted: (Int, Bool) -> Void
    let onStartRest: () -> Void
    @State private var showingNotes = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    Text("\(planned.sets) x \(planned.reps) · \(planned.restSec)s rest")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)

                    if let previousHint {
                        Text(previousHint)
                            .font(.caption)
                            .foregroundStyle(accent)
                    }

                    if let groupId = planned.groupId, !groupId.isEmpty {
                        Text("Superset \(groupId)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accent.opacity(0.14))
                            .clipShape(Capsule())
                    }

                    if !cueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(cueText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accent)
                            .padding(.leading, 8)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(accent)
                                    .frame(width: 3)
                            }
                    }
                }

                Spacer()

                Button("Start Rest") {
                    onStartRest()
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(accent)
            }

            if let groupId = planned.groupId,
               !groupId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !startsRestAfterSet {
                Text("No auto-rest until the end of this superset round.")
                    .font(.caption)
                    .foregroundStyle(Theme.textFaint)
            }

            DisclosureGroup(isExpanded: $showingNotes) {
                VStack(spacing: 10) {
                    TextField("Cue", text: $cueText, axis: .vertical)
                        .workoutInputStyle()
                    TextField("Private notes", text: $noteText, axis: .vertical)
                        .lineLimit(2, reservesSpace: true)
                        .workoutInputStyle()
                }
                .padding(.top, 8)
            } label: {
                Label("Notes & Cues", systemImage: "pencil")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textDim)
            }

            VStack(spacing: 10) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, set in
                    WorkoutSetRow(
                        index: index,
                        set: set,
                        accent: accent,
                        unit: unit,
                        onWeightSet: { onWeightSet(index, $0) },
                        onRepsSet: { onRepsSet(index, $0) },
                        onToggleCompleted: { onToggleCompleted(index, $0) }
                    )
                }
            }
        }
        .cardStyle()
    }
}

private struct WorkoutSetRow: View {
    let index: Int
    let set: SetLog
    let accent: Color
    let unit: String
    let onWeightSet: (Double) -> Void
    let onRepsSet: (Int) -> Void
    let onToggleCompleted: (Bool) -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Set \(index + 1)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)

                Spacer()

                Button {
                    onToggleCompleted(!set.completed)
                } label: {
                    Label(set.completed ? "Done" : "Mark Done", systemImage: set.completed ? "checkmark.circle.fill" : "circle")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(set.completed ? accent : Theme.textDim)
            }

            HStack(spacing: 10) {
                WorkoutNumberField(
                    title: "Weight",
                    value: set.weight == 0 ? "" : formatWeight(set.weight),
                    unit: unit,
                    keyboard: .decimalPad,
                    onChange: { text in
                        onWeightSet(Double(text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0)
                    }
                )

                WorkoutNumberField(
                    title: "Reps",
                    value: set.reps == 0 ? "" : "\(set.reps)",
                    unit: "",
                    keyboard: .numberPad,
                    onChange: { text in
                        onRepsSet(Int(text.filter(\.isNumber)) ?? 0)
                    }
                )
            }
        }
        .padding(12)
        .background(set.completed ? accent.opacity(0.14) : Theme.inputBg.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(set.completed ? accent.opacity(0.45) : .white.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct WorkoutNumberField: View {
    let title: String
    let value: String
    let unit: String
    let keyboard: UIKeyboardType
    let onChange: (String) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.1)
                .foregroundStyle(Theme.textFaint)

            TextField(title, text: Binding(
                get: { value },
                set: { onChange($0) }
            ))
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

private extension View {
    func workoutInputStyle() -> some View {
        self
            .foregroundStyle(Theme.text)
            .tint(Theme.accentLight)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }
}

private struct FloatingRestBar: View {
    let active: ActiveWorkout
    let accent: Color
    let onAddTime: () -> Void
    let onSkip: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = remainingSeconds(now: context.date)

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rest")
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .foregroundStyle(accent)

                        Text(remaining > 0 ? formatClock(remaining) : "Rest complete")
                            .font(.title2.monospacedDigit().weight(.bold))
                            .foregroundStyle(remaining > 0 ? Theme.text : accent)
                    }

                    Spacer()

                    Button("+15s", action: onAddTime)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Theme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Button("Skip", action: onSkip)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                ProgressView(value: progress(remaining: remaining))
                    .tint(accent)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accent.opacity(0.35), lineWidth: 1)
            }
        }
    }

    private func remainingSeconds(now: Date) -> Int {
        guard let restEndsAt = active.restEndsAt else { return 0 }
        let seconds = (restEndsAt / 1000) - now.timeIntervalSince1970
        return max(0, Int(ceil(seconds)))
    }

    private func progress(remaining: Int) -> Double {
        guard active.restTotal > 0 else { return 0 }
        return 1 - (Double(remaining) / Double(active.restTotal))
    }
}
private func formatClock(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainder = seconds % 60
    return String(format: "%d:%02d", minutes, remainder)
}

private func formatWeight(_ weight: Double) -> String {
    if weight.rounded() == weight {
        return "\(Int(weight))"
    }

    return String(format: "%.1f", weight)
}
