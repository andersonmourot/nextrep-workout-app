import SwiftUI

struct ProgramsListView: View {
    @Binding var isAuthenticated: Bool
    @State private var appData: AppData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    
    var filteredPrograms: [Program] {
        if searchText.isEmpty {
            return appData?.customPrograms ?? []
        } else {
            return appData?.customPrograms.filter { program in
                program.name.localizedCaseInsensitiveContains(searchText) ||
                program.coach.localizedCaseInsensitiveContains(searchText) ||
                program.category.localizedCaseInsensitiveContains(searchText)
            } ?? []
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading programs...")
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
                } else if let programs = appData?.customPrograms, programs.isEmpty {
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
                            ProgramRowView(program: program)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search programs...")
                }
            }
            .navigationTitle("Programs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        logout()
                    }
                }
            }
            .onAppear {
                loadAppData()
            }
        }
    }
    
    private func loadAppData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let data = try await APIClient.shared.getAppData()
                await MainActor.run {
                    self.appData = data
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
    
    private func logout() {
        APIClient.shared.logout()
        isAuthenticated = false
    }
}

#Preview {
    ProgramsListView(isAuthenticated: .constant(true))
}

struct ProgramRowView: View {
    let program: Program
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(program.name)
                    .font(.headline)
                Spacer()
                Text(program.level)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .cornerRadius(8)
            }
            
            Text(program.coach)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Label("\(program.durationWeeks) weeks", systemImage: "calendar")
                Spacer()
                Label("\(program.daysPerWeek) days/week", systemImage: "figure.strengthtraining.traditional")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Text(program.category)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .foregroundStyle(.secondary)
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProgramsListView()
}
