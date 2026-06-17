import AudioToolbox
import Foundation
import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showingFinishConfirm = false
    @State private var finishedLog: WorkoutLog?
    let program: Program
    let day: ProgramDay
    var week: Int = 1

    var body: some View {
        ScrollView {
            if let active = store.appData.activeWorkout {
                VStack(alignment: .leading, spacing: 20) {
                    header(active: active)

                    RestTimerCard(active: active, accent: accent) {
                        store.stopRest()
                    }

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
        .screenBackground()
        .navigationDestination(isPresented: summaryIsPresented) {
            if let finishedLog {
                WorkoutSummaryView(log: finishedLog, unit: store.appData.unit) {
                    closeSummaryAndWorkout()
                }
            }
        }
        .onAppear {
            store.startWorkout(program: program, day: day, week: week)
            Task {
                await store.requestTimerNotificationPermission()
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
                    rows: active.sets.indices.contains(exerciseIndex) ? active.sets[exerciseIndex] : [],
                    onWeightChange: { setIndex, delta in
                        guard active.sets.indices.contains(exerciseIndex),
                              active.sets[exerciseIndex].indices.contains(setIndex) else {
                            return
                        }
                        let current = active.sets[exerciseIndex][setIndex].weight
                        store.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: current + delta)
                    },
                    onRepsChange: { setIndex, delta in
                        guard active.sets.indices.contains(exerciseIndex),
                              active.sets[exerciseIndex].indices.contains(setIndex) else {
                            return
                        }
                        let current = active.sets[exerciseIndex][setIndex].reps
                        store.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: current + delta)
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
    let rows: [SetLog]
    let onWeightChange: (Int, Double) -> Void
    let onRepsChange: (Int, Int) -> Void
    let onToggleCompleted: (Int, Bool) -> Void
    let onStartRest: () -> Void

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

            VStack(spacing: 10) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, set in
                    WorkoutSetRow(
                        index: index,
                        set: set,
                        accent: accent,
                        unit: unit,
                        onWeightChange: { onWeightChange(index, $0) },
                        onRepsChange: { onRepsChange(index, $0) },
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
    let onWeightChange: (Double) -> Void
    let onRepsChange: (Int) -> Void
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
                SetValueControl(
                    title: "Weight",
                    value: formatWeight(set.weight),
                    unit: unit,
                    minusAction: { onWeightChange(-5) },
                    plusAction: { onWeightChange(5) }
                )

                SetValueControl(
                    title: "Reps",
                    value: "\(set.reps)",
                    unit: "",
                    minusAction: { onRepsChange(-1) },
                    plusAction: { onRepsChange(1) }
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

private struct SetValueControl: View {
    let title: String
    let value: String
    let unit: String
    let minusAction: () -> Void
    let plusAction: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.1)
                .foregroundStyle(Theme.textFaint)

            HStack(spacing: 8) {
                Button(action: minusAction) {
                    Image(systemName: "minus")
                }
                .buttonStyle(SetStepperButtonStyle())

                VStack(spacing: 1) {
                    Text(value)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Theme.text)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .foregroundStyle(Theme.textFaint)
                    }
                }
                .frame(minWidth: 42)

                Button(action: plusAction) {
                    Image(systemName: "plus")
                }
                .buttonStyle(SetStepperButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SetStepperButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.bold))
            .foregroundStyle(Theme.text)
            .frame(width: 28, height: 28)
            .background(configuration.isPressed ? Theme.surface3 : Theme.surface)
            .clipShape(Circle())
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
