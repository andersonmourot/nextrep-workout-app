import SwiftUI

struct DashboardView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab: Tab? = nil
    
    var body: some View {
        ScreenWrapper {
            VStack(spacing: 0) {
                // Resume workout banner (if active workout exists)
                if store.appData.activeWorkout != nil {
                    ResumeWorkoutBanner {
                        selectedTab = .workout
                    }
                    .padding(.bottom, 16)
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Today's workout card
                        todayWorkoutSection
                        
                        // Stats row
                        statsSection
                        
                        // Recent activity
                        recentActivitySection
                    }
                    .padding(.bottom, 100) // Space for bottom tab bar
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedTab != nil },
                set: { if !$0 { selectedTab = nil } }
            )) {
                if let tab = selectedTab {
                    switch tab {
                    case .workout:
                        Text("Workout Screen") // TODO: Implement Workout screen
                    case .programDetail:
                        Text("Program Detail Screen") // TODO: Implement Program Detail screen
                    }
                }
            }
        }
        .task {
            await store.loadAppData()
            await store.loadCatalog()
            // Set accent from theme color
            if let themeColor = store.appData.themeColor {
                Theme.setAccent(from: themeColor)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting())
                .eyebrow()
            
            Text(store.userName)
                .screenTitle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Today's Workout Section
    
    private var todayWorkoutSection: some View {
        Group {
            if let program = store.activeProgram {
                let run = programRun(program: program, logs: store.userLogs, since: store.appData.programAnchors[program.id])
                
                if run.isComplete {
                    programCompleteCard(program: program)
                } else if let nextDay = resolveProgramDay(program: program, dayLocalIdx: run.nextDayIndex, week: run.currentWeekIndex + 1) {
                    activeProgramCard(program: program, day: nextDay, week: run.currentWeekIndex + 1, run: run)
                }
            } else {
                noActiveProgramCard
            }
        }
    }
    
    private func activeProgramCard(program: Program, day: ProgramDay, week: Int, run: ProgramRun) -> some View {
        let hasActiveWorkout = store.appData.activeWorkout?.programId == program.id
        let exerciseChips = Array(day.exercises.prefix(4))
        let moreCount = max(0, day.exercises.count - 4)
        let programAccent = Color(hex: UInt(Int(accentColor(for: program).dropFirst(2), radix: 16) ?? 0x355E3B))
        
        return Button(action: {
            selectedTab = .programDetail
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Top row
                HStack {
                    Text("Today · \(program.name)")
                        .eyebrow()
                    
                    Spacer()
                    
                    Text("Week \(week) · Day \(run.nextDayIndex + 1)")
                        .chip()
                }
                
                // Title
                Text(day.name)
                    .sectionTitle()
                
                // Subtitle
                Text(day.focus)
                    .font(Theme.body(14))
                    .foregroundColor(Theme.textDim)
                
                // Exercise chips
                if !exerciseChips.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                        ForEach(exerciseChips) { exercise in
                            Text(exerciseLabel(for: exercise))
                                .chip()
                        }
                        
                        if moreCount > 0 {
                            Text("+\(moreCount) more")
                                .chip()
                        }
                    }
                }
                
                // Action button
                Button(action: {
                    Task {
                        if hasActiveWorkout {
                            selectedTab = .workout
                        } else {
                            await store.startWorkout(programId: program.id, dayId: day.id, week: week)
                            selectedTab = .workout
                        }
                    }
                }) {
                    Text(hasActiveWorkout ? "Resume Workout" : "Start Workout")
                }
                .buttonStyle(PrimaryButton())
            }
            .cardStyle()
            .programCardGradient()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func programCompleteCard(program: Program) -> some View {
        Button(action: {
            selectedTab = .programDetail
        }) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Program complete")
                    .sectionTitle()
                
                Text("Congratulations! You've completed all \(program.durationWeeks) weeks of \(program.name).")
                    .font(Theme.body(14))
                    .foregroundColor(Theme.textDim)
                
                Button(action: {
                    selectedTab = .programDetail
                }) {
                    Text("View Program")
                }
                .buttonStyle(PrimaryButton())
            }
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var noActiveProgramCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("No active program")
                .sectionTitle()
            
            Text("Select a program to start tracking your workouts and see your progress.")
                .font(Theme.body(14))
                .foregroundColor(Theme.textDim)
            
            Button(action: {
                // TODO: Navigate to Programs tab
            }) {
                Text("Browse Programs")
            }
            .buttonStyle(PrimaryButton())
        }
        .cardStyle()
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            // Streak
            statCard(
                icon: "flame.fill",
                value: "\(computeStreak(logs: store.userLogs))",
                suffix: "days"
            )
            
            // Week ring
            weekProgressCard
            
            // Total workouts
            statCard(
                icon: "dumbbell.fill",
                value: "\(store.userLogs.count)",
                suffix: "total"
            )
        }
    }
    
    private func statCard(icon: String, value: String, suffix: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Theme.accent)
                .font(.title2)
            
            Text(value)
                .font(Theme.display(24))
                .foregroundColor(Theme.text)
            
            Text(suffix)
                .font(Theme.body(11))
                .foregroundColor(Theme.textDim)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(12)
    }
    
    private var weekProgressCard: some View {
        let weekCount = workoutsThisWeek(
            logs: store.userLogs,
            programId: store.appData.activeProgramId,
            since: store.appData.activeProgramId.flatMap { store.appData.programAnchors[$0] }
        )
        let weekTarget = store.activeProgram?.daysPerWeek ?? 3
        let progress = Double(weekCount) / Double(weekTarget)
        
        return VStack(spacing: 8) {
            ZStack {
                ProgressRing(value: progress)
                    .frame(width: 60, height: 60)
                
                Text("\(weekCount)")
                    .font(Theme.display(20))
                    .foregroundColor(Theme.text)
            }
            
            Text("of \(weekTarget)/wk")
                .font(Theme.body(11))
                .foregroundColor(Theme.textDim)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(12)
    }
    
    // MARK: - Recent Activity Section
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .sectionTitle()
                
                Spacer()
                
                Button("View all") {
                    // TODO: Navigate to Profile/Progress
                }
                .font(Theme.body(14))
                .foregroundColor(Theme.accentLt)
            }
            
            if store.userLogs.isEmpty {
                emptyActivityCard
            } else {
                VStack(spacing: 12) {
                    ForEach(store.userLogs.prefix(3)) { log in
                        activityRow(log: log)
                    }
                }
            }
        }
    }
    
    private var emptyActivityCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(Theme.textDim)
                .font(.title2)
            
            Text("Your completed workouts will show up here.")
                .font(Theme.body(14))
                .foregroundColor(Theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
    
    private func activityRow(log: WorkoutLog) -> some View {
        let program = store.allPrograms.first { $0.id == log.programId } ?? store.appData.customPrograms.first { $0.id == log.programId }
        let day = program?.days.first { $0.id == log.dayId }
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(day?.name ?? "Workout")
                    .font(Theme.body(14))
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.text)
                
                Text("\(program?.name ?? "Program") · \(formatDate(log.date))")
                    .font(Theme.body(12))
                    .foregroundColor(Theme.textDim)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Theme.accent)
                    .font(.caption)
                
                Text("\(Int(round(log.totalVolume))) \(store.unit)")
                    .font(Theme.body(12))
                    .foregroundColor(Theme.accent)
            }
        }
        .cardStyle(12)
    }
    
    // MARK: - Helpers
    
    private func accentColor(for program: Program) -> String {
        return program.accent ?? "#355E3B"
    }
    
    private enum Tab {
        case workout
        case programDetail
    }
}

#Preview {
    DashboardView()
        .background(Theme.bg)
}