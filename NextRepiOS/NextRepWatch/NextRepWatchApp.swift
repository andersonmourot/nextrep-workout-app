import SwiftUI

@main
struct NextRepWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
            
            WorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "dumbbell")
                }
        }
    }
}

struct TimerView: View {
    @State private var remainingTime = 60
    @State private var isRunning = false
    @State private var currentPhase = "REST"
    
    var body: some View {
        VStack(spacing: 20) {
            Text(currentPhase)
                .font(.headline)
                .foregroundColor(currentPhase == "WORK" ? .green : .orange)
            
            Text("\(remainingTime)")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
            
            Button(action: toggleTimer) {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.largeTitle)
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Timer")
    }
    
    private func toggleTimer() {
        isRunning.toggle()
        if isRunning {
            startTimer()
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if remainingTime > 0 {
                remainingTime -= 1
                WKInterfaceDevice.current().play(.click)
            } else {
                timer.invalidate()
                isRunning = false
                WKInterfaceDevice.current().play(.notification)
            }
        }
    }
}

struct WorkoutView: View {
    @State private var currentExercise = "Bench Press"
    @State private var currentSet = 1
    @State private var totalSets = 3
    @State private var completedSets: Set<Int> = []
    
    var body: some View {
        VStack(spacing: 15) {
            Text(currentExercise)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            HStack {
                Text("Set \(currentSet) of \(totalSets)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 10) {
                ForEach(1...totalSets, id: \.self) { set in
                    Button(action: {
                        toggleSet(set)
                    }) {
                        Image(systemName: completedSets.contains(set) ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(completedSets.contains(set) ? .green : .gray)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Workout")
    }
    
    private func toggleSet(_ set: Int) {
        if completedSets.contains(set) {
            completedSets.remove(set)
        } else {
            completedSets.insert(set)
            WKInterfaceDevice.current().play(.success)
        }
    }
}