import SwiftUI

enum IntervalTimerType: String, CaseIterable {
    case tabata = "TABATA"
    case emom = "EMOM"
    case amrap = "AMRAP"
    case custom = "Custom"
    
    var description: String {
        switch self {
        case .tabata: return "20s work, 10s rest, 8 rounds"
        case .emom: return "Every minute on the minute"
        case .amrap: return "As many rounds as possible"
        case .custom: return "Custom intervals"
        }
    }
}

@Observable
class IntervalTimerViewModel {
    var timerType: IntervalTimerType = .tabata
    var workSeconds: Int = 20
    var restSeconds: Int = 10
    var totalRounds: Int = 8
    var totalDuration: Int = 0 // For AMRAP (in minutes)
    
    var currentRound = 1
    var currentPhase: TimerPhase = .work
    var remainingTime = 20
    var isRunning = false
    var isPaused = false
    var isComplete = false
    
    private var timer: Timer?
    private(set) var totalElapsedSeconds = 0
    
    enum TimerPhase {
        case work
        case rest
        case preparation
    }
    
    // MARK: - Timer Control
    
    func startTimer() {
        isRunning = true
        isPaused = false
        currentPhase = .work
        remainingTime = workSeconds
        
        // Schedule background notification for timer completion
        let totalDuration = calculateTotalDuration()
        AudioManager.shared.scheduleTimerCompletionNotification(after: totalDuration)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        
        AudioManager.shared.setupAudioSession()
    }
    
    private func tick() {
        remainingTime -= 1
        totalElapsedSeconds += 1
        
        // Countdown beeps
        if remainingTime == 3 {
            AudioManager.shared.playCountdownBeep()
        }
        
        if remainingTime <= 0 {
            advancePhase()
        }
    }
    
    private func advancePhase() {
        switch timerType {
        case .tabata:
            if currentPhase == .work {
                // Switch to rest
                currentPhase = .rest
                remainingTime = restSeconds
                AudioManager.shared.playBellSound()
            } else {
                // Switch to work or complete
                if currentRound < totalRounds {
                    currentRound += 1
                    currentPhase = .work
                    remainingTime = workSeconds
                    AudioManager.shared.playBellSound()
                } else {
                    completeTimer()
                }
            }
            
        case .emom:
            // EMOM: work for the whole minute, then next round
            if currentRound < totalRounds {
                currentRound += 1
                remainingTime = 60 // Always 60 seconds for EMOM
                AudioManager.shared.playBellSound()
            } else {
                completeTimer()
            }
            
        case .amrap:
            // AMRAP: continuous work/rest cycles for total duration
            let totalSeconds = totalDuration * 60
            if totalElapsedSeconds >= totalSeconds {
                completeTimer()
            } else {
                // Alternate work/rest
                if currentPhase == .work {
                    currentPhase = .rest
                    remainingTime = restSeconds
                } else {
                    currentPhase = .work
                    remainingTime = workSeconds
                }
                AudioManager.shared.playBellSound()
            }
            
        case .custom:
            // Custom intervals
            if currentPhase == .work {
                if restSeconds > 0 {
                    currentPhase = .rest
                    remainingTime = restSeconds
                    AudioManager.shared.playBellSound()
                } else {
                    // No rest, go to next round
                    advanceRound()
                }
            } else {
                advanceRound()
            }
        }
    }
    
    private func advanceRound() {
        if currentRound < totalRounds {
            currentRound += 1
            currentPhase = .work
            remainingTime = workSeconds
            AudioManager.shared.playBellSound()
        } else {
            completeTimer()
        }
    }
    
    private func completeTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isComplete = true
        AudioManager.shared.playWorkoutCompleteSound()
        AudioManager.shared.cancelPendingNotifications()
    }
    
    func pauseTimer() {
        isPaused = true
        timer?.invalidate()
        timer = nil
        AudioManager.shared.cancelPendingNotifications()
    }
    
    func resumeTimer() {
        isPaused = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        
        // Reschedule notification
        let remainingDuration = calculateRemainingDuration()
        AudioManager.shared.scheduleTimerCompletionNotification(after: remainingDuration)
    }
    
    func resetTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        isComplete = false
        currentRound = 1
        currentPhase = .work
        remainingTime = workSeconds
        totalElapsedSeconds = 0
        AudioManager.shared.cancelPendingNotifications()
    }
    
    // MARK: - Helper Methods
    
    private func calculateTotalDuration() -> Int {
        switch timerType {
        case .tabata:
            return (workSeconds + restSeconds) * totalRounds
        case .emom:
            return 60 * totalRounds
        case .amrap:
            return totalDuration * 60
        case .custom:
            return (workSeconds + restSeconds) * totalRounds
        }
    }
    
    private func calculateRemainingDuration() -> Int {
        let totalDuration = calculateTotalDuration()
        return totalDuration - totalElapsedSeconds
    }
    
    func addRound() {
        totalRounds += 1
    }
    
    func removeRound() {
        if totalRounds > 1 {
            totalRounds -= 1
        }
    }
    
    deinit {
        timer?.invalidate()
        AudioManager.shared.cancelPendingNotifications()
    }
}

