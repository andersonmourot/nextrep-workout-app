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

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    dismissKeyboard()
                } label: {
                    Image(systemName: "checkmark")
                }
                .font(.headline.weight(.semibold))
                .accessibilityLabel("Dismiss keyboard")
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
            if let active = store.appData.activeWorkout {
                if active.restEndsAt != nil {
                    FloatingRestBar(
                        active: active,
                        accent: accent,
                        timerSound: store.appData.timerSound,
                        onAddTime: { store.extendRest(by: 15) },
                        onSkip: { store.stopRest() }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
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
        let namesById = exerciseNameLookup
        let previousHintsById = previousHintLookup

        return VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(domainSupersetGroups(day.exercises).enumerated()), id: \.offset) { _, group in
                if group.isSuperset {
                    SupersetWorkoutCard(
                        accent: accent,
                        group: group,
                        plannedExercises: day.exercises,
                        activeSets: active.sets,
                        unit: store.appData.unit,
                        exerciseName: { exerciseName(for: $0, lookup: namesById) },
                        previousHint: { previousHintsById[$0.exerciseId] },
                        cueText: cueBinding,
                        noteText: noteBinding,
                        onWeightSet: { exerciseIndex, setIndex, weight in
                            store.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight)
                        },
                        onRepsSet: { exerciseIndex, setIndex, reps in
                            store.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: reps)
                        },
                        onToggleCompleted: { exerciseIndex, setIndex, completed in
                            let planned = day.exercises[exerciseIndex]
                            store.setCompleted(
                                exerciseIndex: exerciseIndex,
                                setIndex: setIndex,
                                completed: completed,
                                restSec: restSecondsAfterSet(exerciseIndex: exerciseIndex, planned: planned),
                                exerciseName: exerciseName(for: planned, lookup: namesById)
                            )
                        }
                    )
                } else if let exerciseIndex = group.indices.first {
                    let planned = day.exercises[exerciseIndex]
                    let restAfterSet = restSecondsAfterSet(exerciseIndex: exerciseIndex, planned: planned)
                    let startsRestAfterSet = restAfterSet > 0
                    WorkoutExerciseCard(
                        accent: accent,
                        name: exerciseName(for: planned, lookup: namesById),
                        planned: planned,
                        unit: store.appData.unit,
                        previousHint: previousHintsById[planned.exerciseId],
                        startsRestAfterSet: startsRestAfterSet,
                        cueText: cueBinding(for: planned.exerciseId),
                        noteText: noteBinding(for: planned.exerciseId),
                        rows: active.sets.indices.contains(exerciseIndex) ? active.sets[exerciseIndex] : [],
                        onWeightSet: { setIndex, weight in
                            store.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight)
                        },
                        onRepsSet: { setIndex, reps in
                            store.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: reps)
                        },
                        onToggleCompleted: { setIndex, completed in
                            store.setCompleted(
                                exerciseIndex: exerciseIndex,
                                setIndex: setIndex,
                                completed: completed,
                                restSec: restAfterSet,
                                exerciseName: exerciseName(for: planned, lookup: namesById)
                            )
                        }
                    )
                }
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

    private var exerciseNameLookup: [String: String] {
        var lookup: [String: String] = [:]
        for exercise in store.catalog.exercises {
            lookup[exercise.id] = exercise.name
        }
        for exercise in store.appData.customExercises {
            lookup[exercise.id] = exercise.name
        }
        return lookup
    }

    private var previousHintLookup: [String: String] {
        var lookup: [String: String] = [:]
        for log in store.appData.logs.sorted(by: { $0.date > $1.date }) {
            for exercise in log.exercises where lookup[exercise.exerciseId] == nil {
                if let set = exercise.sets.last {
                    lookup[exercise.exerciseId] = "Previous: \(formatWeight(set.weight)) \(store.appData.unit) x \(set.reps)"
                }
            }
        }
        return lookup
    }

    private func exerciseName(for planned: PlannedExercise, lookup: [String: String]? = nil) -> String {
        if let name = planned.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }

        if let name = lookup?[planned.exerciseId] {
            return name
        }
        return exerciseNameLookup[planned.exerciseId] ?? planned.exerciseId
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

    private func cueBinding(for exerciseId: String) -> Binding<String> {
        Binding(
            get: { store.appData.exerciseSubheaders[exerciseId] ?? "" },
            set: { store.setExerciseCue(exerciseId: exerciseId, cue: $0) }
        )
    }

    private func noteBinding(for exerciseId: String) -> Binding<String> {
        Binding(
            get: { store.appData.exerciseNotes[exerciseId] ?? "" },
            set: { store.setExerciseNote(exerciseId: exerciseId, note: $0) }
        )
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
                    Text("Mark a set Done to start the programmed rest timer.")
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
            .onChange(of: active.restEndsAt) { _, _ in
                didSignalCompletion = false
            }
            .onChange(of: remaining) { _, newValue in
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

                Button {
                    showingNotes.toggle()
                } label: {
                    Image(systemName: "note.text")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(showingNotes ? accent : Theme.textDim)
                        .frame(width: 32, height: 32)
                        .background(Theme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if showingNotes {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Exercise notes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textDim)

                    TextField("Cue shown under exercise name", text: $cueText, axis: .vertical)
                        .workoutInputStyle()

                    TextField("Private notes", text: $noteText, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .workoutInputStyle()
                }
            }

            if let groupId = planned.groupId,
               !groupId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !startsRestAfterSet {
                Text("No auto-rest until the end of this superset round.")
                    .font(.caption)
                    .foregroundStyle(Theme.textFaint)
            }

            VStack(spacing: 8) {
                WorkoutSetHeader(unit: unit)
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

private struct SupersetWorkoutCard: View {
    let accent: Color
    let group: SupersetGroup
    let plannedExercises: [PlannedExercise]
    let activeSets: [[SetLog]]
    let unit: String
    let exerciseName: (PlannedExercise) -> String
    let previousHint: (PlannedExercise) -> String?
    let cueText: (String) -> Binding<String>
    let noteText: (String) -> Binding<String>
    let onWeightSet: (Int, Int, Double) -> Void
    let onRepsSet: (Int, Int, Int) -> Void
    let onToggleCompleted: (Int, Int, Bool) -> Void
    @State private var showingNotesFor: Int?

    private var memberIndices: [Int] {
        group.indices.filter { plannedExercises.indices.contains($0) }
    }

    private var roundCount: Int {
        memberIndices
            .map { activeSets.indices.contains($0) ? activeSets[$0].count : plannedExercises[$0].sets }
            .max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Superset \(group.label)")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1.3)
                        .foregroundStyle(accent)

                    Text("No rest between exercises")
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    Text("\(roundCount) round\(roundCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                }

                Spacer()
            }

            legend

            VStack(spacing: 12) {
                ForEach(0..<roundCount, id: \.self) { round in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Round \(round + 1)")
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .tracking(1.1)
                            .foregroundStyle(Theme.textFaint)

                        ForEach(Array(memberIndices.enumerated()), id: \.offset) { memberOffset, exerciseIndex in
                            if activeSets.indices.contains(exerciseIndex),
                               activeSets[exerciseIndex].indices.contains(round) {
                                SupersetSetRow(
                                    label: "\(group.label)\(memberOffset + 1)",
                                    set: activeSets[exerciseIndex][round],
                                    unit: unit,
                                    accent: accent,
                                    onWeightSet: { onWeightSet(exerciseIndex, round, $0) },
                                    onRepsSet: { onRepsSet(exerciseIndex, round, $0) },
                                    onToggleCompleted: { onToggleCompleted(exerciseIndex, round, $0) }
                                )
                            }
                        }
                    }
                    .padding(12)
                    .background(Theme.inputBg.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .cardStyle()
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.45), lineWidth: 1.5)
        }
    }

    private var legend: some View {
        VStack(spacing: 8) {
            ForEach(Array(memberIndices.enumerated()), id: \.offset) { memberOffset, exerciseIndex in
                let planned = plannedExercises[exerciseIndex]
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(group.label)\(memberOffset + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 28)
                            .background(accent)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(exerciseName(planned))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.text)

                            if let previousHint = previousHint(planned) {
                                Text(previousHint)
                                    .font(.caption)
                                    .foregroundStyle(accent)
                            }

                            if !cueText(planned.exerciseId).wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(cueText(planned.exerciseId).wrappedValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(accent)
                            }
                        }

                        Spacer()

                        Button {
                            showingNotesFor = showingNotesFor == exerciseIndex ? nil : exerciseIndex
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption)
                        }
                        .foregroundStyle(Theme.textDim)
                    }

                    if showingNotesFor == exerciseIndex {
                        TextField("Cue", text: cueText(planned.exerciseId), axis: .vertical)
                            .workoutInputStyle()
                        TextField("Private notes", text: noteText(planned.exerciseId), axis: .vertical)
                            .lineLimit(2, reservesSpace: true)
                            .workoutInputStyle()
                    }
                }
                .padding(10)
                .background(Theme.surface2.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

private struct SupersetSetRow: View {
    let label: String
    let set: SetLog
    let unit: String
    let accent: Color
    let onWeightSet: (Double) -> Void
    let onRepsSet: (Int) -> Void
    let onToggleCompleted: (Bool) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(accent)
                .frame(width: 34)

            WorkoutNumberField(
                title: "Weight",
                value: set.weight == 0 ? "" : formatWeight(set.weight),
                unit: unit,
                keyboard: .decimalPad,
                onChange: { onWeightSet(Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) }
            )

            WorkoutNumberField(
                title: "Reps",
                value: set.reps == 0 ? "" : "\(set.reps)",
                unit: "",
                keyboard: .numberPad,
                onChange: { onRepsSet(Int($0.filter(\.isNumber)) ?? 0) }
            )

            Button {
                onToggleCompleted(!set.completed)
            } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
            }
            .foregroundStyle(set.completed ? accent : Theme.textDim)
        }
        .padding(10)
        .background(set.completed ? accent.opacity(0.14) : Theme.surface2.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        HStack(spacing: 8) {
            Text("\(index + 1)")
                .font(.subheadline.monospacedDigit().weight(.bold))
                .foregroundStyle(Theme.textDim)
                .frame(width: 28)

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

            Button {
                onToggleCompleted(!set.completed)
            } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 34)
            }
            .foregroundStyle(set.completed ? accent : Theme.textDim)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(set.completed ? accent.opacity(0.14) : Theme.inputBg.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(set.completed ? accent.opacity(0.45) : .white.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct WorkoutSetHeader: View {
    let unit: String

    var body: some View {
        HStack(spacing: 8) {
            Text("Set")
                .frame(width: 28, alignment: .center)
            Text("Weight (\(unit))")
                .frame(maxWidth: .infinity)
            Text("Reps")
                .frame(maxWidth: .infinity)
            Text("Done")
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 44, alignment: .center)
        }
        .font(.caption2.weight(.semibold))
        .textCase(.uppercase)
        .tracking(1.0)
        .foregroundStyle(Theme.textFaint)
        .padding(.horizontal, 10)
    }
}

private struct WorkoutNumberField: View {
    let title: String
    let value: String
    let unit: String
    let keyboard: UIKeyboardType
    let onChange: (String) -> Void

    var body: some View {
        TextField(title, text: Binding(
                get: { value },
                set: { onChange($0) }
            ))
            .keyboardType(keyboard)
            .multilineTextAlignment(.center)
            .font(.subheadline.monospacedDigit().weight(.semibold))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 9)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .frame(maxWidth: .infinity)
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
    let timerSound: String
    let onAddTime: () -> Void
    let onSkip: () -> Void
    @State private var signaledSeconds: Set<Int> = []

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
            .onAppear {
                signalIfNeeded(remaining: remaining)
            }
            .onChange(of: active.restEndsAt) { _, _ in
                signaledSeconds = []
            }
            .onChange(of: remaining) { _, newValue in
                signalIfNeeded(remaining: newValue)
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

    private func signalIfNeeded(remaining: Int) {
        guard [3, 2, 1, 0].contains(remaining), !signaledSeconds.contains(remaining) else {
            return
        }
        signaledSeconds.insert(remaining)
        if remaining == 0 {
            playNextRepTimerSound(timerSound)
        } else {
            AudioServicesPlaySystemSound(1104)
        }
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
