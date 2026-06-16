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
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.textDim)
                TextField("Search programs...", text: $searchText)
                    .foregroundColor(Theme.text)
            }
            .padding()
            .background(Theme.surface2)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Programs list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(filteredPrograms) { program in
                        Button(action: {
                            selectedProgram = program
                        }) {
                            ProgramCardStyled(program: program)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Programs")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedProgram) { program in
            ProgramDetailView(program: program)
        }
        .onAppear {
            loadAppData()
        }
        .screenBackground()
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

struct ProgramCardStyled: View {
    let program: Program
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Eyebrow: category · level
            HStack(spacing: 4) {
                if let category = program.category {
                    Text(category.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.accent)
                }
                if let category = program.category, program.level != nil {
                    Text("·")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textDim)
                }
                if let level = program.level {
                    Text(level)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accent.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            // Title
            Text(program.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.text)
            
            // Meta info
            VStack(alignment: .leading, spacing: 4) {
                if let coach = program.coach {
                    Text("Coach \(coach)")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textDim)
                }
                
                HStack(spacing: 16) {
                    if let durationWeeks = program.durationWeeks {
                        Label("\(durationWeeks) weeks", systemImage: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textDim)
                    }
                    if let daysPerWeek = program.daysPerWeek {
                        Label("\(daysPerWeek) days/week", systemImage: "figure.strengthtraining.traditional")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textDim)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
        .overlay(
            LinearGradient(
                gradient: Gradient(colors: [
                    Theme.accent.opacity(0.12),
                    Color.clear
                ]),
                startPoint: UnitPoint(x: 0.0, y: 0.0),
                endPoint: UnitPoint(x: cos(150 * .pi / 180), y: sin(150 * .pi / 180))
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}