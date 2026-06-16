import SwiftUI

struct ProfileView: View {
    @StateObject private var store = AppStore()
    @State private var newWeight: String = ""
    @State private var showingWorkoutHistory: Bool = false
    @State private var showingBodyWeightHistory: Bool = false
    @State private var showingMaxTracker: Bool = false
    @State private var showingSettings: Bool = false
    @State private var showingNutrition: Bool = false
    
    private var workoutsCount: Int {
        store.userLogs.count
    }
    
    private var dayStreak: Int {
        computeStreak(logs: store.userLogs)
    }
    
    private var totalVolumeK: String {
        let vol = totalVolume(logs: store.userLogs) / 1000
        return String(format: "%.1fk", vol)
    }
    
    private var bodyWeightEntries: [BodyWeightEntry] {
        store.appData.bodyWeightEntries.sorted { $0.date > $1.date }
    }
    
    private var recentWorkouts: [WorkoutLog] {
        store.userLogs.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        Text("Progress")
                            .font(Theme.display(32))
                            .foregroundColor(Theme.text)
                            .tracking(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 3-stat row
                        statsRow
                        
                        // Tracker nav rows
                        trackerNavRows
                        
                        // Body Weight card
                        bodyWeightCard
                        
                        // Workout History section
                        workoutHistorySection
                    }
                }
                .padding()
            }
        }
        .navigationDestination(isPresented: $showingWorkoutHistory) {
            WorkoutHistoryView()
        }
        .navigationDestination(isPresented: $showingBodyWeightHistory) {
            BodyWeightHistoryView()
        }
        .navigationDestination(isPresented: $showingMaxTracker) {
            MaxTrackerView()
        }
        .navigationDestination(isPresented: $showingSettings) {
            SettingsView()
        }
        .navigationDestination(isPresented: $showingNutrition) {
            NutritionView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(Theme.text)
                }
            }
        }
        .task {
            await store.loadAppData()
        }
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            // Workouts
            statCard(
                title: "Workouts",
                value: "\(workoutsCount)"
            )
            
            // Day streak
            statCard(
                title: "Day streak",
                value: "\(dayStreak)"
            )
            
            // Volume
            statCard(
                title: "\(totalVolumeK) Volume",
                value: store.unit
            )
        }
    }
    
    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.display(24))
                .foregroundColor(Theme.text)
                .tracking(1)
            
            Text(title)
                .font(Theme.body(10))
                .foregroundColor(Theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Tracker Nav Rows
    
    private var trackerNavRows: some View {
        VStack(spacing: 12) {
            // Nutrition
            Button(action: {
                showingNutrition = true
            }) {
                HStack {
                    Image(systemName: "leaf")
                        .font(.title3)
                        .foregroundColor(Theme.accent)
                    
                    Text("Nutrition")
                        .font(Theme.body(14))
                        .foregroundColor(Theme.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                }
                .padding(16)
                .background(Theme.surface)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Max Tracker
            Button(action: { showingMaxTracker = true }) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundColor(Theme.accent)
                    
                    Text("Max Tracker")
                        .font(Theme.body(14))
                        .foregroundColor(Theme.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                }
                .padding(16)
                .background(Theme.surface)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Body Weight Card
    
    private var bodyWeightCard: some View {
        VStack(spacing: 16) {
            // Sparkline
            if bodyWeightEntries.count >= 2 {
                bodyWeightSparkline
            } else {
                // Empty state
                Text("Log your weight to see trends")
                    .font(Theme.body(12))
                    .foregroundColor(Theme.placeholder)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(Theme.placeholder)
                    )
            }
            
            // Latest value + delta
            if let latest = bodyWeightEntries.first {
                HStack(spacing: 12) {
                    Text(String(format: "%.1f", latest.weight))
                        .font(Theme.display(36))
                        .foregroundColor(Theme.text)
                        .tracking(1)
                    
                    if let first = bodyWeightEntries.last, first.id != latest.id {
                        let delta = latest.weight - first.weight
                        let deltaText = delta > 0 ? "+\(String(format: "%.1f", delta))" : String(format: "%.1f", delta)
                        HStack(spacing: 4) {
                            Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                            Text(deltaText)
                                .font(Theme.body(12))
                        }
                        .foregroundColor(delta > 0 ? Theme.accent : .green)
                    }
                }
            }
            
            // Add weight input
            HStack(spacing: 8) {
                TextField("Weight", text: $newWeight)
                    .keyboardType(.decimalPad)
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {
                    if let weight = Double(newWeight) {
                        Task {
                            await store.addBodyWeight(weight: weight)
                            newWeight = ""
                        }
                    }
                }) {
                    Text("Log")
                        .font(Theme.body(14))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.accent)
                        .cornerRadius(8)
                }
                .disabled(newWeight.isEmpty)
            }
            
            // Recent list (last 5)
            if !bodyWeightEntries.isEmpty {
                VStack(spacing: 8) {
                    ForEach(bodyWeightEntries.prefix(5)) { entry in
                        bodyWeightRow(entry: entry)
                    }
                    
                    if bodyWeightEntries.count > 5 {
                        Button("Show More") {
                            showingBodyWeightHistory = true
                        }
                        .font(Theme.body(12))
                        .foregroundColor(Theme.accent)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private var bodyWeightSparkline: some View {
        let weights = bodyWeightEntries.map { $0.weight }
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? 0
        let range = maxWeight - minWeight
        
        return VStack {
            GeometryReader { geometry in
                ZStack {
                    // Area fill
                    if range > 0 {
                        Path { path in
                            for (index, weight) in weights.enumerated() {
                                let x = geometry.size.width * CGFloat(index) / CGFloat(weights.count - 1)
                                let normalizedY = range > 0 ? (weight - minWeight) / range : 0.5
                                let y = geometry.size.height * (1 - normalizedY)
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .fill(Theme.accent.opacity(0.2))
                        
                        // Line
                        Path { path in
                            for (index, weight) in weights.enumerated() {
                                let x = geometry.size.width * CGFloat(index) / CGFloat(weights.count - 1)
                                let normalizedY = range > 0 ? (weight - minWeight) / range : 0.5
                                let y = geometry.size.height * (1 - normalizedY)
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Theme.accent, lineWidth: 2)
                    }
                }
            }
            .frame(height: 100)
        }
    }
    
    private func bodyWeightRow(entry: BodyWeightEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(entry.date))
                    .font(Theme.body(12))
                    .foregroundColor(Theme.text)
                
                Text(formatShortDate(entry.date))
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
            }
            
            Spacer()
            
            Text(String(format: "%.1f", entry.weight))
                .font(Theme.body(14))
                .foregroundColor(Theme.text)
            
            Button(action: {
                Task {
                    await store.deleteBodyWeight(id: entry.id)
                }
            }) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Workout History Section
    
    private var workoutHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout History")
                .font(Theme.body(16))
                .fontWeight(.semibold)
                .foregroundColor(Theme.text)
            
            if recentWorkouts.isEmpty {
                Text("No workouts yet")
                    .font(Theme.body(12))
                    .foregroundColor(Theme.placeholder)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentWorkouts) { log in
                        workoutLogCard(log: log)
                    }
                    
                    if store.userLogs.count > 5 {
                        Button("Show More") {
                            showingWorkoutHistory = true
                        }
                        .font(Theme.body(12))
                        .foregroundColor(Theme.accent)
                    }
                }
            }
        }
    }
    
    private func workoutLogCard(log: WorkoutLog) -> some View {
        let program = store.allPrograms.first { $0.id == log.programId }
        let day = program?.days.first { $0.id == log.dayId }
        let setCount = log.exercises.reduce(0) { $0 + $1.sets.count }
        
        return Button(action: {}) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(day?.name ?? "Workout")
                        .font(Theme.body(14))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.text)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await deleteLog(log)
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Text("\(program?.name ?? "Program") · \(formatDate(log.date))")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
                
                HStack(spacing: 8) {
                    Text("\(setCount) sets")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                    
                    Image(systemName: "arrow.up")
                        .font(.caption)
                        .foregroundColor(Theme.accent)
                    
                    Text(String(format: "%.0f", log.totalVolume))
                        .font(Theme.body(10))
                        .foregroundColor(Theme.accent)
                }
            }
            .padding(12)
            .background(Theme.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Delete Log
    
    private func deleteLog(_ log: WorkoutLog) async {
        store.appData.logs.removeAll { $0.id == log.id }
        await store.saveAppData()
    }
}