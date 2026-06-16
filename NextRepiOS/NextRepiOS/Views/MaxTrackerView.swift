import SwiftUI
import Charts

struct MaxTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = AppStore()
    @State private var selectedTracker: MaxTracker?
    @State private var showingDetail: Bool = false
    @State private var showingNewForm: Bool = false
    @State private var newTrackerName: String = ""
    @State private var searchText: String = ""
    
    private var filteredTrackers: [MaxTracker] {
        if searchText.isEmpty {
            return store.appData.maxTrackers
        } else {
            return store.appData.maxTrackers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(Theme.text)
                            Text("Profile")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.text)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { showingNewForm = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(Theme.accent)
                    }
                }
                .padding()
                .background(Theme.surface)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title + subtitle
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Personal records")
                                .font(Theme.body(12))
                                .foregroundColor(Theme.textDim)
                            
                            Text("Max Tracker")
                                .font(Theme.display(28))
                                .foregroundColor(Theme.text)
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // New tracker form
                        if showingNewForm {
                            newTrackerForm
                        }
                        
                        // Search bar
                        if !store.appData.maxTrackers.isEmpty {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Theme.textDim)
                                
                                TextField("Search lifts", text: $searchText)
                                    .font(Theme.body(14))
                                    .foregroundColor(Theme.text)
                            }
                            .padding(12)
                            .background(Theme.surface2)
                            .cornerRadius(12)
                        }
                        
                        // Trackers list
                        if filteredTrackers.isEmpty {
                            Text("No max trackers yet")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.placeholder)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 80)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(filteredTrackers) { tracker in
                                    trackerCard(tracker: tracker)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationDestination(isPresented: $showingDetail) {
            if let tracker = selectedTracker {
                MaxTrackerDetailView(tracker: tracker)
            }
        }
        .task {
            await store.loadAppData()
        }
    }
    
    private var newTrackerForm: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Exercise name", text: $newTrackerName)
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
            }
            .padding(12)
            .background(Theme.surface2)
            .cornerRadius(12)
            
            HStack(spacing: 12) {
                Button(action: { showingNewForm = false }) {
                    Text("Cancel")
                        .font(Theme.body(14))
                        .foregroundColor(Theme.textDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.surface2)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    if !newTrackerName.trimmingCharacters(in: .whitespaces).isEmpty {
                        Task {
                            await store.addMaxTracker(name: newTrackerName.trimmingCharacters(in: .whitespaces))
                            newTrackerName = ""
                            showingNewForm = false
                        }
                    }
                }) {
                    Text("Save")
                        .font(Theme.body(14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(newTrackerName.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.surface2 : Theme.accent)
                        .cornerRadius(12)
                }
                .disabled(newTrackerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(12)
    }
    
    private func trackerCard(tracker: MaxTracker) -> some View {
        Button(action: {
            selectedTracker = tracker
            showingDetail = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tracker.name)
                        .font(Theme.body(14))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.text)
                    
                    if let latest = tracker.latestRecord {
                        Text("\(Int(latest.weight)) \(store.appData.unit) × \(latest.reps)")
                            .font(Theme.body(10))
                            .foregroundColor(Theme.textDim)
                    } else {
                        Text("No records yet")
                            .font(Theme.body(10))
                            .foregroundColor(Theme.placeholder)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textDim)
            }
            .padding(12)
            .background(Theme.surface)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Max Tracker Detail View

struct MaxTrackerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let tracker: MaxTracker
    @StateObject private var store = AppStore()
    @State private var newWeight: String = ""
    @State private var newReps: String = "1"
    @State private var showingLogForm: Bool = false
    @State private var deleteRecordId: String? = nil
    @State private var deleteConfirm: Bool = false
    @State private var shouldDismiss: Bool = false
    
    private var sortedRecords: [MaxRecord] {
        tracker.records.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(Theme.text)
                            Text("Max Tracker")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.text)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Theme.surface)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Lift name + best
                        VStack(alignment: .leading, spacing: 8) {
                            Text(tracker.name)
                                .font(Theme.display(28))
                                .foregroundColor(Theme.text)
                                .tracking(1)
                            
                            Text("Best: \(Int(tracker.bestWeight)) \(store.appData.unit)")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Trend chart
                        if tracker.records.count >= 2 {
                            trendChart
                        } else if tracker.records.count == 1 {
                            Text("Log more records to see trends")
                                .font(Theme.body(12))
                                .foregroundColor(Theme.placeholder)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            Text("No records yet")
                                .font(Theme.body(12))
                                .foregroundColor(Theme.placeholder)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                        
                        // Log a max card
                        if showingLogForm {
                            logMaxForm
                        } else {
                            Button(action: { showingLogForm = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Theme.accent)
                                    
                                    Text("Log a max")
                                        .font(Theme.body(14))
                                        .foregroundColor(Theme.text)
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(Theme.surface)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // History list
                        if sortedRecords.isEmpty {
                            Text("No history yet")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.placeholder)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("History")
                                    .font(Theme.body(12))
                                    .foregroundColor(Theme.textDim)
                                
                                VStack(spacing: 8) {
                                    ForEach(sortedRecords) { record in
                                        historyRow(record: record)
                                    }
                                }
                            }
                        }
                        
                        // Delete tracker card
                        if deleteConfirm {
                            deleteConfirmation
                        } else {
                            Button(action: { deleteConfirm = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                    
                                    Text("Delete tracker")
                                        .font(Theme.body(14))
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .onChange(of: shouldDismiss) { _ in
            if shouldDismiss {
                dismiss()
            }
        }
        .task {
            await store.loadAppData()
        }
    }
    
    private var trendChart: some View {
        let sortedByDate = tracker.records.sorted { $0.date < $1.date }
        
        return VStack(alignment: .leading, spacing: 12) {
            Chart(sortedByDate) { record in
                LineMark(
                    x: .value("Date", record.date),
                    y: .value("Weight", record.weight)
                )
                .foregroundStyle(Theme.accent)
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", record.date),
                    y: .value("Weight", record.weight)
                )
                .foregroundStyle(Theme.accent)
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisValueLabel()
                        .font(Theme.body(10))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .font(Theme.body(10))
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(12)
    }
    
    private var logMaxForm: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Text("Weight")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
                
                HStack {
                    TextField("0", text: $newWeight)
                        .font(Theme.body(14))
                        .foregroundColor(Theme.text)
                        .keyboardType(.decimalPad)
                        .frame(maxWidth: .infinity)
                    
                    Text(store.appData.unit)
                        .font(Theme.body(14))
                        .foregroundColor(Theme.textDim)
                }
                .padding(12)
                .background(Theme.surface2)
                .cornerRadius(12)
            }
            
            VStack(spacing: 8) {
                Text("Reps")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
                
                TextField("1", text: $newReps)
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(Theme.surface2)
                    .cornerRadius(12)
            }
            
            HStack(spacing: 12) {
                Button(action: { showingLogForm = false }) {
                    Text("Cancel")
                        .font(Theme.body(14))
                        .foregroundColor(Theme.textDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.surface2)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    if let weight = Double(newWeight), weight >= 0,
                       let reps = Int(newReps), reps > 0 {
                        Task {
                            await store.addMaxRecord(trackerId: tracker.id, weight: weight, reps: reps)
                            newWeight = ""
                            newReps = "1"
                            showingLogForm = false
                        }
                    }
                }) {
                    Text("Save")
                        .font(Theme.body(14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(canSave ? Theme.accent : Theme.surface2)
                        .cornerRadius(12)
                }
                .disabled(!canSave)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(12)
    }
    
    private var canSave: Bool {
        guard let weight = Double(newWeight), weight >= 0 else { return false }
        guard let reps = Int(newReps), reps > 0 else { return false }
        return true
    }
    
    private func historyRow(record: MaxRecord) -> some View {
        let isDeleting = deleteRecordId == record.id
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(record.date))
                    .font(Theme.body(12))
                    .foregroundColor(Theme.textDim)
                
                Text("\(Int(record.weight)) × \(record.reps)")
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
            }
            
            Spacer()
            
            if isDeleting {
                HStack(spacing: 8) {
                    Button(action: {
                        Task {
                            await store.deleteMaxRecord(trackerId: tracker.id, recordId: record.id)
                            deleteRecordId = nil
                        }
                    }) {
                        Text("Confirm")
                            .font(Theme.body(12))
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        deleteRecordId = nil
                    }) {
                        Text("Cancel")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.textDim)
                    }
                }
            } else {
                Button(action: {
                    deleteRecordId = record.id
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(Theme.surface)
        .cornerRadius(12)
    }
    
    private var deleteConfirmation: some View {
        HStack(spacing: 12) {
            Button(action: { deleteConfirm = false }) {
                Text("Cancel")
                    .font(Theme.body(14))
                    .foregroundColor(Theme.textDim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.surface2)
                    .cornerRadius(12)
            }
            
            Button(action: {
                Task {
                    await store.deleteMaxTracker(id: tracker.id)
                    shouldDismiss = true
                }
            }) {
                Text("Delete")
                    .font(Theme.body(14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.red)
                    .cornerRadius(12)
            }
        }
    }
}