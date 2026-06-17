import Foundation
import SwiftUI
import UIKit

struct WorkoutHistoryView: View {
    @Environment(AppStore.self) private var store
    @State private var weightText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                profileStats
                trackerLinks
                bodyWeightSection
                recentWorkoutsSection
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var sortedLogs: [WorkoutLog] {
        store.appData.logs.sorted { lhs, rhs in
            logDate(lhs) > logDate(rhs)
        }
    }

    private var recentLogs: [WorkoutLog] {
        Array(sortedLogs.prefix(5))
    }

    private var profileStats: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ProfileStatTile(
                icon: "dumbbell.fill",
                value: "\(store.appData.logs.count)",
                label: "Workouts"
            )
            ProfileStatTile(
                icon: "chart.line.uptrend.xyaxis",
                value: formatVolume(totalVolume),
                label: "Volume \(store.appData.unit)"
            )
            ProfileStatTile(
                icon: "flame.fill",
                value: "\(profileStreak)",
                label: "Streak"
            )
        }
    }

    private var totalVolume: Double {
        store.appData.logs.reduce(0) { total, log in
            total + log.totalVolume
        }
    }

    private var profileStreak: Int {
        computeProfileStreak(logs: store.appData.logs)
    }

    private var trackerLinks: some View {
        VStack(spacing: 10) {
            NavigationLink {
                NutritionTrackerView()
            } label: {
                ProfileNavigationCard(
                    icon: "fork.knife",
                    title: "Nutrition",
                    subtitle: todayNutrition.map { "\($0.calories) cal today" } ?? "Track macros and water"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                MaxTrackerView()
            } label: {
                ProfileNavigationCard(
                    icon: "trophy.fill",
                    title: "Max Tracker",
                    subtitle: store.appData.maxTrackers.isEmpty ? "Track your top lifts" : "\(store.appData.maxTrackers.count) tracked lifts"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var bodyWeightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Body Weight")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Spacer()

                if let latest = sortedBodyWeight.last {
                    Text("\(formatWeight(latest.weight)) \(store.appData.unit)")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(Theme.accentLight)
                }
            }

            if sortedBodyWeight.count >= 2 {
                MiniLineChart(values: sortedBodyWeight.map(\.weight))
                    .frame(height: 90)
                    .padding(12)
                    .background(Theme.inputBg.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(spacing: 10) {
                TextField("Today's weight", text: $weightText)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.inputBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button("Log") {
                    if let weight = Double(weightText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        store.addBodyWeight(weight)
                        weightText = ""
                    }
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if sortedBodyWeight.isEmpty {
                Text("Log body weight to see your trend here.")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            } else {
                ForEach(sortedBodyWeight.suffix(3).reversed()) { entry in
                    HStack {
                        Text(formatBodyWeightDate(entry.date))
                            .font(.caption)
                            .foregroundStyle(Theme.textDim)

                        Spacer()

                        Text("\(formatWeight(entry.weight)) \(store.appData.unit)")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(Theme.text)

                        Button {
                            store.deleteBodyWeight(id: entry.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .foregroundStyle(.red.opacity(0.8))
                    }
                    .padding(10)
                    .background(Theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .cardStyle()
    }

    private var sortedBodyWeight: [BodyWeightEntry] {
        store.appData.bodyWeight.sorted { $0.date < $1.date }
    }

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Spacer()

                if sortedLogs.count > 5 {
                    NavigationLink {
                        AllWorkoutHistoryView(logs: sortedLogs, unit: store.appData.unit)
                    } label: {
                        Text("View all")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.accentLight)
                    }
                }
            }

            if sortedLogs.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(recentLogs) { log in
                        NavigationLink {
                            WorkoutLogDetailView(log: log)
                        } label: {
                            WorkoutLogRow(log: log, unit: store.appData.unit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var todayNutrition: NutritionEntry? {
        store.appData.nutritionLog.first { $0.date == todayKey() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Workout History")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("\(store.appData.logs.count) completed")
                .font(.caption)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Theme.accentLight)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No workouts yet", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(Theme.text)

            Text("Finished workouts will appear here with the weight and reps you logged.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

private struct ProfileStatTile: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Theme.accentLight)

            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.0)
                .foregroundStyle(Theme.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.05), lineWidth: 1)
        }
    }
}

private struct ProfileNavigationCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Theme.accentLight)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textFaint)
        }
        .cardStyle()
    }
}

private struct ProfileMiniMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(Theme.text)
            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Theme.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private func profileInput(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
    TextField(placeholder, text: text)
        .keyboardType(keyboard)
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Theme.inputBg)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
}

struct NutritionTrackerView: View {
    @Environment(AppStore.self) private var store
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var carbsText = ""
    @State private var fatText = ""
    @State private var waterText = ""
    @State private var goalCaloriesText = ""
    @State private var goalProteinText = ""
    @State private var goalCarbsText = ""
    @State private var goalFatText = ""
    @State private var goalWaterText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                todaySummary
                inputCard
                targetCard
                recentNutrition
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .onAppear {
            seedGoalFieldsIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nutrition")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("Track today's macros and water.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
    }

    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Spacer()

                if let todayNutrition {
                    Text("\(todayNutrition.calories) cal")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(Theme.accentLight)
                }
            }

            if let todayNutrition {
                HStack(spacing: 8) {
                    ProfileMiniMetric(value: "\(todayNutrition.protein)g", label: "Protein")
                    ProfileMiniMetric(value: "\(todayNutrition.carbs)g", label: "Carbs")
                    ProfileMiniMetric(value: "\(todayNutrition.fat)g", label: "Fat")
                    ProfileMiniMetric(value: "\(todayNutrition.water)", label: "Water")
                }
            } else {
                Text("No nutrition logged today.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            }

            if let todayNutrition {
                VStack(spacing: 10) {
                    MetricProgressBar(label: "Calories", value: Double(todayNutrition.calories), target: Double(store.appData.nutritionGoals.calories), suffix: "")
                    MetricProgressBar(label: "Protein", value: Double(todayNutrition.protein), target: Double(store.appData.nutritionGoals.protein), suffix: "g")
                    MetricProgressBar(label: "Carbs", value: Double(todayNutrition.carbs), target: Double(store.appData.nutritionGoals.carbs), suffix: "g")
                    MetricProgressBar(label: "Fat", value: Double(todayNutrition.fat), target: Double(store.appData.nutritionGoals.fat), suffix: "g")
                    MetricProgressBar(label: "Water", value: Double(todayNutrition.water), target: Double(store.appData.nutritionGoals.water), suffix: "")
                }
            }
        }
        .cardStyle()
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log Nutrition")
                .font(.headline)
                .foregroundStyle(Theme.text)

            HStack(spacing: 10) {
                profileInput("Calories", text: $caloriesText, keyboard: .numberPad)
                profileInput("Protein", text: $proteinText, keyboard: .numberPad)
            }
            HStack(spacing: 10) {
                profileInput("Carbs", text: $carbsText, keyboard: .numberPad)
                profileInput("Fat", text: $fatText, keyboard: .numberPad)
                profileInput("Water", text: $waterText, keyboard: .numberPad)
            }

            Button("Save Today's Nutrition") {
                store.setTodayNutrition(
                    calories: Int(caloriesText) ?? todayNutrition?.calories ?? 0,
                    protein: Int(proteinText) ?? todayNutrition?.protein ?? 0,
                    carbs: Int(carbsText) ?? todayNutrition?.carbs ?? 0,
                    fat: Int(fatText) ?? todayNutrition?.fat ?? 0,
                    water: Int(waterText) ?? todayNutrition?.water ?? 0
                )
                caloriesText = ""
                proteinText = ""
                carbsText = ""
                fatText = ""
                waterText = ""
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .cardStyle()
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Targets")
                .font(.headline)
                .foregroundStyle(Theme.text)

            HStack(spacing: 10) {
                profileInput("Calories", text: $goalCaloriesText, keyboard: .numberPad)
                profileInput("Protein", text: $goalProteinText, keyboard: .numberPad)
            }
            HStack(spacing: 10) {
                profileInput("Carbs", text: $goalCarbsText, keyboard: .numberPad)
                profileInput("Fat", text: $goalFatText, keyboard: .numberPad)
                profileInput("Water", text: $goalWaterText, keyboard: .numberPad)
            }

            Button("Save Targets") {
                store.setNutritionGoals(
                    NutritionGoals(
                        calories: Int(goalCaloriesText) ?? store.appData.nutritionGoals.calories,
                        protein: Int(goalProteinText) ?? store.appData.nutritionGoals.protein,
                        carbs: Int(goalCarbsText) ?? store.appData.nutritionGoals.carbs,
                        fat: Int(goalFatText) ?? store.appData.nutritionGoals.fat,
                        water: Int(goalWaterText) ?? store.appData.nutritionGoals.water
                    )
                )
                seedGoalFields(force: true)
            }
            .buttonStyle(GhostButtonStyle())
        }
        .cardStyle()
    }

    private var recentNutrition: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.headline)
                .foregroundStyle(Theme.text)

            if store.appData.nutritionLog.isEmpty {
                Text("Nutrition history will show here.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .cardStyle()
            } else {
                ForEach(store.appData.nutritionLog.sorted(by: { $0.date > $1.date }).prefix(7)) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(formatBodyWeightDate(entry.date))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.text)
                            Text("P \(entry.protein)g · C \(entry.carbs)g · F \(entry.fat)g · Water \(entry.water)")
                                .font(.caption)
                                .foregroundStyle(Theme.textDim)
                        }
                        Spacer()
                        Text("\(entry.calories)")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(Theme.accentLight)
                    }
                    .padding(10)
                    .background(Theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private var todayNutrition: NutritionEntry? {
        store.appData.nutritionLog.first { $0.date == todayKey() }
    }

    private func seedGoalFieldsIfNeeded() {
        guard goalCaloriesText.isEmpty,
              goalProteinText.isEmpty,
              goalCarbsText.isEmpty,
              goalFatText.isEmpty,
              goalWaterText.isEmpty else {
            return
        }
        seedGoalFields(force: true)
    }

    private func seedGoalFields(force: Bool = false) {
        if force || goalCaloriesText.isEmpty { goalCaloriesText = "\(store.appData.nutritionGoals.calories)" }
        if force || goalProteinText.isEmpty { goalProteinText = "\(store.appData.nutritionGoals.protein)" }
        if force || goalCarbsText.isEmpty { goalCarbsText = "\(store.appData.nutritionGoals.carbs)" }
        if force || goalFatText.isEmpty { goalFatText = "\(store.appData.nutritionGoals.fat)" }
        if force || goalWaterText.isEmpty { goalWaterText = "\(store.appData.nutritionGoals.water)" }
    }
}

struct MaxTrackerView: View {
    @Environment(AppStore.self) private var store
    @State private var maxName = ""
    @State private var maxWeightText = ""
    @State private var maxRepsText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                inputCard
                trackerList
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Max Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Max Tracker")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("Track top sets for your lifts.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Max")
                .font(.headline)
                .foregroundStyle(Theme.text)

            HStack(spacing: 10) {
                profileInput("Lift", text: $maxName)
                profileInput("Weight", text: $maxWeightText, keyboard: .decimalPad)
                profileInput("Reps", text: $maxRepsText, keyboard: .numberPad)
            }

            Button("Save Max") {
                if let weight = Double(maxWeightText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    store.addMaxRecord(name: maxName, weight: weight, reps: Int(maxRepsText) ?? 1)
                    maxName = ""
                    maxWeightText = ""
                    maxRepsText = ""
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .cardStyle()
    }

    private var trackerList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tracked Lifts")
                .font(.headline)
                .foregroundStyle(Theme.text)

            if store.appData.maxTrackers.isEmpty {
                Text("No lifts tracked yet.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .cardStyle()
            } else {
                ForEach(store.appData.maxTrackers) { tracker in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(tracker.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.text)

                                Text(latestMaxText(tracker))
                                    .font(.caption)
                                    .foregroundStyle(Theme.textDim)
                            }

                            Spacer()

                            Button {
                                store.deleteMaxTracker(id: tracker.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .foregroundStyle(.red.opacity(0.8))
                        }

                        let values = tracker.records.sorted { $0.date < $1.date }.map { estimatedOneRepMax(weight: $0.weight, reps: $0.reps) }
                        if values.count >= 2 {
                            MiniLineChart(values: values)
                                .frame(height: 70)
                                .padding(10)
                                .background(Theme.inputBg.opacity(0.65))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(10)
                    .background(Theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private func latestMaxText(_ tracker: MaxTracker) -> String {
        guard let latest = tracker.records.sorted(by: { $0.date > $1.date }).first else {
            return "No records"
        }

        let e1rm = estimatedOneRepMax(weight: latest.weight, reps: latest.reps)
        return "\(formatWeight(latest.weight)) \(store.appData.unit) x \(latest.reps) · e1RM \(formatWeight(e1rm))"
    }
}

struct AllWorkoutHistoryView: View {
    let logs: [WorkoutLog]
    let unit: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(logs) { log in
                    NavigationLink {
                        WorkoutLogDetailView(log: log)
                    } label: {
                        WorkoutLogRow(log: log, unit: unit)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("All Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }
}

private struct BodyWeightTrend: View {
    let entries: [BodyWeightEntry]

    var body: some View {
        GeometryReader { proxy in
            let points = trendPoints(size: proxy.size)

            ZStack(alignment: .bottomLeading) {
                Path { path in
                    guard let first = points.first else {
                        return
                    }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(Theme.accentLight, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(Theme.accentLight)
                        .frame(width: 7, height: 7)
                        .position(point)
                }
            }
        }
    }

    private func trendPoints(size: CGSize) -> [CGPoint] {
        let weights = entries.map(\.weight)
        guard let minWeight = weights.min(), let maxWeight = weights.max(), entries.count > 1 else {
            return []
        }

        let range = max(1, maxWeight - minWeight)
        return entries.enumerated().map { index, entry in
            let x = size.width * CGFloat(index) / CGFloat(max(1, entries.count - 1))
            let normalized = (entry.weight - minWeight) / range
            let y = size.height - (size.height * CGFloat(normalized))
            return CGPoint(x: x, y: y)
        }
    }
}

struct WorkoutLogDetailView: View {
    @Environment(AppStore.self) private var store
    let log: WorkoutLog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("Logged Exercises")
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    ForEach(Array(log.exercises.enumerated()), id: \.offset) { _, exercise in
                        LoggedExerciseCard(
                            exercise: exercise,
                            name: exerciseName(for: exercise.exerciseId),
                            unit: store.appData.unit
                        )
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(log.dayName)
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(log.programName)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.3)
                    .foregroundStyle(Theme.accentLight)

                Text(log.dayName)
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .foregroundStyle(Theme.text)

                Text(formatDate(log.date))
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            }

            HStack(spacing: 10) {
                HistoryMetricTile(value: formatDuration(log.durationSec), label: "Time")
                HistoryMetricTile(value: "\(completedSetCount(log))", label: "Sets")
                HistoryMetricTile(value: formatVolume(log.totalVolume), label: "Vol \(store.appData.unit)")
            }
        }
        .cardStyle()
    }

    private func exerciseName(for exerciseId: String) -> String {
        let allExercises = store.catalog.exercises + store.appData.customExercises
        return allExercises.first(where: { $0.id == exerciseId })?.name ?? exerciseId
    }
}

private struct WorkoutLogRow: View {
    let log: WorkoutLog
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.dayName)
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    Text("\(log.programName) · \(formatDate(log.date))")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textFaint)
            }

            HStack(spacing: 10) {
                chip(systemImage: "timer", text: formatDuration(log.durationSec))
                chip(systemImage: "list.bullet", text: "\(completedSetCount(log)) sets")
                chip(systemImage: "chart.line.uptrend.xyaxis", text: "\(formatVolume(log.totalVolume)) \(unit)")
            }
        }
        .cardStyle()
    }

    private func chip(systemImage: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Theme.textDim)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Theme.surface2)
        .clipShape(Capsule())
    }
}

private struct LoggedExerciseCard: View {
    let exercise: LoggedExercise
    let name: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name)
                .font(.headline)
                .foregroundStyle(Theme.text)

            if exercise.sets.isEmpty {
                Text("No completed sets were saved for this exercise.")
                    .font(.caption)
                    .foregroundStyle(Theme.textFaint)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.text)

                            Spacer()

                            Text("\(formatWeight(set.weight)) \(unit) x \(set.reps)")
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .foregroundStyle(Theme.accentLight)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)

                        if index < exercise.sets.count - 1 {
                            Divider()
                                .overlay(.white.opacity(0.08))
                        }
                    }
                }
                .background(Theme.inputBg.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .cardStyle()
    }
}

