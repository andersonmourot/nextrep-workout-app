import SwiftUI

struct ProgramsView: View {
    @State private var catalog: Catalog?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedProgram: Program?
    
    var filteredPrograms: [Program] {
        if searchText.isEmpty {
            return catalog?.programs ?? []
        } else {
            return catalog?.programs.filter { program in
                program.name.localizedCaseInsensitiveContains(searchText) ||
                (program.coach?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (program.category?.localizedCaseInsensitiveContains(searchText) ?? false)
            } ?? []
        }
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .padding()
            } else if let error = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                    Text("Error")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        loadAppData()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if let programs = catalog?.programs, programs.isEmpty {
                VStack {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                    Text("No Programs")
                        .font(.headline)
                    Text("You don't have any programs yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(filteredPrograms) { program in
                        Button(action: {
                            selectedProgram = program
                        }) {
                            ProgramRowView(program: program)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .searchable(text: $searchText, prompt: "Search programs...")
            }
        }
        .background(Theme.bg)
        .navigationTitle("Programs")
        .navigationDestination(item: $selectedProgram) { program in
            ProgramDetailView(program: program)
        }
        .onAppear {
            loadAppData()
        }
    }
    
    private func loadAppData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let catalogData = try await APIClient.shared.getCatalog()
                await MainActor.run {
                    self.catalog = catalogData
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct ProgramRowView: View {
    let program: Program
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(program.name)
                    .font(.headline)
                Spacer()
                if let level = program.level {
                    Text(level)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .cornerRadius(8)
                }
            }
            
            if let coach = program.coach {
                Text(coach)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                if let durationWeeks = program.durationWeeks {
                    Label("\(durationWeeks) weeks", systemImage: "calendar")
                }
                Spacer()
                if let daysPerWeek = program.daysPerWeek {
                    Label("\(daysPerWeek) days/week", systemImage: "figure.strengthtraining.traditional")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            if let category = program.category {
                Text(category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .foregroundStyle(.secondary)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}