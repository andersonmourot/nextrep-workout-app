import AudioToolbox
import Combine
import SwiftUI

struct IntervalTimerView: View {
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var mode = "TABATA"
    @State private var workSeconds = 20
    @State private var restSeconds = 10
    @State private var rounds = 8
    @State private var emomInterval = 60
    @State private var amrapCap = 600
    @State private var remaining = 20
    @State private var currentRound = 1
    @State private var isWorkPhase = true
    @State private var isRunning = false
    @State private var isComplete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                modePicker
                timerCard
                controls
                settings
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Timer")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .onAppear {
            resetTimer()
        }
        .onChange(of: mode) { _ in
            resetTimer()
        }
        .onReceive(ticker) { _ in
            tick()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Interval Timer")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("TABATA · EMOM · AMRAP")
                .font(.caption)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Theme.accentLight)
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            Text("TABATA").tag("TABATA")
            Text("EMOM").tag("EMOM")
            Text("AMRAP").tag("AMRAP")
        }
        .pickerStyle(.segmented)
    }

    private var timerCard: some View {
        VStack(spacing: 14) {
            Text(statusLabel)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundStyle(Theme.accentLight)

            Text(formatIntervalClock(remaining))
                .font(.system(size: 64, weight: .bold, design: .default).monospacedDigit())
                .foregroundStyle(isComplete ? Theme.accentLight : Theme.text)
                .minimumScaleFactor(0.7)

            Text(roundLabel)
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)

            ProgressView(value: progress)
                .tint(Theme.accentLight)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                isRunning.toggle()
                if isComplete {
                    resetTimer()
                    isRunning = true
                }
            } label: {
                Text(isRunning ? "Pause" : "Start")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                resetTimer()
            } label: {
                Text("Reset")
            }
            .buttonStyle(GhostButtonStyle())
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .foregroundStyle(Theme.text)

            switch mode {
            case "EMOM":
                StepperRow(title: "Interval", value: $emomInterval, range: 15...300, step: 15, suffix: "s") {
                    resetTimer()
                }
                StepperRow(title: "Rounds", value: $rounds, range: 1...60, step: 1, suffix: "") {
                    resetTimer()
                }
            case "AMRAP":
                StepperRow(title: "Time cap", value: $amrapCap, range: 60...3600, step: 60, suffix: "s") {
                    resetTimer()
                }
            default:
                StepperRow(title: "Work", value: $workSeconds, range: 5...300, step: 5, suffix: "s") {
                    resetTimer()
                }
                StepperRow(title: "Rest", value: $restSeconds, range: 0...300, step: 5, suffix: "s") {
                    resetTimer()
                }
                StepperRow(title: "Rounds", value: $rounds, range: 1...60, step: 1, suffix: "") {
                    resetTimer()
                }
            }
        }
        .cardStyle()
    }

    private var statusLabel: String {
        if isComplete {
            return "Complete"
        }

        switch mode {
        case "EMOM":
            return "Every minute on the minute"
        case "AMRAP":
            return "As many rounds as possible"
        default:
            return isWorkPhase ? "Work" : "Rest"
        }
    }

    private var roundLabel: String {
        switch mode {
        case "AMRAP":
            return "Time cap"
        default:
            return "Round \(currentRound) of \(rounds)"
        }
    }

    private var phaseDuration: Int {
        switch mode {
        case "EMOM":
            return emomInterval
        case "AMRAP":
            return amrapCap
        default:
            return isWorkPhase ? workSeconds : max(1, restSeconds)
        }
    }

    private var progress: Double {
        guard phaseDuration > 0 else {
            return 0
        }

        return 1 - (Double(remaining) / Double(phaseDuration))
    }

    private func tick() {
        guard isRunning, !isComplete else {
            return
        }

        if remaining > 0 {
            remaining -= 1
        }

        if remaining == 0 {
            advancePhase()
        }
    }

    private func advancePhase() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

        switch mode {
        case "EMOM":
            if currentRound >= rounds {
                finishTimer()
            } else {
                currentRound += 1
                remaining = emomInterval
            }
        case "AMRAP":
            finishTimer()
        default:
            if isWorkPhase && restSeconds > 0 {
                isWorkPhase = false
                remaining = restSeconds
            } else if currentRound < rounds {
                currentRound += 1
                isWorkPhase = true
                remaining = workSeconds
            } else {
                finishTimer()
            }
        }
    }

    private func finishTimer() {
        isRunning = false
        isComplete = true
        remaining = 0
    }

    private func resetTimer() {
        isRunning = false
        isComplete = false
        currentRound = 1
        isWorkPhase = true

        switch mode {
        case "EMOM":
            remaining = emomInterval
        case "AMRAP":
            remaining = amrapCap
        default:
            remaining = workSeconds
        }
    }
}

private struct StepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let suffix: String
    let onChange: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)

                Text("\(value)\(suffix)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.textDim)
            }

            Spacer()

            Stepper("", value: $value, in: range, step: step)
                .labelsHidden()
                .onChange(of: value) { _ in
                    onChange()
                }
        }
        .padding(12)
        .background(Theme.inputBg.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private func formatIntervalClock(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainder = seconds % 60
    return String(format: "%d:%02d", minutes, remainder)
}
