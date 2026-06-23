import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            if store.user == nil {
                NavigationStack {
                    AuthView()
                }
            } else {
                AppShellView()
            }
        }
        .task {
            await store.restoreSession()
        }
        .preferredColorScheme(preferredColorScheme)
        .overlay {
            if store.isLoading {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    ProgressView()
                        .tint(Color(hex: store.appData.themeColor))
                        .padding(24)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch store.appData.themeMode {
        case "dark":
            return .dark
        case "light":
            return .light
        default:
            return nil
        }
    }
}

struct AppShellView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                NavigationStack {
                    DashboardView()
                }
                .tabItem {
                    Label("Home", systemImage: "house")
                }

                NavigationStack {
                    ProgramsListView()
                }
                .tabItem {
                    Label("Programs", systemImage: "square.grid.2x2")
                }

                NavigationStack {
                    IntervalTimerView()
                }
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

                NavigationStack {
                    PeopleSearchView()
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

                NavigationStack {
                    WorkoutHistoryView()
                }
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
            }
            .tint(Color(hex: store.appData.themeColor))

            if let activeWorkoutContext {
                ResumeWorkoutBanner(program: activeWorkoutContext.program, day: activeWorkoutContext.day) {
                    store.presentWorkout()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 58)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { store.isWorkoutPresented },
            set: { if !$0 { store.dismissWorkout() } }
        )) {
            if let activeContext {
                NavigationStack {
                    ActiveWorkoutView(
                        program: activeContext.program,
                        day: activeContext.day,
                        week: activeContext.week
                    )
                }
            } else {
                EmptyView()
            }
        }
    }

    private var activeContext: (program: Program, day: ProgramDay, week: Int)? {
        let programId = store.appData.activeWorkout?.programId ?? store.workoutPresentationProgramId
        let dayId = store.appData.activeWorkout?.dayId ?? store.workoutPresentationDayId
        let week = store.appData.activeWorkout?.week ?? store.workoutPresentationWeek ?? 1

        guard let programId,
              let dayId,
              let program = store.allPrograms.first(where: { $0.id == programId }),
              let dayIndex = program.days.firstIndex(where: { $0.id == dayId }),
              let day = domainResolveProgramDay(program, dayIndex: dayIndex, week: week) else {
            return nil
        }

        return (program, day, week)
    }

    private var activeWorkoutContext: (program: Program, day: ProgramDay, week: Int)? {
        guard let active = store.appData.activeWorkout,
              let program = store.allPrograms.first(where: { $0.id == active.programId }),
              let dayIndex = program.days.firstIndex(where: { $0.id == active.dayId }),
              let day = domainResolveProgramDay(program, dayIndex: dayIndex, week: active.week ?? 1) else {
            return nil
        }

        return (program, day, active.week ?? 1)
    }
}

private struct ResumeWorkoutBanner: View {
    let program: Program
    let day: ProgramDay
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.accentLight)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Resume Workout")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.text)
                    Text("\(program.name) · \(day.name)")
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.up")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textFaint)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct PlaceholderView: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Theme.accentLight)

            Text(title)
                .font(.system(.largeTitle, design: .default, weight: .semibold))
                .foregroundStyle(Theme.text)

            Text("This screen is mapped in docs/ios-swiftui-screens.md and is ready for the next phase.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textDim)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground()
    }
}