private struct HistoryMetricTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.bold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.1)
                .foregroundStyle(Theme.accentLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface2.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private func completedSetCount(_ log: WorkoutLog) -> Int {
    log.exercises.reduce(0) { total, exercise in
        total + exercise.sets.count
    }
}

private func computeProfileStreak(logs: [WorkoutLog]) -> Int {
    guard !logs.isEmpty else {
        return 0
    }

    let days = Set(logs.compactMap { localDayKey($0.date) })
    var cursor = Calendar.current.startOfDay(for: Date())

    if !days.contains(dayKey(cursor)) {
        cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
    }

    var streak = 0
    while days.contains(dayKey(cursor)) {
        streak += 1
        cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
    }

    return streak
}

private func localDayKey(_ value: String) -> String? {
    parseDate(value).map(dayKey)
}

private func dayKey(_ date: Date) -> String {
    DayKeyFormatter.shared.string(from: date)
}

private func logDate(_ log: WorkoutLog) -> Date {
    parseDate(log.date) ?? .distantPast
}

private func parseDate(_ value: String) -> Date? {
    if let date = ISO8601DateFormatter().date(from: value) {
        return date
    }

    return SelfDateFormatter.shared.date(from: value)
}

private func formatDate(_ value: String) -> String {
    guard let date = parseDate(value) else {
        return value
    }

    return DisplayDateFormatter.shared.string(from: date)
}

private func formatDuration(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainder = seconds % 60
    return "\(minutes)m \(remainder)s"
}

private func formatVolume(_ volume: Double) -> String {
    if volume.rounded() == volume {
        return "\(Int(volume))"
    }

    return String(format: "%.1f", volume)
}

private func formatWeight(_ weight: Double) -> String {
    if weight.rounded() == weight {
        return "\(Int(weight))"
    }

    return String(format: "%.1f", weight)
}

private func estimatedOneRepMax(weight: Double, reps: Int) -> Double {
    guard reps > 1 else {
        return weight
    }

    return weight * (1 + Double(reps) / 30)
}

private func formatBodyWeightDate(_ value: String) -> String {
    if let date = BodyWeightDateFormatter.input.date(from: value) {
        return BodyWeightDateFormatter.output.string(from: date)
    }

    return value
}

private func todayKey() -> String {
    BodyWeightDateFormatter.input.string(from: Date())
}

private enum DisplayDateFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private enum DayKeyFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private enum BodyWeightDateFormatter {
    static let input: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let output: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

private enum SelfDateFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
