import SwiftUI

struct NutritionView: View {
    @StateObject private var store = AppStore()
    @State private var selectedDate: Date = Date()
    @State private var showingHistory: Bool = false
    @State private var showingGoalsEditor: Bool = false
    @State private var addCaloriesValue: String = ""
    @State private var addProteinValue: String = ""
    @State private var addCarbsValue: String = ""
    @State private var addFatValue: String = ""
    @State private var goalsSavedMessage: String = ""
    
    // Draft goals
    @State private var draftCalories: String = ""
    @State private var draftProtein: String = ""
    @State private var draftCarbs: String = ""
    @State private var draftFat: String = ""
    @State private var draftWater: String = ""
    
    // Photos
    @State private var showingImagePicker: Bool = false
    @State private var selectedImageIndex: Int = 0
    @State private var selectedImages: [UIImage] = []
    
    private var currentEntry: NutritionEntry {
        store.getNutritionEntry(for: localDateKey(selectedDate))
    }
    
    private var goals: NutritionGoals {
        store.appData.nutritionGoals
    }
    
    private var historyDates: [String] {
        store.appData.nutritionLog.keys.sorted().reversed()
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily fuel")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.accent)
                            .tracking(2)
                        
                        Text("Nutrition")
                            .font(Theme.display(32))
                            .foregroundColor(Theme.text)
                            .tracking(1)
                        
                        Text("Log your daily calories, macros, and hydration.")
                            .font(Theme.body(14))
                            .foregroundColor(Theme.textDim)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Date picker
                    VStack(alignment: .leading, spacing: 12) {
                        DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                            .onChange(of: selectedDate) { _ in
                                addCaloriesValue = ""
                                addProteinValue = ""
                                addCarbsValue = ""
                                addFatValue = ""
                            }
                        
                        Button(action: { showingHistory.toggle() }) {
                            HStack {
                                Text("History")
                                    .font(Theme.body(14))
                                    .foregroundColor(Theme.text)
                                
                                Spacer()
                                
                                Image(systemName: showingHistory ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(Theme.textDim)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if showingHistory {
                            VStack(spacing: 8) {
                                ForEach(historyDates, id: \.self) { date in
                                    Button(action: {
                                        selectedDate = parseStoredDate(date)
                                    }) {
                                        HStack {
                                            Text(formatDate(date))
                                                .font(Theme.body(12))
                                                .foregroundColor(Theme.text)
                                            
                                            Spacer()
                                            
                                            if let entry = store.appData.nutritionLog[date] {
                                                Text("\(entry.calories) kcal · \(entry.protein)/\(entry.carbs)/\(entry.fat)g · \(entry.water) 💧")
                                                    .font(Theme.body(10))
                                                    .foregroundColor(Theme.textDim)
                                            }
                                        }
                                        .padding(8)
                                        .background(localDateKey(selectedDate) == date ? Theme.accent.opacity(0.2) : Theme.surface)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
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
                    
                    // Calories card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Calories")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.textDim)
                            .tracking(2)
                        
                        HStack(spacing: 20) {
                            // Ring
                            ZStack {
                                Circle()
                                    .stroke(Theme.surface2, lineWidth: 12)
                                    .frame(width: 100, height: 100)
                                
                                let progress = Double(currentEntry.calories) / Double(goals.calories)
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 100, height: 100)
                                
                                VStack(spacing: 2) {
                                    Text("\(currentEntry.calories)")
                                        .font(Theme.display(20))
                                        .foregroundColor(Theme.text)
                                    
                                    Text("of \(goals.calories)")
                                        .font(Theme.body(10))
                                        .foregroundColor(Theme.textDim)
                                }
                            }
                            
                            Spacer()
                            
                            // Add field
                            VStack(alignment: .trailing, spacing: 8) {
                                TextField("Add calories", text: $addCaloriesValue)
                                    .keyboardType(.numberPad)
                                    .font(Theme.body(14))
                                    .foregroundColor(Theme.text)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(12)
                                    .background(Theme.inputBg)
                                    .cornerRadius(12)
                                    .frame(width: 120)
                                
                                Button(action: {
                                    if let value = Int(addCaloriesValue), value > 0 {
                                        Task {
                                            var newEntry = currentEntry
                                            newEntry.calories = max(0, currentEntry.calories + value)
                                            try? await store.setNutritionEntry(newEntry)
                                            addCaloriesValue = ""
                                        }
                                    }
                                }) {
                                    Text("Add")
                                        .font(Theme.body(12))
                                        .foregroundColor(.white)
                                        .frame(width: 120)
                                        .padding(8)
                                        .background(Theme.accent)
                                        .cornerRadius(8)
                                }
                                .disabled(addCaloriesValue.isEmpty)
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
                    
                    // Macros card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Macros")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.textDim)
                            .tracking(2)
                        
                        macroRow(label: "Protein", value: currentEntry.protein, goal: goals.protein, addValue: $addProteinValue, unit: "g")
                        macroRow(label: "Carbs", value: currentEntry.carbs, goal: goals.carbs, addValue: $addCarbsValue, unit: "g")
                        macroRow(label: "Fat", value: currentEntry.fat, goal: goals.fat, addValue: $addFatValue, unit: "g")
                    }
                    .padding(16)
                    .background(Theme.surface)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    
                    // Water card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Water")
                                .font(Theme.body(12))
                                .foregroundColor(Theme.textDim)
                                .tracking(2)
                            
                            Spacer()
                            
                            Text("\(currentEntry.water) / \(goals.water) glasses")
                                .font(Theme.body(12))
                                .foregroundColor(Theme.textDim)
                        }
                        
                        let glassCount = max(goals.water, currentEntry.water)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(8, glassCount)), spacing: 8) {
                            ForEach(0..<glassCount, id: \.self) { index in
                                Button(action: {
                                    Task {
                                        var newEntry = currentEntry
                                        if currentEntry.water == index + 1 {
                                            newEntry.water = index
                                        } else {
                                            newEntry.water = index + 1
                                        }
                                        try? await store.setNutritionEntry(newEntry)
                                    }
                                }) {
                                    Image(systemName: index < currentEntry.water ? "drop.fill" : "drop")
                                        .font(.title3)
                                        .foregroundColor(index < currentEntry.water ? Theme.accent : Theme.textDim)
                                        .frame(width: 40, height: 40)
                                        .background(Theme.surface2)
                                        .cornerRadius(8)
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
                    
                    // Goals editor
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: {
                            draftCalories = String(goals.calories)
                            draftProtein = String(goals.protein)
                            draftCarbs = String(goals.carbs)
                            draftFat = String(goals.fat)
                            draftWater = String(goals.water)
                            showingGoalsEditor.toggle()
                        }) {
                            HStack {
                                Text("Goals")
                                    .font(Theme.body(12))
                                    .foregroundColor(Theme.textDim)
                                    .tracking(2)
                                
                                Spacer()
                                
                                Image(systemName: showingGoalsEditor ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(Theme.textDim)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if showingGoalsEditor {
                            VStack(spacing: 12) {
                                goalField(label: "Calories", value: $draftCalories)
                                goalField(label: "Protein (g)", value: $draftProtein)
                                goalField(label: "Carbs (g)", value: $draftCarbs)
                                goalField(label: "Fat (g)", value: $draftFat)
                                goalField(label: "Water (glasses)", value: $draftWater)
                                
                                if !goalsSavedMessage.isEmpty {
                                    Text(goalsSavedMessage)
                                        .font(Theme.body(12))
                                        .foregroundColor(Theme.accent)
                                }
                                
                                Button(action: {
                                    Task {
                                        if let cal = Int(draftCalories),
                                           let pro = Int(draftProtein),
                                           let car = Int(draftCarbs),
                                           let fat = Int(draftFat),
                                           let wat = Int(draftWater) {
                                            let newGoals = NutritionGoals(calories: cal, protein: pro, carbs: car, fat: fat, water: wat)
                                            try? await store.setNutritionGoals(newGoals)
                                            goalsSavedMessage = "Saved"
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                goalsSavedMessage = ""
                                            }
                                        }
                                    }
                                }) {
                                    Text("Save Goals")
                                        .font(Theme.body(14))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(12)
                                        .background(Theme.accent)
                                        .cornerRadius(12)
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
                    
                    // Day photos
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Day Photos")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.textDim)
                            .tracking(2)
                        
                        HStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { index in
                                if index < currentEntry.photos.count {
                                    // Photo placeholder (would need to decode base64)
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.surface2)
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(Theme.textDim)
                                        )
                                } else {
                                    Button(action: {
                                        selectedImageIndex = index
                                        showingImagePicker = true
                                    }) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.textDim.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                            .frame(width: 80, height: 80)
                                            .overlay(
                                                Image(systemName: "plus")
                                                    .foregroundColor(Theme.textDim)
                                            )
                                    }
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
                .padding()
            }
        }
        .task {
            await store.loadAppData()
        }
    }
    
    private func macroRow(label: String, value: Int, goal: Int, addValue: Binding<String>, unit: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
                
                Text("\(value) / \(goal)\(unit)")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
            }
            
            Spacer()
            
            TextField("Add", text: addValue)
                .keyboardType(.numberPad)
                .font(Theme.body(12))
                .foregroundColor(Theme.text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(8)
                .background(Theme.inputBg)
                .cornerRadius(8)
                .frame(width: 60)
            
            Button(action: {
                if let val = Int(addValue.wrappedValue), val > 0 {
                    Task {
                        var newEntry = currentEntry
                        switch label {
                        case "Protein":
                            newEntry.protein = max(0, currentEntry.protein + val)
                        case "Carbs":
                            newEntry.carbs = max(0, currentEntry.carbs + val)
                        case "Fat":
                            newEntry.fat = max(0, currentEntry.fat + val)
                        default:
                            break
                        }
                        try? await store.setNutritionEntry(newEntry)
                        addValue.wrappedValue = ""
                    }
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(Theme.accent)
            }
            .disabled(addValue.wrappedValue.isEmpty)
        }
    }
    
    private func goalField(label: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.body(12))
                .foregroundColor(Theme.textDim)
            
            TextField("", text: value)
                .keyboardType(.numberPad)
                .font(Theme.body(14))
                .foregroundColor(Theme.text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(Theme.inputBg)
                .cornerRadius(12)
        }
    }
}