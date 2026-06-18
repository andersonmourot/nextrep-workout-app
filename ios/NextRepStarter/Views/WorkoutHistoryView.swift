import Foundation
import PhotosUI
import SwiftUI
import UIKit

struct WorkoutHistoryView: View {
    @Environment(AppStore.self) private var store
    @State private var weightText = ""
    @State private var pendingDeleteLog: WorkoutLog?

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .tint(Theme.accentLight)
            }
        }
        .screenBackground()
        .alert("Delete Workout?", isPresented: Binding(
            get: { pendingDeleteLog != nil },
            set: { if !$0 { pendingDeleteLog = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDeleteLog = nil }
            Button("Delete", role: .destructive) {
                if let pendingDeleteLog {
                    store.deleteWorkoutLog(id: pendingDeleteLog.id)
                }
                pendingDeleteLog = nil
            }
        } message: {
            Text("This removes the workout from your synced history.")
        }
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

                if !sortedBodyWeight.isEmpty {
                    NavigationLink {
                        BodyWeightHistoryView(unit: store.appData.unit)
                    } label: {
                        Text("View all")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.accentLight)
                    }
                }
            }

            HStack {
                Spacer()

                if let latest = sortedBodyWeight.last {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(formatWeight(latest.weight)) \(store.appData.unit)")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(Theme.accentLight)

                        if let delta = bodyWeightDeltaText {
                            Text(delta)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(bodyWeightDeltaColor)
                        }
                    }
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

    private var bodyWeightDeltaText: String? {
        guard let first = sortedBodyWeight.first,
              let latest = sortedBodyWeight.last,
              sortedBodyWeight.count >= 2 else {
            return nil
        }
        let delta = latest.weight - first.weight
        if delta == 0 {
            return "No change since start"
        }
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(formatWeight(delta)) \(store.appData.unit) since start"
    }

    private var bodyWeightDeltaColor: Color {
        guard let first = sortedBodyWeight.first,
              let latest = sortedBodyWeight.last else {
            return Theme.textFaint
        }
        if latest.weight < first.weight {
            return .green.opacity(0.9)
        }
        if latest.weight > first.weight {
            return Theme.accentLight
        }
        return Theme.textFaint
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
                        AllWorkoutHistoryView(unit: store.appData.unit)
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
                            WorkoutLogRow(log: log, unit: store.appData.unit) {
                                pendingDeleteLog = log
                            }
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
    @State private var selectedDate = Date()
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
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                datePickerCard
                todaySummary
                inputCard
                photoCard
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
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task { await loadNutritionPhotos(newItems) }
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

    private var datePickerCard: some View {
        HStack {
            DatePicker("Date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.compact)
                .foregroundStyle(Theme.text)
                .tint(Theme.accentLight)

            Spacer()

            Button("Today") {
                selectedDate = Date()
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Theme.accentLight)
        }
        .cardStyle()
    }

    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDateKey == todayKey() ? "Today" : formatBodyWeightDate(selectedDateKey))
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Spacer()

                if let selectedNutrition {
                    Text("\(selectedNutrition.calories) cal")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(Theme.accentLight)
                }
            }

            if let selectedNutrition {
                HStack(spacing: 18) {
                    ProgressRing(
                        value: nutritionProgress(current: selectedNutrition.calories, target: store.appData.nutritionGoals.calories),
                        size: 118,
                        lineWidth: 11,
                        color: Theme.accentLight,
                        center: "\(selectedNutrition.calories)",
                        caption: "kcal"
                    )

                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(max(0, store.appData.nutritionGoals.calories - selectedNutrition.calories)) kcal left")
                            .font(.headline)
                            .foregroundStyle(Theme.text)
                        Text("Goal \(store.appData.nutritionGoals.calories) kcal")
                            .font(.caption)
                            .foregroundStyle(Theme.textDim)

                        HStack(spacing: 6) {
                            ProfileMiniMetric(value: "\(selectedNutrition.protein)g", label: "Protein")
                            ProfileMiniMetric(value: "\(selectedNutrition.carbs)g", label: "Carbs")
                            ProfileMiniMetric(value: "\(selectedNutrition.fat)g", label: "Fat")
                        }
                    }
                }
            } else {
                Text("No nutrition logged for this day.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            }

            if let selectedNutrition {
                VStack(spacing: 10) {
                    MetricProgressBar(label: "Calories", value: Double(selectedNutrition.calories), target: Double(store.appData.nutritionGoals.calories), suffix: "")
                    MetricProgressBar(label: "Protein", value: Double(selectedNutrition.protein), target: Double(store.appData.nutritionGoals.protein), suffix: "g")
                    MetricProgressBar(label: "Carbs", value: Double(selectedNutrition.carbs), target: Double(store.appData.nutritionGoals.carbs), suffix: "g")
                    MetricProgressBar(label: "Fat", value: Double(selectedNutrition.fat), target: Double(store.appData.nutritionGoals.fat), suffix: "g")
                    MetricProgressBar(label: "Water", value: Double(selectedNutrition.water), target: Double(store.appData.nutritionGoals.water), suffix: "")
                }

                waterButtons(current: selectedNutrition.water)
            } else {
                waterButtons(current: 0)
            }
        }
        .cardStyle()
    }

    private func waterButtons(current: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Water")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textDim)

            HStack(spacing: 8) {
                ForEach(0..<max(store.appData.nutritionGoals.water, max(current, 1)), id: \.self) { index in
                    Button {
                        let next = current == index + 1 ? index : index + 1
                        saveNutrition(
                            calories: selectedNutrition?.calories ?? 0,
                            protein: selectedNutrition?.protein ?? 0,
                            carbs: selectedNutrition?.carbs ?? 0,
                            fat: selectedNutrition?.fat ?? 0,
                            water: next
                        )
                    } label: {
                        Image(systemName: "drop.fill")
                            .font(.caption)
                            .foregroundStyle(index < current ? .white : Theme.textFaint)
                            .frame(width: 28, height: 28)
                            .background(index < current ? Theme.accent : Theme.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add Nutrition")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                Text("Use Add fields for quick logging, or Save Nutrition to set exact values.")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }

            NutritionAddField(label: "Add calories", unit: "kcal") { value in
                adjustNutrition(calories: value)
            }

            VStack(spacing: 12) {
                NutritionMacroAddRow(
                    label: "Protein",
                    value: selectedNutrition?.protein ?? 0,
                    goal: store.appData.nutritionGoals.protein,
                    color: Color(hex: "#3B82F6")
                ) { value in
                    adjustNutrition(protein: value)
                }

                NutritionMacroAddRow(
                    label: "Carbs",
                    value: selectedNutrition?.carbs ?? 0,
                    goal: store.appData.nutritionGoals.carbs,
                    color: Color(hex: "#F97316")
                ) { value in
                    adjustNutrition(carbs: value)
                }

                NutritionMacroAddRow(
                    label: "Fat",
                    value: selectedNutrition?.fat ?? 0,
                    goal: store.appData.nutritionGoals.fat,
                    color: Color(hex: "#A855F7")
                ) { value in
                    adjustNutrition(fat: value)
                }
            }

            Divider().overlay(.white.opacity(0.08))

            Text("Set exact values")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textDim)

            HStack(spacing: 10) {
                profileInput("Calories", text: $caloriesText, keyboard: .numberPad)
                profileInput("Protein", text: $proteinText, keyboard: .numberPad)
            }
            HStack(spacing: 10) {
                profileInput("Carbs", text: $carbsText, keyboard: .numberPad)
                profileInput("Fat", text: $fatText, keyboard: .numberPad)
                profileInput("Water", text: $waterText, keyboard: .numberPad)
            }

            Button("Save Nutrition") {
                saveNutrition(
                    calories: Int(caloriesText) ?? selectedNutrition?.calories ?? 0,
                    protein: Int(proteinText) ?? selectedNutrition?.protein ?? 0,
                    carbs: Int(carbsText) ?? selectedNutrition?.carbs ?? 0,
                    fat: Int(fatText) ?? selectedNutrition?.fat ?? 0,
                    water: Int(waterText) ?? selectedNutrition?.water ?? 0
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

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Photos", systemImage: "photo")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Spacer()

                Text("\(selectedPhotos.count) / 3")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.textDim)
            }

            Text("Add up to 3 photos for this day.")
                .font(.caption)
                .foregroundStyle(Theme.textDim)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, photo in
                    ZStack(alignment: .topTrailing) {
                        nutritionImage(photo)
                            .frame(height: 92)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(.white.opacity(0.08), lineWidth: 1)
                            }

                        Button {
                            var next = selectedPhotos
                            next.remove(at: index)
                            store.setNutritionPhotos(date: selectedDateKey, photos: next)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(.black.opacity(0.65))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(5)
                    }
                }

                if selectedPhotos.count < 3 {
                    PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 3 - selectedPhotos.count, matching: .images) {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title3.weight(.semibold))
                            Text("Add photo")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Theme.accentLight)
                        .frame(height: 92)
                        .frame(maxWidth: .infinity)
                        .background(Theme.inputBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                                .foregroundStyle(.white.opacity(0.14))
                        }
                    }
                }
            }
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
                    Button {
                        if let date = BodyWeightDateFormatter.input.date(from: entry.date) {
                            selectedDate = date
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(formatBodyWeightDate(entry.date))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.text)
                                Text("P \(entry.protein)g · C \(entry.carbs)g · F \(entry.fat)g · Water \(entry.water)\(photoCountText(entry))")
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
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var selectedNutrition: NutritionEntry? {
        store.appData.nutritionLog.first { $0.date == selectedDateKey }
    }

    private var selectedPhotos: [String] {
        selectedNutrition?.photos ?? []
    }

    private var selectedDateKey: String {
        BodyWeightDateFormatter.input.string(from: selectedDate)
    }

    private func nutritionProgress(current: Int, target: Int) -> Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, Double(current) / Double(target)))
    }

    private func photoCountText(_ entry: NutritionEntry) -> String {
        guard let count = entry.photos?.count, count > 0 else { return "" }
        return " · \(count) photo\(count == 1 ? "" : "s")"
    }

    private func saveNutrition(calories: Int, protein: Int, carbs: Int, fat: Int, water: Int) {
        store.setNutritionEntry(
            date: selectedDateKey,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            water: water
        )
    }

    private func adjustNutrition(calories: Int = 0, protein: Int = 0, carbs: Int = 0, fat: Int = 0, water: Int = 0) {
        let current = selectedNutrition
        saveNutrition(
            calories: max(0, (current?.calories ?? 0) + calories),
            protein: max(0, (current?.protein ?? 0) + protein),
            carbs: max(0, (current?.carbs ?? 0) + carbs),
            fat: max(0, (current?.fat ?? 0) + fat),
            water: max(0, (current?.water ?? 0) + water)
        )
    }

    private func loadNutritionPhotos(_ items: [PhotosPickerItem]) async {
        var next = selectedPhotos
        for item in items.prefix(max(0, 3 - next.count)) {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let dataURL = nutritionCompressedDataURL(from: image) else {
                continue
            }
            next.append(dataURL)
        }
        store.setNutritionPhotos(date: selectedDateKey, photos: Array(next.prefix(3)))
        selectedPhotoItems = []
    }

    private func nutritionCompressedDataURL(from image: UIImage) -> String? {
        let maxDimension: CGFloat = 1080
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: max(1, size.width * scale), height: max(1, size.height * scale))
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        guard let data = resized.jpegData(compressionQuality: 0.6) else { return nil }
        return "data:image/jpeg;base64,\(data.base64EncodedString())"
    }

    private func nutritionUIImage(from dataURL: String) -> UIImage? {
        let base64 = dataURL.components(separatedBy: ",").last ?? dataURL
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }

    @ViewBuilder
    private func nutritionImage(_ dataURL: String) -> some View {
        if let image = nutritionUIImage(from: dataURL) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Theme.surface2
                Image(systemName: "photo")
                    .foregroundStyle(Theme.textFaint)
            }
        }
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

