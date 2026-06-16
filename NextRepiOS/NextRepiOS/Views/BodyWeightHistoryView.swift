import SwiftUI

struct BodyWeightHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = AppStore()
    
    private var bodyWeightEntries: [BodyWeightEntry] {
        store.appData.bodyWeightEntries.sorted { $0.date > $1.date }
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
                            Text("Progress")
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
                        // Title + subtitle
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Body Weight History")
                                .font(Theme.display(28))
                                .foregroundColor(Theme.text)
                                .tracking(1)
                            
                            Text("Every logged entry, newest first.")
                                .font(Theme.body(12))
                                .foregroundColor(Theme.textDim)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Body weight list
                        if bodyWeightEntries.isEmpty {
                            Text("No weight entries yet")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.placeholder)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 80)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(bodyWeightEntries) { entry in
                                    bodyWeightRow(entry: entry)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await store.loadAppData()
        }
    }
    
    private func bodyWeightRow(entry: BodyWeightEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(entry.date))
                    .font(Theme.body(14))
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
}