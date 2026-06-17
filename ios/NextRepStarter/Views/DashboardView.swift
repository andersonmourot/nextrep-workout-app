import Foundation
import SwiftUI

struct DashboardView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                todayCard
                statsGrid
                recentActivity
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting())
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Theme.accentLight)

            Text(store.user?.name ?? store.appData.name)
                .font(.system(size: 38, weight: .bold, design: .default))
                .foregroundStyle(Theme.text)
        }
    }

    private var todayCard: some View {
        Group {
            if let program = activeProgram {
                activeProgramCard(program: program)
            } else {
                noActiveProgramCard
            }
        }
    }

    private func activeProgramCard(program: Program) -> some View {
        let run = domainProgramRun(
            program: program,
            logs: store.appData.logs,
            since: store.appData.programAnchors[program.id]
        )
        let day = nextDay(for: program)
        let accent = Color(hex: program.accent)

        return VStack(alignment: .leading, spacing: 16) {
            NavigationLink {
                ProgramDetailView(program: program)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today · \(program.name)")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1.3)
                        .foregroundStyle(accent)

                    Text(day?.name ?? "Program complete")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundStyle(Theme.text)

                    Text(day?.focus ?? "Review your progress or choose a new program.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            if let day {
                HStack {
                    Button {
                        store.startWorkout(program: program, day: day, week: run.week)
                        store.presentWorkout()
                    } label: {
                        Text(isActiveWorkout(program: program, day: day, week: run.week) ? "Resume Workout" : "Start Workout")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            } else if let firstDay = domainResolveProgramDay(program, dayIndex: 0, week: 1) {
                Button {
                    store.resetProgramProgress(id: program.id)
                    store.startWorkout(program: program, day: firstDay, week: 1)
                    store.presentWorkout()
                } label: {
                    Text("Start Workout")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(18)
        .background {
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [accent.opacity(0.30), Theme.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(accent.opacity(0.22))
                    .blur(radius: 28)
                    .frame(width: 120, height: 120)
                    .offset(x: 35, y: -40)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        }
    }

    private var noActiveProgramCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("No active program", systemImage: "square.grid.2x2")
                .font(.headline)
                .foregroundStyle(Theme.text)

            Text("Choose a program to make your next workout easy to start from Home.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)

            NavigationLink {
                ProgramsListView()
            } label: {
                Text("Browse Programs")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .cardStyle()
    }

    private var statsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            DashboardStatTile(icon: "flame.fill", value: "\(streak)", label: "Streak")
            DashboardStatTile(icon: "dumbbell.fill", value: "\(store.appData.logs.count)", label: "Workouts")
        }
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Spacer()

                if !recentLogs.isEmpty {
                    NavigationLink {
                        WorkoutHistoryView()
                    } label: {
                        Text("View all")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.accentLight)
                    }
                }
            }

            if recentLogs.isEmpty {
                Text("Finished workouts will show up here.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                VStack(spacing: 10) {
                    ForEach(recentLogs) { log in
                        NavigationLink {
                            WorkoutLogDetailView(log: log)
                        } label: {
                            RecentActivityRow(log: log, unit: store.appData.unit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var activeProgram: Program? {
        guard let activeProgramId = store.appData.activeProgramId else {
            return nil
        }

        return store.allPrograms.first(where: { $0.id == activeProgramId })
    }

    private var recentLogs: [WorkoutLog] {
        sortedLogs.prefix(3).map { $0 }
    }

    private var sortedLogs: [WorkoutLog] {
        store.appData.logs.sorted { dashboardLogDate($0) > dashboardLogDate($1) }
    }

    private var streak: Int {
        domainComputeStreak(logs: store.appData.logs)
    }

    private func nextDay(for program: Program) -> ProgramDay? {
        let run = domainProgramRun(
            program: program,
            logs: store.appData.logs,
            since: store.appData.programAnchors[program.id]
        )
        guard !run.isComplete else {
            return nil
        }

        return domainResolveProgramDay(program, dayIndex: run.dayIndex, week: run.week)
    }

    private func isActiveWorkout(program: Program, day: ProgramDay, week: Int) -> Bool {
        guard let activeWorkout = store.appData.activeWorkout else {
            return false
        }

        let sameSlot = activeWorkout.programId == program.id &&
            activeWorkout.dayId == day.id &&
            (activeWorkout.week ?? 1) == week
        guard sameSlot else {
            return false
        }

        return !store.appData.logs.contains { log in
            log.programId == program.id &&
                log.dayId == day.id &&
                (log.week ?? 1) == week
        }
    }
}

private struct DashboardStatTile: View {
    let icon: String
    let value: String
    let label: String
    var ringValue: Double? = nil

    var body: some View {
        VStack(spacing: 8) {
            if let ringValue {
                ProgressRing(value: ringValue, size: 38, lineWidth: 5, center: nil)
            } else {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(Theme.accentLight)
            }

            Text(value)
                .font(.title2.monospacedDigit().weight(.bold))
                .foregroundStyle(Theme.text)

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

private struct RecentActivityRow: View {
    let log: WorkoutLog
    let unit: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.dayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)

                Text("\(log.programName) · \(dashboardFormatDate(log.date))")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(dashboardFormatNumber(log.totalVolume)) \(unit)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(Theme.accentLight)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.textFaint)
            }
        }
        .cardStyle()
    }
}

private func greeting() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 5..<12:
        return "Good morning"
    case 12..<17:
        return "Good afternoon"
    default:
        return "Good evening"
    }
}

private func dashboardLogDate(_ log: WorkoutLog) -> Date {
    dashboardParseDate(log.date) ?? .distantPast
}

private func dashboardParseDate(_ value: String) -> Date? {
    ISO8601DateFormatter().date(from: value) ?? DashboardFallbackDateFormatter.shared.date(from: value)
}

private func dashboardFormatDate(_ value: String) -> String {
    guard let date = dashboardParseDate(value) else {
        return value
    }

    return DashboardDisplayDateFormatter.shared.string(from: date)
}

private func dashboardFormatNumber(_ value: Double) -> String {
    if value.rounded() == value {
        return "\(Int(value))"
    }

    return String(format: "%.1f", value)
}

private enum DashboardDisplayDateFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

private enum DashboardFallbackDateFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
