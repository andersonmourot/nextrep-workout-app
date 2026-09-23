import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            if store.updateRequired {
                UpdateRequiredView(storeURL: store.appStoreURL)
            } else if store.user == nil {
                NavigationStack {
                    AuthView()
                }
                .keyboardDismissToolbar()
            } else {
                AppShellView()
            }
        }
        .task {
            await store.restoreSession()
        }
        .task {
            await store.checkForUpdates()
        }
        .accentColor(Color(hex: store.appData.themeColor))
        .tint(Color(hex: store.appData.themeColor))
        .preferredColorScheme(preferredColorScheme)
        .scrollDismissesKeyboard(.interactively)
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

func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

struct AppShellView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                NavigationStack {
                    DashboardView()
                }
                .keyboardDismissToolbar()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

                NavigationStack {
                    ProgramsListView()
                }
                .keyboardDismissToolbar()
                .tabItem {
                    Label("Programs", systemImage: "square.grid.2x2")
                }

                NavigationStack {
                    IntervalTimerView()
                }
                .keyboardDismissToolbar()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

                NavigationStack {
                    PeopleSearchView()
                }
                .keyboardDismissToolbar()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

                NavigationStack {
                    WorkoutHistoryView()
                }
                .keyboardDismissToolbar()
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

            if let version = store.updateAvailableVersion {
                UpdateNudgeBanner(
                    version: version,
                    storeURL: store.appStoreURL,
                    onDismiss: { store.dismissUpdateNudge() }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, activeWorkoutContext != nil ? 132 : 58)
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
                .keyboardDismissToolbar()
            } else {
                EmptyView()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.finishStaleWorkoutIfNeeded()
                Task {
                    await store.checkForUpdates()
                }
            } else if phase == .background {
                Task {
                    await store.syncNow()
                }
            }
        }
        .task(id: store.activeWorkout?.restEndsAt) {
            await watchRestCompletion()
        }
    }

    /// Plays the rest-complete tone at expiry even when the workout sheet
    /// (and its FloatingRestBar) isn't on screen. While the app is
    /// backgrounded, the scheduled local notification covers it instead.
    private func watchRestCompletion() async {
        guard let endsAt = store.activeWorkout?.restEndsAt else {
            return
        }
        let endDate = Date(timeIntervalSince1970: endsAt / 1000)
        while !Task.isCancelled, Date.now < endDate {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        guard !Task.isCancelled,
              store.activeWorkout?.restEndsAt == endsAt else {
            return
        }
        playNextRepTimerSound(store.appData.timerSound)
    }

    private var activeContext: (program: Program, day: ProgramDay, week: Int)? {
        let programId = store.activeWorkout?.programId ?? store.workoutPresentationProgramId
        let dayId = store.activeWorkout?.dayId ?? store.workoutPresentationDayId
        let week = store.activeWorkout?.week ?? store.workoutPresentationWeek ?? 1

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
        guard let active = store.activeWorkout,
              let program = store.allPrograms.first(where: { $0.id == active.programId }),
              let dayIndex = program.days.firstIndex(where: { $0.id == active.dayId }),
              let day = domainResolveProgramDay(program, dayIndex: dayIndex, week: active.week ?? 1) else {
            return nil
        }

        return (program, day, active.week ?? 1)
    }
}

/// Full-screen gate shown when the backend reports this build is below the
/// minimum supported version. No way past — the only action is the App Store.
private struct UpdateRequiredView: View {
    let storeURL: URL?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Theme.accent)

                Text("Update required")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Theme.text)

                Text("This version of NextRep is no longer supported. Updating takes a moment and keeps all your data.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center)

                Button {
                    if let storeURL {
                        UIApplication.shared.open(storeURL)
                    }
                } label: {
                    Text("Update on the App Store")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(storeURL == nil)
            }
            .padding(32)
            .frame(maxWidth: 400)
        }
    }
}

private extension View {
    func keyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    dismissKeyboard()
                } label: {
                    Image(systemName: "checkmark")
                }
                .font(.headline.weight(.semibold))
                .accessibilityLabel("Dismiss keyboard")
            }
        }
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

/// Dismissible "new version available" pill — tapping Update opens the App
/// Store listing; dismissing snoozes it until a newer version ships.
private struct UpdateNudgeBanner: View {
    let version: String
    let storeURL: URL?
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.app.fill")
                .font(.title3)
                .foregroundStyle(Theme.accentLight)

            VStack(alignment: .leading, spacing: 2) {
                Text("NextRep \(version) available")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.text)
                Text("Update for the latest improvements")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
                    .lineLimit(1)
            }

            Spacer()

            Button("Update") {
                if let storeURL {
                    UIApplication.shared.open(storeURL)
                }
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Theme.accent)
            .clipShape(Capsule())
            .disabled(storeURL == nil)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textFaint)
            }
            .accessibilityLabel("Dismiss update notice")
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        }
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
