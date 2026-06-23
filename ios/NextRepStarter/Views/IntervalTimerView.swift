import AudioToolbox
import AVFoundation
import Combine
import SwiftUI

struct NextRepTimerSound: Identifiable, Equatable {
    let id: String
    let label: String
    let systemSoundId: SystemSoundID?
    let vibrates: Bool
}

let nextRepTimerSounds: [NextRepTimerSound] = [
    NextRepTimerSound(id: "beep", label: "Beep", systemSoundId: 1057, vibrates: false),
    NextRepTimerSound(id: "bell", label: "Bell", systemSoundId: 1025, vibrates: false),
    NextRepTimerSound(id: "chime", label: "Chime", systemSoundId: 1054, vibrates: false),
    NextRepTimerSound(id: "alert", label: "Alert", systemSoundId: 1005, vibrates: false),
    NextRepTimerSound(id: "vibrate", label: "Vibrate", systemSoundId: nil, vibrates: true)
]

func nextRepTimerSound(for id: String) -> NextRepTimerSound {
    nextRepTimerSounds.first { $0.id == id } ?? nextRepTimerSounds[0]
}

func playNextRepTimerSound(_ id: String) {
    let sound = nextRepTimerSound(for: id)
    configureNextRepAudioSession()
    if let systemSoundId = sound.systemSoundId {
        AudioServicesPlaySystemSound(systemSoundId)
    }
    if sound.vibrates || sound.systemSoundId == nil {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

private func configureNextRepAudioSession() {
    #if os(iOS)
    try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    try? AVAudioSession.sharedInstance().setActive(true, options: [])
    #endif
}

struct IntervalTimerView: View {
    @Environment(AppStore.self) private var store
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let stopwatchTicker = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    @State private var topMode = "timer"
    @State private var timerInput = ""
    @State private var timerTotal = 60
    @State private var timerRemaining = 60
    @State private var timerRunning = false
    @State private var timerDone = false
    @State private var stopwatchCentiseconds = 0
    @State private var stopwatchRunning = false
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
    @State private var showingSoundPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                topModePicker
                switch topMode {
                case "stopwatch":
                    stopwatchCard
                case "interval":
                    intervalModePicker
                    intervalCard
                    intervalControls
                    intervalSettings
                default:
                    countdownCard
                    recentTimers
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Timer")
        .navigationBarTitleDisplayMode(.inline)
        .accentColor(Color(hex: store.appData.themeColor))
        .tint(Color(hex: store.appData.themeColor))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSoundPicker = true
                } label: {
                    Image(systemName: "speaker.wave.2")
                }
                .tint(Theme.accentLight)
            }
        }
        .sheet(isPresented: $showingSoundPicker) {
            NavigationStack {
                soundCard
                    .padding(16)
                    .frame(maxWidth: 448)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .accentColor(Color(hex: store.appData.themeColor))
                    .tint(Color(hex: store.appData.themeColor))
                    .screenBackground()
                    .navigationTitle("Completion Sound")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showingSoundPicker = false
                            }
                            .tint(Theme.accentLight)
                        }
                    }
            }
        }
        .screenBackground()
        .onAppear {
            topMode = ["timer", "stopwatch", "interval"].contains(store.appData.timerMode) ? store.appData.timerMode : "timer"
            seedIntervalSettings()
        }
        .onChange(of: mode) { _, _ in
            resetTimer()
            store.setIntervalFormat(mode)
        }
        .onChange(of: topMode) { _, newMode in
            store.setTimerMode(newMode)
        }
        .onReceive(ticker) { _ in
            tickCountdown()
            tickInterval()
        }
        .onReceive(stopwatchTicker) { _ in
            tickStopwatch()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Timer")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("Timer · Stopwatch · Interval")
                .font(.caption)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Theme.accentLight)
        }
    }

    private var topModePicker: some View {
        Picker("Timer mode", selection: $topMode) {
            Text("Timer").tag("timer")
            Text("Stopwatch").tag("stopwatch")
            Text("Interval").tag("interval")
        }
        .pickerStyle(.segmented)
    }

    private var soundCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completion Sound")
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    Text("Used for countdown, interval, and workout rest completion.")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                }

                Spacer()

                Button("Preview") {
                    playNextRepTimerSound(store.appData.timerSound)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: store.appData.themeColor))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 94), spacing: 8)], spacing: 8) {
                ForEach(nextRepTimerSounds) { sound in
                    Button {
                        store.setTimerSound(sound.id)
                        playNextRepTimerSound(sound.id)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: sound.id == "vibrate" ? "iphone.radiowaves.left.and.right" : "speaker.wave.2.fill")
                                .font(.caption.weight(.bold))
                            Text(sound.label)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(store.appData.timerSound == sound.id ? .white : Theme.textDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(store.appData.timerSound == sound.id ? Color(hex: store.appData.themeColor) : Theme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }

    private var countdownCard: some View {
        VStack(spacing: 18) {
            ProgressRing(
                value: timerTotal > 0 ? Double(timerRemaining) / Double(timerTotal) : 0,
                size: 190,
                lineWidth: 12,
                center: timerDone ? "Done" : formatIntervalClock(timerRemaining)
            )

            if timerDone {
                Text("Time's up!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accentLight)
            }

            HStack(spacing: 10) {
                TextField("Set time (mm:ss or seconds)", text: $timerInput)
                    .keyboardType(.numberPad)
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.inputBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onChange(of: timerInput) { _, newValue in
                        timerInput = maskTimerInput(newValue)
                    }

                Button(timerRunning ? "Reset" : "Start") {
                    timerRunning ? resetCountdown() : startCountdown()
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private var recentTimers: some View {
        if !store.appData.savedTimers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Timers")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                ForEach(store.appData.savedTimers) { timer in
                    HStack {
                        Button {
                            loadSavedTimer(timer.seconds)
                        } label: {
                            Label(timer.label, systemImage: "play.fill")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.text)

                        Spacer()

                        Button {
                            store.removeSavedTimer(id: timer.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .foregroundStyle(.red.opacity(0.8))
                    }
                    .padding(12)
                    .background(Theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .cardStyle()
        }
    }

    private var stopwatchCard: some View {
        VStack(spacing: 22) {
            Text(stopwatchText)
                .font(.system(size: 58, weight: .bold, design: .default).monospacedDigit())
                .foregroundStyle(Theme.text)

            HStack(spacing: 10) {
                Button {
                    stopwatchRunning.toggle()
                } label: {
                    Text(stopwatchRunning ? "Pause" : stopwatchCentiseconds == 0 ? "Start" : "Resume")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    stopwatchRunning = false
                    stopwatchCentiseconds = 0
                } label: {
                    Text("Reset")
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
        .cardStyle()
    }

    private var intervalModePicker: some View {
        Picker("Mode", selection: $mode) {
            Text("TABATA").tag("TABATA")
            Text("EMOM").tag("EMOM")
            Text("AMRAP").tag("AMRAP")
        }
        .pickerStyle(.segmented)
    }

    private var intervalCard: some View {
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

    private var intervalControls: some View {
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

    private var intervalSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .foregroundStyle(Theme.text)

            switch mode {
            case "EMOM":
                StepperRow(title: "Interval", value: $emomInterval, range: 15...300, step: 15, suffix: "s") {
                    persistIntervalSettings()
                    resetTimer()
                }
                StepperRow(title: "Rounds", value: $rounds, range: 1...60, step: 1, suffix: "") {
                    persistIntervalSettings()
                    resetTimer()
                }
            case "AMRAP":
                StepperRow(title: "Time cap", value: $amrapCap, range: 60...3600, step: 60, suffix: "s") {
                    persistIntervalSettings()
                    resetTimer()
                }
            default:
                StepperRow(title: "Work", value: $workSeconds, range: 5...300, step: 5, suffix: "s") {
                    persistIntervalSettings()
                    resetTimer()
                }
                StepperRow(title: "Rest", value: $restSeconds, range: 0...300, step: 5, suffix: "s") {
                    persistIntervalSettings()
                    resetTimer()
                }
                StepperRow(title: "Rounds", value: $rounds, range: 1...60, step: 1, suffix: "") {
                    persistIntervalSettings()
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

    private func tickCountdown() {
        guard topMode == "timer", timerRunning else { return }
        if timerRemaining > 1 {
            timerRemaining -= 1
        } else {
            timerRemaining = 0
            timerRunning = false
            timerDone = true
            playNextRepTimerSound(store.appData.timerSound)
        }
    }

    private func tickStopwatch() {
        guard topMode == "stopwatch", stopwatchRunning else { return }
        stopwatchCentiseconds += 1
    }

    private func tickInterval() {
        guard topMode == "interval" else { return }
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
        playNextRepTimerSound(store.appData.timerSound)

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

    private func startCountdown() {
        let seconds = parseTimerInput(timerInput) ?? timerTotal
        let total = max(1, seconds)
        timerTotal = total
        timerRemaining = total
        timerDone = false
        timerRunning = true
        store.addSavedTimer(seconds: total)
    }

    private func resetCountdown() {
        timerRunning = false
        timerDone = false
        timerRemaining = timerTotal
    }

    private func loadSavedTimer(_ seconds: Int) {
        timerRunning = false
        timerDone = false
        timerTotal = seconds
        timerRemaining = seconds
        timerInput = formatIntervalClock(seconds)
    }

    private var stopwatchText: String {
        let totalSeconds = stopwatchCentiseconds / 100
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let hundredths = stopwatchCentiseconds % 100
        return String(format: "%d:%02d.%02d", minutes, seconds, hundredths)
    }

    private func seedIntervalSettings() {
        let settings = store.appData.intervalSettings
        emomInterval = settings.emomInterval
        rounds = settings.tabataRounds
        workSeconds = settings.tabataWork
        restSeconds = settings.tabataRest
        amrapCap = settings.amrapCap
        mode = store.appData.intervalFormat ?? "TABATA"
        resetTimer()
    }

    private func persistIntervalSettings() {
        var settings = store.appData.intervalSettings
        settings.emomInterval = emomInterval
        settings.emomRounds = rounds
        settings.tabataWork = workSeconds
        settings.tabataRest = restSeconds
        settings.tabataRounds = rounds
        settings.amrapCap = amrapCap
        store.setIntervalSettings(settings)
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
                .onChange(of: value) { _, _ in
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

private func parseTimerInput(_ input: String) -> Int? {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    if trimmed.contains(":") {
        let parts = trimmed.split(separator: ":", omittingEmptySubsequences: false)
        let minutes = Int(String(parts.first ?? "0")) ?? 0
        let seconds = parts.count > 1 ? (Int(String(parts[1])) ?? 0) : 0
        return minutes * 60 + seconds
    }
    return Int(trimmed)
}

private func maskTimerInput(_ input: String) -> String {
    let digits = String(input.filter(\.isNumber).prefix(4))
    guard digits.count > 2 else { return digits }
    let split = digits.index(digits.endIndex, offsetBy: -2)
    return "\(digits[..<split]):\(digits[split...])"
}
