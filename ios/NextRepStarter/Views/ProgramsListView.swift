import SwiftUI

struct ProgramsListView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                searchField

                if filteredPrograms.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPrograms) { program in
                            ProgramCard(program: program, isActive: program.id == store.appData.activeProgramId)
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
                Button {
                    Task { await store.reload() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .tint(Theme.accentLight)
            }

            ToolbarItem(placement: .topBarLeading) {
                Button("Log Out") {
                    store.logout()
                }
                .font(.footnote.weight(.semibold))
                .tint(Theme.textDim)
            }
        }
        .screenBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Programs")
                .font(.system(size: 34, weight: .bold, design: .condensed))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("\(filteredPrograms.count) available")
                .font(.caption)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Theme.accentLight)
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

            Text("Try a different search, or verify that /api/catalog is reachable.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var filteredPrograms: [Program] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return store.allPrograms
        }

        return store.allPrograms.filter { program in
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
}

struct ProgramCard: View {
    let program: Program
    let isActive: Bool

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
                        .font(.system(.title2, design: .condensed, weight: .bold))
                        .foregroundStyle(Theme.text)
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(accent)
                }
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