struct IntervalTimerView: View {
    @State private var viewModel = IntervalTimerViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color based on phase
                (viewModel.currentPhase == .work ? Color.green.opacity(0.3) : Color.orange.opacity(0.3))
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    if !viewModel.isComplete {
                        timerContentView
                    } else {
                        completionView
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        viewModel.resetTimer()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                TimerSettingsView(viewModel: viewModel)
            }
        }
    }
    
    var timerContentView: some View {
        VStack(spacing: 30) {
            // Timer type and round info
            VStack(spacing: 8) {
                Text(viewModel.timerType.rawValue)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Round \(viewModel.currentRound) of \(viewModel.totalRounds)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Phase indicator
            Text(viewModel.currentPhase == .work ? "WORK" : "REST")
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(viewModel.currentPhase == .work ? .green : .orange)
            
            // Main timer display
            Text(formatTime(viewModel.remainingTime))
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
            
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: viewModel.currentPhase == .work ? .green : .orange))
            
            // Control buttons
            HStack(spacing: 20) {
                if !viewModel.isRunning {
                    Button(action: viewModel.startTimer) {
                        Text("Start")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else if viewModel.isPaused {
                    Button(action: viewModel.resumeTimer) {
                        Text("Resume")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    Button(action: viewModel.pauseTimer) {
                        Text("Pause")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                if viewModel.isRunning || viewModel.isPaused {
                    Button(action: viewModel.resetTimer) {
                        Text("Reset")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                }
            }
            
            // Add/Remove rounds (only when not running)
            if !viewModel.isRunning && !viewModel.isPaused {
                HStack(spacing: 20) {
                    Button(action: viewModel.removeRound) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                    
                    Text("Rounds: \(viewModel.totalRounds)")
                        .font(.headline)
                    
                    Button(action: viewModel.addRound) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    var completionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Timer Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Great job! You completed \(viewModel.totalRounds) rounds")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start New Timer") {
                viewModel.resetTimer()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    var progress: Double {
        switch viewModel.timerType {
        case .tabata:
            let total = (viewModel.workSeconds + viewModel.restSeconds) * viewModel.totalRounds
            return Double(total - viewModel.remainingTime) / Double(total)
        case .emom:
            return Double(viewModel.currentRound) / Double(viewModel.totalRounds)
        case .amrap:
            let total = viewModel.totalDuration * 60
            return Double(viewModel.totalElapsedSeconds) / Double(total)
        case .custom:
            let total = (viewModel.workSeconds + viewModel.restSeconds) * viewModel.totalRounds
            return Double(total - viewModel.remainingTime) / Double(total)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct TimerSettingsView: View {
    @Bindable var viewModel: IntervalTimerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Timer Type") {
                    Picker("Type", selection: $viewModel.timerType) {
                        ForEach(IntervalTimerType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type as IntervalTimerType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text(viewModel.timerType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Work Settings") {
                    HStack {
                        Text("Work Duration")
                        Spacer()
                        Stepper("\(viewModel.workSeconds)s", value: $viewModel.workSeconds, in: 5...300)
                    }
                }
                
                Section("Rest Settings") {
                    HStack {
                        Text("Rest Duration")
                        Spacer()
                        Stepper("\(viewModel.restSeconds)s", value: $viewModel.restSeconds, in: 0...300)
                    }
                }
                
                if viewModel.timerType == .amrap {
                    Section("AMRAP Duration") {
                        HStack {
                            Text("Total Duration")
                            Spacer()
                            Stepper("\(viewModel.totalDuration) min", value: $viewModel.totalDuration, in: 1...60)
                        }
                    }
                } else {
                    Section("Rounds") {
                        HStack {
                            Text("Total Rounds")
                            Spacer()
                            Stepper("\(viewModel.totalRounds)", value: $viewModel.totalRounds, in: 1...50)
                        }
                    }
                }
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    IntervalTimerView()
}