private struct NutritionAddField: View {
    let label: String
    let unit: String
    let onAdd: (Int) -> Void
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("\(label) (\(unit))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textDim)

            HStack(spacing: 10) {
                profileInput("0", text: $text, keyboard: .numberPad)

                Button {
                    submit()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func submit() {
        let value = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        guard value != 0 else { return }
        onAdd(value)
        text = ""
    }
}

private struct NutritionMacroAddRow: View {
    let label: String
    let value: Int
    let goal: Int
    let color: Color
    let onAdd: (Int) -> Void
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textDim)
                Spacer()
                Text("\(value) / \(goal)g")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.text)
            }

            MetricProgressBar(label: label, value: Double(value), target: Double(goal), suffix: "g", color: color)

            HStack(spacing: 10) {
                profileInput("0", text: $text, keyboard: .numberPad)

                Button {
                    submit()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func submit() {
        let amount = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        guard amount != 0 else { return }
        onAdd(amount)
        text = ""
    }
}

struct MaxTrackerView: View {
    @Environment(AppStore.self) private var store
    @State private var maxName = ""
    @State private var maxWeightText = ""
    @State private var maxRepsText = ""
    @State private var searchQuery = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                inputCard
                searchField
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

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textFaint)

            TextField("Search lifts", text: $searchQuery)
                .foregroundStyle(Theme.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.inputBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
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
            } else if filteredTrackers.isEmpty {
                Text("No lifts match \"\(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines))\".")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .cardStyle()
            } else {
                ForEach(filteredTrackers) { tracker in
                    NavigationLink {
                        MaxTrackerDetailView(trackerId: tracker.id)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(tracker.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.text)

                                Text(latestMaxText(tracker))
                                    .font(.caption)
                                    .foregroundStyle(Theme.textDim)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if let latest = tracker.records.sorted(by: { $0.date > $1.date }).first {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(formatWeight(latest.weight))")
                                        .font(.subheadline.monospacedDigit().weight(.bold))
                                        .foregroundStyle(Theme.text)
                                    Text(store.appData.unit)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(Theme.textFaint)
                                }
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.textFaint)
                        }
                        .padding(10)
                        .background(Theme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var filteredTrackers: [MaxTracker] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = store.appData.maxTrackers.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        guard !trimmed.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    private func latestMaxText(_ tracker: MaxTracker) -> String {
        guard let latest = tracker.records.sorted(by: { $0.date > $1.date }).first else {
            return "No records"
        }

        let e1rm = estimatedOneRepMax(weight: latest.weight, reps: latest.reps)
        return "\(formatWeight(latest.weight)) \(store.appData.unit) x \(latest.reps) · e1RM \(formatWeight(e1rm))"
    }
}

struct MaxTrackerDetailView: View {
    @Environment(AppStore.self) private var store
    @State private var weightText = ""
    @State private var repsText = ""
    @State private var pendingDeleteRecord: MaxRecord?
    @State private var showingDeleteTrackerConfirm = false
    let trackerId: String

    private var tracker: MaxTracker? {
        store.appData.maxTrackers.first { $0.id == trackerId }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let tracker {
                    header(tracker)
                    trend(tracker)
                    addRecord(tracker)
                    history(tracker)
                } else {
                    Text("Tracker not found.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                        .cardStyle()
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(tracker?.name ?? "Max")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .alert("Delete Record?", isPresented: Binding(
            get: { pendingDeleteRecord != nil },
            set: { if !$0 { pendingDeleteRecord = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDeleteRecord = nil }
            Button("Delete", role: .destructive) {
                if let pendingDeleteRecord {
                    store.deleteMaxRecord(trackerId: trackerId, recordId: pendingDeleteRecord.id)
                }
                pendingDeleteRecord = nil
            }
        } message: {
            Text("This removes the max record from your synced data.")
        }
        .alert("Delete Tracker?", isPresented: $showingDeleteTrackerConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deleteMaxTracker(id: trackerId)
            }
        } message: {
            Text("This deletes the tracker and all of its records.")
        }
    }

    private func header(_ tracker: MaxTracker) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Max Tracker")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .foregroundStyle(Theme.accentLight)

                Text(tracker.name)
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundStyle(Theme.text)
            }

            HStack(spacing: 8) {
                MaxMetricTile(label: "Best", value: bestWeightText(tracker))
                MaxMetricTile(label: "Latest", value: latestWeightText(tracker))
                MaxMetricTile(label: "e1RM", value: bestE1RMText(tracker))
            }

            Button(role: .destructive) {
                showingDeleteTrackerConfirm = true
            } label: {
                Label("Delete Tracker", systemImage: "trash")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.red.opacity(0.9))
        }
        .cardStyle()
    }

    private func bestWeightText(_ tracker: MaxTracker) -> String {
        guard let best = tracker.records.max(by: { $0.weight < $1.weight }) else {
            return "-"
        }
        return "\(formatWeight(best.weight)) \(store.appData.unit)"
    }

    private func latestWeightText(_ tracker: MaxTracker) -> String {
        guard let latest = tracker.records.sorted(by: { $0.date > $1.date }).first else {
            return "-"
        }
        return "\(formatWeight(latest.weight)) x \(latest.reps)"
    }

    private func bestE1RMText(_ tracker: MaxTracker) -> String {
        guard let best = tracker.records
            .map({ estimatedOneRepMax(weight: $0.weight, reps: $0.reps) })
            .max() else {
            return "-"
        }
        return "\(formatWeight(best)) \(store.appData.unit)"
    }

    private func trendDeltaText(_ records: [MaxRecord]) -> String? {
        let sorted = records.sorted { $0.date < $1.date }
        guard let first = sorted.first, let last = sorted.last, sorted.count >= 2 else {
            return nil
        }
        let delta = last.weight - first.weight
        if delta == 0 {
            return "No change across logged entries"
        }
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(formatWeight(delta)) \(store.appData.unit) from first to latest"
    }

    private func dateRangeText(_ records: [MaxRecord]) -> String? {
        let sorted = records.sorted { $0.date < $1.date }
        guard let first = sorted.first, let last = sorted.last, first.date != last.date else {
            return nil
        }
        return "\(formatBodyWeightDate(first.date)) - \(formatBodyWeightDate(last.date))"
    }

    private func recordE1RMText(_ record: MaxRecord) -> String {
        "e1RM \(formatWeight(estimatedOneRepMax(weight: record.weight, reps: record.reps))) \(store.appData.unit)"
    }

    private struct MaxMetricTile: View {
        let label: String
        let value: String

        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(label)
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.textFaint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Theme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func trend(_ tracker: MaxTracker) -> some View {
        let sorted = tracker.records.sorted { $0.date < $1.date }
        let values = sorted.map(\.weight)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Trend")
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    if let range = dateRangeText(sorted) {
                        Text(range)
                            .font(.caption)
                            .foregroundStyle(Theme.textFaint)
                    }
                }

                Spacer()

                if let delta = trendDeltaText(sorted) {
                    Text(delta)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.accentLight)
                        .multilineTextAlignment(.trailing)
                }
            }

            if values.count >= 2 {
                MiniLineChart(values: values)
                    .frame(height: 120)
                    .padding(12)
                    .background(Theme.inputBg.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                HStack {
                    Text("\(formatWeight(values.first ?? 0))")
                    Spacer()
                    Text("\(formatWeight(values.last ?? 0)) \(store.appData.unit)")
                }
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            } else {
                Text(values.isEmpty ? "Log a max to start a trend line." : "Log one more max to see your trend.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            }
        }
        .cardStyle()
    }

    private func addRecord(_ tracker: MaxTracker) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log a Max")
                .font(.headline)
                .foregroundStyle(Theme.text)

            HStack(spacing: 10) {
                profileInput("Weight", text: $weightText, keyboard: .decimalPad)
                profileInput("Reps", text: $repsText, keyboard: .numberPad)
            }

            Button("Add Entry") {
                if let weight = Double(weightText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    store.addMaxRecordToTracker(trackerId: tracker.id, weight: weight, reps: Int(repsText) ?? 1)
                    weightText = ""
                    repsText = ""
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .cardStyle()
    }

    private func history(_ tracker: MaxTracker) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)
                .foregroundStyle(Theme.text)

            if tracker.records.isEmpty {
                Text("No entries yet.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .cardStyle()
            } else {
                ForEach(tracker.records.sorted { $0.date > $1.date }) { record in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(formatBodyWeightDate(record.date))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.textDim)

                            Text(recordE1RMText(record))
                                .font(.caption)
                                .foregroundStyle(Theme.textFaint)
                        }

                        Spacer()

                        Text("\(formatWeight(record.weight)) \(store.appData.unit) x \(record.reps)")
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(Theme.text)

                        Button {
                            pendingDeleteRecord = record
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
}

struct AllWorkoutHistoryView: View {
    @Environment(AppStore.self) private var store
    @State private var pendingDeleteLog: WorkoutLog?
    let unit: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(logs.prefix(20))) { log in
                    NavigationLink {
                        WorkoutLogDetailView(log: log)
                    } label: {
                        WorkoutLogRow(log: log, unit: unit) {
                            pendingDeleteLog = log
                        }
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
        .alert("Delete Workout?", isPresented: Binding(
            get: { pendingDeleteLog != nil },
            set: { if !$0 { pendingDeleteLog = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDeleteLog = nil }
            Button("Delete", role: .destructive) {
                if let pendingDeleteLog {
                    store.deleteWorkoutLog(id: pendingDeleteLog.id)
                }
                pendingDeleteLog = nil
            }
        } message: {
            Text("This removes the workout from your synced history.")
        }
    }

    private var logs: [WorkoutLog] {
        store.appData.logs.sorted { lhs, rhs in
            logDate(lhs) > logDate(rhs)
        }
    }
}

struct BodyWeightHistoryView: View {
    @Environment(AppStore.self) private var store
    let unit: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if entries.isEmpty {
                    Text("No weight entries yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                        .cardStyle()
                } else {
                    ForEach(entries) { entry in
                        HStack {
                            Text(formatBodyWeightDate(entry.date))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.text)

                            Spacer()

                            Text("\(formatWeight(entry.weight)) \(unit)")
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .foregroundStyle(Theme.text)

                            Button {
                                store.deleteBodyWeight(id: entry.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .foregroundStyle(.red.opacity(0.8))
                        }
                        .cardStyle()
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Body Weight")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var entries: [BodyWeightEntry] {
        store.appData.bodyWeight.sorted { $0.date > $1.date }
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
    var onDelete: (() -> Void)? = nil

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

                if let onDelete {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                    .foregroundStyle(.red.opacity(0.8))
                    .buttonStyle(.plain)
                }

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
