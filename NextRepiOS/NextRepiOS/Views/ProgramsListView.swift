import SwiftUI

struct ProgramsListView: View {
    @StateObject private var store = AppStore()
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    @State private var showingProgramEditor = false
    @State private var selectedProgram: Program?
    @State private var showingProgramHistory: Bool = false
    
    private let categories = ["All", "Bodybuilding", "Strength", "HIIT", "Powerlifting", "Functional", "Bodyweight"]
    
    var body: some View {
        ScreenWrapper {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Search field
                    searchField
                    
                    // Category filter chips
                    categoryChips
                    
                    // Program cards
                    programCards
                }
                .padding(.bottom, 100)
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedProgram != nil },
                set: { if !$0 { selectedProgram = nil } }
            )) {
                if let program = selectedProgram {
                    ProgramDetailView(program: program)
                }
            }
            .navigationDestination(isPresented: $showingProgramHistory) {
                ProgramHistoryView()
            }
            .sheet(isPresented: $showingProgramEditor) {
                // TODO: Implement Program editor
                Text("Program Editor (stub)")
                    .font(Theme.body(16))
                    .foregroundColor(Theme.text)
                    .padding()
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
        HStack {
            Text("Programs")
                .font(Theme.display(28))
                .foregroundColor(Theme.text)
                .tracking(1)
            
            Spacer()
            
            Button(action: {
                showingProgramHistory = true
            }) {
                Image(systemName: "clock")
                    .font(.title2)
                    .foregroundColor(Theme.textDim)
                    .frame(width: 36, height: 36)
                    .background(Theme.surface2)
                    .clipShape(Circle())
            }
            
            Button(action: {
                showingProgramEditor = true
            }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(Theme.accent)
                    .frame(width: 36, height: 36)
                    .background(Theme.surface2)
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Search Field
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textDim)
            
            TextField("Search", text: $searchText)
                .font(Theme.body(14))
                .foregroundColor(Theme.text)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(Theme.inputBg)
        .cornerRadius(12)
    }
    
    // MARK: - Category Chips
    
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category)
                            .font(Theme.body(11))
                            .fontWeight(.medium)
                            .foregroundColor(selectedCategory == category ? .white : Theme.textDim)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == category ? Theme.accent : Theme.surface2)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 40)
    }
    
    // MARK: - Program Cards
    
    private var programCards: some View {
        let filteredPrograms = filterAndSortPrograms()
        
        return Group {
            if filteredPrograms.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredPrograms) { program in
                        programCard(program)
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .foregroundColor(Theme.textDim)
                .font(.title)
            
            Text("No programs found")
                .font(Theme.body(14))
                .foregroundColor(Theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Theme.surface)
        .cornerRadius(16)
    }
    
    private func programCard(_ program: Program) -> some View {
        let isActive = store.appData.activeProgramId == program.id
        let isFavorite = store.appData.favoriteProgramIds.contains(program.id)
        let isCustom = store.appData.customPrograms.contains { $0.id == program.id }
        let accentColor = Color(hex: UInt(Int(accentColor(for: program).dropFirst(2), radix: 16) ?? 0x355E3B))
        
        return Button(action: {
            selectedProgram = program
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Top row with eyebrow and badges
                HStack {
                    Text("\(program.category) · \(program.level)")
                        .font(Theme.body(11))
                        .foregroundColor(accentColor.opacity(0.8))
                        .tracking(2)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        if isCustom {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(Theme.textDim)
                        }
                        
                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Theme.accent)
                        }
                        
                        if isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(Theme.accent)
                        }
                    }
                }
                
                // Title
                Text(program.name)
                    .font(Theme.display(20))
                    .foregroundColor(Theme.text)
                    .tracking(1)
                
                // Summary
                if let summary = program.summary {
                    Text(summary)
                        .font(Theme.body(14))
                        .foregroundColor(Theme.textDim)
                        .lineLimit(2)
                }
                
                // Meta row
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                    
                    Text("\(program.durationWeeks) weeks")
                        .font(Theme.body(12))
                        .foregroundColor(Theme.textDim)
                    
                    Spacer()
                    
                    Image(systemName: "dumbbell")
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                    
                    Text("\(program.daysPerWeek) days/week")
                        .font(Theme.body(12))
                        .foregroundColor(Theme.textDim)
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        accentColor.opacity(0.15),
                        Theme.surface
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Filtering and Sorting
    
    private func filterAndSortPrograms() -> [Program] {
        var programs = store.mergedPrograms()
        
        // Filter by category
        if selectedCategory != "All" {
            programs = programs.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let lowerSearch = searchText.lowercased()
            programs = programs.filter { program in
                let searchableText = [
                    program.name,
                    program.summary ?? "",
                    program.coach,
                    program.category,
                    program.level,
                    "\(program.daysPerWeek) day(s)"
                ].joined(separator: " ").lowercased()
                
                return searchableText.contains(lowerSearch)
            }
        }
        
        // Sort: active first, then favorites in order, then the rest
        let activeId = store.appData.activeProgramId
        let favoriteIds = store.appData.favoriteProgramIds
        
        programs.sort { p1, p2 in
            let p1Active = p1.id == activeId
            let p2Active = p2.id == activeId
            
            if p1Active != p2Active {
                return p1Active // Active programs come first
            }
            
            let p1FavoriteIndex = favoriteIds.firstIndex(of: p1.id)
            let p2FavoriteIndex = favoriteIds.firstIndex(of: p2.id)
            
            if p1FavoriteIndex != nil && p2FavoriteIndex == nil {
                return true // Favorite programs come before non-favorites
            }
            
            if p1FavoriteIndex != nil && p2FavoriteIndex != nil {
                return p1FavoriteIndex! < p2FavoriteIndex! // Maintain favorite order
            }
            
            return false
        }
        
        return programs
    }
    
    // MARK: - Helpers
    
    private func accentColor(for program: Program) -> String {
        return program.accent ?? "#355E3B"
    }
}

#Preview {
    ProgramsListView()
        .background(Theme.bg)
}