import SwiftUI

struct ProgramsListView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""
    @State private var selectedCategory = "All"
    @State private var isManaging = false
    @State private var showingHiddenPrograms = false
    @State private var showingTrash = false
    @State private var pendingManageProgram: Program?

    private let categories = ["All", "Bodybuilding", "Strength", "HIIT", "Powerlifting", "Functional", "Bodyweight"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if showingHiddenPrograms {
                    hiddenProgramsContent
                } else if showingTrash {
                    trashedProgramsContent
                } else {
                    header
                    searchField
                    categoryFilters
                    recoveryShortcuts

                    if orderedPrograms.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(orderedPrograms) { program in
                                ProgramListRow(
                                    program: program,
                                    isActive: program.id == store.appData.activeProgramId,
                                    isCustom: store.isCustomProgram(program),
                                    isFavorite: store.appData.favoriteProgramIds.contains(program.id),
                                    isManaging: isManaging,
                                    onManage: {
                                        pendingManageProgram = program
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 13) {
                    NavigationLink {
                        ProgramEditorView()
                    } label: {
                        Image(systemName: "plus")
                    }

                    NavigationLink {
                        ExerciseLibraryView()
                    } label: {
                        Image(systemName: "figure.strengthtraining.traditional")
                    }

                    NavigationLink {
                        CompletedProgramHistoryView()
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }

                    if !store.appData.hiddenProgramIds.isEmpty {
                        Button {
                            showingHiddenPrograms = true
                            isManaging = true
                        } label: {
                            Image(systemName: "eye")
                        }
                    }

                    if !store.appData.trashedPrograms.isEmpty {
                        Button {
                            showingTrash = true
                            isManaging = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }

                    Button {
                        isManaging.toggle()
                        pendingManageProgram = nil
                        if !isManaging {
                            showingHiddenPrograms = false
                            showingTrash = false
                        }
                    } label: {
                        Image(systemName: isManaging ? "checkmark" : "slider.horizontal.3")
                    }
                }
                .tint(Theme.accentLight)
            }
        }
        .screenBackground()
        .alert("Manage Program", isPresented: Binding(
            get: { pendingManageProgram != nil },
            set: { if !$0 { pendingManageProgram = nil } }
        )) {
            if let program = pendingManageProgram {
                if store.isCustomProgram(program) {
                    Button("Move to Trash", role: .destructive) {
                        store.deleteCustomProgram(id: program.id)
                        pendingManageProgram = nil
                    }
                } else {
                    Button("Hide Program", role: .destructive) {
                        store.hideProgram(id: program.id)
                        pendingManageProgram = nil
                    }
                }
                Button("Cancel", role: .cancel) { pendingManageProgram = nil }
            }
        } message: {
            if let program = pendingManageProgram {
                Text(store.isCustomProgram(program) ? "Move \(program.name) to Trash? You can restore it later from Programs." : "Hide \(program.name)? You can restore hidden defaults from Programs.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Programs")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("\(orderedPrograms.count) available")
                .font(.caption)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Theme.accentLight)
        }
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(selectedCategory == category ? .white : Theme.textDim)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Theme.accent : Theme.inputBg)
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(.white.opacity(selectedCategory == category ? 0 : 0.08), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    @ViewBuilder
    private var recoveryShortcuts: some View {
        if !store.appData.hiddenProgramIds.isEmpty || !store.appData.trashedPrograms.isEmpty {
            HStack(spacing: 10) {
                if !store.appData.hiddenProgramIds.isEmpty {
                    Button {
                        showingHiddenPrograms = true
                        isManaging = true
                    } label: {
                        Label("Hidden (\(store.appData.hiddenProgramIds.count))", systemImage: "eye")
                    }
                    .buttonStyle(GhostButtonStyle())
                }

                if !store.appData.trashedPrograms.isEmpty {
                    Button {
                        showingTrash = true
                        isManaging = true
                    } label: {
                        Label("Trash (\(store.appData.trashedPrograms.count))", systemImage: "trash")
                    }
                    .buttonStyle(GhostButtonStyle())
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textFaint)

            TextField("Search programs", text: $query)
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

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No programs found")
                .font(.headline)
                .foregroundStyle(Theme.text)

            Text(emptyMessage)
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var filteredPrograms: [Program] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let categoryFiltered: [Program]
        if selectedCategory == "All" {
            categoryFiltered = store.allPrograms
        } else {
            categoryFiltered = store.allPrograms.filter { program in
                program.category == selectedCategory
            }
        }

        guard !trimmed.isEmpty else {
            return categoryFiltered
        }

        return categoryFiltered.filter { program in
            let haystack = [
                program.name,
                program.summary,
                program.coach,
                program.category,
                program.level,
                "\(program.daysPerWeek) day",
                "\(program.daysPerWeek) days"
            ]
            .joined(separator: " ")
            .localizedCaseInsensitiveContains(trimmed)

            return haystack
        }
    }

    private var orderedPrograms: [Program] {
        filteredPrograms.sorted { lhs, rhs in
            let lhsRank = programRank(lhs)
            let rhsRank = programRank(rhs)
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }

            let lhsCustom = store.isCustomProgram(lhs)
            let rhsCustom = store.isCustomProgram(rhs)
            if lhsCustom != rhsCustom {
                return lhsCustom
            }

            let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            if nameComparison != .orderedSame {
                return nameComparison == .orderedAscending
            }

            return lhs.id < rhs.id
        }
    }

    private var hiddenPrograms: [Program] {
        store.catalog.programs
            .filter { store.appData.hiddenProgramIds.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var sortedTrashedPrograms: [TrashedProgram] {
        store.appData.trashedPrograms.sorted { lhs, rhs in
            lhs.deletedAt > rhs.deletedAt
        }
    }

    private var emptyMessage: String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return "No programs match \"\(trimmed)\"."
        }
        if selectedCategory != "All" {
            return "No \(selectedCategory) programs are currently visible."
        }
        return "No programs are currently visible."
    }

    private func programRank(_ program: Program) -> Int {
        if program.id == store.appData.activeProgramId {
            return 0
        }
        if let favoriteIndex = store.appData.favoriteProgramIds.firstIndex(of: program.id) {
            return 1 + favoriteIndex
        }
        return 100
    }

    private var hiddenProgramsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                showingHiddenPrograms = false
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.textDim)

            VStack(alignment: .leading, spacing: 6) {
                Text("Hidden Programs")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.text)
                Text("Restore defaults to return them to your main list.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            }

            if hiddenPrograms.isEmpty {
                Text("No hidden programs.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                ForEach(hiddenPrograms) { program in
                    HiddenProgramRow(program: program) {
                        store.restoreHiddenProgram(id: program.id)
                    }
                }

                Button {
                    store.restoreHiddenPrograms()
                } label: {
                    Label("Restore All", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
    }

    private var trashedProgramsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                showingTrash = false
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.textDim)

            VStack(alignment: .leading, spacing: 6) {
                Text("Trash")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.text)
                Text("Restore deleted custom programs or delete them permanently.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
            }

            if sortedTrashedPrograms.isEmpty {
                Text("No deleted custom programs.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                ForEach(sortedTrashedPrograms) { trashed in
                    TrashedProgramRow(
                        trashed: trashed,
                        onRestore: {
                            store.restoreTrashedProgram(id: trashed.program.id)
                        },
                        onPurge: {
                            store.purgeTrashedProgram(id: trashed.program.id)
                        }
                    )
                }
            }
        }
    }
}

private struct ProgramListRow: View {
    let program: Program
    let isActive: Bool
    let isCustom: Bool
    let isFavorite: Bool
    let isManaging: Bool
    let onManage: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink {
                ProgramDetailView(program: program)
            } label: {
                ProgramCard(program: program, isActive: isActive, isCustom: isCustom, isFavorite: isFavorite)
            }
            .buttonStyle(.plain)

            if isManaging {
                Button {
                    onManage()
                } label: {
                    Image(systemName: isCustom ? "trash" : "eye.slash")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isCustom ? .red.opacity(0.9) : Theme.accentLight)
                        .frame(width: 34, height: 34)
                        .background(Theme.inputBg.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(10)
            }
        }
    }
}

struct ProgramCard: View {
    let program: Program
    let isActive: Bool
    var isCustom: Bool = false
    var isFavorite: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(program.category) · \(program.level)")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1.3)
                        .foregroundStyle(accent)

                    Text(program.name)
                        .font(.system(.title2, design: .default, weight: .bold))
                        .foregroundStyle(Theme.text)
                }

                Spacer()

                if isCustom {
                    statusIcon("pencil")
                }

                if isActive {
                    statusIcon("checkmark.circle.fill")
                }

                if isFavorite {
                    statusIcon("star.fill")
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textFaint)
            }

            Text(program.summary)
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                meta(systemImage: "calendar", text: "\(program.durationWeeks) weeks")
                meta(systemImage: "dumbbell", text: "\(program.daysPerWeek) days/week")
                Spacer()
            }
        }
        .padding(16)
        .background {
            LinearGradient(
                colors: [accent.opacity(0.18), Theme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        }
    }

    private var accent: Color {
        Color(hex: program.accent)
    }

    private func statusIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.caption.weight(.bold))
            .foregroundStyle(accent)
            .padding(5)
            .background(accent.opacity(0.16))
            .clipShape(Circle())
    }

    private func meta(systemImage: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Theme.textDim)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.surface2)
        .clipShape(Capsule())
    }
}

private struct HiddenProgramRow: View {
    let program: Program
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(program.name)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                Text("\(program.category) · \(program.level) · \(program.durationWeeks) weeks")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }

            Spacer()

            Button {
                onRestore()
            } label: {
                Label("Restore", systemImage: "arrow.counterclockwise")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Theme.accentLight)
        }
        .cardStyle()
    }
}

private struct TrashedProgramRow: View {
    let trashed: TrashedProgram
    let onRestore: () -> Void
    let onPurge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(trashed.program.name)
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    Text("\(trashed.program.category) · \(trashed.program.level)")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    onRestore()
                } label: {
                    Label("Restore", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(GhostButtonStyle())

                Button(role: .destructive) {
                    onPurge()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
        .cardStyle()
    }
}
