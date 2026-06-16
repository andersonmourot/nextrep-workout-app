import SwiftUI

struct ProgramDetailView: View {
    let program: Program
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = AppStore()
    @State private var selectedWeek: Int = 1
    @State private var showingSwitchConfirmation = false
    @State private var pendingProgramId: String?
    @State private var pendingDayId: String?
    @State private var pendingWeek: Int?
    
    private let maxFavorites = 5
    
    var body: some View {
        ScreenWrapper {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero card
                    heroCard
                    
                    // Week pager (if durationWeeks > 1)
                    if program.durationWeeks > 1 {
                        weekPager
                    }
                    
                    // Day list
                    dayList
                }
                .padding(.bottom, 20)
            }
            .navigationDestination(isPresented: Binding(
                get: { pendingProgramId != nil },
                set: { if !$0 { 
                    pendingProgramId = nil
                    pendingDayId = nil
                    pendingWeek = nil
                } }
            )) {
                if store.activeWorkout != nil {
                    ActiveWorkoutView()
                }
            }
            .alert("Switch Programs?", isPresented: $showingSwitchConfirmation) {
                Button("Cancel", role: .cancel) {
                    pendingProgramId = nil
                    pendingDayId = nil
                    pendingWeek = nil
                }
                Button("Switch", role: .destructive) {
                    if let programId = pendingProgramId,
                       let dayId = pendingDayId,
                       let week = pendingWeek {
                        Task {
                            await handleSwitchAndStart(programId: programId, dayId: dayId, week: week)
                        }
                    }
                }
            } message: {
                Text("You have an active workout in progress. Switching programs will end your current workout. Continue?")
            }
        }
        .task {
            await store.loadAppData()
            await store.loadCatalog()
            
            // Set accent from theme color
            if let themeColor = store.appData.themeColor {
                Theme.setAccent(from: themeColor)
            }
            
            // Set initial week to current week from programRun
            let run = programRun(program: program, logs: store.userLogs, since: store.appData.programAnchors[program.id])
            selectedWeek = run.currentWeekIndex + 1
        }
    }
    
    // MARK: - Hero Card
    
    private var heroCard: some View {
        let isActive = store.appData.activeProgramId == program.id
        let isFavorite = store.appData.favoriteProgramIds.contains(program.id)
        let isCustom = store.appData.customPrograms.contains { $0.id == program.id }
        let accentColor = Color(hex: UInt(Int(accentColor(for: program).dropFirst(2), radix: 16) ?? 0x355E3B))
        let canFavorite = isFavorite || store.appData.favoriteProgramIds.count < maxFavorites
        
        return VStack(alignment: .leading, spacing: 16) {
            // Top row with favorite toggle
            HStack {
                Spacer()
                
                Button(action: {
                    Task {
                        await toggleFavorite()
                    }
                }) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(isFavorite ? Theme.accent : Theme.textDim)
                }
                .disabled(!canFavorite && !isFavorite)
            }
            
            // Eyebrow with category · level + custom/following pill
            HStack(spacing: 8) {
                Text("\(program.category) · \(program.level)")
                    .eyebrow()
                
                if isCustom {
                    Text("Custom")
                        .chip()
                } else if program.collaborative == true {
                    Text("Following")
                        .chip()
                }
            }
            
            // Title
            Text(program.name)
                .font(Theme.display(32))
                .foregroundColor(Theme.text)
                .tracking(1)
            
            // Description
            if let summary = program.summary {
                Text(summary)
                    .font(Theme.body(14))
                    .foregroundColor(Theme.textDim)
            }
            
            // Meta tiles
            HStack(spacing: 12) {
                metaTile(title: "Weeks", value: "\(program.durationWeeks)")
                metaTile(title: "Days/wk", value: "\(program.daysPerWeek)")
                metaTile(title: "Days", value: "\(program.days.count)")
            }
            
            // Set as Active Program button
            if isActive {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.caption)
                    Text("Active Program")
                }
                .buttonStyle(GhostButton())
                .disabled(true)
            } else {
                Button(action: {
                    Task {
                        await store.setActiveProgram(program.id)
                    }
                }) {
                    Text("Set as Active Program")
                }
                .buttonStyle(PrimaryButton())
            }
        }
        .cardStyle()
        .programCardGradient()
    }
    
    private func metaTile(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.display(20))
                .foregroundColor(Theme.text)
            
            Text(title)
                .font(Theme.body(10))
                .foregroundColor(Theme.textDim)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(12)
    }
    
    // MARK: - Week Pager
    
    private var weekPager: some View {
        HStack {
            Button(action: {
                if selectedWeek > 1 {
                    selectedWeek -= 1
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(selectedWeek > 1 ? Theme.text : Theme.textDim)
            }
            .disabled(selectedWeek <= 1)
            
            Spacer()
            
            Text("Week \(selectedWeek)")
                .font(Theme.display(16))
                .foregroundColor(Theme.text)
                .tracking(1)
            
            Spacer()
            
            Button(action: {
                if selectedWeek < program.durationWeeks {
                    selectedWeek += 1
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(selectedWeek < program.durationWeeks ? Theme.text : Theme.textDim)
            }
            .disabled(selectedWeek >= program.durationWeeks)
        }
        .cardStyle(12)
    }
    
    // MARK: - Day List
    
    private var dayList: some View {
        VStack(spacing: 12) {
            ForEach(0..<program.days.count, id: \.self) { index in
                if let day = resolveProgramDay(program: program, dayLocalIdx: index, week: selectedWeek) {
                    dayCard(day: day, index: index)
                }
            }
        }
    }
    
    private func dayCard(day: ProgramDay, index: Int) -> some View {
        let isUpNext = isDayUpNext(day: day, index: index)
        let isLogged = isDayLogged(day: day, week: selectedWeek)
        let isActiveWorkoutDay = store.appData.activeWorkout?.programId == program.id &&
                                  store.appData.activeWorkout?.dayId == day.id &&
                                  store.appData.activeWorkout?.week == selectedWeek
        let accentColor = Color(hex: UInt(Int(accentColor(for: program).dropFirst(2), radix: 16) ?? 0x355E3B))
        
        let cardContent = VStack(alignment: .leading, spacing: 12) {
            dayHeader(day: day, index: index, isUpNext: isUpNext, isLogged: isLogged, isActiveWorkoutDay: isActiveWorkoutDay, accentColor: accentColor)
            exerciseList(day: day)
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUpNext ? accentColor.opacity(0.5) : Color.white.opacity(0.05), lineWidth: isUpNext ? 2 : 1)
        )
        .shadow(
            color: isUpNext ? accentColor.opacity(0.3) : .black.opacity(0.6),
            radius: isUpNext ? 16 : 12,
            x: 0,
            y: 8
        )
        
        return Button(action: {
            // TODO: Navigate to Day review
        }) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func dayHeader(day: ProgramDay, index: Int, isUpNext: Bool, isLogged: Bool, isActiveWorkoutDay: Bool, accentColor: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                dayEyebrow(index: index, isUpNext: isUpNext, isLogged: isLogged, accentColor: accentColor)
                Text(day.name)
                    .font(Theme.display(18))
                    .foregroundColor(Theme.text)
                    .tracking(1)
                Text(day.focus)
                    .font(Theme.body(12))
                    .foregroundColor(Theme.textDim)
            }
            
            Spacer()
            
            startButton(day: day, isActiveWorkoutDay: isActiveWorkoutDay, accentColor: accentColor)
        }
    }
    
    private func dayEyebrow(index: Int, isUpNext: Bool, isLogged: Bool, accentColor: Color) -> some View {
        HStack(spacing: 6) {
            Text("Day \(index + 1)")
                .font(Theme.body(11))
                .foregroundColor(Theme.placeholder)
                .tracking(2)
            
            if isLogged {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(Theme.accent)
            } else if isUpNext {
                Text("Up next")
                    .font(Theme.body(10))
                    .foregroundColor(accentColor)
            }
        }
    }
    
    private func startButton(day: ProgramDay, isActiveWorkoutDay: Bool, accentColor: Color) -> some View {
        Button(action: {
            handleStartDay(dayId: day.id, week: selectedWeek)
        }) {
            Text(isActiveWorkoutDay ? "Resume" : "Start")
                .font(Theme.body(12))
                .foregroundColor(accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.surface2)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.4), lineWidth: 1)
                )
        }
    }
    
    private func exerciseList(day: ProgramDay) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(day.exercises.enumerated()), id: \.element.id) { index, exercise in
                exerciseRow(exercise: exercise, day: day, isLast: index == day.exercises.count - 1)
            }
        }
    }
    
    private func exerciseRow(exercise: PlannedExercise, day: ProgramDay, isLast: Bool) -> some View {
        let hasLibraryExercise = store.allExercises.contains { $0.id == exercise.exerciseId }
        let accentColor = Color(hex: UInt(Int(accentColor(for: program).dropFirst(2), radix: 16) ?? 0x355E3B))
        
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exerciseLabel(for: exercise))
                    .font(Theme.body(14))
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.text)
                
                Text("\(exercise.sets) × \(exercise.reps) · \(exercise.restSec)s rest")
                    .font(Theme.body(12))
                    .foregroundColor(Theme.textDim)
            }
            
            Spacer()
            
            if hasLibraryExercise {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textDim)
            }
        }
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
        .contentShape(Rectangle())
    }
    
    // MARK: - Helpers
    
    private func accentColor(for program: Program) -> String {
        return program.accent ?? "#355E3B"
    }
    
    private func isDayUpNext(day: ProgramDay, index: Int) -> Bool {
        let run = programRun(program: program, logs: store.userLogs, since: store.appData.programAnchors[program.id])
        return !run.isComplete && index == run.nextDayIndex && selectedWeek == run.currentWeekIndex + 1
    }
    
    private func isDayLogged(day: ProgramDay, week: Int) -> Bool {
        return store.userLogs.contains { log in
            log.programId == program.id && log.dayId == day.id && log.week == week
        }
    }
    
    private func handleStartDay(dayId: String, week: Int) {
        let hasActiveWorkout = store.appData.activeWorkout != nil
        let isDifferentProgram = store.appData.activeWorkout?.programId != program.id
        
        if hasActiveWorkout && isDifferentProgram {
            // Show confirmation dialog
            pendingProgramId = program.id
            pendingDayId = dayId
            pendingWeek = week
            showingSwitchConfirmation = true
        } else {
            // Start workout directly
            let dayIndex = program.days.firstIndex { $0.id == dayId } ?? 0
            Task {
                await store.startWorkout(programId: program.id, dayId: dayId, week: week, dayIndex: dayIndex)
                pendingProgramId = program.id
                pendingDayId = dayId
                pendingWeek = week
            }
        }
    }
    
    private func handleSwitchAndStart(programId: String, dayId: String, week: Int) async {
        // End current workout
        await store.endWorkout()
        
        // Set new active program
        await store.setActiveProgram(programId)
        
        // Start new workout
        let dayIndex = program.days.firstIndex { $0.id == dayId } ?? 0
        await store.startWorkout(programId: programId, dayId: dayId, week: week, dayIndex: dayIndex)
        
        pendingProgramId = programId
        pendingDayId = dayId
        pendingWeek = week
    }
    
    private func toggleFavorite() async {
        var favorites = store.appData.favoriteProgramIds
        if favorites.contains(program.id) {
            favorites.removeAll { $0 == program.id }
        } else if favorites.count < maxFavorites {
            favorites.append(program.id)
        }
        store.appData.favoriteProgramIds = favorites
        await store.saveAppData()
    }
}

#Preview {
    NavigationStack {
        ProgramDetailView(program: Program(
            id: "1",
            name: "Full Body Blast",
            category: "Bodybuilding",
            level: "Intermediate",
            coach: "Coach Smith",
            durationWeeks: 8,
            daysPerWeek: 3,
            days: [
                ProgramDay(id: "1", name: "Day 1", focus: "Chest & Back", exercises: []),
                ProgramDay(id: "2", name: "Day 2", focus: "Legs", exercises: []),
                ProgramDay(id: "3", name: "Day 3", focus: "Shoulders & Arms", exercises: [])
            ],
            summary: "A comprehensive full body program for intermediate lifters"
        ))
    }
    .background(Theme.bg)
}